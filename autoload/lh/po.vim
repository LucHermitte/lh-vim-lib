"=============================================================================
" File:         autoload/lh/po.vim                                {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.5.0.
let s:k_version = '40500'
" Created:      03rd Feb 2017
" Last Update:  27th Jun 2018
"------------------------------------------------------------------------
" Description:
"       Utility functions to handle Portable Object messages
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
function! lh#po#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#po#verbose(...)
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

function! lh#po#debug(expr) abort
  return eval(a:expr)
endfunction

" s:getSNR([func_name]) {{{3
function! s:getSNR(...)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

"------------------------------------------------------------------------
" ## Exported functions {{{1
" # context {{{2
" Function: s:translate(id) {{{3
let s:k_cached_translations = {}
function! s:translate(id) dict abort
  let cache = lh#dict#let(s:k_cached_translations, self._env.LANG .'.'. self._env.TEXTDOMAIN, {})
  if !has_key(cache, a:id)
    if executable('bash')
      let cache[a:id] = lh#os#system('bash -c '.shellescape('echo $"'.a:id.'"'), self._env)
    else
      " TODO: support windows
      let cache[a:id] = a:id
    endif
  endif
  return cache[a:id]
endfunction

" Function: lh#po#context([domain, domain_dir]) {{{3
" Default domain & domain dir = Vim
function! lh#po#context(...) abort
  let res = lh#object#make_top_type({'_env': {}})
  let res._env.TEXTDOMAIN    = get(a:, 1, 'vim')
  let res._env.TEXTDOMAINDIR = get(a:, 1, $VIMRUNTIME.'/lang')
  let res._env.LANG          = exists('$LC_MESSAGES') ? $LC_MESSAGES : v:lang
  let res.translate = function(s:getSNR('translate'))
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
