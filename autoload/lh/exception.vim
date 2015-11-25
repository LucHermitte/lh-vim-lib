"=============================================================================
" File:         autoload/lh/exception.vim                         {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} gmail {dot} com>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      3.3.16.
let s:k_version = '3316'
" Created:      18th Nov 2015
" Last Update:  25th Nov 2015
"------------------------------------------------------------------------
" Description:
"       Functions related to VimL Exceptions
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#exception#version()
  return s:k_version
endfunction

" # Debug   {{{2
if !exists('s:verbose')
  let s:verbose = 0
endif
function! lh#exception#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#exception#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

" # Call Stack decoding {{{2

" Function: lh#exception#callstack(throwpoint) {{{3
function! lh#exception#callstack(throwpoint) abort
  let stack = split(a:throwpoint, '\.\.')
  call reverse(stack)

  let function_stack = []
  let dScripts = {}
  for sFunc in stack
    let func_data = matchlist(sFunc, '\(\k\+\)\[\(\d\+\)\]')
    if empty(func_data)
      " TODO: support when vim is in other language than English or French
      " => need access to vim internal gettext usage
      let func_data = matchlist(sFunc, '\(\k\+\), \%(line\|ligne\) \(\d\+\)')
    endif
    if !empty(func_data)
      let definition = split(lh#askvim#exe('verbose function '.func_data[1]), "\n")
      let script = matchstr(definition[1], '.\{-}\s\+\zs\f\+$')
      let script = substitute(script, '^\~', $HOME, '')
      let fname  = substitute(func_data[1], '<SNR>\d\+_', 's:', '')
      if filereadable(script)
        if !has_key(dScripts, script)
          let dScripts[script] = reverse(readfile(script))
        endif
        let fstart = len(dScripts[script]) - match(dScripts[script], '^\s*fu\%[nction]!\=\s\+'.fname)
        let function_stack += [{'script': script, 'fname': fname,
              \ 'offset': func_data[2], 'fstart': fstart,
              \ 'pos': (func_data[2]+fstart)
              \ }]
      endif
    endif
  endfor
  return function_stack
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
