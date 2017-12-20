# Object Oriented Programming in vim scripts
Sorry, I won't spend much time on explaining what Object Oriented Programming
is about.  I'll just concentrate on what could be done in Vim side and what
lh-vim-lib has to offer on the subject.

## How to do OO in vim scripts
A simplistic and perverted view of an object is: a collection of data and
of methods that apply to that data.

Often we seek to provide a safe capsule around the data, and the data is
expected to be accessed through a controlled interface/abstraction. The
interface is defined as a series of exposed methods. These methods are somehow
the messages the object can handle and respond to. What is important is not the
data, but the service the object can provide us.

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

Of course vim script language is not a rich as Python Language: we don't have
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

As a matter of fact I highly advise you against this practice. Anonymous
functions are a
[nightmare to debug](https://stackoverflow.com/questions/39862874/how-to-debug-error-while-processing-function-in-vim-and-nvim),
all we can know about the function is a number and its code (e.g. `function
343`). We have no way to trace back in which file it has been defined. As a
consequence, it'll defeat any attempt made at decoding
[`v:throwpoint`](http://vimhelp.appspot.com/eval.txt.html#v%3athrowpoint). More
precisely, it'll defeat my [assertion framework](DbC.md), my
[unit-testing framework](https://github.com/LucHermitte/vim-UT), and tricks
like [`:WTF`](../autoload/lh/exception.vim#179) (TODO: document this feature
elsewhere).


Also, when an object has been created with an anonymous function, reloading the
script where the function is defined won't necessarily update the definition of
the function in the object.

So, instead, use external script functions. The previous example thus becomes:

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
like Javascript, let me know if there is a better name.

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

## What lh-vim-lib can bring to the table
OK. Now, you know how to create objects and use them in vim scripts.

You're certainly wondering what's the point of documenting this as a part of
lh-vim-lib.

Well, lh-vim-lib provides a few small services vaguely related to OO
programming in vim script. There are not _must have_, but they are still quite
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
_method-injection_ with older versions of Vim.

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

This can also be used on an existing object to inject methods defined a
script-local functions.

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

This can also be used on an existing object to inject methods defined a
script-local functions.

### Is this dictionary an (lhvl) object?
In order to check whether a dictionary is actually an object built with
`lh#object#make_top_type()`, I provide the boolean function
`lh#object#is_an_object(a_dictionary)`.

## See Also
I remember to have seen other vim scripts using objects in their code. They had
other utility functions, best practices, etc. Alas I can't remember their names.
