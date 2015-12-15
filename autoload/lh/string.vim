"=============================================================================
" File:         autoload/lh/string.vim                            {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      3.4.0.
let s:k_version = '3400'
" Created:      08th Dec 2015
" Last Update:  15th Dec 2015
"------------------------------------------------------------------------
" Description:
"       String related function
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
function! lh#string#version()
  return s:k_version
endfunction

" # Debug   {{{2
if !exists('s:verbose')
  let s:verbose = 0
endif
function! lh#string#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#string#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
"
" # Trimming {{{2
"
" Function: lh#string#trim(string) {{{3
" @version 3.4.0
function! lh#string#trim(string) abort
  return matchstr('^\v\s*\zs.{-}\ze\s*$', a:string)
endfunction

" # Matching {{{2
" Function: lh#string#matches(string, pattern) {{{3
" snippet from Peter Rincker: http://stackoverflow.com/a/34069943/15934
" @version 3.4.0
function! lh#string#matches(string, pattern) abort
  let res = []
  call substitute(a:string, a:pattern, '\=add(res, submatch(0))', 'g')
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
