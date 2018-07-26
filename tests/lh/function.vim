"=============================================================================
" File:		tests/lh/function.vim                                   {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/License.md>
" Version:	4.0.0
" Created:	03rd Nov 2008
" Last Update:	26th Jul 2018
"------------------------------------------------------------------------
" Description:
" 	Tests for autoload/lh/function.vim
" }}}1
"=============================================================================

UTSuite [lh-vim-lib] Testing lh#function plugin

runtime autoload/lh/function.vim
runtime autoload/lh/partial.vim

let s:cpo_save=&cpo
set cpo&vim

" ## Test {{{1
"------------------------------------------------------------------------
function! Test(...) " {{{2
  let nb = len(a:000)
  " echo "test(".nb.':' .join(a:000, ' -- ')')'
  let i =0
  while i!= len(a:000)
    echo "Test: type(".i.")=".type(a:000[i]).' --> '. string(a:000[i])
    let i += 1
  endwhile
endfunction

function! Print(...) " {{{2
  let res = lh#list#accumulate([1,2,'foo'], 'string', 'join(v:1_, " ## ")')
  return res
endfunction

function! Id(...) " {{{2
  return copy(a:000)
endfunction

function! s:TestId() " {{{2
  if has('float')
    let v12 = 1.2
  else
    let v12 = 12
  endif
  let r = Id(1, 'string', [0], [[1]], {'ffo': 42}, function('exists'), v12)
  AssertEquals! (len(r), 7)
  AssertEquals!(should#be#number (r[0]), 1)
  AssertEquals!(should#be#string (r[1]), 1)
  AssertEquals!(should#be#list   (r[2]), 1)
  AssertEquals!(should#be#list   (r[3]), 1)
  AssertEquals!(should#be#dict   (r[4]), 1)
  AssertEquals!(should#be#funcref(r[5]), 1)
  if has('float')
    AssertEquals!(should#be#float(r[6]), 1)
  endif
  AssertEquals(r[0], 1)
  AssertEquals(r[1], 'string')
  AssertEquals(r[2], [0])
  AssertEquals(r[3], [[1]])
  AssertEquals(r[4].ffo,  42)
  AssertEquals(r[5], function('exists'))
  if has('float')
    AssertEquals(r[6], 1.2)
  endif
endfunction

function! s:Test_bind() " {{{2
  " lh#function#bind + lh#function#execute
  let rev4 = lh#function#bind(function('Id'), 'v:4_', 42, 'v:3_', 'v:2_', 'v:1_')
  let r = lh#function#execute(rev4, 1,'two','three', [4,5])
  AssertEquals! (len(r), 5)
  Assert! should#be#list   (r[0])
  Assert! should#be#number (r[1])
  Assert! should#be#string (r[2])
  Assert! should#be#string (r[3])
  Assert! should#be#number (r[4])

  AssertEquals(r[0], [4,5])
  AssertEquals(r[1], 42)
  AssertEquals(r[2], 'three')
  AssertEquals(r[3], 'two')
  AssertEquals(r[4], 1)
endfunction

function! s:Test_bind_compound_vars() " {{{2
  " lh#function#bind + lh#function#execute
  let rev4 = lh#function#bind(function('Id'), 'v:4_', 'v:1_ . v:2_', 'v:3_', 'v:2_', 'v:1_')
  let r = lh#function#execute(rev4, 1,'two','three', [4,5])
  AssertEquals! (len(r), 5)
  Assert! should#be#list   (r[0])
  Assert! should#be#string (r[1])
  Assert! should#be#string (r[2])
  Assert! should#be#string (r[3])
  Assert! should#be#number (r[4])

  AssertEquals(r[0], [4,5])
  AssertEquals(r[1], '1two')
  AssertEquals(r[2], 'three')
  AssertEquals(r[3], 'two')
  AssertEquals(r[4], 1)
endfunction


function! s:Test_execute_func_string_name() " {{{2
  " function name as string
  let r = lh#function#execute('Id', 1,'two',3)
  AssertEquals! (len(r), 3)
  Assert! should#be#number (r[0])
  Assert! should#be#string (r[1])
  Assert! should#be#number (r[2])
  AssertEquals(r[0], 1)
  AssertEquals(r[1], 'two')
  AssertEquals(r[2], 3)
endfunction

function! s:Test_execute_string_expr() " {{{2
  " exp as binded-string
  let r = lh#function#execute('Id(12,len(v:2_).v:2_, 42, v:3_, v:1_)', 1,'two',3)
  AssertEquals! (len(r), 5)
  Assert! should#be#number (r[0])
  Assert! should#be#string (r[1])
  Assert! should#be#number (r[2])
  Assert! should#be#number (r[3])
  Assert! should#be#number (r[4])
  AssertEquals(r[0], 12)
  AssertEquals(r[1], len('two').'two')
  AssertEquals(r[2], 42)
  AssertEquals(r[3], 3)
  AssertEquals(r[4], 1)
endfunction

function! s:Test_execute_func() " {{{2
  " calling a function() + bind
  let r = lh#function#execute(function('Id'), 1,'two','v:1_',['a',42])
  AssertEquals! (len(r), 4)
  Assert! should#be#number (r[0])
  Assert! should#be#string (r[1])
  Assert! should#be#string (r[2])
  Assert! should#be#list   (r[3])
  AssertEquals(r[0], 1)
  AssertEquals(r[1], 'two')
  AssertEquals(r[2], 'v:1_')
  AssertEquals(r[3], ['a', 42])
endfunction
"------------------------------------------------------------------------
function! s:Test_bind_func_string_name_AND_execute() " {{{2
  " function name as string
  let rev3 = lh#function#bind('Id', 'v:3_', 12, 'v:2_', 'v:1_')
  let r = lh#function#execute(rev3, 1,'two',3)

  AssertEquals! (len(r), 4)
  Assert! should#be#number (r[0])
  Assert! should#be#number (r[1])
  Assert! should#be#string (r[2])
  Assert! should#be#number (r[3])
  AssertEquals(r[0], 3)
  AssertEquals(r[1], 12)
  AssertEquals(r[2], 'two')
  AssertEquals(r[3], 1)
endfunction

function! s:Test_bind_string_expr_AND_execute() " {{{2
" expressions as string
  let rev3 = lh#function#bind('Id(12,len(v:2_).v:2_, 42, v:3_, v:1_)')
  let r = lh#function#execute(rev3, 1,'two',3)
  AssertEquals!(len(r), 5)
  Assert! should#be#number (r[0])
  Assert! should#be#string (r[1])
  Assert! should#be#number (r[2])
  Assert! should#be#number (r[3])
  Assert! should#be#number (r[4])
  AssertEquals(r[0], 12)
  AssertEquals(r[1], len('two').'two')
  AssertEquals(r[2], 42)
  AssertEquals(r[3], 3)
  AssertEquals(r[4], 1)
endfunction

function! s:Test_double_bind_func_name() " {{{2
  let f1 = lh#function#bind('Id', 1, 2, 'v:1_', 4, 'v:2_')
  " Comment "f1=".string(f1)
  let r = lh#function#execute(f1, 3, 5)
  AssertEquals!(len(r), 5)
  let i = 0
  while i != len(r)
    Assert! should#be#number (r[i])
    AssertEquals(r[i], i+1)
    let i += 1
  endwhile

  " f2
  let f2 = lh#function#bind(f1, 'v:1_', 5)
  " Comment "f2=f1(v:1_, 5)=".string(f2)
  let r = lh#function#execute(f2, 3)
  AssertEquals!(len(r), 5)
  let i = 0
  while i != len(r)
    Assert! should#be#number (r[i])
    " echo "?? ".(r[i])."==".(i+1)
    AssertEquals(r[i], i+1)
    let i += 1
  endwhile
endfunction

function! s:Test_double_bind_func() " {{{2
  let f1 = lh#function#bind(function('Id'), 1, 2, 'v:1_', 4, 'v:2_')
  " Comment "f1=".string(f1)
  let r = lh#function#execute(f1, 3, 5)
  AssertEquals!(len(r), 5)
  let i = 0
  while i != len(r)
    Assert! should#be#number (r[i])
    AssertEquals(r[i], i+1)
    let i += 1
  endwhile

  " f2
  let f2 = lh#function#bind(f1, 'v:1_', 5)
  " Comment "f2=f1(v:1_, 5)=".string(f2)
  let r = lh#function#execute(f2, 3)
  AssertEquals!(len(r), 5)
  let i = 0
  while i != len(r)
    Assert! should#be#number (r[i])
    AssertEquals(r[i], i+1)
    let i += 1
  endwhile
endfunction

function! s:Test_double_bind_func_cplx() " {{{2
  let g:bar = "bar"
  let f1 = lh#function#bind(function('Id'), 1, 2, 'v:1_', 4, 'v:2_', 'v:3_', 'v:4_', 'v:5_', 'v:6_', 'v:7_')
  " Comment "2bcpl# f1=".string(f1)
  let f2 = lh#function#bind(f1, 'len(g:bar.v:1_)+v:1_', [1,2], '[v:1_, v:2_]', 4,5,6,7)

  " let f2 = lh#function#bind(f1, 'v:1_', 5, 'foo', g:bar, 'len(g:bar.v:1_)+v:1_', [1,2], '[v:1_, v:2_]')
  " Comment "2bcpl# f2=f1(v:1_, 5)=".string(f2)

  let r = lh#function#execute(f2, 42, "foo")
  AssertEquals!(len(r), 10)
  AssertEquals(r[0], 1)
  AssertEquals(r[1], 2)
  AssertEquals(r[2], len(g:bar.42)+42)
  AssertEquals(r[3], 4)
  AssertEquals(r[4], [1,2])
  AssertEquals(r[5], [42, "foo"])
  AssertEquals(r[6], 4)
  AssertEquals(r[7], 5)
  AssertEquals(r[8], 6)
  AssertEquals(r[9], 7)
  " Comment "2bcpl# ".string(r)
endfunction

function! s:Test_double_bind_expr() " {{{2
  let f1 = lh#function#bind('Id(1, 2, v:1_, v:3_, v:2_)')
  " Comment "2be# f1=".string(f1)
  let r = lh#function#execute(f1, 3, 5, 4)
  " Comment "2be# ".string(r)
  AssertEquals! (len(r), 5)
  let i = 0
  while i != len(r)
    Assert! should#be#number (r[i])
    AssertEquals(r[i], i+1)
    let i += 1
  endwhile

  " f2
  let f2 = lh#function#bind(f1, 'v:1_', 'foo', [])
  " Comment "2be# f2=f1(v:1_, 5)=".string(f2)
  let r = lh#function#execute(f2, 3)
  " Comment "2be# ".string(r)
  AssertEquals!(len(r), 5)
  let i = 0
  while i != len(r)-2
    Assert! should#be#number (r[i])
    AssertEquals(r[i], i+1)
    let i += 1
  endwhile

  Assert! should#be#list (r[-2])
  AssertEquals(r[-2], [])
  Assert! should#be#string (r[-1])
  AssertEquals(r[-1], 'foo')
endfunction

"todo: write double-binded tests for all kind of binded parameters:
" 'len(g:bar)'
" 42
" []
" v:1_ + len(v:2_.v:3_)
" '"foo"'
" v:1_

" Function: s:Test_partial() {{{3
function! s:Test_partial() abort
  let l:Cb = lh#partial#make('has', ['gui_running'])
  AssertEquals(1, lh#partial#execute(l:Cb))
  let l:Cb = lh#partial#make('has', [])
  AssertEquals(1, lh#partial#execute(l:Cb, 'gui_running'))
  AssertEquals(0, lh#partial#execute(l:Cb, 'g*i_running'))
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
