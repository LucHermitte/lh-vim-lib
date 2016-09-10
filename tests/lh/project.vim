"=============================================================================
" File:         tests/lh/project.vim                              {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0.0.
let s:k_version = '4000'
" Created:      10th Sep 2016
" Last Update:  10th Sep 2016
"------------------------------------------------------------------------
" Description:
"       Tests for lh#project
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

UTSuite [lh-vim-lib] Testing lh#project

let s:cpo_save=&cpo
set cpo&vim

" ## Dependencies {{{1
runtime autoload/lh/project.vim
runtime autoload/lh/let.vim

let s:prj_varname = 'b:'.get(g:, 'lh#project#varname', 'crt_project')

"------------------------------------------------------------------------
" ## Tests {{{1
function! s:Test_create() " {{{2
  let cleanup = lh#on#exit()
        \.restore(s:prj_varname)
        \.restore('g:test')
        \.restore('b:test')
  try
    silent! unlet {s:prj_varname}
    silent! unlet g:test
    silent! unlet b:test
    let p = lh#project#new({'name': 'UT'})
    AssertIs(p, {s:prj_varname})
    AssertEquals(p.depth(), 1)

    LetTo p:test = 'prj1'
    AssertEquals(lh#option#get('test'), 'prj1')
    LetTo b:test = 'buff'
    AssertEquals(lh#option#get('test'), 'buff')

    let g:test = 'glob'
    AssertEquals(lh#option#get('test'), 'buff')
    Unlet p:test
    AssertEquals(lh#option#get('test'), 'buff')
    LetTo p:test = 'prj1'
    Unlet b:test
    AssertEquals(lh#option#get('test'), 'prj1')
    Unlet p:test
    AssertEquals(lh#option#get('test'), 'glob')
  finally
    call cleanup.finalize()
  endtry
endfunction

function! s:Test_inherit() " {{{2
  let cleanup = lh#on#exit()
        \.restore(s:prj_varname)
        \.restore('g:test')
        \.restore('b:test')
  try
    silent! unlet {s:prj_varname}
    silent! unlet g:test
    silent! unlet b:test
    let p1 = lh#project#new({'name': 'UT1'})
    AssertIs(p1, {s:prj_varname})
    AssertEquals(p1.depth(), 1)
    Assert lh#option#is_unset(lh#option#get('test'))
    LetTo p:test = 'prj1'
    AssertEquals(lh#option#get('test'), 'prj1')
    LetTo b:test = 'buff'
    AssertEquals(lh#option#get('test'), 'buff')


    let p2 = lh#project#new({'name': 'UT2'})
    AssertEquals(p2.depth(), 2)
    AssertIs(p1, p2.parents[0])
    AssertIs(p2, {s:prj_varname})
    LetTo p:test = 'prj2'
    AssertEquals(lh#option#get('test'), 'buff')
    Unlet b:test
    AssertEquals(lh#option#get('test'), 'prj2')

    let g:test = 'glob'
    AssertEquals(lh#option#get('test'), 'prj2')
    Unlet p:test
    AssertEquals(lh#option#get('test'), 'prj1')
    Unlet p:test
    AssertEquals(lh#option#get('test'), 'glob')
  finally
    call cleanup.finalize()
  endtry
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
