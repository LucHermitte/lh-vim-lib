"=============================================================================
" File:         tests/lh/ref.vim                                  {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0.0.
let s:k_version = '4000'
" Created:      09th Sep 2016
" Last Update:  09th Sep 2016
"------------------------------------------------------------------------
" Description:
"       «description»
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

UTSuite [lh-vim-lib] Testing lh#ref

let s:cpo_save=&cpo
set cpo&vim

" ## Dependencies {{{1
runtime autoload/lh/ref.vim
runtime autoload/lh/option.vim
runtime autoload/lh/let.vim
runtime plugin/let.vim

"------------------------------------------------------------------------
" ## Fixtures {{{1
function! s:Setup() abort
  let s:cleanup = lh#on#exit()
        \.restore('g:dummy')
        \.restore('b:dummy')
  Unlet g:dummy
  Unlet b:dummy
endfunction

function! s:Teardown() abort
  call s:cleanup.finalize()
endfunction

" ## Tests {{{1
function! s:Test_let_n_bind() " {{{2
  let g:dummy = [1,2,3]
  Assert ! lh#ref#is_bound(g:dummy)

  let b:dummy = g:dummy
  Assert ! lh#ref#is_bound(b:dummy)
  LetTo b:dummy = g:dummy
  Assert !lh#ref#is_bound(b:dummy)

  silent! unlet b:dummy
  let b:dummy = lh#ref#bind('g:dummy')
  Assert lh#ref#is_bound(b:dummy)
  LetTo b:dummy = lh#ref#bind('g:dummy')
  Assert lh#ref#is_bound(b:dummy)

  LetTo b:dummy = 12
  Assert !lh#ref#is_bound(b:dummy)
endfunction

function! s:Test_values() " {{{2
  let g:dummy = [1,2,3]
  Assert ! lh#ref#is_bound(g:dummy)
  AssertEqual(lh#option#get('dummy'), g:dummy)

  let b:dummy = g:dummy
  Assert ! lh#ref#is_bound(b:dummy)
  AssertEqual(lh#option#get('dummy'), g:dummy)
  LetTo b:dummy = g:dummy
  Assert !lh#ref#is_bound(b:dummy)
  AssertEqual(lh#option#get('dummy'), g:dummy)
  let g:dummy = [1, 2, 3, 4]
  AssertDiffer(lh#option#get('dummy'), g:dummy)

  silent! unlet b:dummy
  let b:dummy = lh#ref#bind('g:dummy')
  Assert lh#ref#is_bound(b:dummy)
  AssertEqual(lh#option#get('dummy'), g:dummy)
  LetTo b:dummy = lh#ref#bind('g:dummy')
  Assert lh#ref#is_bound(b:dummy)
  AssertEqual(lh#option#get('dummy'), g:dummy)
  let g:dummy = [1, 2, 3, 4, 5]
  AssertEqual(lh#option#get('dummy'), g:dummy)

  LetTo b:dummy = 12
  Assert !lh#ref#is_bound(b:dummy)
endfunction

function! s:Test_ref_to_attributes() " {{{2
  let g:dummy = {'a': [1,2,3]}
  Assert ! lh#ref#is_bound(g:dummy)
  AssertEqual(lh#option#get('dummy'), g:dummy)

  silent! unlet b:dummy
  let b:dummy = lh#ref#bind(g:dummy, 'a')
  Assert lh#ref#is_bound(b:dummy)
  AssertEqual(lh#option#get('dummy'), g:dummy.a)
  LetTo b:dummy = lh#ref#bind(g:dummy, 'a')
  Assert lh#ref#is_bound(b:dummy)
  AssertEqual(lh#option#get('dummy'), g:dummy.a)
  call b:dummy.assign(b:dummy.resolve() + ['Z'])
  AssertEqual(lh#option#get('dummy'), g:dummy.a)
  AssertEqual([1, 2, 3, 'Z'], g:dummy.a)

  " Beware, this is not longer a symbolic link, but an hard link
  let g:dummy = {'a': [1, 2, 3, 4, 5]}
  AssertDiffer(lh#option#get('dummy'), g:dummy.a)

  LetTo b:dummy = 12
  Assert !lh#ref#is_bound(b:dummy)
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
