"=============================================================================
" File:         autoload/lh/mark.vim                              {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0.
let s:k_version = '400'
" Created:      24th Jul 2017
" Last Update:  24th Jul 2017
"------------------------------------------------------------------------
" Description:
"       Functions related to marks
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
function! lh#mark#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#mark#verbose(...)
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

function! lh#mark#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

" Function: lh#mark#is_unused(mark) {{{3
function! lh#mark#is_unused(mark) abort
  return getpos(a:mark)[1:] == [0,0,0]
endfunction

" Function: lh#mark#find_first_unused() {{{3
let s:a_ascii_code = char2nr('a')
let s:A_ascii_code = char2nr('A')
let s:quote        = "'"
let s:k_mark_names
      \ = map(range(26), 's:quote . nr2char(v:val+s:A_ascii_code)')
      \ + map(range(26), 's:quote . nr2char(v:val+s:a_ascii_code)')
function! lh#mark#find_first_unused() abort
  let idx = lh#list#find_if_fast(s:k_mark_names, 'lh#mark#is_unused(v:val)')
  return get(s:k_mark_names, idx, -1)
endfunction


"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
