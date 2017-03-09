"=============================================================================
" File:		autoload/lh/visual.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:	4.0.0
let s:k_version = 400
" Created:	08th Sep 2008
" Last Update:	09th Mar 2017
"------------------------------------------------------------------------
" 	Helpers functions releated to the visual mode
"
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#visual#version()
  return s:k_version
endfunction

" # Debug {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#visual#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Log(...)
  call call('lh#log#this', a:000)
endfunction

function! s:Verbose(...)
  if s:verbose
    call call('s:Log', a:000)
  endif
endfunction

function! lh#visual#debug(expr) abort
  return eval(a:expr)
endfunction


"=============================================================================
" ## Functions {{{1

" Function: lh#visual#selection()                              {{{3
" @return the text currently selected
function! lh#visual#selection() abort
  try
    let a_save = @a
    silent! normal! gv"ay
    return @a
  finally
    let @a = a_save
  endtry
endfunction

" Function: lh#visual#cut()                                    {{{3
" @return and delete the text currently selected
function! lh#visual#cut()
  try
    let a_save = @a
    normal! gv"ad
    return @a
  finally
    let @a = a_save
  endtry
endfunction

" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
