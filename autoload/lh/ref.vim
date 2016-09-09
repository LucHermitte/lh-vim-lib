"=============================================================================
" File:         autoload/lh/ref.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0.0.
let s:k_version = '4000'
" Created:      09th Sep 2016
" Last Update:  09th Sep 2016
"------------------------------------------------------------------------
" Description:
"       «description»
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
function! lh#ref#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#ref#verbose(...)
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

function! lh#ref#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## functions {{{1
" # Public  {{{1

" Function: lh#ref#bind(varname) {{{3
function! lh#ref#bind(varname) abort
  let res =
        \ { 'to': a:varname
        \ , 'type': s:bind
        \ }
  let res.resolve = function(s:getSNR('resolve'))
  return res
endfunction

" # Private {{{2
let s:bind = get(s:, 'bind', {})

" Function: lh#ref#is_bound(var) {{{3
function! lh#ref#is_bound(var) abort
  return type(a:var) == type({}) && get(a:var, 'type', 42) is s:bind
endfunction

function! s:resolve() dict abort
  return eval(self.to)
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
" s:getSNR([func_name]) {{{2
function! s:getSNR(...)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
