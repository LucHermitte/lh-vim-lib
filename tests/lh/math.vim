"=============================================================================
" File:         tests/lh/math.vim                                 {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      3.8.0.
let s:k_version = '380'
" Created:      29th Feb 2016
" Last Update:  29th Feb 2016
"------------------------------------------------------------------------
" Description:
"       Tests for autoload/lh/maths.vim
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

UTSuite [lh-vim-lib] Testing lh/math.vim

runtime autoload/lh/math.vim

let s:cpo_save=&cpo
set cpo&vim

"------------------------------------------------------------------------
function! s:Test_abs()
  AssertEqual(12,    lh#math#abs(12))
  AssertEqual(12,    lh#math#abs(-12))
  AssertEqual(12.42, lh#math#abs(12.42))
  AssertEqual(12.42, lh#math#abs(-12.42))
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
