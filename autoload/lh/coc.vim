"=============================================================================
" File:         autoload/lh/coc.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 w/ exception license
"               <URL:http://github.com/LucHermitte/lh-vim-lib/blob/master/License.md>
" Version:      4.6.4.
let s:k_version = '464'
" Created:      24th May 2019
" Last Update:  24th May 2019
"------------------------------------------------------------------------
" Description:
"       Support functions for COC.nvim
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
function! lh#coc#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#coc#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Log(expr, ...) abort
  call call('lh#log#this',[a:expr]+a:000)
endfunction

function! s:Verbose(expr, ...) abort
  if s:verbose
    call call('s:Log',[a:expr]+a:000)
  endif
endfunction

function! lh#coc#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

"------------------------------------------------------------------------
" ## Internal functions {{{1
" Function: lh#coc#_split_open(...) {{{3
function! lh#coc#_split_open(...) abort
  call s:Verbose('lh#coc#_split_open(%1)', a:000)
  if a:1 =~ '^+'
    let where = a:1[1:]
    let files = a:000[1:]
    call s:Verbose("where: %1", where)
  else
    let files = a:000
  endif
  call s:Verbose('files: %1', files)

  if lh#buffer#jump(files[0], 'sp') > 0 && exists('where')
    exe where
  endif
endfunction

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
