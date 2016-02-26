"=============================================================================
" File:         plugin/let.vim                                    {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/blob/master/License.md>
" Version:      3.7.1
" Created:      31st May 2010
" Last Update:  23rd Feb 2016
"------------------------------------------------------------------------
" Description:
"       Defines a command :LetIfUndef that sets a variable if undefined
" 
"------------------------------------------------------------------------
" Installation:
"       Drop this file into {rtp}/plugin
"       Requires Vim7+
" History:      
" 	v2.2.1: first version of this command into lh-vim-lib
" 	v3.0.0: GPLv3
" 	v3.0.1: :LetIfUndef works with dictionaries as well
" 	        function moved to its own autoload plugin
" 	v3.7.*: +:PushOption :PopOption
" TODO: 
" }}}1
"=============================================================================

" Avoid global reinclusion {{{1
let s:k_version = 300
if &cp || (exists("g:loaded_let")
      \ && (g:loaded_let >= s:k_version)
      \ && !exists('g:force_reload_let'))
  finish
endif
let g:loaded_let = s:k_version
let s:cpo_save=&cpo
set cpo&vim
" Avoid global reinclusion }}}1
"------------------------------------------------------------------------
" Commands and Mappings {{{1
command! -nargs=+ LetIfUndef call lh#let#if_undef(<f-args>)

command! -nargs=+ -complete=customlist,lh#let#_push_options_complete
      \ PushOptions call lh#let#_push_options(<f-args>)
command! -nargs=+ -complete=customlist,lh#let#_pop_options_complete
      \ PopOptions call lh#let#_pop_options(<f-args>)
" Commands and Mappings }}}1
"------------------------------------------------------------------------
" Functions {{{1
" Note: most functions are best placed into
" autoload/«your-initials»/«let».vim
" Keep here only the functions are are required when the plugin is loaded,
" like functions that help building a vim-menu for this plugin.

" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
