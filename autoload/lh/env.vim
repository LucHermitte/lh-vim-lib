"=============================================================================
" File:         autoload/lh/env.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      3.6.1
let s:k_version = 361
" Created:      19th Jul 2010
" Last Update:  08th Jan 2016
"------------------------------------------------------------------------
" Description:
"       Functions related to environment (variables)
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#env#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#env#verbose(...)
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

function! lh#env#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## Exported functions {{{1
function! lh#env#expand_all(string)
  let res = ''
  let tail = a:string
  while !empty(tail)
    let [ all, head, var, tail; dummy ] = matchlist(tail, '\(.\{-}\)\%(${\(.\{-}\)}\)\=\(.*\)')
    if empty(var)
      let res .= tail
      break
    else
      let res .= head
      let val = eval('$'.var)
      let res .= val
    endif
  endwhile
  return res
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
