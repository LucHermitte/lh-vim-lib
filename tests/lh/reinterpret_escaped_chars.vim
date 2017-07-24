"=============================================================================
" File:         tests/lh/dev-reinterpret_escaped_chars.vim        {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib/
" Version:      4.0.0
let s:k_version = '400'
" Created:      04th Nov 2015
" Last Update:  24th Jul 2017
"------------------------------------------------------------------------
" Description:
"       Test lh#mapping#reinterpret_escaped_char
" }}}1
"=============================================================================

UTSuite [lh-dev] Testing lh#mapping#reinterpret_escaped_char

runtime autoload/lh/dev.vim

let s:cpo_save=&cpo
set cpo&vim

"------------------------------------------------------------------------
function! s:Test_1()
  AssertEq(lh#mapping#reinterpret_escaped_char('\<left\>'), "\<left>")
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
