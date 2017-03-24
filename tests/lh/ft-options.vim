"=============================================================================
" File:		tests/lh/dev-option.vim                           {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/master/tree/License.md>
" Version:      4.0.0
let s:k_version = 400
" Created:	05th Oct 2009
" Last Update:	08th Mar 2017
"------------------------------------------------------------------------
" Description:
"       Test lh#ft#options#*() functions
"       Run the test with :UTRun %
" }}}1
"=============================================================================

UTSuite [lh-vim-lib] Testing lh#ft#option functions

let s:cpo_save=&cpo
set cpo&vim

" ## Dependencies {{{1
runtime autoload/lh/ft/option.vim
runtime autoload/lh/project.vim
runtime autoload/lh/let.vim
runtime autoload/lh/option.vim
runtime autoload/lh/os.vim

let cleanup = lh#on#exit()
      \.restore('g:force_reload_lh_project')
try
  runtime plugin/lh-project.vim
finally
  call cleanup.finalize()
endtry

let s:prj_varname = 'b:'.get(g:, 'lh#project#varname', 'crt_project')

"------------------------------------------------------------------------
" ## Fixture {{{1
function! s:Setup() " {{{2
  let s:prj_list = lh#project#list#_save()
  let s:cleanup = lh#on#exit()
        \.restore('b:'.s:prj_varname)
        \.restore('s:prj_varname')
        \.restore('g:lh#project.auto_discover_root')
        " \.register({-> lh#project#list#_restore(s:prj_list)})
  let g:lh#project = { 'auto_discover_root': 'no' }
  if exists('b:'.s:prj_varname)
    exe 'unlet b:'.s:prj_varname
  endif
endfunction

function! s:Teardown() " {{{2
  call s:cleanup.finalize()
  call lh#project#list#_restore(s:prj_list)
endfunction

"------------------------------------------------------------------------
" ## Tests {{{1
function! s:Test_global() " {{{2
  let cleanup = lh#on#exit()
        \.restore('g:foo')
        \.restore('b:foo')
        \.restore('g:FT_foo')
        \.restore('b:FT_foo')
        \.restore('g:bar')
        \.restore('b:bar')
        \.restore('g:FT_bar')
        \.restore('b:FT_bar')
  try
    Unlet g:foo
    Unlet b:foo
    Unlet p:foo
    Unlet g:FT_foo
    Unlet b:FT_foo
    Unlet p:FT_foo
    Unlet g:bar
    Unlet b:bar
    Unlet p:bar
    Unlet g:FT_bar
    Unlet b:FT_bar
    Unlet p:FT_bar
    let g:foo = 42
    AssertEquals(lh#ft#option#get('foo', 'FT', 12) , 42)
    AssertEquals(lh#ft#option#get('bar', 'FT', 12) , 12)

    let b:foo = 43
    AssertEquals(lh#ft#option#get('foo', 'FT', 12) , 43)

    let g:FT_foo = 44
    AssertEquals(lh#ft#option#get('foo', 'FT', 12) , 44)

    let b:FT_foo = 45
    AssertEquals(lh#ft#option#get('foo', 'FT', 12) , 45)
  finally
    call cleanup.finalize()
  endtry
endfunction

function! s:Test_local() " {{{2
  let cleanup = lh#on#exit()
        \.restore('b:foo')
        \.restore('g:FT_foo')
        \.restore('b:FT_foo')
  try
    let b:foo = 43
    AssertEquals(lh#ft#option#get('foo', 'FT', 12) , 43)

    let g:FT_foo = 44
    AssertEquals(lh#ft#option#get('foo', 'FT', 12) , 44)

    let b:FT_foo = 45
    AssertEquals(lh#ft#option#get('foo', 'FT', 12) , 45)
  finally
    call cleanup.finalize()
  endtry
endfunction

function! s:Test_FT_global() " {{{2

  let cleanup = lh#on#exit()
        \.restore('g:FT_foo')
        \.restore('b:FT_foo')
  try
    let g:FT_foo = 44
    AssertEquals(lh#ft#option#get('foo', 'FT', 12) , 44)

    let b:FT_foo = 45
    AssertEquals(lh#ft#option#get('foo', 'FT', 12) , 45)
  finally
    call cleanup.finalize()
  endtry
endfunction

" Function: s:Test_inheritedFT() {{{2
function! s:Test_inheritedFT()
  AssertEquals(lh#ft#option#inherited_filetypes('zz') , ['zz'])
  AssertEquals(lh#ft#option#inherited_filetypes('c') , ['c'])
  AssertEquals(lh#ft#option#inherited_filetypes('cpp') , ['cpp', 'c'])

  let cleanup = lh#on#exit()
        \.restore('g:foo1_inherits')
        \.restore('g:foo2_inherits')
        \.restore('b:foo3_inherits')
  try
    let g:foo1_inherits = 'foo'
    let g:foo2_inherits = 'foo1'
    let b:foo3_inherits = 'foo1,foo'
    AssertTxt (lh#ft#option#inherited_filetypes('foo') == ['foo'],
          \ 'foo inherits from '.string(lh#ft#option#inherited_filetypes('foo')))
    AssertTxt (lh#ft#option#inherited_filetypes('foo1') == ['foo1', 'foo'],
          \ 'foo1 inherits from '.string(lh#ft#option#inherited_filetypes('foo1')))
    AssertTxt (lh#ft#option#inherited_filetypes('foo2') == ['foo2', 'foo1', 'foo'],
          \ 'foo2 inherits from '.string(lh#ft#option#inherited_filetypes('foo2')))
    AssertTxt (lh#ft#option#inherited_filetypes('foo3') == ['foo3', 'foo1', 'foo', 'foo'],
          \ 'foo3 inherits from '.string(lh#ft#option#inherited_filetypes('foo3')))
  finally
    call cleanup.finalize()
  endtry
endfunction

" Function: s:Test_MergeDicts() {{{2
function! s:Test_MergeDicts() abort
  let cleanup = lh#on#exit()
        \.restore('g:foo')
        \.restore('b:foo')
        \.restore('g:FT_foo')
        \.restore('b:FT_foo')
  try
    Unlet g:foo
    Unlet b:foo
    Unlet g:FT_foo
    Unlet b:FT_foo
    LetTo g:foo.glob        = 'g'
    LetTo g:foo.spe_buff    = 'g'
    LetTo g:foo.spe_gFT     = 'g'

    LetTo g:FT_foo.gFT      = 'gft'
    LetTo g:FT_foo.spe_gFT  = 'gft'
    LetTo g:FT_foo.spe_bFT  = 'gft'

    LetTo b:foo.buff        = 'b'
    LetTo b:foo.spe_buff    = 'b'
    LetTo b:foo.spe_bFT     = 'b'

    LetTo b:FT_foo.bFT      = 'bft'
    LetTo b:FT_foo.spe_bFT  = 'bft'

    let d = lh#ft#option#get_all('foo', 'FT')
    AssertEquals(d.glob,     'g')
    AssertEquals(d.buff,     'b')
    AssertEquals(d.spe_buff, 'b')
    AssertEquals(d.gFT,      'gft')
    AssertEquals(d.spe_gFT,  'gft')
    AssertEquals(d.bFT,      'bft')
    AssertEquals(d.spe_bFT,  'bft')
  finally
    call cleanup.finalize()
  endtry
endfunction
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
