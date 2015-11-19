"=============================================================================
" File:		tests/lh/test-Fargs2String.vim                           {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/License.md>
" Version:	3.3.11
" Created:	16th Apr 2007
" Last Update:	19th Nov 2015
"------------------------------------------------------------------------
" Description:	Tests for lh-vim-lib . lh#command#Fargs2String
"
"------------------------------------------------------------------------
" Installation:
" 	Relies on vim-UT
" }}}1
"=============================================================================

UTSuite [lh-vim-lib] Testing lh#command#Fargs2String

function! s:TestEmpty()
  let empty = []
  let res = lh#command#Fargs2String(empty)
  AssertTxt(len(empty)==0, 'Expected empty')
  AssertEquals(res, '')
endfunction

function! s:TestSimpleText1()
  let expected = 'text'
  let one = [ expected ]
  let res = lh#command#Fargs2String(one)
  AssertEquals(len(one), 0)
  AssertEquals(res, expected)
endfunction

function! s:TestSimpleTextN()
  let expected = 'text'
  let list = [ expected , 'stuff1', 'stuff2']
  let res = lh#command#Fargs2String(list)
  AssertEquals(len(list), 2)
  AssertEquals(res, expected)
endfunction

function! s:TestComposedN()
  let expected = '"a several tokens string"'
  let list = [ '"a', 'several', 'tokens', 'string"', 'stuff1', 'stuff2']
  let res = lh#command#Fargs2String(list)
  AssertEquals(len(list), 2)
  AssertEquals(res, expected)
  AssertEquals(list, ['stuff1', 'stuff2'])
  AssertIs(list, list)
  AssertIsNot(list, ['stuff1', 'stuff2'])
endfunction

function! s:TestComposed1()
  let expected = '"string"'
  let list = [ '"string"', 'stuff1', 'stuff2']
  let res = lh#command#Fargs2String(list)
  AssertEquals(len(list), 2)
  AssertEquals(res, expected)
  AssertEquals(list, ['stuff1', 'stuff2'])
  AssertIsNot(list, ['stuff1', 'stuff2'])
endfunction

function! s:TestInvalidString()
  let expected = '"a string'
  let list = [ '"a', 'string']
  let res = lh#command#Fargs2String(list)
  AssertEquals(len(list), 0)
  AssertEquals(res, expected)
endfunction

function! AllTests()
  call s:TestEmpty()
  call s:TestSimpleText1()
  call s:TestSimpleTextN()
  call s:TestComposed1()
  call s:TestComposedN()
endfunction

"=============================================================================
" vim600: set fdm=marker:
