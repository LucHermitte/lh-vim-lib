"=============================================================================
" File:		autoload/lh/position.vim                               {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/License.md>
" Version:	3.3.14
" Created:	05th Sep 2007
" Last Update:	21st Nov 2015
"------------------------------------------------------------------------
" Description:	?description?
"
"------------------------------------------------------------------------
" Installation:
" 	Drop it into {rtp}/autoload/lh/
" 	Vim 7+ required.
" History:	?history?
" 	v1.0.0:
" 		Creation
"       v3.0.0: GPLv3
" TODO:
" }}}1
"=============================================================================


"=============================================================================
let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Functions {{{1
" # Debug {{{2
function! lh#position#verbose(level)
  let s:verbose = a:level
endfunction

function! s:Verbose(expr)
  if exists('s:verbose') && s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#position#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" # Public {{{2
" Function: lh#position#is_before {{{3
" @param[in] positions as those returned from |getpos()|
" @return whether lhs_pos is before rhs_pos
function! lh#position#is_before(lhs_pos, rhs_pos)
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
function! lh#position#IsBefore(lhs_pos, rhs_pos)
  return lh#position#is_before(a:lhs_pos, a:rhs_pos)
endfunction


" Function: lh#position#char_at_mark {{{3
" @return the character at a given mark (|mark|)
function! lh#position#char_at_mark(mark)
  let c = getline(a:mark)[col(a:mark)-1]
  return c
endfunction
function! lh#position#CharAtMark(mark)
return lh#position#char_at_mark(a:mark)
endfunction

" Function: lh#position#char_at_pos {{{3
" @return the character at a given position (|getpos()|)
function! lh#position#char_at_pos(pos)
  let c = getline(a:pos[1])[(a:pos[2])-1]
  return c
endfunction
function! lh#position#CharAtPos(pos)
  return  lh#position#char_at_pos(a:pos)
endfunction

" Function: lh#position#char_at {{{3
function! lh#position#char_at(lin, col)
  let c = getline(a:lin)[(a:col)-1]
  return c
endfunction

" Function: lh#position#extract(pos1, pos2) {{{3
" positions from |getpos()|
function! lh#position#extract(pos1, pos2) abort
  let lines = getline(a:pos1[0], a:pos2[0])
  let lines[-1] = lines[-1][:a:pos2[1]-2]
  let lines[0]  = lines[0][a:pos1[1] : ]
  return join(lines, "\n")
endfunction

" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
