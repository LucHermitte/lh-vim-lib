"=============================================================================
" File:         autoload/lh/leader.vim                            {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      3.3.9.
let s:k_version = '339'
" Created:      13th Nov 2015
" Last Update:  13th Nov 2015
"------------------------------------------------------------------------
" Description:
"       Helper functions releated to leader/localleader
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#leader#version()
  return s:k_version
endfunction

" # Debug   {{{2
if !exists('s:verbose')
  let s:verbose = 0
endif
function! lh#leader#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#leader#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

" # Fetch {{{2

" Function: lh#leader#get(default='\') {{{3
function! lh#leader#get(...) abort
  let default = a:0 > 0 ? a:1 : '\'
  let leader = get(g:, 'mapleader', default)
  return leader
endfunction

" Function: lh#leader#get_local(default='\') {{{3
function! lh#leader#get_local(...) abort
  let default = a:0 > 0 ? a:1 : '\'
  let leader = get(g:, 'maplocalleader', default)
  return leader
endfunction

" # Set {{{2

" Function: lh#leader#set_local_if_unset(value) {{{3
function! lh#leader#set_local_if_unset(value) abort
  if ! exists('g:maplocalleader')
    let g:maplocalleader = a:value
  endif
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
