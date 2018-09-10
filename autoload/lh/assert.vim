"=============================================================================
" File:         autoload/lh/assert.vim                            {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.6.0.
let s:k_version = '40603'
" Created:      23rd Nov 2016
" Last Update:  10th Sep 2018
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

" s:getSNR([func_name]) {{{2
function! s:getSNR(...)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
"
" Function: lh#assert#_trace_assert(msg) {{{2
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
    let cb[0].type = 'E'
    let s:errors += cb
    call s:Verbose('Assertion failed: %{1.text} -- %{1.filename}:%{1.lnum}', cb[0])
    if empty(g:lh#assert#_mode)
      let msg = lh#fmt#printf("Assertion failed:\n-> %{1.text} -- %{1.filename}:%{1.lnum}",cb[0])
      let mode = lh#ui#which('confirm', msg, "&Ignore\n&Stop\n&Debug\nStack&trace...", 1)
      if mode ==? 'stacktrace...'
        call setqflist(cb)
        if exists(':Copen')
          Copen
        else
          copen
        endif
        redraw
        let mode = lh#ui#which('confirm', msg, "...&Ignore\n...&Stop\n...&Debug", 1)
        let mode = strpart(mode, 3)
      endif
    else
      let mode = g:lh#assert#_mode
    endif
    if mode ==? 'stop'
      throw a:msg
    elseif mode ==? 'debug'
      debug echo "You'll have to play with `:bt`, `:up` and `:echo` to explore the situation"
    endif
  endif
endfunction

" Function: lh#assert#_shall_ignore() {{{2
function! lh#assert#_shall_ignore() abort
  return g:lh#assert#_mode ==? 'ignore'
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
let g:lh#assert#_mode = get(g:, 'lh#assert#_mode', '')
" Function: lh#assert#mode(...) {{{3
function! lh#assert#mode(...) abort
  if a:0 > 0
    exe 'Toggle PluginAssertmode '.a:1
  endif
  return g:lh#assert#_mode
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
function! s:__ignore(...) dict abort "{{{4
  return self
endfunction
function! s:__eval(bool) dict abort "{{{4
  return a:bool
endfunction
function! s:__negate(bool) dict abort "{{{4
  return ! a:bool
endfunction
function! s:not() dict abort " {{{4
  let res = copy(self)
  let res.__eval = function(s:getSNR('__negate'))
  return res
endfunction
function! s:is_lt(ref, ...) dict abort " {{{4
  if ! self.__eval(self.actual < a:ref)
    let msg = a:0 > 0 ? a:1 : 'Expected '.string(self.actual).' to be lesser than '.string(a:ref)
    call lh#assert#_trace_assert(msg)
  endif
  return self
endfunction
function! s:is_le(ref, ...) dict abort " {{{4
  if ! self.__eval(self.actual <= a:ref)
    let msg = a:0 > 0 ? a:1 : 'Expected '.string(self.actual).' to be lesser or equal to '.string(a:ref)
    call lh#assert#_trace_assert(msg)
  endif
  return self
endfunction
function! s:is_gt(ref, ...) dict abort " {{{4
  if ! self.__eval(self.actual > a:ref)
    let msg = a:0 > 0 ? a:1 : 'Expected '.string(self.actual).' to be greater than '.string(a:ref)
    call lh#assert#_trace_assert(msg)
  endif
  return self
endfunction
function! s:is_ge(ref, ...) dict abort " {{{4
  if ! self.__eval(self.actual >= a:ref)
    let msg = a:0 > 0 ? a:1 : 'Expected '.string(self.actual).' to be greater or equal to '.string(a:ref)
    call lh#assert#_trace_assert(msg)
  endif
  return self
endfunction
function! s:eq(ref, ...) dict abort " {{{4
  if ! self.__eval(self.actual == a:ref)
    let msg = a:0 > 0 ? a:1 : 'Expected '.string(self.actual).' to equal '.string(a:ref)
    call lh#assert#_trace_assert(msg)
  endif
  return self
endfunction
function! s:diff(ref, ...) dict abort " {{{4
  if ! self.__eval(self.actual != a:ref)
    let msg = a:0 > 0 ? a:1 : 'Expected '.string(self.actual).' to differ from '.string(a:ref)
    call lh#assert#_trace_assert(msg)
  endif
  return self
endfunction
function! s:match(pattern, ...) dict abort " {{{4
  if self.__eval(self.actual !~ a:pattern)
    let msg = a:0 > 0 ? a:1 : 'Pattern '.string(a:pattern).' does not match '.string(self.actual)
    call lh#assert#_trace_assert(msg)
  endif
endfunction
function! s:has_key(key, ...) dict abort " {{{4
  if ! self.__eval(has_key(self.actual, a:key))
    let msg = a:0 > 0 ? a:1 : 'Expected '.string(self.actual).' to have key '.string(a:key)
    call lh#assert#_trace_assert(msg)
  endif
  return self
endfunction

function! s:empty(...) dict abort " {{{4
  if ! self.__eval(empty(self.actual))
    let msg = a:0 > 0 ? a:1 : 'Variable is not empty but contain: '.string(self.actual)
    call lh#assert#_trace_assert(msg)
  endif
  return self
endfunction
function! s:is_set(...) dict abort " {{{4
  if ! self.__eval(lh#option#is_set(self.actual))
    let msg = a:0 > 0 ? a:1 : 'Variable is not set: '.lh#string#as(self.actual)
    call lh#assert#_trace_assert(msg)
  endif
  return self
endfunction
function! s:is_unset(...) dict abort " {{{4
  if ! self.__eval(lh#option#is_unset(self.actual))
    let msg = a:0 > 0 ? a:1 : 'Variable is not unset: '.lh#string#as(self.actual)
    call lh#assert#_trace_assert(msg)
  endif
  return self
endfunction
function! s:verifies(func, ...) dict abort "{{{4
  let args = get(a:, 1, [])
  if ! self.__eval( (type(a:func)==type('') && lh#type#is_dict(self.actual) && has_key(self.actual, a:func)) ? call(self.actual[a:func], args, self.actual) : call(a:func, [self.actual]+args))
    let msg = a:0 > 0 ? a:2 : lh#string#as(self.actual)." doesn't verify: ".string(a:func)
    call lh#assert#_trace_assert(msg)
  endif
  return self
endfunction
function! s:get(id, ...) dict abort " {{{4
  if     type(self.actual) == type({})
    call call(self.has_key, [a:id] + a:000, self)
  elseif type(self.actual) == type([])
    let actual = self.actual " because I share a common global objet => need to save the actual value tested
    call lh#assert#type(a:id).is(42, 'Expected a number as index in an array, got '.string(a:id))
    call lh#assert#value(len(actual)).is_gt(a:id, 'Expected the index ('.a:id.') to be lesser than the number of elements ('.len(actual).'): '.string(actual))
    let self.actual = actual
  else
    call lh#assert#unexpected('Expected a dictionary or an array. Got a '.lh#type#name(type(self.actual)).': '.string(self.actual))
    return self
  endif
  " We should not get an unset element here given the previous tests
  let element = get(self.actual, a:id)
  let self.actual = element
  return self
endfunction

" Pre-built #value() result " {{{4
function! s:pre_build_value() abort
  let res = lh#object#make_top_type({})
  let res.__eval     = function(s:getSNR('__eval'))
  let res.not        = function(s:getSNR('not'))
  let res.is_lt      = function(s:getSNR('is_lt'))
  let res.is_le      = function(s:getSNR('is_le'))
  let res.is_gt      = function(s:getSNR('is_gt'))
  let res.is_ge      = function(s:getSNR('is_ge'))
  let res.eq         = function(s:getSNR('eq'))
  let res.differ     = function(s:getSNR('diff'))
  let res.match      = function(s:getSNR('match'))
  let res.has_key    = function(s:getSNR('has_key'))
  let res.empty      = function(s:getSNR('empty'))
  let res.is_set     = function(s:getSNR('is_set'))
  let res.is_unset   = function(s:getSNR('is_unset'))
  let res.verifies   = function(s:getSNR('verifies'))
  let res.get        = function(s:getSNR('get'))

  let ignored = lh#object#make_top_type({})
  let ignored.not      = function(s:getSNR('__ignore'))
  let ignored.is_lt    = ignored.not
  let ignored.is_le    = ignored.not
  let ignored.is_gt    = ignored.not
  let ignored.is_ge    = ignored.not
  let ignored.eq       = ignored.not
  let ignored.differ   = ignored.not
  let ignored.match    = ignored.not
  let ignored.has_key  = ignored.not
  let ignored.empty    = ignored.not
  let ignored.is_set   = ignored.not
  let ignored.is_unset = ignored.not
  let ignored.verifies = ignored.not
  let ignored.get      = ignored.not
  return [res, ignored]
endfunction
let [s:value_default, s:value_ignore] = s:pre_build_value()

function! lh#assert#value(actual) abort " {{{3
  " We use and modify a global object, but this is not a problem
  let res = lh#assert#_shall_ignore() ? s:value_ignore : s:value_default
  let res.actual = a:actual
  return res
endfunction

" Function: lh#assert#type(actual [, message]) {{{3
function! s:type_is(expected, ...) dict abort " {{{4
  let t_actual = type(self.actual)
  if ! self.__eval(t_actual == type(a:expected))
    let msg = a:0 > 0 ? a:1 : 'Expected '.string(self.actual).' to be a '.lh#type#name(type(a:expected)).' not a '.lh#type#name(t_actual)
    call lh#assert#_trace_assert(msg)
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
function! s:pre_build_type() abort " {{{4
  let res = lh#object#make_top_type({})
  let res.__eval     = function(s:getSNR(lh#assert#_shall_ignore() ? '__ignore' : '__eval'))
  let res.not        = function(s:getSNR('not'))
  let res.is         = function(s:getSNR('type_is'))
  let res.belongs_to = function(s:getSNR('type_belongs_to'))

  let ignored = lh#object#make_top_type({})
  let ignored.not        = function(s:getSNR('__ignore'))
  let ignored.is         = ignored.not
  let ignored.belongs_to = ignored.not
  return [res, ignored]
endfunction
let [s:type_default, s:type_ignore] = s:pre_build_type()

function! lh#assert#type(actual) abort " {{{4
  " We use and modify a global object, but this is not a problem
  let res = lh#assert#_shall_ignore() ? s:type_ignore : s:type_default
  let res.actual = a:actual
  return res
endfunction
"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
