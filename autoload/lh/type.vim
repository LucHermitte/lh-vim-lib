"=============================================================================
" File:         autoload/lh/type.vim                              {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      5.4.1
let s:k_version = '050401'
" Created:      20th Feb 2017
" Last Update:  02nd Jan 2025
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
" Function: lh#type#name(type) {{{2
let s:names =
      \{ type(0)              : 'number'
      \, type('')             : 'string'
      \, type(function('has')): 'funcref'
      \, type([])             : 'list'
      \, type({})             : 'dictionary'
      \, type(0.0)            : 'float'
      \, 8                    : 'job'
      \, 9                    : 'channel'
      \ }
if exists('v:true')
  let s:names[type(v:true)] = 'bool'
  " let s:names[v:false] = 'bool'
endif
if exists('v:null')
  let s:names[type(v:null)] = 'none'
endif
if exists('v:none')
  let s:names[type(v:none)] = 'none'
endif
if exists('v:t_blob')      | let s:names[v:t_bool] = 'blob'      | endif
if exists('v:t_class')     | let s:names[v:t_bool] = 'class'     | endif
if exists('v:t_object')    | let s:names[v:t_bool] = 'object'    | endif
if exists('v:t_typealias') | let s:names[v:t_bool] = 'typealias' | endif
if exists('v:t_enum')      | let s:names[v:t_bool] = 'enum'      | endif
if exists('v:t_enumvalue') | let s:names[v:t_bool] = 'enumvalue' | endif


function! lh#type#name(type) abort
  return get(s:names, a:type, 'unknown')
endfunction

" Function: lh#type#is_dict(value) {{{2
function! lh#type#is_dict(value) abort
  return type(a:value) == type({})
endfunction

" Function: lh#type#is_list(value) {{{2
function! lh#type#is_list(value) abort
  return type(a:value) == type([])
endfunction

" Function: lh#type#is_funcref(value) {{{2
function! lh#type#is_funcref(value) abort
  return type(a:value) == type(function('has'))
endfunction

" Function: lh#type#is_string(value) {{{2
function! lh#type#is_string(value) abort
  return type(a:value) == type('')
endfunction

" Function: lh#type#is_number(value) {{{2
function! lh#type#is_number(value) abort
  return type(a:value) == type(0)
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
