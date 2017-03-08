"=============================================================================
" File:         tests/lh/let.vim                                  {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/blob/master/License.md>
" Version:      4.0.0
" Created:      10th Sep 2012
" Last Update:  08th Mar 2017
"------------------------------------------------------------------------
" Description:
" 	Tests for plugin/let.vim's LetIfUndef
"------------------------------------------------------------------------
" TODO:
" * Test :Unlet and lh#let#unlet
" }}}1
"=============================================================================

UTSuite [lh-vim-lib] Testing LetIfUndef command

let s:cpo_save=&cpo
set cpo&vim

" ## Dependencies {{{1
if exists(':Reload')
  Reload plugin/let.vim
else
  runtime plugin/let.vim
endif
runtime autoload/lh/let.vim
runtime autoload/lh/list.vim

let cleanup = lh#on#exit()
      \.restore('g:force_reload_lh_project')
try
  runtime plugin/lh-project.vim
finally
  call cleanup.finalize()
endtry


" ## Fixture {{{1
let s:prj_varname = 'b:'.get(g:, 'lh#project#varname', 'crt_project')
function! s:Setup() " {{{2
  let s:prj_list = lh#project#list#_save()
  let s:cleanup = lh#on#exit()
        \.restore('b:'.s:prj_varname)
        \.restore('s:prj_varname')
        \.restore('g:lh#project.auto_discover_root')
  let g:lh#project = { 'auto_discover_root': 'no' }
  if exists('b:'.s:prj_varname)
    exe 'unlet b:'.s:prj_varname
  endif
endfunction

function! s:Teardown() " {{{2
  call s:cleanup.finalize()
  call lh#project#list#_restore(s:prj_list)
endfunction

