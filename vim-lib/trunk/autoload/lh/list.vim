"=============================================================================
" $Id$
" File:		autoload/lh/list.vim                                      {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" Version:	2.1.1
" Created:	17th Apr 2007
" Last Update:	$Date$ (17th Apr 2007)
"------------------------------------------------------------------------
" Description:	
" 	Defines functions related to |Lists|
" 
"------------------------------------------------------------------------
" Installation:	
" 	Drop it into {rtp}/autoload/lh/
" 	Vim 7+ required.
" History:	
" 	v2.1.1: 
" 	(*) uniq_sort
" 	v2.0.7:
" 	(*) Bug fix: lh#list#Match()
" 	v2.0.6:
" 	(*) lh#list#Find_if() supports search predicate, and start index
" 	(*) lh#list#Match() supports start index
" 	v2.0.0:
" TODO:		«missing features»
" }}}1
"=============================================================================


"=============================================================================
let s:cpo_save=&cpo
set cpo&vim

"------------------------------------------------------------------------
" Functions {{{1

" Function: lh#list#Match(list, to_be_matched [, idx]) {{{2
function! lh#list#Match(list, to_be_matched, ...)
  let idx = (a:0>0) ? a:1 : 0
  while idx < len(a:list)
    if match(a:list[idx], a:to_be_matched) != -1
      return idx
    endif
    let idx += 1
  endwhile
  return -1
endfunction

" Function: lh#list#Find_if(list, predicate [, predicate-arguments] [, start-pos]) {{{2
function! lh#list#Find_if(list, predicate, ...)
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
      throw "lh#list#Match_if: unexpected argument type"
    endif
  elseif a:0 != 0
      throw "lh#list#Match_if: unexpected number of arguments: lh#list#Match_if(list, predicate [, predicate-arguments] [, start-pos])"
  endif

  " The search loop
  while idx != len(a:list)
    let predicate = substitute(a:predicate, 'v:val', 'a:list['.idx.']', 'g')
    let predicate = substitute(predicate, 'v:\(\d\+\)_', 'args[\1-1]', 'g')
    let res = eval(predicate)
    if res | return idx | endif
    let idx += 1
  endwhile
  return -1
endfunction

" Function: lh#list#unique_sort(list [, func]) {{{2
" See also http://vim.wikia.com/wiki/Unique_sorting
"
" Works like sort(), optionally taking in a comparator (just like the
" original), except that duplicate entries will be removed.
" todo: support another argument that act as an equality predicate
function! lh#list#unique_sort(list, ...)
  let dictionary = {}
  for i in a:list
    let dictionary[string(i)] = i
  endfor
  let result = []
  echo values(dictionary)
  if ( exists( 'a:1' ) )
    let result = sort( values( dictionary ), a:1 )
  else
    let result = sort( values( dictionary ) )
  endif
  return result
endfunction

function! lh#list#unique_sort2(list, ...)
  let list = copy(a:list)
  if ( exists( 'a:1' ) )
    call sort(list, a:1 )
  else
    call sort(list)
  endif
  if len(list) <= 1 | return list | endif
  let result = [ list[0] ]
  let last = list[0]
  let i = 1
  while i < len(list)
    if last != list[i]
      let last = list[i]
      call add(result, last)
    endif
    let i += 1
  endwhile
  return result
endfunction

" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
