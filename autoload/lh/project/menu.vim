"=============================================================================
" File:         autoload/lh/project/menu.vim                      {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      5.1.0.
let s:k_version = '50100'
" Created:      21st Feb 2017
" Last Update:  06th Mar 2020
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
  let priority = g:lh#project.menu.priority . a:priority
  let name = g:lh#project.menu.name . a:name
  let args = [ a:modes, priority, name, a:binding ] + a:000
  call call('lh#menu#make', args)
  if index(a:000, '<buffer>') >= 0
    call s:Verbose("Registering local menu: %1", args)
    let prj = lh#project#crt()
    if lh#option#is_set(prj)
      call add(prj._menus, args)
    endif
  endif
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

" Function: lh#project#menu#reserve_id([prj]) {{{3
let s:last_id = get(s:, 'last_id', 200)
function! lh#project#menu#reserve_id(...) abort
  let prj = a:0 == 0 ? lh#project#crt() : a:1
  let id = prj.get('menu.priority')
  if lh#option#is_set(id)
    return id
  else
    let s:last_id += 10
    let prj.set('menu.priority', s:last_id)
    return s:last_id
  endif
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
