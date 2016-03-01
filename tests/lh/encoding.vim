"=============================================================================
" File:         tests/lh/encoding.vim                             {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      3.8.1.
let s:k_version = '381'
" Created:      01st Mar 2016
" Last Update:  01st Mar 2016
"------------------------------------------------------------------------
" Description:
"       UT for lh#encoding#*() functions
" }}}1
"=============================================================================

UTSuite [lh-vim-lib] Testing lh/encoding.vim

runtime autoload/lh/encoding.vim

let s:cpo_save=&cpo
set cpo&vim

"------------------------------------------------------------------------

function! s:_len_eq_width(string)
  AssertEqual(strwidth(a:string), lh#encoding#strlen(a:string))
endfunction

function! s:Test_len()
  call s:_len_eq_width('toto')
  call s:_len_eq_width('éèàçêë')
  call s:_len_eq_width('€')
  call s:_len_eq_width('42€')
endfunction

"------------------------------------------------------------------------
" Function: s:Test_at() {{{3
function! s:Test_at() abort
  let chars = ['a', 'b', 'é', 'à', '1', '2', '€']
  let string = join(chars, '')
  AssertEqual! (len(chars), lh#encoding#strlen(string))

  let i = 0
  while i != len(chars)
    AssertEqual(chars[i], lh#encoding#at(string, i))
    let i += 1
  endwhile
endfunction

"------------------------------------------------------------------------
" Function: s:Test_strpart() {{{3
function! s:Test_strpart() abort
  let chars = ['a', 'b', 'é', 'à', '1', '2', '€']
  let string = join(chars, '')
  AssertEqual! (len(chars), lh#encoding#strlen(string))

  let i = 0
  while i != len(chars)
    let j = i
    while j != len(chars)
      AssertEqual(lh#encoding#strpart(string, i, j-i+1), join(chars[i:j], ''))
      let j += 1
    endwhile
    let i += 1
  endwhile

endfunction
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
