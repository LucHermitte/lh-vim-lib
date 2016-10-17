"=============================================================================
" File:         autoload/lh/file.vim                              {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0
let s:k_version = '4000'
" Created:      01st Jun 2016
" Last Update:  17th Oct 2016
"------------------------------------------------------------------------
" Description:
"       File related functions
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#file#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#file#verbose(...)
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

function! lh#file#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" # file stamps {{{2
" Function: lh#file#stamp(filename [, update_callback]) {{{3
function! lh#file#stamp(filename, ...) abort " {{{4
  if !filereadable(a:filename)
    throw "Cannot access to " . a:filename
  endif
  let res = { 'filename': a:filename, 'stamp': getftime(a:filename) }

  let res.check_up_to_date = function(s:getSNR('check_up_to_date'))

  " return {{{4
  return res
endfunction

function! s:check_up_to_date() dict abort "{{{4
  let new_stamp = getftime(self.filename)
  let must_update = self.stamp < new_stamp
  call s:Verbose('Check if file %1 data is up-to-date at %3 -- last update: %2 --> %4!',
          \ self.filename, self.stamp, new_stamp, must_update ? 'YES' : 'NO')
  if must_update
    if has_key(self, '_update_callback')
      call call(self.update_callback, self)
    endif
    let self.stamp = new_stamp
    call s:Verbose('Time stamp for %1 updated to %2', self.filename, self.stamp)
  endif
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

" s:getSNR([func_name]) {{{2
function! s:getSNR(...)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
