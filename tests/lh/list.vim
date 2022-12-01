"=============================================================================
" File:		tests/lh/list.vim                                 {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/License.md>
" Version:      4.7.0
" Created:	19th Nov 2008
" Last Update:  01st Dec 2022
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
runtime autoload/lh/dict.vim

" # Tests {{{1
"------------------------------------------------------------------------
" Find_if {{{2
function! s:Test_Find_If_string_predicate()
    :let b = { 'min': 12, 'max': 42 }
    :let l = [ 1, 5, 48, 25, 5, 28, 6]
    :let i = lh#list#Find_if(l, 'v:val>v:1_.min  && v:val<v:1_.max && v:val%v:2_==0', [b, 2] )
    " echo i . '/' . len(l)
    AssertEquals (i ,  5)
    AssertEquals (l[i] ,  28)
    " :echo l[i]
endfunction

function! s:Test_Find_If_functor_predicate()
    :let l = [ 1, 5, 48, 25, 5, 28, 6]
    :let i = lh#list#find_if(l, 'v:1_>12  && v:1_<42 && v:1_%2==0')
    " echo i . '/' . len(l)
    AssertEquals (i ,  5)
    AssertEquals (l[i] ,  28)
    " :echo l[i]
endfunction

function! s:Test_Find_If_fast_functor_predicate()
    :let l = [ 1, 5, 48, 25, 5, 28, 6]
    :let i = lh#list#find_if_fast(l, 'v:val>12  && v:val<42 && v:val%2==0')
    " echo i . '/' . len(l)
    AssertEquals (i ,  5)
    AssertEquals (l[i] ,  28)
    " :echo l[i]
endfunction

