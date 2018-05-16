"=============================================================================
" File:         autoload/lh/position.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      4.4.0
let s:k_version = 440
" Created:      05th Sep 2007
" Last Update:  16th May 2018
"------------------------------------------------------------------------
" Description:  Cursor related functions
" }}}1
"=============================================================================


"=============================================================================
let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#position#version()
  return s:k_version
endfunction

" # Debug {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#position#verbose(...)
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

function! lh#position#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## Functions {{{1
" # Public {{{2
" Function: lh#position#is_before                 {{{3
" @param[in] positions as those returned from |getpos()|
" @return whether lhs_pos is before rhs_pos
function! lh#position#is_before(lhs_pos, rhs_pos) abort
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


" Function: lh#position#compare(lhs_pos, rhs_pos) {{{3
function! lh#position#compare(lhs_pos, rhs_pos) abort
  if a:lhs_pos[0] != a:rhs_pos[0]
    throw "Positions from incompatible buffers can't be ordered"
  endif
  "1 test lines
  "2 test cols
  let res
        \ = (a:lhs_pos[1] == a:rhs_pos[1])
        \ ? (a:lhs_pos[2] - a:rhs_pos[2])
        \ : (a:lhs_pos[1] - a:rhs_pos[1])
  return res
endfunction

" Function: lh#position#char_at_mark              {{{3
" @return the character at a given mark (|mark|)
function! lh#position#char_at_mark(mark) abort
  let c = getline(a:mark)[col(a:mark)-1]
  return c
endfunction
function! lh#position#CharAtMark(mark)
return lh#position#char_at_mark(a:mark)
endfunction

" Function: lh#position#char_at_pos               {{{3
" @return the character at a given position (|getpos()|)
function! lh#position#char_at_pos(pos) abort
  let c = getline(a:pos[1])[(a:pos[2])-1]
  return c
endfunction
function! lh#position#CharAtPos(pos) abort
  return  lh#position#char_at_pos(a:pos)
endfunction

" Function: lh#position#char_at                   {{{3
function! lh#position#char_at(lin, col)
  let c = getline(a:lin)[(a:col)-1]
  return c
endfunction

" Function: lh#position#extract(pos1, pos2)       {{{3
" positions from |getpos()|
function! lh#position#extract(pos1, pos2) abort
  call s:Verbose('extract(%1, %2)', a:pos1, a:pos2)
  let pos1 = len(a:pos1) == 4 ? a:pos1[1:2] : a:pos1
  let pos2 = len(a:pos2) == 4 ? a:pos2[1:2] : a:pos2
  let lines = getline(pos1[0], pos2[0])
  let lines[-1] = lines[-1][:pos2[1]-2]
  let lines[0]  = lines[0][pos1[1]-1 : ]
  return join(lines, "\n")
endfunction

" Function: lh#position#getcur()                  {{{3
" @since 4.1.0
if exists('*getcurpos')
  function! lh#position#getcur()
    return getcurpos()
  endfunction
else
  function! lh#position#getcur()
    return getpos('.')
  endfunction
endif

" Function: lh#position#move(direction)           {{{3
" @since 4.4.0
let s:k_move_prefix = lh#has#redo() ? "\<C-G>U" : ""
function! lh#position#move(direction) abort
  call lh#assert#value(a:direction).match("\<left>\\|\<right>")
  return s:k_move_prefix . a:direction
endfunction

" Function: lh#position#move_n(direction, count)  {{{3
" @since 4.4.0
function! lh#position#move_n(direction, count) abort
  return repeat(lh#position#move(a:direction), a:count)
endfunction

" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
