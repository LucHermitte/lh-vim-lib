"=============================================================================
" File:         autoload/lh/assert.vim                            {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0.0.
let s:k_version = '4000'
" Created:      23rd Nov 2016
" Last Update:  20th Feb 2017
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

" Function: lh#assert#is(expected, actual, ...) {{{3
function! lh#assert#is(expected, actual, ...) abort
  if ! (a:expected is a:actual)
    let msg = a:0 > 0 ? a:1 : 'Expected '.a:expected.' to be identical to '.a:actual
    call lh#assert#_trace_assert(msg)
  endif
endfunction

" Function: lh#assert#is_not(expected, actual, ...) {{{3
function! lh#assert#is_not(expected, actual, ...) abort
  if a:expected is a:actual
    let msg = a:0 > 0 ? a:1 : 'Expected '.a:expected.' to not be identical to '.a:actual
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

" Function: lh#assert#if(cond [, msg]) {{{3
function! s:then_expect(cond, ...) dict abort
  if ! a:cond
    let msg = a:0 > 0 ? a:1 : 'Expected True when first condition is True but got '.a:cond
    call lh#assert#_trace_assert(msg)
  endif
endfunction

function! s:then_expect_always_true(...) dict abort
endfunction

function! lh#assert#if(cond) abort
  let res = lh#object#make_top_type({})
  if a:cond
    let res.then_expect = function(s:getSNR('then_expect'))
  else
    let res.then_expect = function(s:getSNR('then_expect_always_true'))
  endif
  return res
endfunction

" Function: lh#assert#empty(value, ...) {{{3
function! lh#assert#empty(value, ...) abort
  if ! empty(a:value)
    let msg = a:0 > 0 ? a:1 : 'Expected '.string(a:value).' to be empty'
    call lh#assert#_trace_assert(msg)
  endif
endfunction

" Function: lh#assert#not_empty(value, ...) {{{3
function! lh#assert#not_empty(value, ...) abort
  if empty(a:value)
    let msg = a:0 > 0 ? a:1 : 'Expected '.string(a:value).' to not empty'
    call lh#assert#_trace_assert(msg)
  endif
endfunction

" Function: lh#assert#value(actual) {{{3
function! s:__eval(bool) dict abort "{{{4
  return a:bool
endfunction
function! s:__negate(bool) dict abort "{{{4
  return ! a:bool
endfunction
function! s:not() dict abort " {{{4
  let self.__eval = function(s:getSNR('__negate'))
  return self
endfunction

function! s:is_lt(ref) dict abort " {{{4
  if ! self.__eval(self.actual < a:ref)
    call lh#assert#_trace_assert('Expected '.(self.actual).' to be lesser than '.a:ref)
  endif
  return self
endfunction
function! s:is_le(ref) dict abort " {{{4
  if ! self.__eval(self.actual w= a:ref)
    call lh#assert#_trace_assert('Expected '.(self.actual).' to be lesser or equal to '.a:ref)
  endif
  return self
endfunction
function! s:is_gt(ref) dict abort " {{{4
  if ! self.__eval(self.actual > a:ref)
    call lh#assert#_trace_assert('Expected '.(self.actual).' to be greater than '.a:ref)
  endif
  return self
endfunction
function! s:is_ge(ref) dict abort " {{{4
  if ! self.__eval(self.actual >= a:ref)
    call lh#assert#_trace_assert('Expected '.(self.actual).' to be greater or equal to '.a:ref)
  endif
  return self
endfunction
function! s:eq(ref) dict abort " {{{4
  if ! self.__eval(self.actual == a:ref)
    call lh#assert#_trace_assert('Expected '.(self.actual).' to equal '.a:ref)
  endif
  return self
endfunction
function! s:diff(ref) dict abort " {{{4
  if ! self.__eval(self.actual != a:ref)
    call lh#assert#_trace_assert('Expected '.(self.actual).' to differ from '.a:ref)
  endif
  return self
endfunction
function! s:has_key(key) dict abort " {{{4
  if ! self.__eval(has_key(self.actual, a:key))
    call lh#assert#_trace_assert('Expected '.string(self.actual).' to have key '.a:key)
  endif
  return self
endfunction

function! lh#assert#value(actual) abort " {{{4
  let res = lh#object#make_top_type({'actual': a:actual})
  let res.__eval  = function(s:getSNR('__eval'))
  let res.not     = function(s:getSNR('not'))
  let res.is_lt   = function(s:getSNR('is_lt'))
  let res.is_le   = function(s:getSNR('is_le'))
  let res.is_gt   = function(s:getSNR('is_gt'))
  let res.is_ge   = function(s:getSNR('is_ge'))
  let res.eq      = function(s:getSNR('eq'))
  let res.diff    = function(s:getSNR('diff'))
  let res.has_key = function(s:getSNR('has_key'))
  return res
endfunction

" Function: lh#assert#type(actual) {{{3
function! s:type_is(expected) dict abort " {{{4
  let t_actual = type(self.actual)
  if ! self.__eval(t_actual == type(a:expected))
    call lh#assert#_trace_assert('Expected '.string(self.actual).' to be a '.lh#type#name(type(a:expected)).' not a '.lh#type#name(t_actual))
  endif
  return self
endfunction
function! s:type_belongs_to(...) dict abort " {{{4
  let t_actual = type(self.actual)
  let t_expected = map(copy(a:000), 'type(v:val)')
  if self.__eval(index(t_expected, t_actual) == -1)
    let s_expected = join(map(t_expected, 'lh#type#name(v:val)'), ', or a ')
    call lh#assert#_trace_assert('Expected '.string(self.actual).' to be either a '.s_expected.', but not a '.lh#type#name(t_actual))
  endif
  return self
endfunction

function! lh#assert#type(actual) abort " {{{4
  let res = lh#object#make_top_type({'actual': a:actual})
  let res.__eval     = function(s:getSNR('__eval'))
  let res.not        = function(s:getSNR('not'))
  let res.is         = function(s:getSNR('type_is'))
  let res.belongs_to = function(s:getSNR('type_belongs_to'))
  return res
endfunction
"------------------------------------------------------------------------
" ## Internal functions {{{1
"
" s:getSNR([func_name]) {{{3
function! s:getSNR(...)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

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
      throw a:msg
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
