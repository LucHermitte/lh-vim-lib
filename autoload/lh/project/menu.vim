"=============================================================================
" File:         autoload/lh/project/menu.vim                      {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0.0.
let s:k_version = '4000'
" Created:      21st Feb 2017
" Last Update:  21st Feb 2017
"------------------------------------------------------------------------
" Description:
"       Helper functions to create project related menu items
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
function! lh#project#menu#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#project#menu#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Log(expr, ...)
  call call('lh#log#this',[a:expr]+a:000)
endfunction

function! s:Verbose(expr, ...)
  if s:verbose
    call call('s:Log',[a:expr]+a:000)
  endif
endfunction

function! lh#project#menu#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Globals {{{1
call lh#let#if_undef('g:lh#project.menu', {'name': '&Project.', 'priority': '50.'})

" ## Exported functions {{{1
" Function: lh#project#menu#make(mode, priority, name, binding, ...) {{{3
function! lh#project#menu#make(modes, priority, name, binding, ...) abort
  call call('lh#menu#make',
        \ [ a:modes
        \ , g:lh#project.menu.priority . a:priority
        \ , g:lh#project.menu.name . a:name
        \ , a:binding
        \ ] + a:000)
endfunction

" Function: lh#project#menu#def_toggle_item(Data) {{{3
function! lh#project#menu#def_toggle_item(Data) abort
  let data = copy(a:Data)
  let data.menu.priority = g:lh#project.menu.priority . data.menu.priority
  let data.menu.name     = g:lh#project.menu.name . data.menu.name
  return lh#menu#def_toggle_item(data)
endfunction

" Function: lh#project#menu#remove(modes, name) {{{3
function! lh#project#menu#remove(modes, name) abort
  call lh#menu#remove(a:modes, g:lh#project.menu.name . a:name)
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
