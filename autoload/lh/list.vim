"=============================================================================
" File:         autoload/lh/list.vim                                      {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      4.0.0
let s:k_version = 40000
" Created:      17th Apr 2007
" Last Update:  02nd Nov 2016
"------------------------------------------------------------------------
" Description:
"       Defines functions related to |Lists|
"
"------------------------------------------------------------------------
" History: {{{2
"       v4.0.0.0
"       (*) ENH: Add lh#list#push_if_new_entity()
"       (*) ENH: Add lh#list#contain_entity()
"       (*) ENH: Add lh#list#arg_min() & max()
"       (*) BUG: Add support for empty lists in `lh#list#find_if`
"       (*) PERF: Simplify lh#list#uniq()
"       (*) ENH: Add lh#list#push_if_new_elements()
"       v3.13.2
"       (*) PERF: Optimize `lh#list#push_if_new`
"       v3.10.3
"       (*) ENH: Add lh#list#zip(), lh#list#zip_as_dict()
"       v3.10.0
"       (*) ENH: Add lh#list#concurrent_for()
"       v3.6.1
"       (*) ENH: Use new logging framework
"       v3.4.0
"       (*) BUG: in lh#list#find_if when predicate is not a string
"       v3.3.20
"       (*) ENH: lh#list#sort(['1', ...], 'N') to sort list of strings encoding
"           numbers.
"       v3.3.17
"       (*) ENH: lh#list#possible_values() will accept things like
"           [1, 'toto', function('has'), {'join': 5}, {'join': 42}]
"       v3.3.16
"       (*) New functions
"           - lh#list#for_each_call()
"           - lh#list#flat_extend()
"       (*) lh#list#possible_values() supports mixed types
"       v3.3.15
"       (*) New functions
"           - lh#list#get() -> map get list
"           - lh#list#map_on() -> map map list
"       v3.3.7
"       (*) lh#list#sort() emulates the correct behaviour of sort(), regarding
"           patches 7.4-341 and 7.4-411
"       v3.3.6
"       (*) New function lh#list#chain_transform(), and new "overload" for
"           lh#list#accumulate()
"       v3.3.5
"       (*) New function lh#list#rotate()
"       v3.3.4
"       (*) New function lh#list#accumulate2()
"       v3.3.1
"       (*) Enhance lh#list#find_if() to support "v:val" as well.
"       v3.2.14:
"       (*) new function lh#list#mask()
"       v3.2.13:
"       (*) new function lh#list#possible_values()
"       v3.2.8:
"       (*) lh#list#sort() wraps sort() to work around error fixed in vim
"           version 7.4.411
"       v3.2.4:
"       (*) new function lh#list#match_re()
"       v3.2.4:
"       (*) new function lh#list#push_if_new()
"       v3.0.0:
"       (*) GPLv3
"       v2.2.2:
"       (*) new functions: lh#list#remove(), lh#list#matches(),
"           lh#list#not_found().
"       v2.2.1:
"       (*) use :unlet in :for loop to support heterogeneous lists
"       (*) binary search algorithms (upper_bound, lower_bound, equal_range)
"       v2.2.0:
"       (*) new functions: lh#list#accumulate, lh#list#transform,
"           lh#list#transform_if, lh#list#find_if, lh#list#copy_if,
"           lh#list#subset, lh#list#intersect
"       (*) the functions are compatible with lh#function functors
"       v2.1.1:
"       (*) unique_sort
"       v2.0.7:
"       (*) Bug fix: lh#list#Match()
"       v2.0.6:
"       (*) lh#list#Find_if() supports search predicate, and start index
"       (*) lh#list#Match() supports start index
"       v2.0.0:
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#list#version()
  return s:k_version
endfunction

" # Debug {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#list#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Log(...)
  call call('lh#log#this', a:000)
endfunction

function! s:Verbose(...)
  if s:verbose
    call call('s:Log', a:000)
  endif
endfunction

function! lh#list#debug(expr) abort
  return eval(a:expr)
endfunction

"=============================================================================
" ## Functions {{{1
"------------------------------------------------------------------------
" # Public {{{2
" Function: lh#list#Transform(input, output, action) {{{3
" deprecated version
function! lh#list#Transform(input, output, action) abort
  let new = map(copy(a:input), a:action)
  let res = extend(a:output,new)
  return res

  for element in a:input
    let action = substitute(a:action, 'v:val','element', 'g')
    let res = eval(action)
    call add(a:output, res)
    unlet element " for heterogeneous lists
  endfor
  return a:output
