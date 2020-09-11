# Callstack decoding

The topic is about obtaining the current function call stack. Its main
applications relate to plugin maintenance: debugging,
[unit testing](https://github.com/LucHermitte/vim-UT), [DbC](DbC.md),
[logging](Log.md) ...

While Vim knows internally its current call stack, this information wasn't
directly available to us up until Vim 8.2.1297 which introduces
[`expand(<stack>)`](http://vimhelp.appspot.com/cmdline.txt.html#%3cstack%3e).
Unfortunatelly the result is in text format and it still needs parsing, but at
least this string isn't localized.
[In a ideal world we would have been able to obtain real callstack object...](https://github.com/vim/vim/issues/1125)

Up until Vim 8.2.1297, we had to trick vim into giving us the information.
The idea was to throw an exception and to decode
[`v:throwpoint`](http://vimhelp.appspot.com/eval.txt.html#v%3athrowpoint). Note
however that this must not be abused as it could cripple down your plugin
performances. Fortunatelly `v:throwpoint` and `expand(<stack>)` are almost in
the same format.

## API
### `lh#exception#callstack(throwpoint)`
Parses `throwpoint`, in the current locale, to extract the function call stack.
This function is compatible with
[`v:throwpoint`](http://vimhelp.appspot.com/eval.txt.html#v%3athrowpoint) and
[`expand(<stack>)`](http://vimhelp.appspot.com/cmdline.txt.html#%3cstack%3e).

Returns a list of:
- `"script"`: filename of the vim script where the function is defined
- `"pos"`:    absolute line number in this script file
- `"fname"`:  function name
- `"fstart"`: line where the function is defined in the script
- `"offset"`: offset, from the start of the function, of the line where the
            exception was thrown

In case the script file could not be obtained, `"script"` will value `"???"`,
`"fstart"` will value 0, and `"pos"` will value `"offset"`.

Example:

```vim
function! s:some_func() abort
    try
        throw "dummy"
    catch /.*/
        let callstack = lh#exception#callstack(v:throwpoint)
    endtry
    do_something_with(callstack)
endfunction

" or
function! s:some_func() abort
    let callstack = lh#exception#callstack(expand('<stack>'))
    do_something_with(callstack)
endfunction
```

Note: In a _*nix_ world, or precisely when `bash` is detected, the call stack
is correctly analysed whatever the current locale is. On a pure windows system,
you'd need to stay in a C locale to make sure `v:throwpoint` could be correctly
decoded.

### `lh#exception#decode([throwpoint=v:throwpoint])`
Given a _throwpoint_ (or `expand(<stack>)`), creates an [object](OO.md)
containing call stack information.

The object is made of:
- `"callstack"`: [list](http://vimhelp.appspot.com/eval.txt.html#List)
  returned by [`lh#exception#callstack()`](#lhexceptioncallstackthrowpoint).
- `"as_qf()"`: method that converts the call stack object into a list accepted
  by [`setqflist()`](http://vimhelp.appspot.com/eval.txt.html#setqflist%28%29).

### `lh#exception#get_callstack()`
Helper function to obtain the call stack at the current call-site. It takes
care of returning `expand('<stack>')` if possible, or of throwing the dummy
exception otherwise. You can see this function as the first main entry point.

It returns the object returned by [`lh#exception#decode()`](#lhexceptiondecodethrowpointvthrowpoint).

Notes:
- As of vim 8.0-314, the size of the call stack is always of 1 when called from
  a "script. See [Vim issue#1480](https://github.com/vim/vim/issues/1480).
- It clears the current function level (i.e. the context of
  `lh#exception#get_callstack()` function).

### `lh#exception#callstack_as_qf(filter, [msg])`
Returns the call stack as a list compatible with
[`setqflist()`](http://vimhelp.appspot.com/eval.txt.html#setqflist%28%29). You
can see this function as the second main entry point.

Internally it returns
[`lh#exception#get_callstack().as_qf()`](#lhexceptionget_callstack) filtered
(by [`filter()`](http://vimhelp.appspot.com/eval.txt.html#filter%28%29))
with `filter` parameter.

The typical use case for this function is from plugins that wish to display the
call stack. This way, we can ignore the context injected by these plugins to
display only pertinent information.


### `lh#exception#say_what()`
This function has been inspired by
https://github.com/tweekmonster/exception.vim
It analyses last error message reported by Vim, the call stack is expanded into
as many entries as required, and the result is displayed in the
[quickfix window](http://vimhelp.appspot.com/quickfix.txt.html#quickfix%2dwindow).

A neat way to use it consists in defining the following command (in your
`.vimrc` for instance) -- at this time I don't provide the command
automatically in a plugin script:

```vim
" .vimrc
" Parameter: number of errors to decode, default: "1"
command! -nargs=? WTF call lh#exception#say_what(<q-args>)
```

The differences (with `tweekmonster/exception.vim`) are the following:
- It supports localized messages
- It supports autoloaded functions, even when `#` isn't in
  [`'isk'`](http://vimhelp.appspot.com/options.txt.html#%27isk%27) (that may
  happen depending on the filetype of the current buffer)
- It uses a framework that have been here for little time for other topics
  (logging, unit testing)
- It has as few loops as possible -- 1. I hate debugging them, 2. This permits
  to run faster.

In the end of DbC framework demo, you'll see a live application of
`lh#exception#say_what()`. You'll also see applications of the other call stack
related functions to display the call stack on failed assertions.

![lh-vim-lib DbC framework demo](screencast-dbc.gif "lh-vim-lib DbC framework demo")
