"=============================================================================
" File:		tests/lh/list.vim                                 {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/License.md>
" Version:      3.3.20
" Created:	19th Nov 2008
" Last Update:  03rd Dec 2015
"------------------------------------------------------------------------
" Description:
" 	Tests for autoload/lh/list.vim
" }}}1
"=============================================================================

UTSuite [lh-vim-lib] Testing lh#list functions

let s:cpo_save=&cpo
set cpo&vim

" # Dependencies {{{1
runtime autoload/lh/function.vim
runtime autoload/lh/list.vim

" # Tests {{{1
"------------------------------------------------------------------------
" Find_if {{{2
function! s:Test_Find_If_string_predicate()
    :let b = { 'min': 12, 'max': 42 }
    :let l = [ 1, 5, 48, 25, 5, 28, 6]
    :let i = lh#list#Find_if(l, 'v:val>v:1_.min  && v:val<v:1_.max && v:val%v:2_==0', [b, 2] )
    " echo i . '/' . len(l)
    Assert i == 5
    Assert l[i] == 28
    " :echo l[i]
endfunction

function! s:Test_Find_If_functor_predicate()
    :let l = [ 1, 5, 48, 25, 5, 28, 6]
    :let i = lh#list#find_if(l, 'v:1_>12  && v:1_<42 && v:1_%2==0')
    " echo i . '/' . len(l)
    Assert i == 5
    Assert l[i] == 28
    " :echo l[i]
endfunction

function! s:Test_find_if_double_bind()
    :let b = { 'min': 12, 'max': 42 }
    :let l = [ 1, 5, 48, 25, 5, 28, 6]
    :let f = lh#function#bind( 'v:3_>v:1_.min  && v:3_<v:1_.max && v:3_%v:2_==0')
    :let p = lh#function#bind(f, b,2,'v:1_')
    :let i = lh#list#find_if(l, p)
    :echo l[i]
endfunction
" double bind is not yet operational
UTIgnore Test_find_if_double_bind

