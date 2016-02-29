"=============================================================================
" File:         autoload/lh/math.vim                              {{{1
" Authors:      Troy Curtis Jr <troycurtisjr@gmail.com>, lh#math#abs() code
"               Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com> (maintainer)
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      3.8.0.
let s:k_version = '380'
" Created:      17th Jan 2016
" Last Update:  29th Feb 2016
"------------------------------------------------------------------------
" Description:
"       Math oriented toolbox
"       - utilities for portability working with math functions
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
let s:verbose = get(s:, 'verbose', 0)
function! lh#math#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Log(expr)
  call lh#log#this(a:expr)
endfunction

function! s:Verbose(expr)
  if s:verbose
    call s:Log(a:expr)
  endif
endfunction

function! lh#math#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" Function: lh#math#abs(val) {{{2
if exists('*abs')
  function! lh#math#abs(val) abort
    return abs(a:val)
  endfunction
else
  function! lh#math#abs(val) abort
    return a:val >= 0 ? a:val : - a:val
  endfunction
endif

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
