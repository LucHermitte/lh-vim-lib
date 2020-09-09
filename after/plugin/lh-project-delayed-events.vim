"=============================================================================
" File:         after/plugin/lh-project-delayed-events.vim        {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPL v3 w/ exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/blob/master/License.md>
" Version:      5.2.1.
let s:k_version = '521'
" Created:      13th Dec 2019
" Last Update:  09th Sep 2020
"------------------------------------------------------------------------
" Description:
"       Events thats needs to be registered after other events
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

" Avoid global reinclusion {{{1
let s:cpo_save=&cpo
set cpo&vim

if &cp || (exists("g:loaded_lh_project_delayed_events")
      \ && (g:loaded_lh_project_delayed_events >= s:k_version)
      \ && !exists('g:force_reload_lh_project_delayed_events'))
  let &cpo=s:cpo_save
  finish
endif
let g:loaded_lh_project_delayed_events = s:k_version
" Avoid global reinclusion }}}1
"------------------------------------------------------------------------
" ## Auto commands {{{1
augroup LH_PROJECT
  au!
  au BufDelete   * call lh#project#_RemoveBufferFromProjectConfig(expand('<abuf>'))

  " Needs to be executed after local_vimrc, hence the after/ directory
  au BufReadPost,BufNewFile * call lh#project#_post_local_vimrc()

  au BufWinEnter,VimEnter * call lh#project#_CheckUpdateCWD()
augroup END
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
