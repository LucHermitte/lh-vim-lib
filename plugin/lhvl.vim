"=============================================================================
" File:		plugin/lhvl.vim                                   {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/blob/master/License.md>
" Version:	4.6.4
let s:k_version = 40604
" Created:	27th Apr 2010
" Last Update:	18th Feb 2020
"------------------------------------------------------------------------
" Description:
"       Non-function resources from lh-vim-lib
"
"------------------------------------------------------------------------
" Installation:
"       Drop the file into {rtp}/plugin
" History:
"       v4.0.0   New commands: :StopBGExecution :Jobs, :JobUnpause, ConfirmGlobal
"       v3.8.2,3 New command: :LHLog
"       v3.1.12  New command: :CleanEmptyBuffers
"       v3.1.6   New command: :LoadedBufDo
"       v3.0.0   GPLv3
"       v2.2.1   first version
" }}}1
"=============================================================================

" Avoid global reinclusion {{{1
let s:cpo_save=&cpo
set cpo&vim

if &cp || (exists("g:loaded_lhvl")
      \ && (g:loaded_lhvl >= s:k_version)
      \ && !exists('g:force_reload_lhvl'))
  let &cpo=s:cpo_save
  finish
endif
let g:loaded_lhvl = s:k_version
" Avoid global reinclusion }}}1
"------------------------------------------------------------------------
" ## Commands and Mappings {{{1
" Moved from lh-cpp
command! PopSearch :call histdel('search', -1)| let @/=histget('search',-1)

command! -nargs=1 LoadedBufDo       call lh#buffer#_loaded_buf_do(<q-args>)
command! -nargs=0 CleanEmptyBuffers call lh#buffer#_clean_empty_buffers()

command! -nargs=+ -complete=customlist,lh#log#_set_logger_complete LHLog
      \ call lh#log#_log(<f-args>)

command! -nargs=1
      \ -complete=customlist,lh#async#_job_queue_names
      \ Jobs       call lh#async#_jobs_console(<q-args>)
command! -nargs=1
      \ -complete=customlist,lh#async#_paused_job_queue_names
      \ JobUnpause call lh#async#_unpause_jobs(<q-args>)
command! -nargs=1
      \ -complete=customlist,lh#async#_complete_job_names
      \ StopBGExecution call lh#async#stop(<q-args>)

command! -nargs=1 ConfirmGlobal call lh#ui#_confirm_global('<args>')

command! -nargs=+ -complete=file
      \ SplitIfNotOpen4COC
      \ call lh#coc#_split_open(<f-args>)

"------------------------------------------------------------------------
" ## Options {{{1
let s:toggle_assert =
      \ { 'variable': 'lh#assert#_mode'
      \ , 'values': ['', 'ignore', 'stop', 'debug' ]
      \ , 'texts':  ['default', 'ignore', 'stop', 'debug']
      \ , 'menu' : {'priority': '500.100', 'name': '&Plugin.Assert &mode'}
      \ }
call lh#menu#def_toggle_item(s:toggle_assert)

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
