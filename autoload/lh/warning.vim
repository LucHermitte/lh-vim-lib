"=============================================================================
" File:         autoload/lh/warning.vim                           {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/blob/master/License.md>
" Version:      5.4.0.
let s:k_version = '540'
" Created:      20th Feb 2024
" Last Update:  20th Feb 2024
"------------------------------------------------------------------------
" Description:
"       Support functions for emitting warnings that remember their context
"
"------------------------------------------------------------------------
" History:
"       v5.4.0 First version
" TODO:
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#warning#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#warning#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Log(expr, ...) abort
  call call('lh#log#this',[a:expr]+a:000)
endfunction

function! s:Verbose(expr, ...) abort
  if s:verbose
    call call('s:Log',[a:expr]+a:000)
  endif
endfunction

function! lh#warning#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Globals {{{1

let s:warnings = get(s:, 'warnings', [])

"------------------------------------------------------------------------
" ## Exported functions {{{1

" Function: lh#warning#clear() {{{2
function! lh#warning#clear() abort
  let s:warnings = []
endfunction

" Function: lh#warning#emit(message) {{{2
function! lh#warning#emit(message) abort
  let context = lh#exception#callstack_as_qf_from('lh#warning', [a:message, 'W'])
  call add(s:warnings, [a:message, context])
  call lh#common#warning_msg(a:message)
endfunction

"------------------------------------------------------------------------
" ## Comamnd functions {{{1

" Function: lh#warning#_command(...) {{{2
function! lh#warning#_command(...) abort
  let action = get(a:, 1, '')
  if action == 'clear'
    call lh#warning#clear()
  elseif action == ''
    call lh#warning#_display()
  else
    echoerr printf("E474: Invalid argument '%s'. Only 'clear' is supported", action)
    return
  endif
endfunction

" Function: lh#warning#_command_complete(A, L, P) {{{3
function! lh#warning#_command_complete(A, L, P) abort
  return ['clear', '']
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

" Function: lh#warning#_display() {{{2
function! lh#warning#_display() abort
  let qf = []
  for wrn in s:warnings
    call extend(qf, wrn[1])
  endfor
  call setqflist(qf)
  call setqflist([], 'a', {'title': 'Vimscript warnings'})
  if exists(':Copen')
    Copen
  else
    copen
  endif
endfunction

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
