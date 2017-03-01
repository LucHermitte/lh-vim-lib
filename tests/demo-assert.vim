"=============================================================================
" File:         tests/demo-assert.vim                             {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0.
let s:k_version = '400'
" Created:      27th Feb 2017
" Last Update:  01st Mar 2017
"------------------------------------------------------------------------
" Description:
"       Demonstrate lh-vim-lib DbC framework
" }}}1
"=============================================================================

if exists(':UTAssert') | finish | endif
runtime autoload/lh/assert.vim

"------------------------------------------------------------------------
" Some function with a contract
function! s:my_sqrt(x)
  call lh#assert#value(a:x).is_ge(0)
  return sqrt(a:x)
endfunction

" Some buggy function (as `sin(x) - 1` may be negative)
function! s:my_computation(x)
  return s:my_sqrt(sin(a:x) - 1)
endfunction

" Some function that innocently trusted the buggy function
function! s:some_other_stuff()
  let res = {}
  for i in range(5, 100)
    let res[i] = s:my_computation(i/10.0* 3.14159)
  endfor
  return res
endfunction

echo s:some_other_stuff()
"=============================================================================
" vim600: set fdm=marker:
