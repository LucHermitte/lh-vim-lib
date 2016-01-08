"=============================================================================
" File:         autoload/lh/fmt.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      3.6.1.
let s:k_version = '3.6.01'
" Created:      20th Nov 2015
" Last Update:  08th Jan 2016
"------------------------------------------------------------------------
" Description:
"       Formatting functions
"
"------------------------------------------------------------------------
" TODO:
"       Support named fields
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#fmt#version()
  return s:k_version
endfunction

" # Debug   {{{2
if !exists('s:verbose')
  let s:verbose = 0
endif
function! lh#fmt#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#fmt#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" # Formatting {{{2
" Function: lh#fmt#printf(format, args) {{{3
" TODO:
" - support precision/width/fill
" - %%1 that would expand into %1
function! lh#fmt#printf(format, ...) abort
  let args = map(copy(a:000), 'lh#string#as(v:val)')
  let res = substitute(a:format, '\v\%(\d+)', '\=args[submatch(1)-1]', 'g')
  return res
endfunction


"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
