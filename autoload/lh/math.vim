"=============================================================================
" File:         autoload/lh/math.vim                              {{{1
" Author:       Troy Curtis Jr <troycurtisjr@gmail.com>
let s:k_version = '350'
" Created:      17th Jan 2016
"------------------------------------------------------------------------
" Description:
"       This file contains utilities for portably working with math functions.
"
"------------------------------------------------------------------------
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#math#version()
  return s:k_version
endfunction

" # Debug   {{{2
if !exists('s:verbose')
  let s:verbose = 0
endif
function! lh#math#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#math#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

" Function: lh#math#abs(val) {{{2
" Returns the absolute value of the given number. Needed for compatibility
" with older vim versions.
function! lh#math#abs(val)
  " This could check to see if the abs() built-in exists, however I suspect
  " the existance check is more expensive than just doing it directly.
  return a:val >= 0 ? a:val : -a:val
endfunction
" }}}2
"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