" ## Tests {{{1
" # LetIfUndef {{{2
function! s:Test_let_if_undef_variables_cmd() " {{{3
  " value = int {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  LetIfUndef g:dummy_test 42
  Assert exists('g:dummy_test')
  AssertEquals(g:dummy_test, 42)
  AssertEquals(type(g:dummy_test), type(42))
  LetIfUndef g:dummy_test 0
  AssertEquals(g:dummy_test, 42)

  " value = string {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  LetIfUndef g:dummy_test 'toto'
  Assert exists('g:dummy_test')
  AssertEquals(g:dummy_test, 'toto')
  AssertEquals(type(g:dummy_test), type(''))
  LetIfUndef g:dummy_test 0
  AssertEquals(g:dummy_test, 'toto')
  LetIfUndef g:dummy_test 'foo'
  AssertEquals(g:dummy_test, 'toto')

  " value = list {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  LetIfUndef g:dummy_test [1, 2, 3]
  Assert exists('g:dummy_test')
  AssertEquals(g:dummy_test, [1, 2, 3])
  AssertEquals(type(g:dummy_test), type([]))
  LetIfUndef g:dummy_test 0
  AssertEquals(g:dummy_test, [1, 2, 3])
  LetIfUndef g:dummy_test [0]
  AssertEquals(g:dummy_test, [1, 2, 3])

  " value = dict {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  LetIfUndef g:dummy_test {'a':1, 'b': {'c': 8}}
  Assert exists('g:dummy_test')
  AssertEquals(g:dummy_test, {'a':1, 'b': {'c': 8}})
  AssertEquals(type(g:dummy_test), type({}))
  LetIfUndef g:dummy_test 0
  AssertEquals(g:dummy_test, {'a':1, 'b': {'c': 8}})
  LetIfUndef g:dummy_test [0]
  AssertEquals(g:dummy_test, {'a':1, 'b': {'c': 8}})

  " value = expression {{{4
  silent! unlet g:dummy_test
  let g:loc = 'test' " only global/buffer/window/tab variables can be used
  Assert !exists('g:dummy_test')
  LetIfUndef g:dummy_test repeat('a', 2).'z'.g:loc
  Assert exists('g:dummy_test')
  AssertEquals(g:dummy_test, 'aaztest')
  AssertEquals(type(g:dummy_test), type(''))
  LetIfUndef g:dummy_test 0
  AssertEquals(g:dummy_test, 'aaztest')
  LetIfUndef g:dummy_test [0]
  AssertEquals(g:dummy_test, 'aaztest')

  " env = string {{{4
  if 0
    " Impossible to test as `unlet $VAR` isn't supported
    silent! unlet $dummy_test
    Assert !exists('$dummy_test')
    LetIfUndef $dummy_test 'toto'
    Assert exists('$dummy_test')
    AssertEquals($dummy_test, 'toto')
    AssertEquals(type($dummy_test), type(''))
    LetIfUndef $dummy_test 0
    AssertEquals($dummy_test, 'toto')
    LetIfUndef $dummy_test 'foo'
    AssertEquals($dummy_test, 'toto')
  endif

  " Invalid Var name {{{4
  AssertThrow(lh#let#if_undef('y:dummy_test', 42))
  AssertThrow(lh#let#if_undef('dummy_test', 42))
  " }}}4
endfunction

function! s:Test_let_if_undef_dictionaries_cmd() " {{{3
  " value = int {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  LetIfUndef g:dummy_test.un.deux 12
  Assert exists('g:dummy_test')
  Assert has_key(g:dummy_test, 'un')
  Assert has_key(g:dummy_test.un, 'deux')
  AssertEquals(g:dummy_test.un.deux, 12)
  LetIfUndef g:dummy_test.un.deux 42
  AssertEquals(g:dummy_test.un.deux, 12)

  AssertEquals(lh#dict#get_composed(g:dummy_test, 'un.deux'), 12)
  AssertEquals(lh#dict#get_composed(g:dummy_test.un, 'deux'), 12)
  Assert lh#option#is_unset(lh#dict#get_composed(g:dummy_test, 'un.trois'))

  " value = string {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  LetIfUndef g:dummy_test.un.deux 'str'
  Assert exists('g:dummy_test')
  Assert has_key(g:dummy_test, 'un')
  Assert has_key(g:dummy_test.un, 'deux')
  AssertEquals(type(g:dummy_test.un.deux), type(''))
  AssertEquals(g:dummy_test.un.deux, 'str')
  LetIfUndef g:dummy_test.un.deux 42
  AssertEquals(g:dummy_test.un.deux, 'str')

  " value = list {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  LetIfUndef g:dummy_test.un.deux [1, 2, ['r']]
  Assert exists('g:dummy_test')
  Assert has_key(g:dummy_test, 'un')
  Assert has_key(g:dummy_test.un, 'deux')
  AssertEquals(type(g:dummy_test.un.deux), type([]))
  AssertEquals(g:dummy_test.un.deux, [1, 2, ['r']])
  LetIfUndef g:dummy_test.un.deux 42
  AssertEquals(g:dummy_test.un.deux, [1, 2, ['r']])

  " value = dict {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  LetIfUndef g:dummy_test.un.deux {'a':1, 'b':{'c':5}}
  Assert exists('g:dummy_test')
  Assert has_key(g:dummy_test, 'un')
  Assert has_key(g:dummy_test.un, 'deux')
  AssertEquals(type(g:dummy_test.un.deux), type({}))
  AssertEquals(g:dummy_test.un.deux, {'a':1, 'b':{'c':5}})
  LetIfUndef g:dummy_test.un.deux 42
  AssertEquals(g:dummy_test.un.deux, {'a':1, 'b':{'c':5}})

  " value = expression {{{4
  silent! unlet g:dummy_test
  let g:loc = 'test' " only global/buffer/window/tab variables can be used
  Assert !exists('g:dummy_test')
  LetIfUndef g:dummy_test.un.deux repeat('a', 2).'z'.g:loc
  Assert exists('g:dummy_test')
  Assert has_key(g:dummy_test, 'un')
  Assert has_key(g:dummy_test.un, 'deux')
  AssertEquals(type(g:dummy_test.un.deux), type(''))
  AssertEquals(g:dummy_test.un.deux, 'aaztest')
  LetIfUndef g:dummy_test.un.deux 42
  AssertEquals(g:dummy_test.un.deux, 'aaztest')

  " Invalid Var name {{{4
  AssertThrow(lh#let#if_undef('y:dummy_test', 42))
  AssertThrow(lh#let#if_undef('dummy_test', 42))
  " }}}4
endfunction

function! s:Test_let_if_undef_variables_fn() " {{{3
  " value = int {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  call lh#let#if_undef('g:dummy_test', 42)
  Assert exists('g:dummy_test')
  AssertEquals(g:dummy_test, 42)
  AssertEquals(type(g:dummy_test), type(42))
  call lh#let#if_undef('g:dummy_test', 0)
  AssertEquals(g:dummy_test, 42)

  " value = string {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  call lh#let#if_undef('g:dummy_test', 'toto')
  Assert exists('g:dummy_test')
  AssertEquals(g:dummy_test, 'toto')
  AssertEquals(type(g:dummy_test), type(''))
  call lh#let#if_undef('g:dummy_test', 0)
  AssertEquals(g:dummy_test, 'toto')
  call lh#let#if_undef('g:dummy_test', 'foo')
  AssertEquals(g:dummy_test, 'toto')

  " value = list {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  call lh#let#if_undef('g:dummy_test', [1, 2, 3])
  Assert exists('g:dummy_test')
  AssertEquals(g:dummy_test, [1, 2, 3])
  AssertEquals(type(g:dummy_test), type([]))
  call lh#let#if_undef('g:dummy_test', 0)
  AssertEquals(g:dummy_test, [1, 2, 3])
  call lh#let#if_undef('g:dummy_test', [0])
  AssertEquals(g:dummy_test, [1, 2, 3])

  " value = dict {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  call lh#let#if_undef('g:dummy_test', {'a':1, 'b': {'c': 8}})
  Assert exists('g:dummy_test')
  AssertEquals(g:dummy_test, {'a':1, 'b': {'c': 8}})
  AssertEquals(type(g:dummy_test), type({}))
  call lh#let#if_undef('g:dummy_test', 0)
  AssertEquals(g:dummy_test, {'a':1, 'b': {'c': 8}})
  call lh#let#if_undef('g:dummy_test', [0])
  AssertEquals(g:dummy_test, {'a':1, 'b': {'c': 8}})

  " value = expression {{{4
  silent! unlet g:dummy_test
  let g:loc = 'test' " only global/buffer/window/tab variables can be used
  Assert !exists('g:dummy_test')
  call lh#let#if_undef('g:dummy_test', repeat('a', 2).'z'.g:loc)
  Assert exists('g:dummy_test')
  AssertEquals(g:dummy_test, 'aaztest')
  AssertEquals(type(g:dummy_test), type(''))
  call lh#let#if_undef('g:dummy_test', 0)
  AssertEquals(g:dummy_test, 'aaztest')
  call lh#let#if_undef('g:dummy_test', [0])
  AssertEquals(g:dummy_test, 'aaztest')

  " Invalid Var name {{{4
  AssertThrow(lh#let#if_undef('y:dummy_test', 42))
  AssertThrow(lh#let#if_undef('dummy_test', 42))
  " }}}4
endfunction

function! s:Test_let_if_undef_dictionaries_fn() " {{{3
  " value = int {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  call lh#let#if_undef('g:dummy_test.un.deux', 12)
  Assert exists('g:dummy_test')
  Assert has_key(g:dummy_test, 'un')
  Assert has_key(g:dummy_test.un, 'deux')
  AssertEquals(g:dummy_test.un.deux, 12)
  call lh#let#if_undef('g:dummy_test.un.deux', 42)
  AssertEquals(g:dummy_test.un.deux, 12)

  " value = string {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  call lh#let#if_undef('g:dummy_test.un.deux', 'str')
  Assert exists('g:dummy_test')
  Assert has_key(g:dummy_test, 'un')
  Assert has_key(g:dummy_test.un, 'deux')
  AssertEquals(type(g:dummy_test.un.deux), type(''))
  AssertEquals(g:dummy_test.un.deux, 'str')
  call lh#let#if_undef('g:dummy_test.un.deux', 42)
  AssertEquals(g:dummy_test.un.deux, 'str')

  " value = list {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  call lh#let#if_undef('g:dummy_test.un.deux', [1, 2, ['r']])
  Assert exists('g:dummy_test')
  Assert has_key(g:dummy_test, 'un')
  Assert has_key(g:dummy_test.un, 'deux')
  AssertEquals(type(g:dummy_test.un.deux), type([]))
  AssertEquals(g:dummy_test.un.deux, [1, 2, ['r']])
  call lh#let#if_undef('g:dummy_test.un.deux', 42)
  AssertEquals(g:dummy_test.un.deux, [1, 2, ['r']])

  " value = dict {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  call lh#let#if_undef('g:dummy_test.un.deux', {'a':1, 'b':{'c':5}})
  Assert exists('g:dummy_test')
  Assert has_key(g:dummy_test, 'un')
  Assert has_key(g:dummy_test.un, 'deux')
  AssertEquals(type(g:dummy_test.un.deux), type({}))
  AssertEquals(g:dummy_test.un.deux, {'a':1, 'b':{'c':5}})
  call lh#let#if_undef('g:dummy_test.un.deux', 42)
  AssertEquals(g:dummy_test.un.deux, {'a':1, 'b':{'c':5}})

  " value = expression {{{4
  silent! unlet g:dummy_test
  let g:loc = 'test' " only global/buffer/window/tab variables can be used
  Assert !exists('g:dummy_test')
  call lh#let#if_undef('g:dummy_test.un.deux', repeat('a', 2).'z'.g:loc)
  Assert exists('g:dummy_test')
  Assert has_key(g:dummy_test, 'un')
  Assert has_key(g:dummy_test.un, 'deux')
  AssertEquals(type(g:dummy_test.un.deux), type(''))
  AssertEquals(g:dummy_test.un.deux, 'aaztest')
  call lh#let#if_undef('g:dummy_test.un.deux', 42)
  AssertEquals(g:dummy_test.un.deux, 'aaztest')

  " Invalid Var name {{{4
  AssertThrow(lh#let#if_undef('y:dummy_test', 42))
  AssertThrow(lh#let#if_undef('dummy_test', 42))
  " }}}4
endfunction

function! s:Test_let_funcref() " {{{3
  " value = int {{{4
  silent! unlet g:Dummy_test
  Assert !exists('g:Dummy_test')
  LetIfUndef g:Dummy_test function('exists')
  Assert exists('g:Dummy_test')
  Assert g:Dummy_test('*has')

  LetTo g:Dummy_test function('has')
  Assert g:Dummy_test('eval')
  " }}}4
endfunction

" # LetTo {{{2
function! s:Test_let_force_variables_cmd() " {{{3
  " value = int {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  LetTo g:dummy_test 42
  Assert exists('g:dummy_test')
  AssertEquals(g:dummy_test, 42)
  AssertEquals(type(g:dummy_test), type(42))
  LetTo g:dummy_test 0
  AssertEquals(g:dummy_test, 0)

  " value = string {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  LetTo g:dummy_test 'toto'
  Assert exists('g:dummy_test')
  AssertEquals(g:dummy_test, 'toto')
  AssertEquals(type(g:dummy_test), type(''))
  LetTo g:dummy_test 0
  AssertEquals(g:dummy_test, 0)
  LetTo g:dummy_test 'foo'
  AssertEquals(g:dummy_test, 'foo')

  " value = list {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  LetTo g:dummy_test [1, 2, 3]
  Assert exists('g:dummy_test')
  AssertEquals(g:dummy_test, [1, 2, 3])
  AssertEquals(type(g:dummy_test), type([]))
  LetTo g:dummy_test 0
  AssertEquals(g:dummy_test, 0)
  LetTo g:dummy_test [0]
  AssertEquals(g:dummy_test, [0])

  " value = dict {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  LetTo g:dummy_test {'a':1, 'b': {'c': 8}}
  Assert exists('g:dummy_test')
  AssertEquals(g:dummy_test, {'a':1, 'b': {'c': 8}})
  AssertEquals(type(g:dummy_test), type({}))
  LetTo g:dummy_test 0
  AssertEquals(g:dummy_test, 0)
  LetTo g:dummy_test [0]
  AssertEquals(g:dummy_test, [0])

  " value = expression {{{4
  silent! unlet g:dummy_test
  let g:loc = 'test' " only global/buffer/window/tab variables can be used
  Assert !exists('g:dummy_test')
  LetTo g:dummy_test repeat('a', 2).'z'.g:loc
  Assert exists('g:dummy_test')
  AssertEquals(g:dummy_test, 'aaztest')
  AssertEquals(type(g:dummy_test), type(''))
  LetTo g:dummy_test 0
  AssertEquals(g:dummy_test, 0)
  LetTo g:dummy_test [0]
  AssertEquals(g:dummy_test, [0])

  " $env = string {{{4
  let $dummy_test = ''
  LetTo $dummy_test 'toto'
  Assert exists('$dummy_test')
  AssertEquals($dummy_test, 'toto')
  AssertEquals(type($dummy_test), type(''))
  LetTo $dummy_test 0
  AssertEquals($dummy_test, 0)
  LetTo $dummy_test 'foo'
  AssertEquals($dummy_test, 'foo')

  " Invalid Var name {{{4
  AssertThrow(lh#let#to('y:dummy_test', 42))
  AssertThrow(lh#let#to('dummy_test', 42))
  " }}}4
endfunction

"------------------------------------------------------------------------
function! s:Test_let_force_dictionaries_cmd() " {{{3
  " value = int {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  LetTo g:dummy_test.un.deux 12
  Assert exists('g:dummy_test')
  Assert has_key(g:dummy_test, 'un')
  Assert has_key(g:dummy_test.un, 'deux')
  AssertEquals(g:dummy_test.un.deux, 12)
  AssertEquals(type(g:dummy_test.un.deux), type(12))
  LetTo g:dummy_test.un.deux 42
  AssertEquals(g:dummy_test.un.deux, 42)
  " cannot change var to dict
  AssertThrow(lh#let#to('g:dummy_test.un.deux.trois', 42))

  " value = string {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  LetTo g:dummy_test.un.deux 'str'
  Assert exists('g:dummy_test')
  Assert has_key(g:dummy_test, 'un')
  Assert has_key(g:dummy_test.un, 'deux')
  AssertEquals(type(g:dummy_test.un.deux), type(''))
  AssertEquals(g:dummy_test.un.deux, 'str')
  LetTo g:dummy_test.un.deux 42
  AssertEquals(g:dummy_test.un.deux, 42)

  " value = list {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  LetTo g:dummy_test.un.deux [1, 2, ['r']]
  Assert exists('g:dummy_test')
  Assert has_key(g:dummy_test, 'un')
  Assert has_key(g:dummy_test.un, 'deux')
  AssertEquals(type(g:dummy_test.un.deux), type([]))
  AssertEquals(g:dummy_test.un.deux, [1, 2, ['r']])
  LetTo g:dummy_test.un.deux 42
  AssertEquals(g:dummy_test.un.deux, 42)

  " value = dict {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  LetTo g:dummy_test.un.deux {'a':1, 'b':{'c':5}}
  Assert exists('g:dummy_test')
  Assert has_key(g:dummy_test, 'un')
  Assert has_key(g:dummy_test.un, 'deux')
  AssertEquals(type(g:dummy_test.un.deux), type({}))
  AssertEquals(g:dummy_test.un.deux, {'a':1, 'b':{'c':5}})
  LetTo g:dummy_test.un.deux 42
  AssertEquals(g:dummy_test.un.deux, 42)

  " value = expression {{{4
  silent! unlet g:dummy_test
  let g:loc = 'test' " only global/buffer/window/tab variables can be used
  Assert !exists('g:dummy_test')
  LetTo g:dummy_test.un.deux repeat('a', 2).'z'.g:loc
  Assert exists('g:dummy_test')
  Assert has_key(g:dummy_test, 'un')
  Assert has_key(g:dummy_test.un, 'deux')
  AssertEquals(type(g:dummy_test.un.deux), type(''))
  AssertEquals(g:dummy_test.un.deux, 'aaztest')
  LetTo g:dummy_test.un.deux 42
  AssertEquals(g:dummy_test.un.deux, 42)

  " Invalid Var name {{{4
  AssertThrow(lh#let#to('y:dummy_test', 42))
  AssertThrow(lh#let#to('dummy_test', 42))
  " }}}4
endfunction

"------------------------------------------------------------------------
function! s:Test_let_force_variables_fn() " {{{3
  " value = int {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  call lh#let#to('g:dummy_test', 42)
  Assert exists('g:dummy_test')
  AssertEquals(g:dummy_test, 42)
  AssertEquals(type(g:dummy_test), type(42))
  call lh#let#to('g:dummy_test', 0)
  AssertEquals(g:dummy_test, 0)

  " value = string {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  call lh#let#to('g:dummy_test', 'toto')
  Assert exists('g:dummy_test')
  AssertEquals(g:dummy_test, 'toto')
  AssertEquals(type(g:dummy_test), type(''))
  call lh#let#to('g:dummy_test', 0)
  AssertEquals(g:dummy_test, 0)
  call lh#let#to('g:dummy_test', 'foo')
  AssertEquals(g:dummy_test, 'foo')

  " value = list {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  call lh#let#to('g:dummy_test', [1, 2, 3])
  Assert exists('g:dummy_test')
  AssertEquals(g:dummy_test, [1, 2, 3])
  AssertEquals(type(g:dummy_test), type([]))
  call lh#let#to('g:dummy_test', 0)
  AssertEquals(g:dummy_test, 0)
  call lh#let#to('g:dummy_test', [0])
  AssertEquals(g:dummy_test, [0])

  " value = dict {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  call lh#let#to('g:dummy_test', {'a':1, 'b': {'c': 8}})
  Assert exists('g:dummy_test')
  AssertEquals(g:dummy_test, {'a':1, 'b': {'c': 8}})
  AssertEquals(type(g:dummy_test), type({}))
  call lh#let#to('g:dummy_test', 0)
  AssertEquals(g:dummy_test, 0)
  call lh#let#to('g:dummy_test', [0])
  AssertEquals(g:dummy_test, [0])

  " value = expression {{{4
  silent! unlet g:dummy_test
  let g:loc = 'test' " only global/buffer/window/tab variables can be used
  Assert !exists('g:dummy_test')
  call lh#let#to('g:dummy_test', repeat('a', 2).'z'.g:loc)
  Assert exists('g:dummy_test')
  AssertEquals(g:dummy_test, 'aaztest')
  AssertEquals(type(g:dummy_test), type(''))
  call lh#let#to('g:dummy_test', 0)
  AssertEquals(g:dummy_test, 0)
  call lh#let#to('g:dummy_test', [0])
  AssertEquals(g:dummy_test, [0])

  " $env = string {{{4
  let $dummy_test = ''
  call lh#let#to('$dummy_test', 'toto')
  Assert exists('$dummy_test')
  AssertEquals($dummy_test, 'toto')
  AssertEquals(type($dummy_test), type(''))
  call lh#let#to('$dummy_test', 0)
  AssertEquals($dummy_test, 0)
  call lh#let#to('$dummy_test', 'foo')
  AssertEquals($dummy_test, 'foo')

  " Invalid Var name {{{4
  AssertThrow(lh#let#to('y:dummy_test', 42))
  AssertThrow(lh#let#to('dummy_test', 42))
  " }}}4
endfunction

"------------------------------------------------------------------------
function! s:Test_let_force_dictionaries_fn() " {{{3
  " value = int {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  call lh#let#to('g:dummy_test.un.deux', 12)
  Assert exists('g:dummy_test')
  Assert has_key(g:dummy_test, 'un')
  Assert has_key(g:dummy_test.un, 'deux')
  AssertEquals(g:dummy_test.un.deux, 12)
  AssertEquals(type(g:dummy_test.un.deux), type(12))
  call lh#let#to('g:dummy_test.un.deux', 42)
  AssertEquals(g:dummy_test.un.deux, 42)

  " value = string {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  call lh#let#to('g:dummy_test.un.deux', 'str')
  Assert exists('g:dummy_test')
  Assert has_key(g:dummy_test, 'un')
  Assert has_key(g:dummy_test.un, 'deux')
  AssertEquals(type(g:dummy_test.un.deux), type(''))
  AssertEquals(g:dummy_test.un.deux, 'str')
  call lh#let#to('g:dummy_test.un.deux', 42)
  AssertEquals(g:dummy_test.un.deux, 42)

  " value = list {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  call lh#let#to('g:dummy_test.un.deux', [1, 2, ['r']])
  Assert exists('g:dummy_test')
  Assert has_key(g:dummy_test, 'un')
  Assert has_key(g:dummy_test.un, 'deux')
  AssertEquals(type(g:dummy_test.un.deux), type([]))
  AssertEquals(g:dummy_test.un.deux, [1, 2, ['r']])
  call lh#let#to('g:dummy_test.un.deux', 42)
  AssertEquals(g:dummy_test.un.deux, 42)

  " value = dict {{{4
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')
  call lh#let#to('g:dummy_test.un.deux', {'a':1, 'b':{'c':5}})
  Assert exists('g:dummy_test')
  Assert has_key(g:dummy_test, 'un')
  Assert has_key(g:dummy_test.un, 'deux')
  AssertEquals(type(g:dummy_test.un.deux), type({}))
  AssertEquals(g:dummy_test.un.deux, {'a':1, 'b':{'c':5}})
  call lh#let#to('g:dummy_test.un.deux', 42)
  AssertEquals(g:dummy_test.un.deux, 42)

  " value = expression {{{4
  silent! unlet g:dummy_test
  let g:loc = 'test' " only global/buffer/window/tab variables can be used
  Assert !exists('g:dummy_test')
  call lh#let#to('g:dummy_test.un.deux', repeat('a', 2).'z'.g:loc)
  Assert exists('g:dummy_test')
  Assert has_key(g:dummy_test, 'un')
  Assert has_key(g:dummy_test.un, 'deux')
  AssertEquals(type(g:dummy_test.un.deux), type(''))
  AssertEquals(g:dummy_test.un.deux, 'aaztest')
  call lh#let#to('g:dummy_test.un.deux', 42)
  AssertEquals(g:dummy_test.un.deux, 42)

  " Invalid Var name {{{4
  AssertThrow(lh#let#to('y:dummy_test', 42))
  AssertThrow(lh#let#to('dummy_test', 42))
  " }}}4
endfunction

"------------------------------------------------------------------------
" # PushOptions {{{2
"------------------------------------------------------------------------
" Function: s:Test_push_option_list() {{{3
function! s:Test_push_option_list() abort
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')

  PushOptions g:dummy_test un
  AssertEqual (g:dummy_test, ['un'])
  PushOptions g:dummy_test deux
  AssertEqual (g:dummy_test, ['un', 'deux'])
  PushOptions g:dummy_test un
  AssertEqual (g:dummy_test, ['un', 'deux'])
  PushOptions g:dummy_test trois un quatre
  AssertEqual (g:dummy_test, ['un', 'deux', 'trois', 'quatre'])

  PopOptions g:dummy_test deux quatre
  AssertEqual (g:dummy_test, ['un', 'trois'])
endfunction

"------------------------------------------------------------------------
" Function: s:Test_push_option_dict {{{3
function! s:Test_push_option_dict() abort
  silent! unlet g:dummy_test
  Assert !exists('g:dummy_test')

  PushOptions g:dummy_test.titi un
  AssertEqual (g:dummy_test.titi, ['un'])
  PushOptions g:dummy_test.titi deux
  AssertEqual (g:dummy_test.titi, ['un', 'deux'])
  PushOptions g:dummy_test.titi un
  AssertEqual (g:dummy_test.titi, ['un', 'deux'])
  PushOptions g:dummy_test.titi trois un quatre
  AssertEqual (g:dummy_test.titi, ['un', 'deux', 'trois', 'quatre'])

  PopOptions g:dummy_test.titi deux quatre
  AssertEqual (g:dummy_test.titi, ['un', 'trois'])
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
