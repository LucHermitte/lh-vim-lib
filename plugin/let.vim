"=============================================================================
" File:         plugin/let.vim                                    {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/blob/master/License.md>
" Version:      4.6.4
let s:k_version = 464
" Created:      31st May 2010
" Last Update:  16th Jan 2019
"------------------------------------------------------------------------
" Description:
"       Defines a command :LetIfUndef that sets a variable if undefined
"
"------------------------------------------------------------------------
" Installation:
"       Drop this file into {rtp}/plugin
"       Requires Vim7+
" History:
" 	v4.0.0: +:LetTo
" 	        :LetTo and LetIfUndef support "var = value" syntax
" 	        :Let* and :Unlet support command-completion
" 	v3.7.*: +:PushOption :PopOption
" 	v3.0.1: :LetIfUndef works with dictionaries as well
" 	        function moved to its own autoload plugin
" 	v3.0.0: GPLv3
" 	v2.2.1: first version of this command into lh-vim-lib
" TODO:
" }}}1
"=============================================================================

" Avoid global reinclusion {{{1
let s:cpo_save=&cpo
set cpo&vim

if &cp || (exists("g:loaded_let")
      \ && (g:loaded_let >= s:k_version)
      \ && !exists('g:force_reload_let'))
  let &cpo=s:cpo_save
  finish
endif
let g:loaded_let = s:k_version
" Avoid global reinclusion }}}1
"------------------------------------------------------------------------
" Commands and Mappings {{{1
command! -nargs=+ -complete=customlist,lh#let#_complete_let
      \ LetIfUndef call lh#let#if_undef(<q-args>)
" NB: I avoid plain `:Let`  by fear other plugin use the same command name
command! -nargs=+ -complete=customlist,lh#let#_complete_let
      \ LetTo      call lh#let#to(<q-args>)
command! -nargs=1 -complete=customlist,lh#let#_complete_let
      \ Unlet      call lh#let#unlet(<f-args>)

command! -nargs=+ -complete=customlist,lh#let#_push_options_complete
      \ PushOptions call lh#let#_push_options(<f-args>)
command! -nargs=+ -complete=customlist,lh#let#_pop_options_complete
      \ PopOptions call lh#let#_pop_options(<f-args>)
" Commands and Mappings }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
