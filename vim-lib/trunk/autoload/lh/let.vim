"=============================================================================
" $Id$
" File:         autoload/lh/let.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" License:      GPLv3 with exceptions
"               <URL:http://code.google.com/p/lh-vim/wiki/License>
" Version:      3.1.6
" Created:      10th Sep 2012
" Last Update:  $Date$
"------------------------------------------------------------------------
" Description:
"       Defines a command :LetIfUndef that sets a variable if undefined
" 
"------------------------------------------------------------------------
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
let s:k_version = 1
function! lh#let#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = 0
function! lh#let#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#let#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" Function: lh#let#if_undef(var, value) {{{3
function! lh#let#if_undef(var, value) abort
  try 
    let [all, dict, key ; dummy] = matchlist(a:var, '^\(.\{-}\)\%(\.\([^.]\+\)\)\=$')
    " echomsg a:var." --> dict=".dict." --- key=".key
    if !empty(key)
      " Dictionaries
      let dict2 = lh#let#if_undef(dict, string({}))
      if !has_key(dict2, key)
        let dict2[key] = type(a:value) == type(function('has')) ? (a:value) : eval(a:value)
      endif
      return dict2[key]
    else
      " other variables
      if !exists(a:var)
        let {a:var} = type(a:value) == type(function('has')) ? (a:value) : eval(a:value)
      endif
      return {a:var}
    endif
  catch /.*/
    echoerr "Cannot set ".a:var." to ".string(a:value).": ".(v:exception .' @ '. v:throwpoint)
  endtry
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
