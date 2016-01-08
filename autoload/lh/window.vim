"=============================================================================
" File:         autoload/lh/window.vim                            {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      3.6.1.
let s:k_version = '361'
" Created:      29th Oct 2015
" Last Update:  08th Jan 2016
"------------------------------------------------------------------------
" Description:
" 	Defines functions that help finding handling windows.
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#window#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#window#verbose(...)
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

function! lh#window#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" # Window Splitting {{{2
" Function: lh#window#create_window_with(cmd) {{{3
" Since a few versions, vim throws a lot of E36 errors around:
" everythime we try to split from a windows where its height equals &winheight
" (the minimum height)
function! lh#window#create_window_with(cmd) abort
  try
    exe a:cmd
  catch /E36:/
    " Try again after an increase of the current window height
    resize +1
    exe a:cmd
  endtry
endfunction

" Function: lh#window#split(bufname) {{{3
function! lh#window#split(...) abort
  call call('lh#window#create_window_with',[join(['split']+a:000, ' ')])
endfunction

" Function: lh#window#new(bufname) {{{3
function! lh#window#new(bufname) abort
  call call('lh#window#create_window_with',[join(['new']+a:000, ' ')])
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
