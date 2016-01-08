"=============================================================================
" File:         autoload/lh/string.vim                            {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      3.6.1.
let s:k_version = '3601'
" Created:      08th Dec 2015
" Last Update:  08th Jan 2016
"------------------------------------------------------------------------
" Description:
"       String related function
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#string#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#string#verbose(...)
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

function! lh#string#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## Exported functions {{{1
"
" # Trimming {{{2
"
" Function: lh#string#trim(string) {{{3
" @version 3.4.0
function! lh#string#trim(string) abort
  return matchstr('^\v\s*\zs.{-}\ze\s*$', a:string)
endfunction

" # Matching {{{2
" Function: lh#string#matches(string, pattern) {{{3
" snippet from Peter Rincker: http://stackoverflow.com/a/34069943/15934
" @version 3.4.0
function! lh#string#matches(string, pattern) abort
  let res = []
  call substitute(a:string, a:pattern, '\=add(res, submatch(0))', 'g')
  return res
endfunction

" # Convertion {{{2
" Function: lh#string#as(val) {{{3
" NOTE: this function cannot use s:Log()
" @version 3.6.1
function! lh#string#as(val) abort
  if     type(a:val) == type([])
    return string(a:val)
  elseif type(a:val) == type({})
    if has_key(a:val, '_to_string')
      return a:val._to_string()
    endif
    return string(a:val)
  endif
  return a:val
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
