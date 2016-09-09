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

"------------------------------------------------------------------------
" ## Tests {{{1
function! s:Test_let_n_bind() " {{{2
  let cleanup = lh#on#exit()
        \.restore('g:dummy')
        \.restore('b:dummy')
  try
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
  finally
    call cleanup.finalize()
  endtry
endfunction

function! s:Test_values() " {{{2
  let cleanup = lh#on#exit()
        \.restore('g:dummy')
        \.restore('b:dummy')
  try
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
  finally
    call cleanup.finalize()
  endtry
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
