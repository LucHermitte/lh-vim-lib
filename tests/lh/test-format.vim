"=============================================================================
" File:         tests/lh/test-format.vim                          {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0
let s:k_version = '4000'
" Created:      20th Nov 2015
" Last Update:  24th Oct 2016
"------------------------------------------------------------------------
" Description:
"       Test lh#fmt#printf
" }}}1
"=============================================================================

UTSuite [lh-vim-lib] Testing lh#fmt#printf

runtime autoload/lh/fmt.vim

let s:cpo_save=&cpo
set cpo&vim

"------------------------------------------------------------------------
function! s:Test_printf()
  AssertEquals(lh#fmt#printf("foo bar"), "foo bar")
  AssertEquals(lh#fmt#printf("foo %1 bar", 42), "foo 42 bar")
  AssertEquals(lh#fmt#printf("foo %1 bar %2", 42, "toto"), "foo 42 bar toto")
  AssertEquals(lh#fmt#printf("foo %2 bar %1", 42, "toto"), "foo toto bar 42")
  AssertEquals(lh#fmt#printf("foo %{2.toto}-%{1.titi} bar %1", {'a':42, 'titi': 'tutu'}, {'toto': {'foo': 42}}), "foo {'foo': 42}-tutu bar {'a': 42, 'titi': 'tutu'}")
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
