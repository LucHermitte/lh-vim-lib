"=============================================================================
" $Id$
" File:         autoload/lh/ft.vim                                {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" License:      GPLv3 with exceptions
"               <URL:http://code.google.com/p/lh-vim/wiki/License>
" Version:      3.1.16
" Created:      28th Jan 2014
" Last Update:  $Date$
"------------------------------------------------------------------------
" Description:
"       library functions related to filetype manipulations
" 
"------------------------------------------------------------------------
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
let s:k_version = 3116
function! lh#ft#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = 0
function! lh#ft#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#ft#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" Function: lh#ft#is_text(...) {{{3
function! lh#ft#is_text(...)
  let ft = a:0 == 0 ? &ft : (a:1)
  return ft =~ '^$\|text\|latex\|tex\|html\|docbk\|help\|mail\|man\|xhtml'
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
