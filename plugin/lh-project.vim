"=============================================================================
" File:         plugin/lh-project.vim                             {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0.0.
let s:k_version = '4000'
" Created:      29th Sep 2016
" Last Update:  02nd Aug 2017
"------------------------------------------------------------------------
" Description:
"       :Project related commands
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

" Avoid global reinclusion {{{1
if &cp || (exists("g:loaded_lh_project")
      \ && (g:loaded_lh_project >= s:k_version)
      \ && !exists('g:force_reload_lh_project'))
  finish
endif
let g:loaded_lh_project = s:k_version
let s:cpo_save=&cpo
set cpo&vim
" Avoid global reinclusion }}}1
"------------------------------------------------------------------------
" ## Options {{{1
let g:lh#project = get(g:, 'lh#project', {})

let s:toggle_auto_discover_root =
      \ { 'variable': 'lh#project.auto_discover_root'
      \ , 'values': ['in_doubt_ask', 'no', 'yes', 'in_doubt_ignore', 'in_doubt_improvise' ]
      \ , 'menu' : {'priority': '500.110.20', 'name': '&Plugin.&Project.auto discover &root'}
      \ }
call lh#menu#def_toggle_item(s:toggle_auto_discover_root)

let s:toggle_auto_detect_project =
      \ { 'variable': 'lh#project.auto_detect'
      \ , 'values': [0, 1]
      \ , 'texts': ['no', 'yes']
      \ , 'menu' : {'priority': '500.110.40', 'name': '&Plugin.&Project.auto detect &project'}
      \ }
call lh#menu#def_toggle_item(s:toggle_auto_detect_project)

let s:toggle_auto_chdir =
      \ { 'variable': 'lh#project.auto_chdir'
      \ , 'values': [0, 1]
      \ , 'texts': ['no', 'yes']
      \ , 'menu' : {'priority': '500.110.40', 'name': '&Plugin.&Project.auto &chdir'}
      \ }
call lh#menu#def_toggle_item(s:toggle_auto_chdir)

" ## Commands {{{1
command! -nargs=* -complete=customlist,lh#project#cmd#_complete
      \ Project
      \ call lh#project#cmd#execute(<f-args>)

" ## Auto commands {{{1
augroup LH_PROJECT
  au!
  au BufUnload   * call lh#project#_RemoveBufferFromProjectConfig(expand('<abuf>'))

  " Needs to be executed after local_vimrc
  au BufReadPost * call lh#project#_post_local_vimrc()

  au BufWinEnter,VimEnter * call lh#project#_CheckUpdateCWD()
augroup END

" ## Register to editorconfig if found {{{1
if !empty(globpath(&rtp, 'autoload/editorconfig.vim'))
  call editorconfig#AddNewHook(function('lh#project#editorconfig#hook'))
endif

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
