"=============================================================================
" File:         tests/lh/object.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0.
let s:k_version = '400'
" Created:      27th Sep 2016
" Last Update:  27th Sep 2016
"------------------------------------------------------------------------
" Description:
"       Unit Tests for autoload/lh/object.vim
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

UTSuite [lh-vim-lib] Testing lh#object

runtime autoload/lh/object.vim

let s:cpo_save=&cpo
set cpo&vim

" ## Tests {{{1
"------------------------------------------------------------------------
" # Simple objects {{{2
function! s:check_simple(var)     " {{{3
  AssertEquals(string(a:var), lh#object#to_string(a:var))
endfunction

function! s:Test_2string_simple() " {{{3
  call s:check_simple(42)
  call s:check_simple('foobar')
  call s:check_simple([1,2,'toto'])
  call s:check_simple({'foo': 'bar', 'num': 42})
endfunction

"------------------------------------------------------------------------
" # list|dict w/ recursion {{{2
function! s:check_rec(var)              " {{{3
  " requires execute()
  if exists('*execute')
    " `execute('echo...` will return a string starting with a newline -> [1:]
    AssertEquals(execute('echo a:var')[1:], lh#object#to_string(a:var))
  endif
endfunction

function! s:Test_2string_multiple_occ() " {{{3
  let l = [1,2, 'toto']
  call s:check_rec([l,l])

  let b = l
  let b += [b]
  call s:check_rec(b)

  let d = {'foo': 'bar', 'num': 42, 'list': l}
  call s:check_rec(d)

  let l += [d]
  call s:check_rec(l)
  call s:check_rec(d)
endfunction

"------------------------------------------------------------------------
" # objects w/ to_string() {{{2
function! s:check_object(var)     " {{{3
  AssertEquals(string(a:var), lh#object#make_top_type(a:var)._to_string())
endfunction

function! s:Test_2string_objects() abort " {{{3
  call s:check_object({'foo': 'bar', 'num': 42})

  let d = {'foo': 'bar', 'num': 42}
  let d2 = lh#object#make_top_type({'d': lh#object#make_top_type(d)})
  AssertEquals(string({'d': d}), d2._to_string())
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
