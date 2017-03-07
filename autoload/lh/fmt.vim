"=============================================================================
" File:         autoload/lh/fmt.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      4.0.0
let s:k_version = '4.0.0'
" Created:      20th Nov 2015
" Last Update:  07th Mar 2017
"------------------------------------------------------------------------
" Description:
"       Formatting functions
"
"------------------------------------------------------------------------
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#fmt#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#fmt#verbose(...)
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

function! lh#fmt#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## Exported functions {{{1
" # Formatting {{{2
" Function: lh#fmt#printf(format, args) {{{3
" WARNING: Beware of infinity loops
" => Don't call lh#fmt#printf() from a _to_string() function that passes the
" objet to be printed w/ "%42". Use a "%{42.field}" instead.
" TODO:
" - support precision/width/fill
" - %%1 that would expand into %1
function! lh#fmt#printf(format, ...) abort
  let matches = lh#string#matches(a:format, '\v\%\zs\d+\ze')
  call lh#list#unique_sort(matches)
  let args = copy(a:000)
  for i in matches
    let args[i-1] = lh#string#as(args[i-1])
  endfor
  " let args = map(args, 'lh#string#as(v:val)')
  let res = substitute(a:format, '\v\%(\d+)', '\=args[submatch(1)-1]', 'g')
  let res = substitute(res, '\v\%\{(\d+)\.(%(\k|\.){-})\}', '\=lh#string#as(lh#dict#get_composed(a:000[submatch(1)-1], submatch(2)))', 'g')
  return res
endfunction


"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
