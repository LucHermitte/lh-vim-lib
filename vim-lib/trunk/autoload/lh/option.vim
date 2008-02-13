"=============================================================================
" $Id$
" File:		autoload/lh/option.vim                                    {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" Version:	2.0.0
" Created:	24th Jul 2004
" Last Update:	$Date$ (07th Oct 2006)
"------------------------------------------------------------------------
" Description:
" 	Defines the global function lh#option#get().
"       Aimed at (ft)plugin writers.
" 
"------------------------------------------------------------------------
" Installation:
" 	Drop this file into {rtp}/autoload/lh/
" 	Requires Vim 7+
" History:	
" 	v2.0.0
" 		Code moved from {rtp}/macros/ 
" }}}1
"=============================================================================


"=============================================================================
let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" Functions {{{1

" Function: lh#option#Get(name, default [, scope])            {{{2
" @return b:{name} if it exists, of g:{name} if it exists, or {default}
" otherwise
" The order of the variables checked can be specified through the optional
" argument {scope}
function! lh#option#Get(name,default,...)
  let scope = (a:0 == 1) ? a:1 : 'bg'
  let name = a:name
  let i = 0
  while i != strlen(scope)
    if exists(scope[i].':'.name) && (0 != strlen({scope[i]}:{name}))
      return {scope[i]}:{name}
    endif
    let i = i + 1
  endwhile 
  return a:default
endfunction

" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
