"=============================================================================
" File:         autoload/lh/env.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      4.7.0
let s:k_version = 470
" Created:      19th Jul 2010
" Last Update:  15th Nov 2019
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
let s:expand_all_hooks = {}
function! s:expand_all_hooks.cmake(var) dict abort
  if empty(globpath(&rtp, 'autoload/lh/cmake.vim'))
    " Ask lh-cmake, if installed
    return ''
  endif
  let var = lh#cmake#get_variables(a:var)
  if has_key(var, a:var)
    return var[a:var].value
  else
    return ''
  endif
endfunction

function! s:do_expand(var) abort
  let val = eval('$'.a:var)
  if empty(val) && has_key(s:expand_all_hooks, &ft)
    let val = s:expand_all_hooks[&ft](a:var)
  endif
  return val
endfunction

function! lh#env#expand_all(string) abort
  let res = substitute(a:string, '\v\$\{(.{-})\}', '\=s:do_expand(submatch(1))', 'g')
  return res
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
