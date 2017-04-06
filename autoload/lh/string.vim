"=============================================================================
" File:         autoload/lh/string.vim                            {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      4.0.0.
let s:k_version = '4000'
" Created:      08th Dec 2015
" Last Update:  06th Apr 2017
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
  return matchstr(a:string, '^\v\_s*\zs.{-}\ze\_s*$')
endfunction

" Function: lh#string#trim_text_right(string, ) {{{3
" @version 4.0.0
function! lh#string#trim_text_right(string, text) abort
  let idx = stridx(a:string, a:text)
  if idx == 0
    return a:string[len(a:text):]
  else
    return a:string
  endif
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
  elseif type(a:val) == type(function('has'))
    return string(a:val)
  endif
  return a:val
endfunction

" # Substitutions {{{2
" Function: lh#string#substitute_unless(string, pat, text) {{{3
" @version 3.9.0
function! lh#string#substitute_unless(string, pat, char) abort
  let s = split(a:string, '\zs\ze')
  call map(s, 'v:val =~ a:pat ? v:val : a:char')
  return join(s, '')
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
