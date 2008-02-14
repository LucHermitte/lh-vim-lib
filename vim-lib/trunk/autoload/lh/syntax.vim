"=============================================================================
" $Id$
" File:		syntax.vim                                           {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" Version:	2.0.5
" Created:	05th Sep 2007
" Last Update:	$Date$ (05th Sep 2007)
"------------------------------------------------------------------------
" Description:	«description»
" 
"------------------------------------------------------------------------
" Installation:
" 	Drop it into {rtp}/autoload/lh/
" 	Vim 7+ required.
" History:	«history»
" 	v1.0.0:
" 		Creation ;
" 		Functions moved from lhVimSpell
" TODO:
" 	function, to inject "contained", see lhVimSpell approach
" }}}1
"=============================================================================


"=============================================================================
" Avoid global reinclusion {{{1
let s:cpo_save=&cpo
set cpo&vim
" Avoid global reinclusion }}}1
"------------------------------------------------------------------------
" Functions {{{1

" Functions: Show name of the syntax kind of a character {{{2
function! lh#syntax#NameAt(l,c, ...)
  let what = a:0 > 0 ? a:1 : 0
  return synIDattr(synID(a:l, a:c, what),'name')
endfunction

function! lh#syntax#NameAtMark(mark, ...)
  let what = a:0 > 0 ? a:1 : 0
  return lh#syntax#NameAt(line(a:mark), col(a:mark), what)
endfunction

" Functions: skip string, comment, character, doxygen {{{2
func! lh#syntax#SkipAt(l,c)
  return lh#syntax#NameAt(a:l,a:c) =~? 'string\|comment\|character\|doxygen'
endfun

func! lh#syntax#Skip()
  return lh#syntax#SkipAt(line('.'), col('.'))
endfun

func! lh#syntax#SkipAtMark(mark)
  return lh#syntax#SkipAt(line(a:mark), col(a:mark))
endfun

" Function: Show current syntax kind {{{2
command! SynShow echo 'hi<'.lh#syntax#NameAtMark('.',1).'> trans<'
      \ lh#syntax#NameAtMark('.',0).'> lo<'.
      \ synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name').'>'


" Function: lh#syntax#SynListRaw(name) : string                     {{{2
function! lh#syntax#SynListRaw(name)
  let a_save = @a
  try
    redir @a
    exe 'silent! syn list '.a:name
    redir END
    let res = @a
  finally
    let @a = a_save
  endtry
  return res
endfunction

function! lh#syntax#SynList(name)
  let raw = lh#syntax#SynListRaw(a:name)
  let res = [] 
  let lines = split(raw, '\n')
  let started = 0
  for l in lines
    if started
      let li = (l =~ 'links to') ? '' : l
    elseif l =~ 'xxx'
      let li = matchstr(l, 'xxx\s*\zs.*')
      let started = 1
    else
      let li = ''
    endif
    if strlen(li) != 0
      let li = substitute(li, 'contained\S*\|transparent\|nextgroup\|skipwhite\|skipnl\|skipempty', '', 'g')
      let kinds = split(li, '\s\+')
      call extend(res, kinds)
    endif
  endfor
  return res
endfunction



" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
