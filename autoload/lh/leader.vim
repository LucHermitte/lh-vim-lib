"=============================================================================
" File:         autoload/lh/leader.vim                            {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      3.6.1.
let s:k_version = '361'
" Created:      13th Nov 2015
" Last Update:  08th Jan 2016
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
let s:verbose = get(s:, 'verbose', 0)
function! lh#leader#verbose(...)
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

function! lh#leader#debug(expr) abort
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