endfunction

" Function: lh#list#transform(input, output, action) {{{3
function! lh#list#transform(input, output, action) abort
  for element in a:input
    let res = lh#function#execute(a:action, element)
    call add(a:output, res)
    unlet element " for heterogeneous lists
  endfor
  return a:output
endfunction

" Function: lh#list#chain_transform(input, actions) {{{3
function! lh#list#chain_transform(input, actions) abort
  let input = a:input
  for transformation in a:actions
    let input = lh#list#transform(input, [], transformation)
  endfor
  return input
endfunction

" Function: lh#list#transform_if(input, output, action, predicate) {{{3
function! lh#list#transform_if(input, output, action, predicate) abort
  for element in a:input
    if lh#function#execute(a:predicate, element)
      let res = lh#function#execute(a:action, element)
      call add(a:output, res)
    endif
    unlet element " for heterogeneous lists
  endfor
  return a:output
endfunction

" Function: lh#list#copy_if(input, output, predicate) {{{3
function! lh#list#copy_if(input, output, predicate) abort
  for element in a:input
    if lh#function#execute(a:predicate, element)
      call add(a:output, element)
    endif
    unlet element " for heterogeneous lists
  endfor
  return a:output
endfunction

" Function: lh#list#accumulate(input, transformation, accumulator) {{{3
function! lh#list#accumulate(input, transformations, accumulator) abort
  if type(a:transformations) == type('')
    let transformed = lh#list#transform(a:input, [], a:transformations)
  else
    let transformed = lh#list#chain_transform(a:input, a:transformations)
  endif
  let res = lh#function#execute(a:accumulator, transformed)
  return res
endfunction

" Function: lh#list#accumulate2(input, init, [accumulator = a+b]) {{{3
function! lh#list#accumulate2(input, init, ...) abort
  let accumulator = a:0 == 0 ? 'v:1_ + v:2_' : a:1
  let res = a:init
  for e in a:input
    let res = lh#function#execute(accumulator, res, e)
  endfor
  return res
endfunction

" Function: lh#list#flatten(list) {{{3
function! lh#list#flatten(list) abort
  let res = []
  for e in a:list
    if type(e) == type([])
      let res += lh#list#flatten(e)
    else
      let res += [e]
    endif
    unlet e
  endfor
  return res
endfunction

" Function: lh#list#match_re(list, to_be_matched [, idx]) {{{3
" Search first regex that match the parameter
function! lh#list#match_re(list, to_be_matched, ...) abort
  let idx = (a:0>0) ? a:1 : 0
  while idx < len(a:list)
    if match(a:to_be_matched, a:list[idx]) != -1
      return idx
    endif
    let idx += 1
  endwhile
  return -1
endfunction

" Function: lh#list#match(list, to_be_matched [, idx]) {{{3
function! lh#list#match(list, to_be_matched, ...) abort
  let idx = (a:0>0) ? a:1 : 0
  while idx < len(a:list)
    if match(a:list[idx], a:to_be_matched) != -1
      return idx
    endif
    let idx += 1
  endwhile
  return -1
endfunction
function! lh#list#Match(list, to_be_matched, ...) abort
  let idx = (a:0>0) ? a:1 : 0
  return lh#list#match(a:list, a:to_be_matched, idx)
endfunction

" Function: lh#list#matches(list, to_be_matched [,idx]) {{{3
" Return the list of indices that match {to_be_matched}
function! lh#list#matches(list, to_be_matched, ...) abort
  let res = []
  let idx = (a:0>0) ? a:1 : 0
  while idx < len(a:list)
    if match(a:list[idx], a:to_be_matched) != -1
      let res += [idx]
    endif
    let idx += 1
  endwhile
  return res
endfunction

" Function: lh#list#Find_if(list, predicate [, predicate-arguments] [, start-pos]) {{{3
function! lh#list#Find_if(list, predicate, ...) abort
  " Parameters
  let idx = 0
  let args = []
  if a:0 == 2
    let idx = a:2
    let args = a:1
  elseif a:0 == 1
    if type(a:1) == type([])
      let args = a:1
    elseif type(a:1) == type(42)
      let idx = a:1
    else
      throw "lh#list#Find_if: unexpected argument type"
    endif
  elseif a:0 != 0
      throw "lh#list#Find_if: unexpected number of arguments: lh#list#Find_if(list, predicate [, predicate-arguments] [, start-pos])"
  endif

  " The search loop
  while idx != len(a:list)
    let predicate = substitute(a:predicate, 'v:val', 'a:list['.idx.']', 'g')
    let predicate = substitute(predicate, 'v:\(\d\+\)_', 'args[\1-1]', 'g')
    let res = eval(predicate)
    " echomsg string(predicate) . " --> " . res
    if res | return idx | endif
    let idx += 1
  endwhile
  return -1
