"=============================================================================
" File:         autoload/lh/ft.vim                                {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      5.2.1
let s:k_version = 50201
" Created:      28th Jan 2014
" Last Update:  15th Sep 2020
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
function! lh#ft#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#ft#verbose(...)
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

function! lh#ft#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" Function: lh#ft#is_text(...) {{{3
function! lh#ft#is_text(...)
  let ft = a:0 == 0 ? &ft : (a:1)
  return ft =~ '^$\|text\|latex\|tex\|html\|docbk\|help\|mail\|man\|xhtml\|markdown\|rst\|gitcommit'
endfunction

" Function: lh#ft#is_script(...) {{{3
function! lh#ft#is_script(...) abort
  let ft = a:0 == 0 ? &ft : (a:1)
  return ft =~ 'sh$\|perl\|ruby\|python'
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
