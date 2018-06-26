"=============================================================================
" File:         autoload/lh/qf.vim                                {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/blob/master/License.md>
" Version:      4.5.0.
let s:k_version = '450'
" Created:      26th Jun 2018
" Last Update:  26th Jun 2018
"------------------------------------------------------------------------
" Description:
"       Defines functions related to quickfix feature
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
function! lh#qf#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#qf#verbose(...)
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

function! lh#qf#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

" Function: lh#qf#get_title() {{{2
" @since V4.5.0
if lh#has#properties_in_qf()
  function! lh#qf#get_title() abort
    return getqflist({'title':1}).title
  endfunction
else
  function! lh#qf#get_title() abort
    let winnr = lh#qf#get_winnr()
    return winnr == 0 ? '' : getwinvar(winnr, 'quickfix_title')
  endfunction
endif

" Function: lh#qf#get_winnr() {{{2
" @since V4.5.0
if exists('*getwininfo')
  function! lh#qf#get_winnr() abort
    let wins = filter(getwininfo(), 'v:val.quickfix && !v:val.loclist')
    " assert(len(wins) <= 1)
    return empty(wins) ? 0 : wins[0].winnr
  endfunction
else
  function! lh#qf#get_winnr() abort
    let buffers = lh#askvim#execute('ls!')
    call filter(buffers, 'v:val =~ "\\[Quickfix List\\]"')
    " :cclose removes the buffer from the list (in my config only??)
    " assert(len(buffers) <= 1)
    return empty(buffers) ? 0 : eval(matchstr(buffers[0], '\v^\s*\zs\d+'))
  endfunction
endif

" Function: lh#qf#is_displayed() {{{2
function! lh#qf#is_displayed() abort
  return lh#qf#get_winnr() ? 1 : 0
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
