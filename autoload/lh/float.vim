"=============================================================================
" File:         autoload/lh/float.vim                             {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      3.6.1
let s:k_version = 361
" Created:      16th Nov 2010
" Last Update:  08th Jan 2016
"------------------------------------------------------------------------
" Description:
"       Defines functions related to |expr-float| numbers
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#float#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#float#verbose(...)
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

function! lh#float#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

" # lh#float#min(list) {{{2
function! lh#float#min(list)
  let am = lh#float#arg_min(a:list)
  return a:list[am]
endfunction

function! lh#float#arg_min(list)
  if empty(a:list) | return -1 | endif
  let m = type(a:list[0]) == type(0.0) ? a:list[0] : str2float(a:list[0])
  let p = 0
  let i = 1
  while i != len(a:list)
    let e = a:list[i]
    if type(e) != type(0.0) |
      let v = str2float(e)
    else
      let v = e
    endif
    if v < m
      let m = v
      let p = i
    endif
    let i += 1
  endwhile
  return p
endfunction


" # lh#float#max(list) {{{2
function! lh#float#max(list)
  let am = lh#float#arg_max(a:list)
  return a:list[am]
endfunction

function! lh#float#arg_max(list)
  if empty(a:list) | return -1 | endif
  let m = type(a:list[0]) == type(0.0) ? a:list[0] : str2float(a:list[0])
  let p = 0
  let i = 1
  while i != len(a:list)
    let e = a:list[i]
    if type(e) != type(0.0) |
      let v = str2float(e)
    else
      let v = e
    endif
    if v > m
      let m = v
      let p = i
    endif
    let i += 1
  endwhile
  return p
endfunction



"------------------------------------------------------------------------
" ## Internal functions {{{1

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
