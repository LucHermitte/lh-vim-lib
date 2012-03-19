"=============================================================================
" $Id$
" File:		plugin/lhvl.vim                                   {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" License:      GPLv3 with exceptions
"               <URL:http://code.google.com/p/lh-vim/wiki/License>
" Version:	3.0.0
" Created:	27th Apr 2010
" Last Update:	$Date$
"------------------------------------------------------------------------
" Description:	
"       Non-function resources from lh-vim-lib
" 
"------------------------------------------------------------------------
" Installation:	
"       Drop the file into {rtp}/plugin
" History:	
"       v2.2.1  first version
"       v3.0.0  GPLv3
" TODO:		«missing features»
" }}}1
"=============================================================================

" Avoid global reinclusion {{{1
let s:k_version = 300
if &cp || (exists("g:loaded_lhvl")
      \ && (g:loaded_lhvl >= s:k_version)
      \ && !exists('g:force_reload_lhvl'))
  finish
endif
let g:loaded_lhvl = s:k_version
let s:cpo_save=&cpo
set cpo&vim
" Avoid global reinclusion }}}1
"------------------------------------------------------------------------
" Commands and Mappings {{{1
" Moved from lh-cpp
command! PopSearch :call histdel('search', -1)| let @/=histget('search',-1)

" Commands and Mappings }}}1
"------------------------------------------------------------------------
" Functions {{{1
" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
