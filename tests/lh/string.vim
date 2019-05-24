"=============================================================================
" File:         tests/lh/string.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.6.4
let s:k_version = '464'
" Created:      15th Dec 2015
" Last Update:  24th May 2019
"------------------------------------------------------------------------
" Description:
"       UT for lh#string#*() functions
" }}}1
"=============================================================================

UTSuite [lh-vim-lib] Testing lh/string.vim

runtime autoload/lh/string.vim

let s:cpo_save=&cpo
set cpo&vim

"------------------------------------------------------------------------
function! s:Test_matches() " {{{2
  let matches = lh#string#matches('sqjg %1 msqkg ml %2 mihs m%43%8', '%\zs\d\+')
  let expected= ['1', '2', '43', '8']
  AssertEquals(matches, expected)
endfunction

function! s:Test_matchstrpos() " {{{2
  " Examples from vim documentation
  AssertEquals(lh#string#matchstrpos('testing', 'ing'),    ['ing', 4, 7])
  AssertEquals(lh#string#matchstrpos('testing', 'ing', 2), ['ing', 4, 7])
  AssertEquals(lh#string#matchstrpos('testing', 'ing', 5), ['', -1, -1])
  AssertEquals(lh#string#matchstrpos([1, '__x'], '\a'), ['x', 1, 2, 3])
  " TODO: add other tests
endfunction

function! s:Test_trim_text() " {{{2
  AssertEquals(lh#string#trim('foobar'), 'foobar')
  AssertEquals(lh#string#trim('  foobar'), 'foobar')
  AssertEquals(lh#string#trim("\t foobar  "), 'foobar')
  AssertEquals(lh#string#trim('foobar  '), 'foobar')

  AssertEquals(lh#string#trim_text_right('foobar', 'foo'), 'bar')
  AssertEquals(lh#string#trim_text_right('foobar', 'fobo'), 'foobar')
  AssertEquals(lh#string#trim_text_right('foobar', 'bar'), 'foobar')
  AssertEquals(lh#string#trim_text_right('foobar', 'foobarbar'), 'foobar')
endfunction

" Function: s:Test_or() {{{3
function! s:Test_or() abort
  AssertEquals(lh#string#or(), '')
  AssertEquals(lh#string#or(''), '')
  AssertEquals(lh#string#or('', ''), '')
  AssertEquals(lh#string#or('', '', ''), '')

  AssertEquals(lh#string#or('1'), '1')
  AssertEquals(lh#string#or('1', ''), '1')
  AssertEquals(lh#string#or('1', '2'), '1')
  AssertEquals(lh#string#or('1', '', ''), '1')
  AssertEquals(lh#string#or('1', '2', ''), '1')
  AssertEquals(lh#string#or('1', '', '3'), '1')
  AssertEquals(lh#string#or('1', '2', '3'), '1')

  AssertEquals(lh#string#or('', '2'), '2')
  AssertEquals(lh#string#or('', '2', ''), '2')
  AssertEquals(lh#string#or('', '2', '3'), '2')

  AssertEquals(lh#string#or('', '', '3'), '3')
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
