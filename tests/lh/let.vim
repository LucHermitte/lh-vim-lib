"=============================================================================
" File:         tests/lh/let.vim                                  {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/blob/master/License.md>
" Version:      3.7.1
" Created:      10th Sep 2012
" Last Update:  23rd Feb 2016
"------------------------------------------------------------------------
" Description:
" 	Tests for plugin/let.vim's LetIfUndef
"------------------------------------------------------------------------
" }}}1
"=============================================================================

UTSuite [lh-vim-lib] Testing LetIfUndef command

let s:cpo_save=&cpo
set cpo&vim

if exists(':Reload')
  Reload plugin/let.vim
else
  runtime plugin/let.vim
endif
runtime autoload/lh/let.vim
runtime autoload/lh/list.vim

" # LetIfUndef {{{2
"------------------------------------------------------------------------
function! s:Test_let_variables()
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  LetIfUndef g:dummy_test 42
  Assert exists('g:dummy_test')
  Assert g:dummy_test == 42
  LetIfUndef g:dummy_test 0
  Assert g:dummy_test == 42
endfunction

"------------------------------------------------------------------------
function! s:Test_let_dictionaries()
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

" # PushOptions {{{2
"------------------------------------------------------------------------
" Function: s:Test_push_option_list() {{{3
function! s:Test_push_option_list() abort
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')

  PushOptions g:dummy_test un
  AssertEqual (g:dummy_test, ['un'])
  PushOptions g:dummy_test deux
  AssertEqual (g:dummy_test, ['un', 'deux'])
  PushOptions g:dummy_test un
  AssertEqual (g:dummy_test, ['un', 'deux'])
  PushOptions g:dummy_test trois un quatre
  AssertEqual (g:dummy_test, ['un', 'deux', 'trois', 'quatre'])

  PopOptions g:dummy_test deux quatre
  AssertEqual (g:dummy_test, ['un', 'trois'])
endfunction

"------------------------------------------------------------------------
" Function: s:Test_push_option_dict {{{3
function! s:Test_push_option_dict() abort
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')

  PushOptions g:dummy_test.titi un
  AssertEqual (g:dummy_test.titi, ['un'])
  PushOptions g:dummy_test.titi deux
  AssertEqual (g:dummy_test.titi, ['un', 'deux'])
  PushOptions g:dummy_test.titi un
  AssertEqual (g:dummy_test.titi, ['un', 'deux'])
  PushOptions g:dummy_test.titi trois un quatre
  AssertEqual (g:dummy_test.titi, ['un', 'deux', 'trois', 'quatre'])

  PopOptions g:dummy_test.titi deux quatre
  AssertEqual (g:dummy_test.titi, ['un', 'trois'])
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