endfunction

" Function: lh#list#find_if(list, predicate [, predicate-arguments] [, start-pos]) {{{3
function! lh#list#find_if(list, predicate, ...) abort
  " Parameters
  let idx = 0
  let args = []
  if a:0 == 1
    let idx = a:1
  elseif a:0 != 0
      throw "lh#list#find_if: unexpected number of arguments: lh#list#find_if(list, predicate [, start-pos])"
  endif

  " The search loop
  if type(a:predicate) == type('string')
    let predicate = substitute(a:predicate, 'v:val', 'v:1_', 'g')
  else
    let predicate = a:predicate
  endif
  while idx < len(a:list)
    let res = lh#function#execute(predicate, a:list[idx])
    if res | return idx | endif
    let idx += 1
  endwhile
  return -1
endfunction

" Function: lh#list#lower_bound(sorted_list, value  [, first[, last]]) {{{3
function! lh#list#lower_bound(list, val, ...) abort
  let first = 0
  let last = len(a:list)
  if a:0 >= 1     | let first = a:1
  elseif a:0 >= 2 | let last = a:2
  elseif a:0 > 2
      throw "lh#list#lower_bound: unexpected number of arguments: lh#list#lower_bound(sorted_list, value  [, first[, last]])"
  endif

  let len = last - first

  while len > 0
    let half = len / 2
    let middle = first + half
    if a:list[middle] < a:val
      let first = middle + 1
      let len -= half + 1
    else
      let len = half
    endif
  endwhile
  return first
endfunction

" Function: lh#list#upper_bound(sorted_list, value  [, first[, last]]) {{{3
function! lh#list#upper_bound(list, val, ...) abort
  let first = 0
  let last = len(a:list)
  if a:0 >= 1     | let first = a:1
  elseif a:0 >= 2 | let last = a:2
  elseif a:0 > 2
      throw "lh#list#upper_bound: unexpected number of arguments: lh#list#upper_bound(sorted_list, value  [, first[, last]])"
  endif

  let len = last - first

  while len > 0
    let half = len / 2
    let middle = first + half
    if a:val < a:list[middle]
      let len = half
    else
      let first = middle + 1
      let len -= half + 1
    endif
  endwhile
  return first
endfunction

" Function: lh#list#equal_range(sorted_list, value  [, first[, last]]) {{{3
" @return [f, l], where
"   f : First position where {value} could be inserted
"   l : Last position where {value} could be inserted
function! lh#list#equal_range(list, val, ...) abort
  let first = 0
  let last = len(a:list)

  " Parameters
  if a:0 >= 1     | let first = a:1
  elseif a:0 >= 2 | let last  = a:2
  elseif a:0 > 2
      throw "lh#list#equal_range: unexpected number of arguments: lh#list#equal_range(sorted_list, value  [, first[, last]])"
  endif

  " The search loop ( == STLPort's equal_range)

  let len = last - first
  while len > 0
    let half = len /  2
    let middle = first + half
    if a:list[middle] < a:val
      let first = middle + 1
      let len -= half + 1
    elseif a:val < a:list[middle]
      let len = half
    else
      let left = lh#list#lower_bound(a:list, a:val, first, middle)
      let right = lh#list#upper_bound(a:list, a:val, middle+1, first+len)
      return [left, right]
    endif

    " let predicate = substitute(a:predicate, 'v:val', 'a:list['.idx.']', 'g')
    " let res = lh#function#execute(a:predicate, a:list[idx])
  endwhile
  return [first, first]
endfunction

" Function: lh#list#arg_max(list [, transfo]) {{{3
function! lh#list#arg_max(list, ...) abort
  if empty(a:list) | return -1 | endif
  let Transfo = a:0 > 0 ? a:1 : function(s:getSNR(id))
  let m = Transfo(a:list[0])
  let p = 0
  let i = 1
  while i != len(a:list)
    let e = a:list[i]
    let v = Transfo(e)
    if v > m
      let m = v
      let p = i
    endif
    let i += 1
  endwhile
  return p
endfunction

