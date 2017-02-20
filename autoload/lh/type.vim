"=============================================================================
" File:         autoload/lh/type.vim                              {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0.0.
let s:k_version = '4000'
" Created:      20th Feb 2017
" Last Update:  20th Feb 2017
"------------------------------------------------------------------------
" Description:
"       Helper functions around |type()|
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
function! lh#type#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#type#verbose(...)
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

function! lh#type#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" Function: lh#type#name(type) {{{3
let s:names =
      \{ type(0)              : 'number'
      \, type('')             : 'string'
      \, type(function('has')): 'funcref'
      \, type([])             : 'list'
      \, type({})             : 'dictionary'
      \, type(0.0)            : 'float'
      \, type(v:true)         : 'bool'
      \, type(v:none)         : 'None'
      \, 8                    : 'job'
      \, 9                    : 'channel'
      \ }
function! lh#type#name(type) abort
  return get(s:names, a:type, 'unknown')
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
