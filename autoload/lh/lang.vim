"=============================================================================
" File:         autoload/lh/lang.vim                              {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/blob/master/License.md>
" Version:      4.6.4.
let s:k_version = '464'
" Created:      09th Oct 2018
" Last Update:  09th Oct 2018
"------------------------------------------------------------------------
" Description:
"       «description»
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#lang#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#lang#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Log(expr, ...) abort
  call call('lh#log#this',[a:expr]+a:000)
endfunction

function! s:Verbose(expr, ...) abort
  if s:verbose
    call call('s:Log',[a:expr]+a:000)
  endif
endfunction

function! lh#lang#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" Function: lh#lang#set_message_temporarily(value) {{{2
" @since Version 4.6.4
" @todo it seems that if `:lang` has been executed then `$LANG` value is
" ignored...
" Problem, on Windows, the accepted language name is 'English_US.1252'
" or 'French_France.1252' while v:lang and $LANG return 'fr_FR.UTF-8'.
" The real information is only available through `:language`
function! lh#lang#set_message_temporarily(value) abort
  let res = lh#on#exit()
  let crt = matchstr(lh#askvim#execute('lang mes')[0], '.*"\zs\S\+\ze"$')
  if crt !~ a:value
    call res.register('lang mes '.crt)
    let value = a:value
    if value != 'C' && stridx(value, '.') == -1
      let value .= matchstr($LANG, '\..*')
    endif
    exe 'lang mes '.value
  endif
  return res
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
