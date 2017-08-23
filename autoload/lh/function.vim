"=============================================================================
" File:         autoload/lh/function.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      4.0.0
let s:k_version = 400
" Created:      03rd Nov 2008
" Last Update:  23rd Aug 2017
"------------------------------------------------------------------------
" Description:
"       Implements:
"       - lh#function#bind()
"       - lh#function#execute()
"       - lh#function#prepare()
"       - a binded function type
"
"------------------------------------------------------------------------
" History:
"       v4.0.0:  ENH: Use new OO top class
"                ENH: Use `call()` instead of `eval()`
"                PERF: Improve `#execute()` performances
"       v3.6.1:  ENH: Use new logging framework
"       v3.4.0:  ENH: lh#function#bind supports composition
"       v3.3.20: Explicit error msg w/ lh#function#execute
"       v3.3.15: lh#function#execute(string) supports now v:val as well.
"       v3.3.11: Bug fix: pass tests
"       v3.2.9:  Bug fix when &isk is messed up in lh#function#execute()
"       v3.0.0:  GPLv3
"       v2.2.0:  first implementation
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------

" ## Misc Functions     {{{1
" # Version {{{2
function! lh#function#version()
  return s:k_version
endfunction

" # Debug {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#function#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
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

function! lh#function#debug(expr) abort
  return eval(a:expr)
endfunction


"=============================================================================
" ## Functions {{{1
" # Function: s:Join(arguments...) {{{2
function! s:Join(args) abort
  let res = ''
  if len(a:args) > 0
    let res = string(a:args[0])
    let i = 1
    while i != len(a:args)
      let res.=','.string(a:args[i])
      let i += 1
    endwhile
  endif
  return res
endfunction

" # Function: s:DoBindList(arguments...) {{{2
function! s:DoBindList(formal, real) abort
  let args = map(copy(a:formal),
        \ 'type(v:val) != type("str")        ? v:val '
        \.': match(v:val, "\\v^v:\\d+_$")>=0 ? a:real[matchstr(v:val, "\\vv:\\zs\\d+\\ze_")-1] '
        \.': eval(s:DoBindEvaluatedString(v:val, a:real))')
  return args
endfunction

" # Function: s:DoBindString(arguments...) {{{2
function! s:DoBindString(expr, real) abort
  let cleanup = lh#on#exit()
        \.restore('&isk')
  try
    set isk&vim
    let expr = substitute(a:expr, '\v<v:val>', a:real.'[0]', 'g')
    let expr = substitute(expr, '\v<v:(\d+)_>', a:real.'[\1-1]', 'g')
    return expr
  finally
    call cleanup.finalize()
  endtry
endfunction

function! s:ToString(expr) abort
  return
        \   type(a:expr) != type('')  ? string(a:expr)
        \ : a:expr =~ '\v<v:(\d+)_>'  ? a:expr
        \ :                             string(a:expr)
        " \ : (a:expr)
endfunction

function! s:DoBindEvaluatedString(expr, real) abort
  let expr = substitute(a:expr,  '\v<v:(\d+)_>', '\=s:ToString(a:real[submatch(1)-1])', 'g')
  return expr
endfunction

" # Function: s:Execute(arguments...) {{{2
function! s:Execute(args) dict abort
  let args = has_key(self, 'args') ? s:DoBindList(self.args, a:args) : a:args
  if type(self.function) == type(function('exists'))
    let res = call(self.function, args)
  elseif type(self.function) == type('string')
    let expr = s:DoBindString(self.function, 'args')
    let res = eval(expr)
  elseif type(self.function) == type({})
    return self.function.execute(args)
  else
    throw "lh#functor#execute: unpected function type: ".type(self.function)
  endif
  return res
endfunction

" # Function: lh#function#prepare(function, arguments_list) {{{2
function! lh#function#prepare(Fn, arguments_list) abort
  if     type(a:Fn) == type(function('exists'))
    let expr = string(a:Fn).'('.s:Join(a:arguments_list).')'
    return expr
  elseif type(a:Fn) == type('string')
    if a:Fn =~ '^[a-zA-Z0-9_#]\+$'
      let expr = string(function(a:Fn)).'('.s:Join(a:arguments_list).')'
      return expr
    else
      let expr = s:DoBindString(a:Fn, 'a:000')
      return expr
    endif
  else
    throw "lh#function#prepare(): {Fn} argument of type ".type(a:Fn). " is unsupported"
  endif
endfunction

" # Function: lh#function#execute(function, arguments...) {{{2
function! lh#function#execute(Fn, ...) abort
  if type(a:Fn) == type({}) && has_key(a:Fn, 'execute')
    return a:Fn.execute(a:000)
  else
    let expr = lh#function#prepare(a:Fn, a:000)
    try
      return eval(expr)
    catch /.*/
      " Note: if you are experimenting a E16: invalid range, you may want to
      " escape the '[' from the expression part as [z-a] is not a valid range,
      " even if your text as nothing to do with a range
      throw "Cannot execute the expression: ".expr ."\nWith a:000=".string(a:000)
            \ ."\n-> ".v:exception
            \ ."\n-> ".v:throwpoint
    endtry
  endif
endfunction

" # Function: lh#function#bind(function, arguments...) {{{2
function! lh#function#bind(Fn, ...) abort
  let args = copy(a:000)
  if type(a:Fn) == type('string') && a:Fn =~ '^[a-zA-Z0-9_#]\+$'
        \ && exists('*'.a:Fn)
    let Fn = function(a:Fn)
  elseif type(a:Fn) == type({})
    " echo string(a:Fn).'('.string(a:000).')'
    " Rebinding another binded function
    " TASSERT has_key(a:Fn, 'function')
    " TASSERT has_key(a:Fn, 'execute')
    " TASSERT has_key(a:Fn, 'args')
    let Fn = a:Fn.function
    let N = has_key(a:Fn, 'args') ? len(a:Fn.args) : 0
    if N != 0 " args to rebind
      let i = 0
      let t_args = [] " necessary to avoid type changes
      while i != N
        let arg = a:Fn.args[i]
        if arg =~ 'v:\d\+_$'
          let arg2 = eval(s:DoBindString(arg, string(args)))
          " echo arg."-(".string(args).")->".string(arg2)
          unlet arg
          let arg = arg2
          unlet arg2
        endif
        call add(t_args, arg)
        let i += 1
        unlet arg
      endwhile
      unlet a:Fn.args
      let a:Fn.args = t_args
    else " expression to fix
      " echo Fn
      " echo s:DoBindString(Fn, string(args))
      " echo eval(string(s:DoBindString(Fn, string(args))))
      let Fn = (s:DoBindEvaluatedString(Fn, args))
    endif
    let args = get(a:Fn, 'args', [])
  else
    let Fn = a:Fn
  endif

  let binded_fn = lh#object#make_top_type({
        \ 'function': Fn,
        \ 'execute':  function(s:getSNR('Execute'))
        \})
  if !empty(args)
    " Special case: when bind is used abusivelly
    let binded_fn.args = args
  endif
  return binded_fn
endfunction

"=============================================================================
" ## Internal functions {{{1
"
" " s:getSNR([func_name]) {{{3
function! s:getSNR(...)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
" Vim: let g:UTfiles='tests/lh/function.vim'
