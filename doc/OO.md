# Object Oriented Programming in vim scripts
Sorry, I won't spend much time on explaining what Object Oriented Programming
is about.  I'll just focus on what could be done in Vim scripts and what
lh-vim-lib has to offer on the subject.

## How to do OO in vim scripts
A simplistic and perverted view of an _object_ is: a collection of _data_ and
of _methods_ that apply to that data.

Often we seek to provide a safe capsule around the data, and the data is
expected to be accessed through a controlled interface/abstraction. The
interface is defined as a series of exposed methods. These methods are somehow
the messages the object can handle and respond to. Note that what is important
is not the data, but the service the object can provide us.

### Dictionaries FTW
In vim script, the best building block available to define _objects_ is the
[dictionary](http://vimhelp.appspot.com/eval.txt.html#Dictionary). It's easy to
define attributes: for each name we have a value. And we can also define
methods as
[dictionary-functions](http://vimhelp.appspot.com/eval.txt.html#Dictionary%2dfunction).

We don't need anything more to define _objects_.

```vim
let my_first_object = {'__my_int': 0}
function! my_first_object.next() abort
    let self.__my_int += 1
endfunction
function! my_first_object.does_know_the_answer() abort
    return self.__my_int == 42
endfunction

...

while 1
    if my_first_object.does_know_the_answer()
        echo "Now I know!"
        break
    endif
    call my_first_object.next()
endwhile
```

Of course vim script language is not a rich as Python language: we don't have
special methods that are automatically used to natively implement stuff like
constructors, addition, stringification...

Also, as you can see, we define _objects_, not _classes_. As best we can have
factory functions that give a structure to _objects_ of a certain kind.

### Best practices
#### Encapsulation
In order to make sure object invariants are always true, it's best to keep
object internal state behind a protective capsule. Often we do this by hiding
internal data, which offers another nice property: it helps having stable
interfaces.

In all cases, there is no native way to have `private` fields in vim
dictionaries. At best we can follow Python conventions, and say that:

> A field with a name prefixed with an underscore is meant to not belong to
> the API: it may be removed, or deeply altered later on. IOW, don't use it in
> client code.

In Python, a field name starting with two underscores doesn't belong to the API
either, and it also relies on Python to avoid name collision when inheriting.
In vim scripts, the distinction doesn't really make any sense. I use it
sometimes to say: _"Really, this one, ignore it, it's none of your concern."_

#### Avoid anonymous functions
In the previous example I've used an
[anonymous-function](http://vimhelp.appspot.com/eval.txt.html#anonymous%2dfunction)
to define object methods.

I know several articles and blog posts promote this technique, but as a matter
of fact I highly advise you against this practice. Anonymous functions are a
[nightmare to debug](https://stackoverflow.com/questions/39862874/how-to-debug-error-while-processing-function-in-vim-and-nvim)
when something goes wrong.
We can know the function name is a number, we can obtain its code and where
it has been defined, but only as long as the function still exists -- This can
be done with `:verbose function {343}` for instance.

The problem is that if the function belongs only to a single dictionary
variable, and if that variable has been disposed of by Vim garbage collector,
then the function reference will also have been disposed of. As a consequence,
`:verbose function {343}` would end up in a `E123: Undefined function: 343`
error message.

As a consequence, it'll defeat any attempt made at decoding
[`v:throwpoint`](http://vimhelp.appspot.com/eval.txt.html#v%3athrowpoint). In
particular, it'll defeat my [assertion framework](DbC.md), my
[unit-testing framework](https://github.com/LucHermitte/vim-UT), and tricks
like [`:WTF`](Callstack.md#lhexceptionsay_what).


Also, when an object has been created with an anonymous function, reloading the
script where the function is defined won't necessarily update the definition of
the function in the object.

So, instead, use external script functions flagged with the `dict` annotation.
The previous example thus becomes:

```vim
function! s:next() dict abort
    let self.__my_int += 1
endfunction
function! s:does_know_the_answer() dict abort
    return self.__my_int == 42
endfunction

let my_first_object = {'__my_int': 0}
let my_first_object.next                 = function('s:next')
let my_first_object.does_know_the_answer = function('s:does_know_the_answer')
```

With older versions of Vim (7.3.1170 ?), `function('s:funcname')` isn't
supported. In those cases, we need the following trick:

```vim
function! s:getSNR(...) abort
  " needed to assure compatibility with old vim versions
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

let my_first_object.next                 = function(s:getSNR('next'))
let my_first_object.does_know_the_answer = function(s:getSNR('does_know_the_answer'))
```

#### Factory functions
In order to avoid scattering object creation all over the place, it's best to
define dedicated factory functions and to always use these functions to define
objects of a certain kind -- this pattern may have another name in language
like Javascript, let me know if there is anything better.

It could look like this:

```vim
function! s:method1(...) dict abort
   ...
endfunction
function! s:method2(...) dict abort
   ...
endfunction
...

function namespace#make_kindname(construction_parameters) abort
    " Check preconditions with lh-vim-lib DbC framework (=> fail-fast)
    call lh#assert#value(a:construction_parameters).verifies(some_preconditions)

    let res = {}
    let res._attribute = s:transform(a:construction_parameters)
    let res.method1    = function('s:method1')
    let res.method2    = function('s:method2')

    return res
endfunction
```

#### Polymorphism, and method overriding
One of the key feature of OO is _"extreme late binding of all things"_. For
most of us, this translates into _polymorphism_. Let's explore the concept with
vim script objects.

First, remember, as in Python, vim script language doesn't support
[_function overloading_](https://en.wikipedia.org/wiki/Function_overloading).
This means we cannot overload methods either.
At best we can define
[variadic functions](http://vimhelp.appspot.com/eval.txt.html#%2e%2e%2e) and
decode their parameters.

Polymorphism in vim scripts will be very close to polymorphism in Python. We
are in the _duck typing_ land: It walks like a duck, it quacks like a duck,
then this is a duck. There is no: _"we expect this parameter to belong to that
class or any derived class"_. We pass the parameter, if it has the right
method, then it certainly is the right parameter.

The first aspect of polymorphism and subtyping is this possibility to use an
object of a _type_ in an expression, and that the _type_ of this object may not
have existed when the expression was designed. Of course, we have no types but
ducks here, but the idea still applies.

```vim
let a_dog  = dog#make("Médor")
let a_bird = bird#make("Tweety")
call s:go_to_park(a_dog)
call s:go_to_park(a_bird)

" As long as both have a move() method, everything is fine.
" These objects don't even need to be related in any way.
```

A second aspect is that we should be able to specialize behaviours in the
objects used in the expression. The result may not be the same, but the
expression stays valid and produces results, which are compatible with some
postconditions.

The usual technique to achieve this consists in
[_overriding methods_](https://en.wikipedia.org/wiki/Method_overriding).

A typical way of doing this in vim scripts would be to have a factory function
for the parent kind of objects that (may) set a method, and a factory function
for the children that overrides that same method.

```vim
" -----[ autoload/parent.vim
function s:method() dict abort
  ...some generic/default behaviour
endfunction

function! parent#make(initial_state) abort
    let res = {'__state': a:initial_state}
    let res.method = function('s:method')
    return res
endfunction
...


" -----[ autoload/child.vim
function s:method() dict abort
  ...specialized behaviour
endfunction

function! child#make(initial_state) abort
    let res = parent#make(a:initial_state)

    " <<--- Here, we override the default behaviour --->>
    let res.method = function('s:method')

    return res
endfunction
```

Now, a problem arises. What if we need to call this default behaviour from the
new function? If a default behaviour has been written, it's likely already
doing interesting things we wouldn't like to duplicate, would we?

Here we have no choice but to store manually the old function reference
somewhere. Unlike Python and most other OO languages, Vim won't assist us in
any way here.

```vim
" -----[ autoload/child.vim
function s:method() dict abort
  do stuff
  call self.__parent_method()
  do some other stuff
endfunction

function! child#make(initial_state) abort
    let res = parent#make(a:initial_state)

    let res.__parent_method = res.method
    let res.method          = function('s:method')

    return res
endfunction
```

Happy? Honestly, I'm not. I really dislike this way of proceeding. I find it
doesn't scale. As personal rules I prefer to rely on
[_Template Method Design Pattern_](https://en.wikipedia.org/wiki/Template_method_pattern),
and to avoid to override methods that already have a behaviour. The drawback is
that I have to think beforehand about what the variation points are expected to
be. Actually, most of the time, I just end-up refactoring by extracting
sub-functions that become variation points.

In vim script, it translates into the following:

```vim
" -----[ autoload/parent.vim
function! s:common_stuff() dict abort
    some stuff that never change
    call self.__first_VP()
    some other stuff that never change
    call self.__second_VP()
    final stuff that never change
endfunction

function! parent#make(initial_state) abort
    let res = {'__state': a:initial_state}
    let res.common_stuff = function('s:common_stuff)
    " If we don't define __first_VP() nor __second_VP(), they are abstract...
    " As well as the object returned by parent#make()
    return res
endfunction

" -----[ autoload/child.vim
function! s:first_VP() dict abort
  ...
endfunction
function! s:second_VP() dict abort
  ...
endfunction

function! child#make(initial_state) abort
    let res = parent#make(a:initial_state)

    " And we make sure the object returned isn't abstract
    let res.__first_VP = function('s:first_VP')
    let res.__second_VP = function('s:second_VP')

    return res
endfunction
```

If you're not used to the terms _variation point_ and _commonalities_, think
that in the _parent_ part of the object you have a generic process where you've
identified hooks/callbacks. These hooks, you'll set them in the _child_ part of
the object built.


In all cases, if you override a method, make sure it accepts the same
parameters in the whole pseudo-hierarchy. Make also sure you never strengthen
preconditions, and that you never relax postconditions. For more information,
search for the
[LSP: Liskov Substitution Principle](https://en.wikipedia.org/wiki/Liskov_substitution_principle).
It has unexpected consequences, or at least, consequences we're used to:
(mutable) circles are not ellipses, sorted lists are not lists,
[coloured points are not points](https://www.pearson.com/us/higher-education/program/Bloch-Effective-Java-2nd-Edition/PGM310651.html),
and so on.

-----

## What lh-vim-lib can bring to the table
OK. Now, we have seen how to create objects and use them in vim scripts.

You're certainly wondering what's the point of documenting this as a part of
lh-vim-lib.

Well, lh-vim-lib provides a few small services vaguely related to OO
programming in vim script. They are not _must have_, but they are still quite
nice to have.

### Stringification
Let's say you want to display `my_first_object` state with `:echo
string(my_first_object)`. What will you see?

```
# In the case anonymous functions are used
{'__my_int': 0, 'does_know_the_answer': function('122'), 'next': function('121')}

# In the case script functions are used
{'__my_int': 0, 'does_know_the_answer': function('<SNR>257_does_know_the_answer'), 'next': function('<SNR>257_next')}
```

In both cases, there is a lot of noise: we don't really need to see
`function('122')` nor `function('<SNR>257_does_know_the_answer')`.

What would have been nicer is to see instead:

```
{'__my_int': 0}
# or in verbose mode:
{'__my_int': 0, '%%methods%%': ['does_know_the_answer', 'next']}
# or even, better:
{(internal state is 0: not the answer)}
```

In order to see these results, first the object needs to be created with:

```vim
let my_first_object = lh#object#make_top_type({'__my_int': 0})
let my_first_object.next = function('s:next')
...
```

`lh#object#make_top_type()` will automatically inject a few things in the
object:
 * a `__lhvl_oo_type()` method,
 * and a `_to_string()` method.

From here, we can display the object state with
`lh#object#to_string(my_first_object)` or with `my_first_object._to_string()`.
Methods won't be displayed. If we really want to display method names, call
first `lh#object#verbose(1)` -- call `lh#object#verbose(0)` to restore
default settings.

If instead, you prefer to display something else entirely, then define
a `to_string()` method, or override the `_to_string()` method with one to your
liking. e.g.

```vim
function! s:_to_string() dict abort
    return printf('{(internal state is %d: %sthe answer)}',
        \ self.__my_int,
        \ self.does_know_the_answer() ? '' : 'not ')
endfunction

function! my#make(....) abort
  ...
  call lh#object#inject_methods(res, s:k_script_name, '_to_string')
  ...
endfunction
```

### Method injection
Injecting methods in an object often requires a lot of duplicated stuff like
for instance:

```vim
let my_first_object.next                 = function('s:next')
let my_first_object.does_know_the_answer = function('s:does_know_the_answer')
...
```

#### Prerequisites for old Vim versions
As you have seen, it can be tedious with old versions of Vim, which requires
the `s:getSNR()` trick in the previous vanilla examples.

lh-vim-lib helper functions still need a similar trick in order to provide
_method-injection_ with older versions of Vim, and also to manually inject
methods (defined as script-local functions) into an existing object, from the
command-line.

The helper functions require either the number (returned by `:scriptname`) of
the current script, or the name of the current script.

IOW, first you'll need:

```vim
" Either this more efficient solution
function! s:getSID() abort
  return eval(matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_getSID$'))
endfunction
let s:k_script_name      = s:getSID()

" Or this much simplier solution, but less efficient
" To be defined at script level, not within a function!
let s:k_script_name      = expand('<sfile>:p')
```

#### `lh#object#inject_methods(object, snr, methodnames...)`
Method 1: You can inject a bunch of methods that have the same names as
script-local functions:

```vim
call lh#object#inject_methods(my_first_object, s:k_script_name,
     \ 'next', 'does_know_the_answer')
```

This can also be used on an existing object to inject methods defined as
script-local functions.

```vim
:" from the command-line
:call lh#object#inject_methods(my_existing_object, expand('%:p'), 'next')
```

#### `lh#object#inject(object, method_name, function_name, snr)`
Method 2: If the method names differ from the script-local function names,
you'll need to use instead:

```vim
function! s:h2g2_next() dict abort
   ...
function! s:h2g2_does_know_the_answer() dict abort
   ...

call lh#object#inject(my_first_object, 'next',                 'h2g2_next',                 s:k_script_name)
call lh#object#inject(my_first_object, 'does_know_the_answer', 'h2g2_does_know_the_answer', s:k_script_name)
```

This can also be used on an existing object to inject methods defined as
script-local functions.

```vim
:" from the command-line
:call lh#object#inject(my_existing_object, 'next', 'h2g2_next', expand('%:p'))
```

### Is this dictionary an (lhvl) object?
In order to check whether a dictionary is actually an object built with
`lh#object#make_top_type()`, I provide the boolean function
`lh#object#is_an_object(a_dictionary)`.

## See Also
I remember to have seen other vim scripts using objects in their code. They had
other utility functions, best practices, etc. Alas I can't remember their names.
