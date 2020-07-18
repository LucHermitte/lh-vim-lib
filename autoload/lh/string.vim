"=============================================================================
" File:         autoload/lh/string.vim                            {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      5.2.0
let s:k_version = '50200'
" Created:      08th Dec 2015
" Last Update:  18th Jul 2020
"------------------------------------------------------------------------
" Description:
"       String related function
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#string#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#string#verbose(...)
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

function! lh#string#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## Exported functions {{{1
"
" # Counting {{{2
" Function: lh#string#count_char(string, what) {{{3
" @since Version 4.2.0
if lh#has#patch('patch-8.0.0794')
  function! lh#string#count_char(...) abort
    return call('count', a:000)
  endfunction
else
  function! lh#string#count_char(string, what, ...) abort
    " len + substitute is 300 times slower than count(string)
    let ic = get(a:, 1, 0) ? '\v' : ''
    return len(substitute(a:string, ic.'[^'.a:what.']', '', 'g'))
    " count + split is twice as slow as len + substitute
    " return call('count', [split(a:string, '\zs')] + a:000)
  endfunction
endif

" # Trimming {{{2
" Function: lh#string#trim(string) {{{3
" @version 3.4.0
function! lh#string#trim(string) abort
  return matchstr(a:string, '^\v\_s*\zs.{-}\ze\_s*$')
endfunction

" Function: lh#string#trim_text_right(string, ) {{{3
" @version 4.0.0
function! lh#string#trim_text_right(string, text) abort
  let idx = stridx(a:string, a:text)
  if idx == 0
    return a:string[len(a:text):]
  else
    return a:string
  endif
endfunction

" # Matching {{{2
" Function: lh#string#matches(string, pattern) {{{3
" snippet from Peter Rincker: http://stackoverflow.com/a/34069943/15934
" @version 3.4.0
function! lh#string#matches(string, pattern) abort
  let res = []
  call substitute(a:string, a:pattern, '\=add(res, submatch(0))', 'g')
  return res
endfunction

" Function: lh#string#matchstrpos(expr, pattern) {{{3
" Back port |matchstrpos()| to older versions of vim
" @version 4.0.0
if exists('*matchstrpos')
  function! lh#string#matchstrpos(expr, pattern, ...) abort
    return call('matchstrpos', [a:expr, a:pattern] + a:000)
  endfunction
else
  function! lh#string#matchstrpos(expr, pattern, ...) abort
    call lh#assert#type(a:expr).belongs_to('', [])
    if type(a:expr) == type('')
      let b = call('match', [a:expr, a:pattern] + a:000)
      if b < 0 | return ['', -1, -1] | endif
      let e = call('matchend', [a:expr, a:pattern] + a:000)
      return [a:expr[b : e], b, e]
    else " list case
      " First the first match
      let res = map(copy(a:expr), '[v:key, call("match", [v:val, a:pattern]+a:000)]')
      call filter(res, 'v:val[1] >= 0')
      if empty(res) | return ['', -1, -1, -1] | endif
      let idx = res[0][0]
      " And finally extract the end and the str
      let b = res[0][1]
      let e = call('matchend', [a:expr[idx], a:pattern] + a:000)
      return [a:expr[idx][b : e], idx, b, e]
    endif
  endfunction
endif

" # Convertion {{{2
" Function: lh#string#as(val) {{{3
" NOTE: this function cannot use s:Log()
" @version 3.6.1
function! lh#string#as(val) abort
  if     type(a:val) == type([])
    return string(a:val)
  elseif type(a:val) == type({})
    if has_key(a:val, '_to_string')
      return a:val._to_string()
    endif
    return string(a:val)
  elseif type(a:val) == type(function('has'))
    return string(a:val)
  endif
  return a:val
endfunction

" # Substitutions {{{2
" Function: lh#string#substitute_unless(string, pat, text) {{{3
" @version 3.9.0
function! lh#string#substitute_unless(string, pat, char) abort
  let s = split(a:string, '\zs\ze')
  call map(s, 'v:val =~ a:pat ? v:val : a:char')
  return join(s, '')
endfunction

" # Miscellaneous {{{2

" Function: lh#string#join(sep, ...) {{{3
" Work as |join()|, but with strings instead of lists
" @since Version 5.2.0
function! lh#string#join(sep, ...) abort
  let strs = filter(copy(a:000), '!empty(v:val)')
  return join(strs, a:sep)
endfunction

" Function: lh#string#or(...) {{{3
" @return the first not empty string
" @version 4.6.4
function! lh#string#or(...) abort
  let r = filter(copy(a:000), '!empty(v:val)')
  return get(r, 0, '')
endfunction
"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
