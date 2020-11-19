"=============================================================================
" File:         autoload/lh/has.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      5.2.2
let s:k_version = '50202'
" Created:      02nd Sep 2016
" Last Update:  19th Nov 2020
"------------------------------------------------------------------------
" Description:
"       Synthetize compatibility options.
"       It's meant to avoid searching the patch list again and again when a
"       feature has appeared in a working version.
"
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

" Function: lh#has#patch(vernumber)       {{{3
if (v:version > 704) || (v:version == 704 && has('patch237'))
  function! lh#has#patch(vernumber) abort
    return has(a:vernumber)
  endfunction
else
  function! lh#has#patch(vernumber) abort
    let [all, major, minor, patch; tail] = matchlist(a:vernumber, '\v^patch-(\d+)\.(\d+)[.-](\d+)$')
    let ver = eval(printf('%d%02d', major, minor))
    return (v:version > ver) || (v:version == ver && has('patch'.patch))
  endfunction
endif

" Function: lh#has#default_in_getbufvar() {{{3
function! lh#has#default_in_getbufvar() abort
  return lh#has#patch("patch-7.3.831")
endfunction

" Function: lh#has#jobs()                 {{{3
function! lh#has#jobs() abort
  return exists('*job_start') && lh#has#patch("patch-7.4.1980")
endfunction

" Function: lh#has#lambda()               {{{3
function! lh#has#lambda() abort
  return has("lambda")
endfunction

" Function: lh#has#partials()             {{{3
function! lh#has#partials() abort
  return lh#has#patch("patch-7.4.1558")
endfunction

" Function: lh#has#properties_in_qf() {{{3
" @since v 4.5.0
function! lh#has#properties_in_qf() abort
  return lh#has#patch("patch-7.4.2200")
endfunction

" Function: lh#has#redo()                 {{{3
" @since v 4.4.0
function! lh#has#redo() abort
  return has('patch-7.4.849')
endfunction

" Function: lh#has#setqflist_lines() {{{3
function! lh#has#setqflist_lines() abort
  return has('patch-8.0.1031')
endfunction

" Function: lh#has#vkey()                 {{{3
function! lh#has#vkey() abort
  return lh#has#patch('patch-7.2-295')
endfunction

" Function: lh#has#writefile_append() {{{3
" @since v 4.6.0
function! lh#has#writefile_append() abort
  return has('patch-7.4.503')
endfunction

" # Vim installation {{{2
" Function: lh#has#plugin(name) {{{3
" @since Version 4.7.1
function! lh#has#plugin(name) abort
  return !empty(globpath(&rtp, a:name))
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
