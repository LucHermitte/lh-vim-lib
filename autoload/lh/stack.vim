"=============================================================================
" $Id$
" File:         autoload/lh/stack.vim                             {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" Version:      3.2.3
let s:k_version = 323
" Created:      20th Sep 2014
" Last Update:  $Date$
"------------------------------------------------------------------------
" Description:
"       Functionto implement the stack ADT
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#stack#version()
  return s:k_version
endfunction

" # Debug   {{{2
if !exists('s:verbose')
  let s:verbose = 0
endif
function! lh#stack#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#stack#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

" # Procedural way {{{2
" Function: lh#stack#push(stack, value) {{{3
function! lh#stack#push(stack, value)
  let a:stack += [a:value]
endfunction

" Function: lh#stack#top(stack) {{{3
function! lh#stack#top(stack) abort
  if empty(a:stack)
    throw "Empty stack. Cannot access top element!"
  endif
  return a:stack[-1]
endfunction

" Function: lh#stack#pop(stack) {{{3
function! lh#stack#pop(stack)
  if empty(a:stack)
    throw "Empty stack. Cannot remove element!"
  endif
  return remove(a:stack, -1)
endfunction

" # OO way {{{2
" Function: lh#stack#new(...) {{{3
function! lh#stack#new(...)
  let s = {
        \ 'values': (a:0 ? (a:1) : [])
        \}
  function! s.push(value) dict
    let self.values+=[a:value]
  endfunction
  function! s.top() dict
    return lh#stack#top(self.values)
  endfunction
  function! s.pop() dict
    return lh#stack#pop(self.values)
  endfunction
  function! s.len() dict
    return len(self.values)
  endfunction
  function! s.empty() dict
    return empty(self.values)
  endfunction
  return s
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
