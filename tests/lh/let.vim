"=============================================================================
" $Id$
" File:         tests/lh/let.vim                                  {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" Version:      001
" Created:      10th Sep 2012
" Last Update:  $Date$
"------------------------------------------------------------------------
" Description:
" 	Tests for plugin/let.vim's LetIfUndef
" 
"------------------------------------------------------------------------
" }}}1
"=============================================================================

UTSuite [lh-vim-lib] Testing LetIfUndef command

let s:cpo_save=&cpo
set cpo&vim

Reload plugin/let.vim

"------------------------------------------------------------------------
function! s:Test_variables()
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  LetIfUndef g:dummy_test 42
  Assert exists('g:dummy_test')
  Assert g:dummy_test == 42
  LetIfUndef g:dummy_test 0
  Assert g:dummy_test == 42
endfunction

"------------------------------------------------------------------------
function! s:Test_dictionaries()
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  LetIfUndef g:dummy_test.un.deux 12
  Assert exists('g:dummy_test')
  Assert has_key(g:dummy_test, 'un')
  Assert has_key(g:dummy_test.un, 'deux')
  Assert g:dummy_test.un.deux == 12
  LetIfUndef g:dummy_test.un.deux 42
  Assert g:dummy_test.un.deux == 12
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