" Function: lh#list#arg_min(list [, transfo]) {{{3
function! lh#list#arg_min(list, ...) abort
  if empty(a:list) | return -1 | endif
  let Transfo = a:0 > 0 ? a:1 : function(s:getSNR(id))
  let m = Transfo(a:list[0])
  let p = 0
  let i = 1
  while i != len(a:list)
    let e = a:list[i]
    let v = Transfo(e)
    if v < m
      let m = v
      let p = i
    endif
    let i += 1
  endwhile
  return p
endfunction

" Function: lh#list#not_found(range) {{{3
" @return whether the range returned from equal_range is empty (i.e. element not found)
function! lh#list#not_found(range) abort
  return a:range[0] == a:range[1]
endfunction

" Function: lh#list#sort(list) {{{3
" Up to vim version 7.4.411
"    echo sort(['{ *//', '{', 'a', 'b'])
" gives: ['a', 'b', '{ *//', '{']
" While
"    sort(['{ *//', '{', 'a', 'b'], function('lh#list#_regular_cmp'))
" gives the correct: ['a', 'b', '{', '{ *//']
"
" Also Vim 7.4-341 fixes number comparison
"
" Behaviours
" - default: string cmp
" - 'n' -> number comp
" - 'N' -> number comp, but on strings
let s:k_has_num_cmp = has("patch-7.4-341")
let s:k_has_fixed_str_cmp = has("patch-7.4-411")
" For testing purposes...
" let s:k_has_num_cmp = 0
" let s:k_has_fixed_str_cmp = 0
function! lh#list#sort(list,...) abort
  let args = [a:list] + a:000
  if len(args) > 1
    if args[1] == 'N'
      let args[0] = map(a:list, 'eval(v:val)')
      let args[1] = 'n'
      let was_sorting_numbers_as_strings = 1
    endif
    if !s:k_has_num_cmp && args[1]=='n'
      let args[1] = 'lh#list#_regular_cmp'
    elseif !s:k_has_fixed_str_cmp && args[1]==''
      let args[1] = 'lh#list#_str_cmp'
    endif
  else
    if !s:k_has_fixed_str_cmp
      let args += ['lh#list#_str_cmp']
    endif
  endif
  let res = call('sort', args)
  if exists('was_sorting_numbers_as_strings')
    call map(res, 'string(v:val)')
  endif
  return res
endfunction

" Function: lh#list#unique_sort(list [, func]) {{{3
" See also http://vim.wikia.com/wiki/Unique_sorting
"
" Works like sort(), optionally taking in a comparator (just like the
" original), except that duplicate entries will be removed.
" todo: support another argument that act as an equality predicate
if exists('*uniq')
  function! lh#list#unique_sort(list, ...) abort
    call call('lh#list#sort', [a:list] + a:000)
    call uniq(a:list)
    return a:list
  endfunction
else
  function! lh#list#unique_sort(list, ...) abort
    let dictionary = {}
    for i in a:list
      let dictionary[string(i)] = i
    endfor
    let result = []
    " echo join(values(dictionary),"\n")
    return call('lh#list#sort', [values(dictionary)] + a:000)
  endfunction
endif

function! lh#list#unique_sort2(list, ...) abort
  let list = copy(a:list)
  call call('lh#list#sort', [list] + a:000)
  return lh#list#uniq(list)
endfunction

" Function: lh#list#uniq(list) {{{3
if exists('*uniq')
  function! lh#list#uniq(...) abort
    return call('uniq', a:000)
  endfunction
else
  function! lh#list#uniq(list) abort
    if len(a:list) <= 1 | return a:list | endif
    let result = [ a:list[0] ]
    for e in a:list[1:]
      if e != result[-1]
        call add(result, e)
      endif
    endfor
    return result

    let last = a:list[0]
    let i = 1
    let ll = len(a:list)
    while i < ll
      if last != a:list[i]
        let last = a:list[i]
        call add(result, last)
      endif
      let i += 1
    endwhile
    return result
  endfunction
endif
" Function: lh#list#subset(list, indices) {{{3
function! lh#list#subset(list, indices) abort
  let result=[]
  for e in a:indices
    " call add(result, a:list[e])
    call add(result, get(a:list, e))
  endfor
  return result
endfunction

" Function: lh#list#mask(list, masks) {{{3
function! lh#list#mask(list, masks) abort
  let len = len(a:list)
  if len != len(a:masks)
    throw "lh#list#mask() needs as many masks as elements in the list"
  endif
  let res = []
  for i in range(len)
    if a:masks[i]
      let res += [a:list[i]]
    endif
  endfor
  return res
endfunction

