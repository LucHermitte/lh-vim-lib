"=============================================================================
" File:         autoload/lh/ref.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0.0.
let s:k_version = '4000'
" Created:      09th Sep 2016
" Last Update:  13th Oct 2016
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

" # bind {{{2
" - Methods {{{3
function! s:resolve() dict abort " {{{4
  if     self.to =~ '^p:'
    return lh#project#_get(self.to[2:])
  elseif self.to =~ ':'
    let [all, scopes, varname; dummy] = matchlist(self.to, '\v^([^:]+):(.+)$')
    return lh#option#get(varname, lh#option#unset(), scopes)
  else
    return eval(self.to)
  endif
endfunction

function! s:to_string(...) dict abort " {{{4
  let handled_list = a:0 > 0 ? a:1 : []
  return '{ref->('.(self.to).'): '.lh#object#_to_string(self.resolve(), handled_list).'}'
endfunction

" Function: lh#ref#bind(varname) {{{3
function! lh#ref#bind(varname) abort
  let res = lh#object#make_top_type
        \ ({ 'to': a:varname
        \ , 'type': s:bind
        \ })
  let res.resolve = function(s:getSNR('resolve'))
  let res._to_string = function(s:getSNR('to_string'))
  return res
endfunction

" # Private {{{2
let s:bind = get(s:, 'bind', {})

" Function: lh#ref#is_bound(var) {{{3
function! lh#ref#is_bound(var) abort
  return type(a:var) == type({}) && get(a:var, 'type', 42) is s:bind
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
