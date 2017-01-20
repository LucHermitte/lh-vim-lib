"=============================================================================
" File:         autoload/lh/stack.vim                             {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      4.0.0
let s:k_version = 400
" Created:      20th Sep 2014
" Last Update:  20th Jan 2017
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
let s:verbose = get(s:, 'verbose', 0)
function! lh#stack#verbose(...)
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

function! lh#stack#debug(expr) abort
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

" Function: lh#stack#top_or(stack, default) {{{3
" @since version 3.9.0
function! lh#stack#top_or(stack, default) abort
  return empty(a:stack) ? a:default : a:stack[-1]
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
  let s = lh#object#make_top_type({
        \ 'values': (a:0 ? (a:1) : [])
        \})
  function! s.push(value) dict
    let self.values+=[a:value]
  endfunction
  function! s.top() dict abort
    return lh#stack#top(self.values)
  endfunction
  function! s.top_or(default) dict abort
    " @since version 3.9.0
    return lh#stack#top_or(self.values, a:default)
  endfunction
  function! s.pop() dict abort
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

" Function: lh#stack#new_list(...) {{{3
" builds what repeat([lh#stack#new()], 42) cannot build
function! lh#stack#new_list(nb)
  let s = {
        \ 'stacks': []
        \}
  function! s.push(stack, value) dict abort
    let idx_is_slice = type(a:stack) == type([])
    let last_idx = idx_is_slice ? (a:stack[-1]) : (a:stack)
    if last_idx >= len(self.stacks)
      throw "Cannout push anything onto the stack #".last_idx."; there are only ".len(self.stacks)
    endif
    if idx_is_slice
      let self.stacks[(a:stack[0]) : (a:stack[1])]+=repeat([[a:value]], 1+a:stack[1]-a:stack[0])
    else
      let self.stacks[a:stack]+=[a:value]
    endif
  endfunction
  function! s.top(stack) dict abort
    if a:stack >= len(self.stacks)
      throw "Cannot access anything onto the stack #".a:stack."; there are only ".len(self.stacks)
    endif
    return lh#stack#top(self.stacks[a:stack])
  endfunction
  function! s.pop(stack) dict abort
    if a:stack >= len(self.stacks)
      throw "Cannot remove anything onto the stack #".a:stack."; there are only ".len(self.stacks)
    endif
    return lh#stack#pop(self.stacks[a:stack])
  endfunction
  function! s.len(stack) dict abort
    if a:stack >= len(self.stacks)
      throw "Cannot access anything onto the stack #".a:stack."; there are only ".len(self.stacks)
    endif
    return len(self.stacks[a:stack])
  endfunction
  function! s.empty(stack) dict abort
    if a:stack >= len(self.stacks)
      throw "Cannot access anything onto the stack #".a:stack."; there are only ".len(self.stacks)
    endif
    return empty(self.stacks[a:stack])
  endfunction
  function! s.expand(nb) dict abort
    " The following is sharing the same (empty) list
    " let self.stacks += repeat([[]], a:nb)
    let i = 0
    while i != a:nb
      let self.stacks += [[]]
      let i += 1
    endwhile
  endfunction
  function! s.clear(nb) dict abort
    let self.stacks = []
    call self.expand(a:nb)
  endfunction
  function! s.nb_stacks() dict
    return len(self.stacks)
  endfunction

  call s.expand(a:nb)
  return s
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