" Function: lh#list#remove(list, indices) {{{3
function! lh#list#remove(list, indices) abort
  " assert(is_sorted(indices))
  let idx = reverse(copy(a:indices))
  for i in idx
    call remove(a:list, i)
  endfor
  return a:list
endfunction

" Function: lh#list#intersect(list1, list2) {{{3
function! lh#list#intersect(list1, list2) abort
  let result = copy(a:list1)
  call filter(result, 'index(a:list2, v:val) >= 0')
  return result

  for e in a:list1
    if index(a:list2, e) > 0
      call result(result, e)
    endif
  endfor
endfunction

" Function: lh#list#flat_extend(list, rhs) {{{3
" @since v3.14.1
function! lh#list#flat_extend(list, rhs) abort
  if type(a:rhs) == type([])
    return extend(a:list, a:rhs)
  else
    return add(a:list, a:rhs)
  endif
endfunction

" Function: lh#list#separate(list, Cond) {{{3
function! lh#list#separate(list, Cond) abort
  if 1 " seems a little bit faster
    let yes = []
    let no = []
    let idx = 0
    for e in a:list
      if a:Cond(idx, e)
        let yes += [e]
      else
        let no += [e]
      endif
      let idx += 1
    endfor
  else
    let yes = filter(copy(a:list), a:Cond)
    let no = filter(a:list, {idx, val -> !a:Cond(idx, val)})
  endif
  return [yes, no]
endfunction
" Function: lh#list#push_if_new(list, value) {{{3
function! lh#list#push_if_new(list, value) abort
  if index(a:list, a:value) < 0
    call add (a:list, a:value)
  endif
  return a:list
endfunction

" Function: lh#list#push_if_new_elements(list, values) {{{3
function! lh#list#push_if_new_elements(list, values) abort
  let new = filter(copy(a:values), 'index(a:list, v:val) < 0')
  call extend(a:list, new)
  return a:list
endfunction

" Function: lh#list#find_entity(list, value) {{{3
" @since 4.0.0
function! lh#list#contain_entity(list, value) abort
  for e in a:list
    if e is a:value
      return 1
    endif
    unlet e
  endfor
  return 0
endfunction

" Function: lh#list#push_if_new_entity(list, value) {{{3
" @version 4.0.0
function! lh#list#push_if_new_entity(list, value) abort
  if !lh#list#contain_entity(a:list, a:value)
    call add(a:list, a:value)
  endif
  return a:list
endfunction

" Function: lh#list#possible_values(list [, key|index [, default_when_absent]) {{{3
function! lh#list#possible_values(list, ...) abort
  if a:0 == 0
    return lh#list#unique_sort(a:list)
  elseif a:0 == 1
    let default = a:0 == 2 ? a:2 : lh#option#unset()
    let dRes = {}
    for E in a:list
      if type(E) == type({}) || type(E) == type([])
        let v = get(E, a:1, default)
        let dRes[string(v)] = v
        unlet v
      endif
      unlet E
    endfor
    " this hack regarding using values and not keys permits to not alter the
    " type of the elements
    let res = lh#list#sort(values(dRes))
    return res
  endif
endfunction

" Function: lh#list#get(list, index|key [, default]) {{{3
" Extract the i-th element in list of lists, or the element named {index} in a
" list of dictionaries
function! lh#list#get(list, index, ...) abort
  let res = map(copy(a:list), 'call ("get", [v:val, a:index]+a:000)')
  return res
endfunction

" Function: lh#list#rotate(list, rot) {{{3
" {rot} must belong to [-len(list)n +len(list)]
function! lh#list#rotate(list, rot) abort
  let res = a:list[a:rot :] + a:list[: (a:rot-1)]
  return res
endfunction

" Function: lh#list#map_on(list, index|key, action) {{{3
function! lh#list#map_on(list, index, action) abort
  return map(a:list, 'lh#list#_apply_on(v:val, a:index, a:action)')
endfunction

" Function: lh#list#for_each_call(list, action) {{{3
function! lh#list#for_each_call(list, action) abort
  try
    for e in a:list
      let action = substitute(a:action, '\v<v:val>', '\=string(e)', 'g')
      exe 'call '.action
      unlet e
    endfor
  catch /.*/
    throw "lh#list#for_each_call: ".v:exception." in ``".action."''"
  endtry
endfunction

