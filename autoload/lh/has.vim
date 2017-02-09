"=============================================================================
" File:         autoload/lh/has.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0
let s:k_version = '400000'
" Created:      02nd Sep 2016
" Last Update:  09th Feb 2017
"------------------------------------------------------------------------
" Description:
"       Synthetize compatibility options.
"       It's meant to avoid searching the patch list again and again when a
"       feature has appeared in a working version.
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
function! lh#has#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#has#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Log(expr, ...)
  call call('lh#log#this',[a:expr]+a:000)
endfunction

function! s:Verbose(expr, ...)
  if s:verbose
    call call('s:Log',[a:expr]+a:000)
  endif
endfunction

function! lh#has#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" # Vim features {{{2

" Function: lh#has#lambda() {{{3
function! lh#has#lambda() abort
  return has("lambda")
endfunction

" Function: lh#has#partials() {{{3
function! lh#has#partials() abort
  return has("patch-7.4.1558")
endfunction

" Function: lh#has#jobs() {{{3
function! lh#has#jobs() abort
  return exists('*job_start') && has("patch-7.4.1980")
endfunction

" Function: lh#has#default_in_getbufvar() {{{3
function! lh#has#default_in_getbufvar() abort
  return has("patch-7.3.831")
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
