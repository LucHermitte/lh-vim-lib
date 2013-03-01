"=============================================================================
" $Id$
" File:         autoload/lh/icomplete.vim                         {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" License:      GPLv3 with exceptions
"               <URL:http://code.google.com/p/lh-vim/wiki/License>
" Version:      3.0.0
" Created:      03rd Jan 2011
" Last Update:  $Date$
"------------------------------------------------------------------------
" Description:
"       Helpers functions to build |ins-completion-menu|
" 
"------------------------------------------------------------------------
" Installation:
"       Drop this file into {rtp}/autoload/lh
"       Requires Vim7+
" History:
"       v3.0.0: GPLv3
" 	v2.2.4: first version
" TODO:
" 	- We are not able to detect the end of the completion mode. As a
" 	consequence we can't prevent c/for<space> to trigger an abbreviation
" 	instead of the right template file.
" 	In an ideal world, there would exist an event post |complete()|
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
let s:k_version = 318
function! lh#icomplete#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = 0
function! lh#icomplete#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#icomplete#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" Function: lh#icomplete#run(startcol, matches, Hook) {{{2
function! lh#icomplete#run(startcol, matches, Hook)
  call lh#icomplete#_register_hook(a:Hook)
  call complete(a:startcol, a:matches)
  return ''
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
" Function: lh#icomplete#_clear_key_bindings() {{{2
function! lh#icomplete#_clear_key_bindings()
  iunmap <buffer> <cr>
  iunmap <buffer> <c-y>
  iunmap <buffer> <esc>
  " iunmap <space>
  " iunmap <tab>
endfunction

" Function: lh#icomplete#_restore_key_bindings() {{{2
function! lh#icomplete#_restore_key_bindings(previous_mappings)
  call s:Verbose('Restore keybindings after completion')
  if has_key(a:previous_mappings, 'cr') && has_key(a:previous_mappings.cr, 'buffer') && a:previous_mappings.cr.buffer
    let cmd = lh#map#define(a:previous_mappings.cr)
  else
    iunmap <buffer> <cr>
  endif
  if has_key(a:previous_mappings, 'c_y') && has_key(a:previous_mappings.c_y, 'buffer') && a:previous_mappings.c_y.buffer
    let cmd = lh#map#define(a:previous_mappings.c_y)
  else
    iunmap <buffer> <c-y>
  endif
  if has_key(a:previous_mappings, 'esc') && has_key(a:previous_mappings.esc, 'buffer') && a:previous_mappings.esc.buffer
    let cmd = lh#map#define(a:previous_mappings.esc)
  else
    iunmap <buffer> <esc>
  endif
  " iunmap <space>
  " iunmap <tab>
endfunction

" Function: lh#icomplete#_register_hook(Hook) {{{2
function! lh#icomplete#_register_hook(Hook)
  " call s:Verbose('Register hook on completion')
  let old_keybindings = {}
  let old_keybindings.cr = maparg('<cr>', 'i', 0, 1)
  let old_keybindings.c_y = maparg('<c-y>', 'i', 0, 1)
  let old_keybindings.esc = maparg('<esc>', 'i', 0, 1)
  exe 'inoremap <buffer> <silent> <cr> <c-y><c-\><c-n>:call' .a:Hook . '()<cr>'
  exe 'inoremap <buffer> <silent> <c-y> <c-y><c-\><c-n>:call' .a:Hook . '()<cr>'
  " <c-o><Nop> doesn't work as expected... 
  " To stay in INSERT-mode:
  " inoremap <silent> <esc> <c-e><c-o>:<cr>
  " To return into NORMAL-mode:
  inoremap <buffer> <silent> <esc> <c-e><esc>

  call lh#event#register_for_one_execution_at('InsertLeave',
	\ ':call lh#icomplete#_restore_key_bindings('.string(old_keybindings).')', 'CompleteGroup')
        " \ ':call lh#icomplete#_clear_key_bindings()', 'CompleteGroup')
endfunction

" Why is it triggered even before entering the completion ? 
function! lh#icomplete#_register_hook2(Hook)
  " call lh#event#register_for_one_execution_at('InsertLeave',
  call lh#event#register_for_one_execution_at('CompleteDone',
	\ ':debug call'.a:Hook.'()<cr>', 'CompleteGroup')
        " \ ':call lh#icomplete#_clear_key_bindings()', 'CompleteGroup')
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
