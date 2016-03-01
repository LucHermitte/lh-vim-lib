"=============================================================================
" File:         tests/lh/string.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      3.4.0.
let s:k_version = '340'
" Created:      15th Dec 2015
" Last Update:  15th Dec 2015
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

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
