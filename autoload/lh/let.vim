"=============================================================================
" File:         autoload/lh/let.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      3.6.1
let s:k_version = 3601
" Created:      10th Sep 2012
" Last Update:  08th Jan 2016
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
function! lh#let#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#let#verbose(...)
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

function! lh#let#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" Function: lh#let#if_undef(var, value) {{{3
function! lh#let#if_undef(var, value) abort
  try
    let [all, dict, key ; dummy] = matchlist(a:var, '^\v(.{-})%(\.([^.]+))=$')
    " echomsg a:var." --> dict=".dict." --- key=".key
    if !empty(key)
      " Dictionaries
      let dict2 = lh#let#if_undef(dict, string({}))
      if !has_key(dict2, key)
        let dict2[key] = type(a:value) == type(function('has')) ? (a:value) : eval(a:value)
        call s:Verbose("let %1.%2 = %3", dict, key, dict2[key])
      endif
      return dict2[key]
    else
      " other variables
      if !exists(a:var)
        let {a:var} = type(a:value) == type(function('has')) ? (a:value) : eval(a:value)
        call s:Verbose("let %1 = %2", a:var, {a:var})
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
" }}}1
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
