"=============================================================================
" File:         autoload/lh/exception.vim                         {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      3.6.1
let s:k_version = '3601'
" Created:      18th Nov 2015
" Last Update:  06th Jan 2016
"------------------------------------------------------------------------
" Description:
"       Functions related to VimL Exceptions
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
" Return a list of:
" - "script": filename of the vimscript where the function is defined
" - "pos":    absolute line number in this script file
" - "fname":  function name
" - "fstart": line where the function is defined in the script
" - "offset": offset, from the start of the function, of the line where the
"             exception was thrown
let g:stacks = []
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
      let fname = func_data[1]
      if fname =~ '\v(\<SNR\>|^)\d+_'
        let script_id = matchstr(fname,  '\v(\<SNR\>|^)\zs\d+\ze_')
        let fname  = substitute(fname, '\v(\<SNR\>|^)\d+_', 's:', '')
        let script = lh#askvim#scriptname(script_id)
      else
        let definition = split(lh#askvim#exe('verbose function '.func_data[1]), "\n")
        let script = matchstr(definition[1], '.\{-}\s\+\zs\f\+$')
      endif
      let script = substitute(script, '^\~', substitute($HOME, '\\', '/', 'g'), '')
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
  let g:stacks += [a:throwpoint]
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
