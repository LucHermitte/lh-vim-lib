"=============================================================================
" $Id$
" File:		buffer.vim                                           {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" Version:	2.0.0
" Created:	23rd Jan 2007
" Last Update:	$Date$
"------------------------------------------------------------------------
" Description:	
" 	Defines functions that help finding windows.
" 
"------------------------------------------------------------------------
" Installation:	
" 	Drop it into {rtp}/autoload/lh/
" 	Vim 7+ required.
" History:	
"	v 1.0.0 First Version
" 	(*) Functions moved from searchInRuntimeTime  
" TODO:		«missing features»
" }}}1
"=============================================================================


"=============================================================================
let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------

" Function: lh#buffer#Find({filename}) {{{3
" If {filename} is opened in a window, jump to this window, otherwise return -1
" Moved from searchInRuntimeTime.vim
function! lh#buffer#Find(filename)
  let b = bufwinnr(a:filename)
  if b == -1 | return b | endif
  exe b.'wincmd w'
  return b
endfunction

" Function: lh#buffer#Jump({filename},{cmd}) {{{3
function! lh#buffer#Jump(filename, cmd)
  if lh#buffer#Find(a:filename) != -1 | return | endif
  exe a:cmd . ' ' . a:filename
endfunction

function! lh#buffer#Scratch(bname, where)
  try
    silent exe a:where.' sp '.a:bname
  catch /.*/
    throw "Can't open a buffer named '".a:bname."'!"
  endtry
  setlocal bt=nofile bh=wipe nobl noswf ro
endfunction
"=============================================================================
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
