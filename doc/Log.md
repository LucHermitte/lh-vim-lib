# Logging Framework

## Description

lh-vim-lib provides a global logger since version 3.6.0.

By default, it'll echo everything with `:echomsg` (through `lh#log#echomsg`).

The logging policy can be set thanks to `lh#log#set_logger()`.
In plugins, logging can be done directly thanks to `lh#log#this()`, or though
an encapsulation, see below.

This logger doesn't support log level directly. Instead, the recommended way to
use it is to have logging helper functions in each plugins (autoload plugins,
or plain plugins, ftplugins, ...)  and to have these functions test a plugin
related verbose option to decide whether they log anything or not.
I use [mu-template](http://github.com/LucHermitte/mu-template) skeletons for
vim plugins to automatically define these
functions in my plugins.

## Usage

### ...from (autoload-)plugins

It looks like this:

```vim
" # Debug
let s:verbose = get(s:, 'verbose', 0)
function! lh#icomplete#verbose(...)
  if a:0 > 0
    let s:verbose = a:1
  endif
  return s:verbose
endfunction

function! s:Log(...)
  call call('lh#log#this', a:000)
endfunction

function! s:Verbose(...)
  if s:verbose
    call call('s:Log', a:000)
  endif
endfunction
```

### ...when we want to see the traces

Thus, if I want to trace what is done in my icomplete autoload plugin, I call

```vim
:call lh#icomplete#verbose(1)
" or If plugin/vim_maintain.vim from lh-misc is installed:
:Verbose icomplete
```

If I want to disable completely all logs, I can execute:

```vim
:call lh#log#set_logger('none')
```

If I prefer to see my traces on the right side, and in a
[|quickfix-window|](http://vimhelp.appspot.com/quickfix.txt.html#quickfix-window)
in order to trace the files + line numbers along with the message to log, I'll
execute

```vim
:call lh#log#set_logger('qf', 'vert')
```

## Screencast

![lh-vim-lib logging framework demo](screencast-log.gif "lh-vim-lib logging framework demo")

## Functions:

| Function                           | Purpose                                                                        |
|------------------------------------|--------------------------------------------------------------------------------|
| `lh#log#echomsg()`                 | Returns a new logger object, that logs with `:echomsg` (internal use)          |
| `lh#log#new()`                     | Returns a new logger object (internal use)                                     |
| `lh#log#none()`                    | Returns a new, inactive, logger object (internal use)                          |
| `lh#log#set_logger(kind, opts)`    | Sets the global logging policy (quickfix/loclist window, none, `echomsg`)      |
| `lh#log#this({format}, {args...})` | Logs a formatted message with the global logger                                |
| `lh#log#exception(...)`            | Logs the exception, and possibly its call stack, with the global logger.       |

