"=============================================================================
" File:         autoload/lh/window.vim                            {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      3.3.8.
let s:k_version = '338'
" Created:      29th Oct 2015
" Last Update:
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
if !exists('s:verbose')
  let s:verbose = 0
endif
function! lh#window#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#window#debug(expr)
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
