"=============================================================================
" $Id$
" File:		position.vim                                           {{{1
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
" 		Creation
" TODO:		
" }}}1
"=============================================================================


"=============================================================================
let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" Functions {{{1

" Function: lh#position#IsBefore {{{2
" @param[in] positions as those returned from |getpos()|
" @return whether lhs_pos is before rhs_pos
function! lh#position#IsBefore(lhs_pos, rhs_pos)
  if a:lhs_pos[0] != a:rhs_pos[0]
    throw "Positions from incompatible buffers can't be ordered"
  endif
  "1 test lines
  "2 test cols
  let before 
	\ = (a:lhs_pos[1] == a:rhs_pos[1])
	\ ? (a:lhs_pos[2] < a:rhs_pos[2])
	\ : (a:lhs_pos[1] < a:rhs_pos[1])
  return before
endfunction


" Function: lh#position#CharAtMark {{{2
" @return the character at a given mark (|mark|)
function! lh#position#CharAtMark(mark)
  let c = getline(a:mark)[col(a:mark)-1]
  return c
endfunction

" Function: lh#position#CharAtPos {{{2
" @return the character at a given position (|getpos()|)
function! lh#position#CharAtPos(pos)
  let c = getline(a:pos[1])[col(a:pos[2])-1]
  return c
endfunction



" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
