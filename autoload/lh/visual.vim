"=============================================================================
" $Id$
" File:		autoload/lh/visual.vim                               {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" License:      GPLv3 with exceptions
"               <URL:http://code.google.com/p/lh-vim/wiki/License>
" Version:	3.0.0
" Created:	08th Sep 2008
" Last Update:	$Date$
"------------------------------------------------------------------------
" 	Helpers functions releated to the visual mode
" 
"------------------------------------------------------------------------
" 	Drop it into {rtp}/autoload/lh/
" 	Vim 7+ required.
" History:	
"       v3.0.0: GPLv3
" 	v2.2.5: lh#visual#cut()
" 	v2.0.6: First appearance
" TODO:		«missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" Functions {{{1

" Function: lh#visual#selection()                              {{{3
" @return the text currently selected
function! lh#visual#selection()
  try
    let a_save = @a
    normal! gv"ay
    return @a
  finally
    let @a = a_save
  endtry
endfunction

" Function: lh#visual#cut()                                    {{{3
" @return and delete the text currently selected
function! lh#visual#cut()
  try
    let a_save = @a
    normal! gv"ad
    return @a
  finally
    let @a = a_save
  endtry
endfunction

" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
