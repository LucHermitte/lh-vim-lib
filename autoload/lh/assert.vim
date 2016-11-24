"=============================================================================
" File:         autoload/lh/assert.vim                            {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0.0.
let s:k_version = '4000'
" Created:      23rd Nov 2016
" Last Update:  24th Nov 2016
"------------------------------------------------------------------------
" Description:
"       Emulates assert_*() functions, but notifies as soon as possible that
"       there is a problem.
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
function! lh#assert#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#assert#verbose(...)
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

function! lh#assert#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" # Error list {{{2
let s:errors = get(s:, 'errors', [])

" Function: lh#assert#clear() {{{3
function! lh#assert#clear() abort
  let s:errors = []
endfunction

" Function: lh#assert#errors() {{{3
function! lh#assert#errors() abort
  return s:errors
endfunction

" # Assertion mode {{{2
let s:mode = get(s:, 'mode', '')
" Function: lh#assert#mode(...) {{{3
function! lh#assert#mode(...) abort
  if a:0 > 0 | let s:mode = a:1 | endif
  return s:mode
endfunction

" # Assertions {{{2
" Function: lh#assert#true(actual, ...) {{{3
function! lh#assert#true(actual, ...) abort
  if ! a:actual
    let msg = a:0 > 0 ? a:1 : 'Expected True but got '.a:actual
    call lh#assert#_trace_assert(msg)
  endif
endfunction

" Function: lh#assert#false(actual, ...) {{{3
function! lh#assert#false(actual, ...) abort
  if a:actual
    let msg = a:0 > 0 ? a:1 : 'Expected False but got '.a:actual
    call lh#assert#_trace_assert(msg)
  endif
endfunction

" Function: lh#assert#equal(expected, actual, ...) {{{3
function! lh#assert#equal(expected, actual, ...) abort
  if a:expected != a:actual
    let msg = a:0 > 0 ? a:1 : 'Expected '.a:expected.' but got '.a:actual
    call lh#assert#_trace_assert(msg)
  endif
endfunction

" Function: lh#assert#not_equal(expected, actual, ...) {{{3
function! lh#assert#not_equal(expected, actual, ...) abort
  if a:expected == a:actual
    let msg = a:0 > 0 ? a:1 : 'Expected not '.a:expected.' but got '.a:actual
    call lh#assert#_trace_assert(msg)
  endif
endfunction

" Function: lh#assert#match(pattern, actual, ...) {{{3
function! lh#assert#match(pattern, actual, ...) abort
  if a:actual !~ a:pattern
    let msg = a:0 > 0 ? a:1 : 'Pattern '.string(a:pattern).' does not match '.string(a:actual)
    call lh#assert#_trace_assert(msg)
  endif
endfunction

" Function: lh#assert#unexpected(...) {{{3
function! lh#assert#unexpected( ...) abort
  let msg = 'Unexception situation' . (a:0 > 0 ? ': '.a:1 : '')
  call lh#assert#_trace_assert(msg)
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
" Function: lh#assert#_trace_assert(msg) {{{3
function! lh#assert#_trace_assert(msg) abort
  let cb = lh#exception#callstack_as_qf('', a:msg)
  " let g:cb = copy(cb)
  if len(cb) > 2
    " Public function called from another function
    let cb[2].text .= ': '.cb[0].text
    call remove(cb, 0, 1)
  elseif len(cb) > 1
    " Public function called from command line
    let cb[1].text .= ': ' . cb[0].text
    call remove(cb, 0)
  endif
  if !empty(cb)
    let s:errors += cb
    call s:Verbose('Assertion failed: %{1.text} -- %{1.filename}:%{1.lnum}', cb[0])
    if empty(s:mode)
      let msg = lh#fmt#printf("Assertion failed:\n-> %{1.text} -- %{1.filename}:%{1.lnum}",cb[0])
      let mode = WHICH('confirm', msg, "&Ignore\n&Stop\n&Debug", 1)
    else
      let mode = s:mode
    endif
    if mode ==? 'stop'
      throw msg
    elseif mode ==? 'debug'
      debug echo "You'll have to play with `:bt`, `:up` and `:echo` to explore the situation"
    endif
  endif
endfunction

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
