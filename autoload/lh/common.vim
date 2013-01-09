"=============================================================================
" $Id$
" File:		autoload/lh/common.vim                               {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" License:      GPLv3 with exceptions
"               <URL:http://code.google.com/p/lh-vim/wiki/License>
" Version:	3.0.0
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
" 	with ruby enabled for lh#common#rand()
" History:	
"       v3.0.1
"       lh#common#rand
"       v3.0.0
"       - GPLv3
" 	v2.1.1
" 	- New function: lh#common#echomsg_multilines()
" 	- lh#common#warning_msg() supports multilines messages
"
" 	v2.0.0:
" 	- Code moved from other plugins
" }}}1
"=============================================================================


"=============================================================================
let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" Functions {{{1

" Function: lh#common#echomsg_multilines {{{2
function! lh#common#echomsg_multilines(text)
  let lines = split(a:text, "[\n\r]")
  for line in lines
    echomsg line
  endfor
endfunction
function! lh#common#echomsgMultilines(text)
  return lh#common#echomsg_multilines(a:text)
endfunction

" Function: lh#common#error_msg {{{2
function! lh#common#error_msg(text)
  if has('gui_running')
    call confirm(a:text, '&Ok', '1', 'Error')
  else
    " echohl ErrorMsg
    echoerr a:text
    " echohl None
  endif
endfunction 
function! lh#common#ErrorMsg(text)
  return lh#common#error_msg(a:text)
endfunction

" Function: lh#common#warning_msg {{{2
function! lh#common#warning_msg(text)
  echohl WarningMsg
  " echomsg a:text
  call lh#common#echomsg_multilines(a:text)
  echohl None
endfunction 
function! lh#common#WarningMsg(text)
  return lh#common#warning_msg(a:text)
endfunction

" Dependencies {{{2
function! lh#common#check_deps(Symbol, File, path, plugin) " {{{3
  if !exists(a:Symbol)
    exe "runtime ".a:path.a:File
    if !exists(a:Symbol)
      call lh#common#error_msg( a:plugin.': Requires <'.a:File.'>')
      return 0
    endif
  endif
  return 1
endfunction

function! lh#common#CheckDeps(Symbol, File, path, plugin) " {{{3
  echomsg "lh#common#CheckDeps() is deprecated, use lh#common#check_deps() instead."
  return lh#common#check_deps(a:Symbol, a:File, a:path, a:plugin)
endfunction

" Function: lh#common#rand(max) {{{3
" This function requires ruby, and it may move to another autoload plugin
function! lh#common#rand(max)
    ruby << EOF
    rmax = VIM::evaluate("a:max")
    rmax = nil if rmax == ""
    VIM::command("return #{rand(rmax).inspect}")
EOF
endfunction
" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
