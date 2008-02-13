"=============================================================================
" $Id$
" File:		autoload/lh/list.vim                                      {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" Version:	2.0.0
" Created:	17th Apr 2007
" Last Update:	$Date$ (17th Apr 2007)
"------------------------------------------------------------------------
" Description:	«description»
" 
"------------------------------------------------------------------------
" Installation:	
" 	Drop it into {rtp}/autoload/lh/
" 	Vim 7+ required.
" History:	
" 	v2.0.0:
" TODO:		«missing features»
" }}}1
"=============================================================================


"=============================================================================
let s:cpo_save=&cpo
set cpo&vim

"------------------------------------------------------------------------
" Functions {{{1

" Function: lh#list#match(list, pattern) {{{2
function! lh#list#Match(list, pattern)
  let idx = 0
  while idx != len(a:list)
    if match(a:list[idx], a:pattern) != -1
      return idx
    endif
    let idx = idx + 1
  endwhile
  return -1
endfunction


" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
