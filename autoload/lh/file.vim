"=============================================================================
" File:         autoload/lh/file.vim                              {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0
let s:k_version = '4000'
" Created:      01st Jun 2016
" Last Update:  03rd Feb 2017
"------------------------------------------------------------------------
" Description:
"       File related functions
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#file#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#file#verbose(...)
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

function! lh#file#debug(expr) abort
  return eval(a:expr)
endfunction

" s:getSNR([func_name]) {{{2
function! s:getSNR(...)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

"------------------------------------------------------------------------
" ## Exported functions {{{1
" # file stamps {{{2
function! s:must_update(filename, file_data) abort " {{{3
  let new_stamp = getftime(a:filename)
  return a:file_data._stamp < new_stamp
endfunction

function! s:get(filename) dict abort " {{{3
  if !has_key(self._files, a:filename) || s:must_update(a:filename, self._files[a:filename])
    call self._update(a:filename)
  endif
  return self._files[a:filename]._data
endfunction

function! s:_update(filename) dict abort " {{{3
  let file_data =
        \ { '_stamp' : getftime(a:filename)
        \ , '_data'  : self._compute_data(a:filename)
        \ }
  let self._files[a:filename] = file_data
  call s:Verbose('Updating %1 data: %2', a:filename, file_data)
endfunction

function! s:clear() dict abort " {{{3
  let self._files = {}
endfunction

function! s:reset() dict abort " {{{3
  call map(copy(keys(self._files)), 'self._update(v:val)')
endfunction

" Function: lh#file#new_cache([update_func]) {{{3
function! lh#file#new_cache(update_func) abort
  let cache = lh#object#make_top_type({})
  let cache._files        = {}
  " Public functions
  let cache.get           = function(s:getSNR('get'))
  let cache.clear         = function(s:getSNR('clear'))
  let cache.reset         = function(s:getSNR('reset'))
  " Internal functions
  let cache._update       = function(s:getSNR('_update'))
  let cache._compute_data = a:update_func
  return cache
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
