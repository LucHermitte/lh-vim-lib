"=============================================================================
" File:         autoload/lh/log.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      3.5.0.
let s:k_version = '350'
" Created:      23rd Dec 2015
" Last Update:  23rd Dec 2015
"------------------------------------------------------------------------
" Description:
"       Logging facilities
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
function! lh#log#version()
  return s:k_version
endfunction

" # Debug   {{{2
if !exists('s:verbose')
  let s:verbose = 0
endif
function! lh#log#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#log#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

" # Create new log object {{{2

" Function: lh#log#new(where, kind) {{{3
" - where: "vert"/""
" - kind:  "qf"/"loc" for loclist
" NOTE: In order to obtain the name of the calling function, an exception is
" thrown and the backtrace is analysed.
" In order to work, this trick requires:
" - a reasonable callstack size (past a point, vim shortens the names returned
"   by v:throwpoint
" - named functions ; i.e. functions defined on dictionaries (and not attached
"   to them) will have their names mangled (actually it'll be a number) and
"   lh#exception#callstack() won't be able to decode them.
"   i.e.
"      function s:foo() dict abort
"         logger.log("here I am");
"      endfunction
"      let dict.foo = function('s:foo')
"   will work correctly fill the quicklist/loclist, but
"      function dict.foo() abort
"         logger.log("here I am");
"      endfunction
"   won't
" TODO: add verbose levels
function! lh#log#new(where, kind) abort
  let log = { 'winnr': bufwinnr('%'), 'kind': a:kind, 'where': a:where}

  " open loc/qf window {{{4
  function! s:open() abort dict
    try
      let buf = bufnr('%')
      exe 'silent! '.(self.where). ' '.(self.kind == 'loc' ? 'l' : 'c').'open'
    finally
      call lh#buffer#find(buf)
    endtry
  endfunction

  " add {{{4
  function! s:add_loc(msg) abort dict
    call setloclist(self.winnr, [a:msg], 'a')
  endfunction
  function! s:add_qf(msg) abort dict
    call setqflist([a:msg], 'a')
  endfunction

  " clear {{{4
  function! s:clear_loc() abort dict
    call setloclist(self.winnr, [])
  endfunction
  function! s:clear_qf() abort dict
    call setqflist([])
  endfunction

  " log {{{4
  function! s:log(msg) abort dict
    let data = { 'text': a:msg }
    try
      throw "dummy"
    catch /.*/
      let bt = lh#exception#callstack(v:throwpoint)
      if len(bt) > 1
        let data.filename = bt[1].script
        let data.lnum     = bt[1].pos
      endif
    endtry
    call self._add(data)
  endfunction

  " reset {{{4
  function! s:reset() dict abort
    call self.clear()
    call self.open()
    return self
  endfunction

  " register methods {{{4
  let log.open  = function('s:open')
  let log._add  = function('s:add_'.a:kind)
  let log.clear = function('s:clear_'.a:kind)
  let log.log   = function('s:log')
  let log.reset = function('s:reset')

  " open the window {{{4
  call log.reset()
  return log
endfunction

" Function: lh#log#none() {{{3
" @return a log object that does nothing
function! lh#log#none() abort
  let log = {}
  function! log.log(...) dict
  endfunction
  function! log.reset() dict
    return self
  endfunction
  return log
endfunction
"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
