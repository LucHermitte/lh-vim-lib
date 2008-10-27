"=============================================================================
" $Id$
" File:		autoload/lh/common.vim                               {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" Version:	2.2.0
" Created:	07th Oct 2006
" Last Update:	$Date$ (08th Feb 2008)
"------------------------------------------------------------------------
" Description:	
" 	Some common functions for:
" 	- displaying error messages
" 	- checking dependencies
" 
"------------------------------------------------------------------------
" Installation:	
" 	Drop it into {rtp}/autoload/lh/
" 	Vim 7+ required.
" History:	
" 	v2.1.1
" 		- New function: lh#common#echomsgMultilines()
" 		- lh#common#WarningMsg() supports multilines messages
"
" 	v2.0.0:
" 		- Code moved from other plugins
" }}}1
"=============================================================================


"=============================================================================
let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" Functions {{{1

" Function: lh#common#echomsgMultilines {{{2
function! lh#common#echomsgMultilines(text)
  let lines = split(a:text, "[\n\r]")
  for line in lines
    echomsg line
  endfor
endfunction

" Function: lh#common#ErrorMsg {{{2
function! lh#common#ErrorMsg(text)
  if has('gui_running')
    call confirm(a:text, '&Ok', '1', 'Error')
  else
    " echohl ErrorMsg
    echoerr a:text
    " echohl None
  endif
endfunction 

" Function: lh#common#WarningMsg {{{2
function! lh#common#WarningMsg(text)
  echohl WarningMsg
  " echomsg a:text
  call lh#common#echomsgMultilines(a:text)
  echohl None
endfunction 

" Dependencies {{{2
function! lh#common#CheckDeps(Symbol, File, path, plugin) " {{{3
  if !exists(a:Symbol)
    exe "runtime ".a:path.a:File
    if !exists(a:Symbol)
      call lh#common#ErrorMsg( a:plugin.': Requires <'.a:File.'>')
      return 0
    endif
  endif
  return 1
endfunction " }}}4
" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