" Function: lh#list#concurrent_for(in1, in2, out1, out2, out_com, [Cmp]) {{{3
" @since Version 3.10.0
function! lh#list#concurrent_for(in1, in2, out1, out2, out_com, ...) abort
  " because of 'N' predicate
  let was_sorting_numbers_as_strings = 0
  let in1 = a:in1
  let in2 = a:in2
  " detect the right predicate
  if a:0 == 0
    let Cmp = function('lh#list#_str_cmp')
  else
    if a:1 == 'N'
      let was_sorting_numbers_as_strings = 1
      let in1 = map(copy(a:in1), 'eval(v:val)')
      let in2 = map(copy(a:in2), 'eval(v:val)')
      let Cmp = function('lh#list#_regular_cmp')
    elseif a:1 == 'n'
      let Cmp = function('lh#list#_regular_cmp')
    else
      let Cmp = a:1
    endif
  endif
  " because let out+=[...] is forbidden
  let out1 = a:out1
  let out2 = a:out2
  let out_com = a:out_com
  let nb1 = len(in1)
  let nb2 = len(in2)
  let i1 = 0
  let i2 = 0
  while i1 < nb1 && i2 < nb2
    let cmp = Cmp(in1[i1], in2[i2])
    if cmp == -1
      let out1 += [in1[i1]]
      let i1 += 1
    elseif cmp == 1
      let out2 += [in2[i2]]
      let i2 += 1
    else
      let out_com += [in1[i1]]
      let i1 += 1
      let i2 += 1
    endif
  endwhile
  call extend(out1, in1[i1 :])
  call extend(out2, in2[i2 :])
  if was_sorting_numbers_as_strings
    " revert numbers to strings
    call map(out1, 'string(v:val)')
    call map(out2, 'string(v:val)')
    call map(out_com, 'string(v:val)')
  endif
  " echomsg len(a:in1) . " - " .len(a:in2)
  " echomsg len(out1) . " - " .len(out2) . " - " . len(out_com)
endfunction

" # Private {{{2
" Function: lh#list#_regular_cmp(lhs, rhs) {{{3
" Up to vim version 7.4.411
"    echo sort(['{ *//', '{', 'a', 'b'])
" gives: ['a', 'b', '{ *//', '{']
" While
"    sort(['{ *//', '{', 'a', 'b'], function('lh#list#_regular_cmp'))
" gives the correct: ['a', 'b', '{', '{ *//']
function! lh#list#_str_cmp(lhs, rhs) abort
  let lhs = a:lhs
  let rhs = a:rhs
  if type(lhs) == type(rhs) && type(lhs) != type('')
    unlet lhs
    unlet rhs
    let lhs = string(a:lhs)
    let rhs = string(a:rhs)
  else
    if type(lhs) != type(0) && type(lhs) != type('')
      unlet lhs
      let lhs = string(a:lhs)
    endif
    if type(rhs) != type(0) && type(rhs) != type('')
      unlet rhs
      let rhs = string(a:rhs)
    endif
  endif
  return lh#list#_regular_cmp(lhs, rhs)
endfunction

" Function: lh#list#_regular_cmp(lhs, rhs) {{{3
" This function can be used to compare numbers up-to-vim 7.4.341
function! lh#list#_regular_cmp(lhs, rhs) abort
  let res = a:lhs <  a:rhs ? -1
        \ : a:lhs == a:rhs ? 0
        \ :                  1
  return res
endfunction

" Function: lh#list#_apply_on(list/dict, index/key, action) {{{3
function! lh#list#_apply_on(list, index, action) abort
  let in  = get(a:list, a:index)
  let out = lh#function#execute(a:action, in)
  let a:list[a:index] = out
  return a:list
endfunction

" Function: lh#list#zip(l1, l2) {{{3
function! lh#list#zip(l1, l2) abort
  if len(a:l1) != len(a:l2)
    throw "Zip operation cannot be performed on lists of different sizes"
  endif
  let res = []
  let idx = range(0, len(a:l1)-1)
  for i in idx
    let res += [ a:l1[i], a:l2[i] ]
  endfor
  return res
endfunction

" Function: lh#list#zip_as_dict(l1, l2) {{{3
function! lh#list#zip_as_dict(l1, l2) abort
  if len(a:l1) != len(a:l2)
    throw "Zip operation cannot be performed on lists of different sizes"
  endif
  let res = {}
  let idx = range(0, len(a:l1)-1)
  for i in idx
    let res[a:l1[i]] = a:l2[i]
  endfor
  return res
endfunction

" Function: lh#list#_id(a) {{{3
function! lh#list#_id(a) abort
  return a:a
endfunction

" Fucntion: s:getSNR([func_name]) {{{3
function! s:getSNR(...)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction
" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
