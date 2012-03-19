"=============================================================================
" $Id$
" File:         autoload/lh/float.vim                             {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" License:      GPLv3 with exceptions
"               <URL:http://code.google.com/p/lh-vim/wiki/License>
" Version:      3.0.0
" Created:      16th Nov 2010
" Last Update:  $Date$
"------------------------------------------------------------------------
" Description:
"       Defines functions related to |expr-float| numbers
" 
"------------------------------------------------------------------------
" Installation:
"       Drop this file into {rtp}/autoload/lh
"       Requires Vim7+
" History:     
"       v2.0.0: first version
"       v3.0.0: GPLv3
" TODO:
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
let s:k_version = 300
function! lh#float#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = 0
function! lh#float#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#float#debug(expr)
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

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
