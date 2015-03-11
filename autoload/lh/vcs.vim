"=============================================================================
" $Id$
" File:         autoload/lh/vcs.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} gmail {dot} com>
"		<URL:http://code.google.com/p/lh-vim/>
" Version:      3.2.6.
let s:k_version = '3.2.6'
" Created:      11th Mar 2015
" Last Update:  $Date$
"------------------------------------------------------------------------
" Description:
"       API VCS detection
"
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#vcs#version()
  return s:k_version
endfunction

" # Debug   {{{2
if !exists('s:verbose')
  let s:verbose = 0
endif
function! lh#vcs#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#vcs#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

" # VCS kind detection {{{2

" Function: lh#vcs#is_svn([path]) {{{3
function! lh#vcs#is_svn(...) abort
  let path = a:0 == 0 ? expand('%:p:h') : a:1
  return !empty(finddir('.svn', path. ';'))
endfunction

" Function: lh#vcs#is_git([path]) {{{3
function! lh#vcs#is_git(...) abort
  let path = a:0 == 0 ? expand('%:p:h') : a:1
  return !empty(finddir('.git', path. ';'))
endfunction

" Function: lh#vcs#get_type([path]) {{{3
function! lh#vcs#get_type(...) abort
  let path = a:0 == 0 ? expand('%:p:h') : a:1
  let kind
        \ = exists('*VCSCommandGetVCSType') ?  substitute(VCSCommandGetVCSType(path), '.', '\l&', 'g')
        \ : lh#vcs#_is_svn(path)            ? 'svn'
        \ : lh#vcs#_is_git(path)            ? 'git'
        \ :                                   'unknown'
  return kind
endfunction
"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
