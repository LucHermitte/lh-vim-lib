"=============================================================================
" File:		plugin/lhvl.vim                                   {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/blob/master/License.md>
" Version:	3.8.3
" Created:	27th Apr 2010
" Last Update:	04th May 2016
"------------------------------------------------------------------------
" Description:	
"       Non-function resources from lh-vim-lib
" 
"------------------------------------------------------------------------
" Installation:	
"       Drop the file into {rtp}/plugin
" History:	
"       v2.2.1   first version
"       v3.0.0   GPLv3
"       v3.1.6   New command: LoadedBufDo
"       v3.1.12  New command: CleanEmptyBuffers
"       v3.8.2,3 New command: LHLog
" TODO:		«missing features»
" }}}1
"=============================================================================

" Avoid global reinclusion {{{1
let s:k_version = 3112
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

command! -nargs=1 LoadedBufDo       call lh#buffer#_loaded_buf_do(<q-args>)
command! -nargs=0 CleanEmptyBuffers call lh#buffer#_clean_empty_buffers()

command! -nargs=1 -complete=customlist,lh#log#_set_logger_complete LHLog 
      \ call lh#log#_log(<q-args>)

" Commands and Mappings }}}1
"------------------------------------------------------------------------
" Functions {{{1
" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