function! s:Test_Find_If_param_functor_predicate()
    :let l = [ 1, 5, 48, 25, 5, 28, 6]
    let f = lh#function#bind('v:1_>v:2_  && v:1_<42 && v:1_%2==0', 'v:1_', 12)
    :let i = lh#list#find_if(l, f)
    " echo i . '/' . len(l)
    AssertEquals (i ,  5)
    AssertEquals (l[i] ,  28)
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
" Uniq {{{2
function! s:Test_uniq()
  AssertEquals([], lh#list#uniq([]))
  AssertEquals([1], lh#list#uniq([1]))
  AssertEquals([1,2,3,4,5,8], lh#list#uniq([1,2,3,4,5,8]))
  AssertEquals([1,2,3,4,5,8], lh#list#uniq([1,1,2,3,4,5,8]))
  AssertEquals([1,2,3,4,2,5,8], lh#list#uniq([1,2,2,2,3,4,2,5,8]))
endfunction

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
    AssertEquals (s ,  expected)
endfunction

function! s:Test_usort2()
    :let l = [ 1, 5, 48, 25, 5, 28, 6]
    :let expected = [ 1, 5, 6, 25, 28, 48]
    :let s = lh#list#unique_sort2(l, 'n')
    " Comment string(s)
    AssertEquals (s ,  expected)
endfunction

"------------------------------------------------------------------------
" Searchs {{{2
function! s:TestBinarySearches() " {{{3
  let v1 = [ -3, -2, -1, -1, 0, 0, 1, 2, 3, 4, 6 ]
  let i = lh#list#lower_bound(v1, 3)
  AssertEquals (v1[i] ,  3)
  let i = lh#list#upper_bound(v1, 3)
  AssertEquals (v1[i] ,  4)
  let r = lh#list#equal_range(v1, 3)
  AssertEquals (v1[r[0]:r[1]-1] ,  [3])

  let i = lh#list#lower_bound(v1, -1)
  AssertEquals (v1[i] ,  -1)
  let i = lh#list#upper_bound(v1, -1)
  AssertEquals (v1[i] ,  0)
  let r = lh#list#equal_range(v1, -1)
  AssertEquals (v1[r[0]:r[1]-1] ,  [-1, -1])

  let i = lh#list#lower_bound(v1, 5)
  AssertEquals (v1[i] ,  6)
  let i = lh#list#upper_bound(v1, 5)
  AssertEquals (v1[i] ,  6)
  let r = lh#list#equal_range(v1, 5)
  AssertEquals (v1[r[0]:r[1]-1] ,  [])

  AssertEquals (len(v1) ,  lh#list#lower_bound(v1, 10))
  AssertEquals (len(v1) ,  lh#list#upper_bound(v1, 10))
  AssertEquals ([len(v1), len(v1)] ,  lh#list#equal_range(v1, 10))
endfunction

" Function: s:Test_arg_min_max() {{{3
function! s:Test_arg_min_max() abort
  let v1 = [ -3, -2, -1, -1, 0, 0, 1, 2, 3, 4, 6 ]
  AssertEquals(lh#list#arg_min(v1), 0)
  AssertEquals(lh#list#arg_max(v1), 10)

  let v2 = [ 0, 0, 1, 20000, -200, 3, 4, 6, -20, -1000, -1, 0, 0, 1, 2, 3, 4, 6 ]
  AssertEquals(lh#list#arg_min(v2), 9)
  AssertEquals(lh#list#arg_max(v2), 3)

  AssertEquals(lh#list#arg_min(v2, function('strlen')), 0)
  AssertEquals(lh#list#arg_max(v2, function('strlen')), 3)
endfunction

" Function: s:Test_match() {{{3
function! s:Test_match() abort
  let list = [ 'abc', 'bcd', 'cde' ]
  AssertEquals(match(list, '^bc'), 1)
  AssertEquals(lh#list#match(list, '^bc'), 1)
endfunction

" Function: s:Test_match_re() {{{3
function! s:Test_match_re() abort
  let rx = ['ff', '^bc', 'bc', 'fd']
  AssertEquals(lh#list#match_re(rx, 'abc'), 2)
  AssertEquals(lh#list#match_re(rx, 'bca'), 1)
endfunction

" Function: s:Test_matches() {{{3
function! s:Test_matches() abort
  let list = [ 'abc', 'bcd', 'cde' ]
  AssertEquals(lh#list#matches(list, '^bc'), [1])
  AssertEquals(lh#list#matches(list, 'bc'), [0, 1])
endfunction

"------------------------------------------------------------------------
" accumulate {{{2

function! s:Test_accumulate_len_strings()
  let strings = [ 'foo', 'bar', 'toto' ]
  let len = eval(lh#list#accumulate(strings, 'strlen', 'join(v:1_,  "+")'))
  AssertEquals (len ,  3+3+4)
endfunction

function! s:Test_accumulate_join()
  let ll = [ 1, 2, 'foo', ['bar'] ]
  let res = lh#list#accumulate(ll, 'string', 'join(v:1_,  " ## ")')
  AssertEquals (res ,  "1 ## 2 ## 'foo' ## ['bar']")
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
    AssertEquals (s ,  expected)
endfunction

"------------------------------------------------------------------------
" masks {{{2
" " Function: s:Test_masks() {{{3
function! s:Test_masks() abort
    let l = [ 1, 25, 5, 48, 25, 5, 28, 6]
    let masks = [ 1, 0, 0, 1, 0, 1, 0, 1]
    AssertEquals(lh#list#mask(l, masks), [1, 48, 5, 6])
endfunction

" subset & remove {{{2
function! s:Test_subset_list()
    :let l = [ 1, 25, 5, 48, 25, 5, 28, 6]
    :let indices = [ 0, 5, 7, 3 ]
    :let expected = [ 1, 5, 6, 48 ]
    :let s = lh#list#subset(l, indices)
    " Comment string(s)
    AssertEquals (s ,  expected)
endfunction

function! s:Test_subset_dict()
    :let d = {'a':1, 'b':2, 'c':3, 'd':4, 'e':5}
    :let keys = [ 'a', 'c', 'd']
    :let expected = {'a':1, 'c':3, 'd':4}
    :let s = lh#dict#subset(d, keys)
    " Comment string(s)
    AssertEquals (s ,  expected)
endfunction

" Function: s:Test_remove() {{{3
function! s:Test_remove() abort
  let l = [ 0, 25, 5, 48, 25, 5, 28, 6]
  let indices = [ 0, 3, 5, 7 ]
  AssertEquals (lh#list#remove(l, indices), [ 25, 5, 25, 28 ])
endfunction

"------------------------------------------------------------------------
" intersect {{{2
function! s:Test_intersect()
    :let l1 = [ 1, 25, 7, 48, 26, 5, 28, 6]
    :let l2 = [ 3, 8, 7, 25, 6 ]
    :let expected = [ 25, 7, 6 ]
    :let s = lh#list#intersect(l1, l2)
    " Comment string(s)
    AssertEquals (s ,  expected)
endfunction

" linear intersect {{{2
" numbers {{{3
function! s:Test_linear_intersect_numbers()
    :let l1 = [ 1, 25, 7, 48, 26, 5, 28, 6]
    :let l2 = [ 3, 8, 7, 25, 6 ]
    :let expected = [ 25, 7, 6 ]
    :call lh#list#sort(l1, 'n')
    :call lh#list#sort(l2, 'n')
    :call lh#list#sort(expected, 'n')
    :let o1 = []
    :let o2 = []
    :let s = []
    :call lh#list#concurrent_for(l1, l2, o1, o2, s, 'n')
    " Comment string(s)
    AssertEquals (s ,  expected)
    AssertEquals (o1 , [1, 5, 26, 28, 48])
    AssertEquals (o2 , [3, 8])
endfunction

" string as numbers {{{3
function! s:Test_linear_intersect_numbers_as_strings()
    :let l1 = [ '1', '25', '7', '48', '26', '5', '28', '6']
    :let l2 = [ '3', '8', '7', '25', '6' ]
    :let expected = [ '25', '7', '6' ]
    :call lh#list#sort(l1, 'N')
    :call lh#list#sort(l2, 'N')
    :call lh#list#sort(expected, 'N')
    :let o1 = []
    :let o2 = []
    :let s = []
    :call lh#list#concurrent_for(l1, l2, o1, o2, s, 'N')
    " Comment string(s)
    AssertEquals (s ,  expected)
    AssertEquals (o1 , ['1', '5', '26', '28', '48'])
    AssertEquals (o2 , ['3', '8'])
endfunction

" strings {{{3
function! s:Test_linear_intersect_strings()
    :let l1 = [ '1', '25', '7', '48', '26', '5', '28', '6']
    :let l2 = [ '3', '8', '7', '25', '6' ]
    :let expected = [ '25', '7', '6' ]
    :call lh#list#sort(l1)
    :call lh#list#sort(l2)
    :call lh#list#sort(expected)
    :let o1 = []
    :let o2 = []
    :let s = []
    :call lh#list#concurrent_for(l1, l2, o1, o2, s)
    " Comment string(s)
    AssertEquals (s ,  expected)
    AssertEquals (o1 , ['1', '26', '28', '48', '5'])
    AssertEquals (o2 , ['3', '8'])
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
  if has("patch-7.4.411")
    " It'll fail with vim 7.3, but I don't care
    AssertEquals (lh#list#possible_values(list, 3), [ 12, [], lh#option#unset()])
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

" Function: s:Test_push_if_new_entity() {{{3
function! s:Test_push_if_new_entity() abort
  let e = [1,2,3]
  let list = [ [1,2,3], [4,5], [7,8] ]

  Assert ! lh#list#contain_entity(list, e)
  Assert lh#list#not_contain_entity(list, e)
  AssertEquals(lh#list#find_entity(list, e), -1)

  AssertEquals(lh#list#push_if_new_entity(list, e), [ [1,2,3], [4,5], [7,8], [1,2,3] ])

  Assert lh#list#contain_entity(list, e)
  Assert ! lh#list#not_contain_entity(list, e)
  AssertEquals(lh#list#find_entity(list, e), 3)

  AssertEquals(lh#list#push_if_new_entity(list, e), [ [1,2,3], [4,5], [7,8], [1,2,3] ])
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

" lh#list#rotate {{{2
function! s:Test_rotate()
    :let l0 = [1, 25, 7, 48, 26, 5]
    AssertEquals (l0,  lh#list#rotate(l0, 0))
    AssertEquals ([25, 7, 48, 26, 5, 1],  lh#list#rotate(l0, 1))
    AssertEquals ([7, 48, 26, 5, 1, 25],  lh#list#rotate(l0, 2))
    AssertEquals ([48, 26, 5, 1, 25, 7],  lh#list#rotate(l0, 3))
    AssertEquals ([26, 5, 1, 25, 7, 48],  lh#list#rotate(l0, 4))
    AssertEquals ([5, 1, 25, 7, 48, 26],  lh#list#rotate(l0, 5))
    AssertEquals ([1, 25, 7, 48, 26, 5],  lh#list#rotate(l0, 6))

    AssertEquals ([25, 7, 48, 26, 5, 1],  lh#list#rotate(l0, -5))
    AssertEquals ([7, 48, 26, 5, 1, 25],  lh#list#rotate(l0, -4))
    AssertEquals ([48, 26, 5, 1, 25, 7],  lh#list#rotate(l0, -3))
    AssertEquals ([26, 5, 1, 25, 7, 48],  lh#list#rotate(l0, -2))
    AssertEquals ([5, 1, 25, 7, 48, 26],  lh#list#rotate(l0, -1))
    AssertEquals ([1, 25, 7, 48, 26, 5],  lh#list#rotate(l0, -6))
endfunction

" Zip {{{2
" Function: s:Test_zip_lists() {{{3
function! s:Test_zip_lists() abort
  let l1 = ['a', 'b', 'c']
  let l2 = [1, 2, 3]
  AssertEquals(lh#list#zip(l1, l2), [['a', 1], ['b', 2], ['c', 3]])
  AssertThrows(lh#list#zip([1], [1,2]))
endfunction

" Function: s:Test_zip_dict() {{{3
function! s:Test_zip_dict() abort
  let l1 = ['a', 'b', 'c']
  let l2 = [1, 2, 3]
  AssertEquals(lh#list#zip_as_dict(l1, l2), {'a': 1, 'b': 2, 'c': 3})
  AssertThrows(lh#list#zip_as_dict([1], [1,2]))
endfunction

" Separate {{{2
" Function: s:Test_separate() {{{3
function! s:Test_separate() abort
  let l = [ 1, 5, 48, 25, 5, 28, 6]

  let [min, max] = lh#list#separate(l, 'v:val < 10')
  AssertEquals(min, [1, 5, 5, 6])
  AssertEquals(max, [48, 25, 28])

  let [min, max] = lh#list#separate(l, 'v:key % 2')
  AssertEquals(min, [5, 25, 28])
  AssertEquals(max, [1, 48, 5, 6])

  if has('lambda')
    let [min, max] = lh#list#separate(l, {idx, val -> val <10})
    AssertEquals(min, [1, 5, 5, 6])
    AssertEquals(max, [48, 25, 28])
  endif
endfunction

" lh#dict#let() {{{2
" Function: s:Test_dict_let() {{{3
function! s:Test_dict_let() abort
  let d = { 'a': { 'b': 1}, 'c': 2}
  AssertEquals(d.a.b, 1)
  AssertEquals(d.c, 2)

  call lh#dict#let(d, 'd', 42)
  AssertEquals(d.d, 42)
  call lh#dict#let(d, 'd.d', 42)
  AssertEquals(d.d, {'d': 42})

  call lh#dict#let(d, 'a.b.z', 42)
  AssertEquals(d.a.b.z, 42)
  call lh#dict#let(d, 'a.z1.z2.z3', 42)
  AssertEquals(d.a.z1.z2.z3, 42)
endfunction

" lh#dict#get_composed() {{{2
" Function: s:Test_dict_get_composed() {{{3
function! s:Test_dict_get_composed() abort
  let D  = { 'a': { 'b': 1, '5.1' : {'z': 0}}, 'c': 2, '8.2': {'9.3' : 42}}
  AssertEquals(D.a.b, 1)
  AssertEquals(D.c, 2)

  " --- Access something already there, 1 level deep
  let a = lh#dict#get_composed(D, 'a')
  AssertIs(a, D.a)

  " --- Access something already there, n level deep
  AssertThrows(lh#dict#get_composed(D, 'a.b.c.d.e', 42))
  call lh#dict#let(D, 'a.b.c.d.e', 42)
  let d = lh#dict#get_composed(D, 'a.b.c.d')
  AssertIs(a, D.a)
  AssertIs(d, D.a.b.c.d)

  " --- Access something with subscript syntax, 1 level deep
  let _82 = lh#dict#get_composed(D, '[8.2]')
  AssertEquals(_82, D['8.2'])
  let _93 = lh#dict#get_composed(D, '[8.2][9.3]')
  AssertEquals(_93, D['8.2']['9.3'])

  let _51 = lh#dict#get_composed(D, 'a[5.1]')
  AssertEquals(_51, D.a['5.1'])

  let z   = lh#dict#get_composed(D, 'a[5.1].z')
  AssertEquals(z, D.a['5.1'].z)
endfunction

" lh#dict#need_ref_on() {{{2
" Function: s:Test_dict_need_ref_on() {{{3
function! s:Test_dict_need_ref_on() abort
  try
    let D  = { 'a': { 'b': 1}, 'c': 2}
    let g:D = D
    AssertEquals(D.a.b, 1)
    AssertEquals(D.c, 2)

    " --- Access something already there, 1 level deep
    let a = lh#dict#need_ref_on(D, 'a')
    AssertIs(a, D.a)

    let a = lh#dict#need_ref_on(D, ['a']) " other syntax
    AssertIs(a, D.a)

    " --- Access something already there, n level deep
    AssertThrows(lh#dict#need_ref_on(g:D, 'a.b.c.d.e', 42))
    call lh#dict#let(D, 'a.b.c.d.e', 42)
    let d = lh#dict#need_ref_on(D, 'a.b.c.d')
    AssertIs(a, D.a)
    AssertIs(d, D.a.b.c.d)

    let c = lh#dict#need_ref_on(D, ['a', 'b', 'c']) " other syntax
    AssertIs(a, D.a)
    AssertIs(c, D.a.b.c)
    AssertIs(d, D.a.b.c.d)

    " --- Add something new, 1 lcl deep
    let ee = lh#dict#need_ref_on(D, 'a.ee')
    AssertIs(a, D.a)
    AssertIs(c, D.a.b.c)
    AssertIs(d, D.a.b.c.d)
    Assert! has_key(D.a, 'ee')
    AssertIs(D.a.ee, ee)
    AssertEquals!(type(ee), type({}))
    AssertEquals(ee, {})

    " --- Add something new, n lcl deep, other syntax
    let ff = lh#dict#need_ref_on(D, 'a.b.c.d.1.2.3.ff', [1, 2])
    AssertIs(a, D.a)
    AssertIs(c, D.a.b.c)
    AssertIs(d, D.a.b.c.d)
    Assert! has_key(D.a, 'ee')
    AssertIs(D.a.ee, ee)
    AssertEquals!(type(ee), type({}))
    AssertEquals(ee, {})
    Assert! has_key(D.a.b.c.d, '1')
    Assert! has_key(D.a.b.c.d.1, '2')
    Assert! has_key(D.a.b.c.d.1.2, '3')
    Assert! has_key(D.a.b.c.d.1.2.3, 'ff')
    AssertIs(D.a.b.c.d.1.2.3.ff, ff)
    AssertEquals!(type(ff), type([]))
    AssertEquals(ff, [1, 2])

    " --- Try to add something that requires a type modification of a
    "  subdict
    let g:D = D
    AssertThrows(lh#dict#need_ref_on(g:D, 'a.b.c.d.e.1.2.3.ff', [1, 2]))
  finally
    call lh#let#unlet('g:D')
  endtry
endfunction

" lh#list#cross() {{{2
" Function: s:Test_cross() {{{3
function! s:Test_cross() abort
  let rng1 = [ 'a', 'b', 'c']
  let rng2 = [ 0, 1, 2]

  if lh#has#lambda()
    AssertEquals(lh#list#cross(rng1, rng2, {a, b -> a.b}),
          \ ['a0', 'b0', 'c0', 'a1', 'b1', 'c1', 'a2', 'b2', 'c2'])

    AssertEquals(lh#list#cross(rng2, rng2, {a, b -> a+b}),
          \ [ 0, 1, 2, 1, 2, 3, 2, 3, 4])
  endif
  " Without lambda
  AssertEquals(lh#list#cross(rng1, rng2, 'v:val.l:val2'),
        \ ['a0', 'b0', 'c0', 'a1', 'b1', 'c1', 'a2', 'b2', 'c2'])

  AssertEquals(lh#list#cross(rng2, rng2, 'v:val + l:val2'),
        \ [ 0, 1, 2, 1, 2, 3, 2, 3, 4])
endfunction
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