"------------------------------------------------------------------------
" Unique Sorting {{{2
function! s:Test_sort_num()
    :let l = [ 1, 5, 48, 25, 5, 28, 6]
    :let expected = [ 1, 5, 5, 6, 25, 28, 48]
    " Comment string(s)
    AssertEquals(lh#list#sort(l, 'n'), expected)

    :let l = [ '1', '5', '48', '25', '5', '28', '6']
    :let expected = [ '1', '5', '5', '6', '25', '28', '48']
    let res = lh#list#sort(l, 'N')
    AssertEquals!(res, expected)
    " Assert sorted in place
    AssertIs(l, res)
endfunction

function! s:Test_sort_num_as_str()
    :let l = [ 1, 5, 48, 25, 5, 28, 6]
    :let expected = [ 1, 25, 28, 48, 5, 5, 6]
    :let s = lh#list#sort(l)
    " Comment string(s)
    AssertEquals(s, expected)
endfunction

function! s:Test_sort_str()
    :let l = ['{ *//', '{', 'a', 'b']
    :let expected = ['a', 'b', '{', '{ *//']
    :let s = lh#list#sort(l)
    " Comment string(s)
    AssertEquals(s, expected)
endfunction

function! s:Test_usort()
    :let l = [ 1, 5, 48, 25, 5, 28, 6]
    :let expected = [ 1, 5, 6, 25, 28, 48]
    :let s = lh#list#unique_sort(l, 'n')
    " Comment string(s)
    Assert s == expected
endfunction

function! s:Test_usort2()
    :let l = [ 1, 5, 48, 25, 5, 28, 6]
    :let expected = [ 1, 5, 6, 25, 28, 48]
    :let s = lh#list#unique_sort2(l, 'n')
    " Comment string(s)
    Assert s == expected
endfunction

"------------------------------------------------------------------------
" Searchs {{{2
function! s:TestBinarySearches()
  let v1 = [ -3, -2, -1, -1, 0, 0, 1, 2, 3, 4, 6 ]
  let i = lh#list#lower_bound(v1, 3)
  Assert v1[i] == 3
  let i = lh#list#upper_bound(v1, 3)
  Assert v1[i] == 4
  let r = lh#list#equal_range(v1, 3)
  Assert v1[r[0]:r[1]-1] == [3]

  let i = lh#list#lower_bound(v1, -1)
  Assert v1[i] == -1
  let i = lh#list#upper_bound(v1, -1)
  Assert v1[i] == 0
  let r = lh#list#equal_range(v1, -1)
  Assert v1[r[0]:r[1]-1] == [-1, -1]

  let i = lh#list#lower_bound(v1, 5)
  Assert v1[i] == 6
  let i = lh#list#upper_bound(v1, 5)
  Assert v1[i] == 6
  let r = lh#list#equal_range(v1, 5)
  Assert v1[r[0]:r[1]-1] == []

  Assert len(v1) == lh#list#lower_bound(v1, 10)
  Assert len(v1) == lh#list#upper_bound(v1, 10)
  Assert [len(v1), len(v1)] == lh#list#equal_range(v1, 10)
endfunction

"------------------------------------------------------------------------
" accumulate {{{2

function! s:Test_accumulate_len_strings()
  let strings = [ 'foo', 'bar', 'toto' ]
  let len = eval(lh#list#accumulate(strings, 'strlen', 'join(v:1_,  "+")'))
  Assert len == 3+3+4
endfunction

function! s:Test_accumulate_join()
  let ll = [ 1, 2, 'foo', ['bar'] ]
  let res = lh#list#accumulate(ll, 'string', 'join(v:1_,  " ## ")')
  Assert res == "1 ## 2 ## 'foo' ## ['bar']"
  " This test will fail because it seems :for each loop cannot iterate on
  " heterogeneous containers
endfunction

function! s:DurationToString(duration)
  " AssertEquals (strftime('%H:%M:%S', res), '01:43:11')
  " Cannot be used as it uses localtime() instead of gmtime to stringify the
  " duration
  let s = a:duration % 60
  let m = a:duration / 60
  let h = m / 60
  let m = m % 60
  let res = printf('%02d:%02d:%02d', h, m, s)
  return res
endfunction

function! s:Test_accumulate_multiple()
  " http://vi.stackexchange.com/questions/5038/how-to-replace-a-list-of-numbers-or-times-timestamps-with-their-sum
  let min_sec = [
        \ '3:04', '3:14', '5:38', '4:12', '10:30', '6:29', '6:53', '11:49',
        \ '9:33', '4:17', '7:49', '6:10', '6:04', '6:28', '6:40', '4:21' ]
  let res = eval(lh#list#accumulate(min_sec, ['split(v:1_, ":")', 'v:1_[0]*60 + v:1_[1]'], 'join(v:1_,  "+")'))
  AssertEquals (s:DurationToString(res), '01:43:11')

  let res = lh#list#accumulate2(lh#list#chain_transform(min_sec, ['split(v:1_, ":")', 'v:1_[0]*60 + v:1_[1]']), 0)
  AssertEquals (s:DurationToString(res), '01:43:11')
  " This test will fail because it seems :for each loop cannot iterate on
  " heterogeneous containers
endfunction
"------------------------------------------------------------------------
" Function: s:Test_accu_dicts() {{{3
function! s:Test_accu_dicts() abort
  let l = [ {"k1": 1}, { "k2":2, "k3": 3}, {"k4": 4}]
  let e =  {"k1": 1,  "k2":2, "k3": 3, "k4": 4}

  AssertEquals(e, lh#list#accumulate2(l, {}, 'extend(v:1_, v:2_)'))
endfunction



"------------------------------------------------------------------------
" Copy_if
function! s:Test_copy_if()
    :let l = [ 1, 25, 5, 48, 25, 5, 28, 6]
    :let expected = [ 25, 48, 25, 28, 6]
    :let s = lh#list#copy_if(l, [], "v:1_ > 5")
    " Comment string(s)
    Assert s == expected
endfunction

"------------------------------------------------------------------------
" subset {{{2
function! s:Test_subset()
    :let l = [ 1, 25, 5, 48, 25, 5, 28, 6]
    :let indices = [ 0, 5, 7, 3 ]
    :let expected = [ 1, 5, 6, 48 ]
    :let s = lh#list#subset(l, indices)
    " Comment string(s)
    Assert s == expected
endfunction

"------------------------------------------------------------------------
" intersect {{{2
function! s:Test_intersect()
    :let l1 = [ 1, 25, 7, 48, 26, 5, 28, 6]
    :let l2 = [ 3, 8, 7, 25, 6 ]
    :let expected = [ 25, 7, 6 ]
    :let s = lh#list#intersect(l1, l2)
    " Comment string(s)
    Assert s == expected
endfunction

"------------------------------------------------------------------------
" possible_values {{{2
function! s:Test_possible_values_list()
  let list = [ 'a', 'b', 42, 'a', 15, 'c', 'c', 8]
  AssertEquals(lh#list#possible_values(list), ['a', 'b', 'c', 15, 42, 8])
endfunction

function! s:Test_possible_values_list_list()
  let list =
        \ [ [ 0, 'a', 42, [] ]
        \ , [ 1, 'b', 42, 12 ]
        \ , [ 2, 42, 42 ]
        \ , [ 3, 'a', 42 ]
        \ , [ 4, 15, 42 ]
        \ , [ 5, 'c', 42 ]
        \ , [ 6, 'c', 42 ]
        \ , [ 7, 8, 42 ]
        \ ]
  AssertEquals (lh#list#possible_values(list, 0), range(8))
  AssertEquals (lh#list#possible_values(list, 1), ['a', 'b', 'c', 15, 42, 8])
  " OK, this line is odd, but it works!
  if has("patch-7.4-411")
    " It'll fail with vim 7.3, but I don't care
    AssertEquals (lh#list#possible_values(list, 3), [ 12, [], {}])
  endif
endfunction

function! s:Test_possible_values_list_dict()
  let list =
        \ [ { 'k1': 0, 'k2': 'a'}
        \ , { 'k1': 1, 'k2': 'b'}
        \ , { 'k1': 2, 'k2': 42}
        \ , { 'k1': 3, 'k2': 'a'}
        \ , { 'k1': 4, 'k2': 15}
        \ , { 'k1': 5, 'k2': 'c'}
        \ , { 'k1': 6, 'k2': 'c'}
        \ , { 'k1': 7, 'k2': 8}
        \ ]
  AssertEquals (lh#list#possible_values(list, 'k1'), range(8))
  AssertEquals (lh#list#possible_values(list, 'k2'), ['a', 'b', 'c', 15, 42, 8])
endfunction

function! s:Test_possible_values_list_dict2()
  let list =
        \ [ { 'k1': 0, 'k2': 'a'}
        \ , { 'k1': 1, 'k2': 'b'}
        \ , { 'k1': 2, 'k2': 42}
        \ , 'foobar'
        \ , { 'k1': 4, 'k2': 15}
        \ , { 'k1': 5, 'k2': 'c'}
        \ , { 'k1': 6, 'k2': 'c'}
        \ , { 'k1': 7, 'k2': 8}
        \ ]
  AssertEquals (lh#list#possible_values(list, 'k1'), [0,1,2,4,5,6,7])
  AssertEquals (lh#list#possible_values(list, 'k2'), ['a', 'b', 'c', 15, 42, 8])
endfunction

"------------------------------------------------------------------------
" lh#list#get() {{{2
" Function: s:Test_get_list() {{{3
function! s:Test_get_list() abort
  let list =
        \ [ [ 0, 'a', 42, [] ]
        \ , [ 1, 'b', 42, 12 ]
        \ , [ 2, 42, 42 ]
        \ , [ 3, 'a', 42 ]
        \ , [ 4, 15, 42 ]
        \ , [ 5, 'c', 42 ]
        \ , [ 6, 'c', 42 ]
        \ , [ 7, 8, 42 ]
        \ ]
  AssertEquals (lh#list#get(list, 0), range(8))
  AssertEquals (lh#list#get(list, 1), ['a', 'b', 42, 'a', 15, 'c', 'c', 8])
endfunction

" Function: s:Test_get_dict() {{{3
function! s:Test_get_dict() abort
  let list =
        \ [ { 'k1': 0, 'k2': 'a'}
        \ , { 'k1': 1, 'k2': 'b'}
        \ , { 'k1': 2, 'k2': 42}
        \ , { 'k1': 3, 'k2': 'a'}
        \ , { 'k1': 4, 'k2': 15}
        \ , { 'k1': 5, 'k2': 'c'}
        \ , { 'k1': 6, 'k2': 'c'}
        \ , { 'k1': 7, 'k2': 8}
        \ ]
  AssertEquals (lh#list#get(list, 'k1'), range(8))
  AssertEquals (lh#list#get(list, 'k2'), ['a', 'b', 42, 'a', 15, 'c', 'c', 8])
endfunction

"------------------------------------------------------------------------
" lh#list#map_on() {{{2
" Function: s:Test_map_on_list() {{{3
function! s:Test_map_on_list() abort
  let list =
        \ [ [ 0, 'a', 42, [] ]
        \ , [ 1, 'b', 42, 12 ]
        \ , [ 2, 42, 42 ]
        \ , [ 3, 'a', 42 ]
        \ , [ 4, 15, 42 ]
        \ , [ 5, 'c', 42 ]
        \ , [ 6, 'c', 42 ]
        \ , [ 7, 8, 42 ]
        \ ]
  let l0 = lh#list#map_on(deepcopy(list), 0, 'v:val * 2')
  AssertEquals (lh#list#get(l0, 0), map(range(8), 'v:val * 2'))
  AssertEquals (lh#list#get(l0, 1), ['a', 'b', 42, 'a', 15, 'c', 'c', 8])

  let l1 = lh#list#map_on(deepcopy(list), 1, 'strlen(v:val) . "foo"')
  AssertEquals (lh#list#get(l1, 0), range(8))
  AssertEquals (lh#list#get(l1, 1), ['1foo', '1foo', '2foo', '1foo', '2foo', '1foo', '1foo', '1foo'])
endfunction

" Function: s:Test_map_on_dict() {{{3
function! s:Te0st_map_on_dict() abort
  let list =
        \ [ { 'k1': 0, 'k2': 'a'}
        \ , { 'k1': 1, 'k2': 'b'}
        \ , { 'k1': 2, 'k2': 42}
        \ , { 'k1': 3, 'k2': 'a'}
        \ , { 'k1': 4, 'k2': 15}
        \ , { 'k1': 5, 'k2': 'c'}
        \ , { 'k1': 6, 'k2': 'c'}
        \ , { 'k1': 7, 'k2': 8}
        \ ]
  let l0 = lh#list#map_on(deepcopy(list), 'k1', 'v:val * 2')
  AssertEquals (lh#list#get(l0, 'k1'), map(range(8), 'v:val * 2'))
  AssertEquals (lh#list#get(l0, 'k2'), ['a', 'b', 42, 'a', 15, 'c', 'c', 8])

  let l1 = lh#list#map_on(deepcopy(list), 'k2', 'strlen(v:val) . "foo"')
  AssertEquals (lh#list#get(l1, 'k1'), range(8))
  AssertEquals (lh#list#get(l1, 'k2'), ['1foo', '1foo', '2foo', '1foo', '2foo', '1foo', '1foo', '1foo'])
endfunction

"------------------------------------------------------------------------
" Function: s:Test_flat_extend() {{{3
function! s:Test_flat_extend() abort
  let list = [1,2,3]

  AssertEquals(lh#list#flat_extend(copy(list), 5), [1,2,3,5])
  AssertEquals(lh#list#flat_extend(copy(list), [5,6]), [1,2,3,5,6])
endfunction

"------------------------------------------------------------------------
" Function: s:Test_push_if_new() {{{3
function! s:Test_push_if_new() abort
  let list = [1,2,3]

  AssertEquals(lh#list#push_if_new(copy(list), 5), [1,2,3,5])
  AssertEquals(lh#list#push_if_new(copy(list), 2), [1,2,3])
endfunction

"------------------------------------------------------------------------
" Function: s:Test_dict_add_new() {{{3
function! s:Test_dict_add_new() abort
  let d1 = {'k1': 1, 'k2': 2}

  AssertEquals(lh#dict#add_new(copy(d1), {'k3': 'trois', 'k4': 'quatre'}), {'k1': 1, 'k2': 2, 'k3': 'trois', 'k4': 'quatre'})
  AssertEquals(lh#dict#add_new(copy(d1), {'k3': 'trois', 'k1': 'un'}), {'k1': 1, 'k2': 2, 'k3': 'trois'})
endfunction

"------------------------------------------------------------------------
" Function: s:Test_for_each_call() {{{3
function! s:Test_for_each_call() abort
  let cleanup = lh#on#exit()
        \.restore('g:d')
  silent! unlet g:d
  try
    let l = [1,2,3,4,5]
    let g:d = []
    call lh#list#for_each_call(l, 'add(g:d, v:val)')
    AssertEquals(g:d, l)

    let l = ['a', 'b', 'c', 'd']
    let g:d = []
    call lh#list#for_each_call(l, 'add(g:d, v:val)')
    AssertEquals(g:d, l)
  finally
    call cleanup.finalize()
  endtry
endfunction

"------------------------------------------------------------------------
" Function: s:Test_flatten() {{{3
function! s:Test_flatten() abort
  let l = [ [[[0]]], 1, 2, [3,4], [5, [6]]]

  AssertEquals(lh#list#flatten(l), range(7))
endfunction
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
"
