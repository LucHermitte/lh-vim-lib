"=============================================================================
" File:         autoload/lh/tags/stack.vim                        {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/blob/master/License.md>
" Version:      4.6.0.
let s:k_version = '460'
" Created:      17th Aug 2018
" Last Update:  17th Aug 2018
"------------------------------------------------------------------------
" Description:
"       Defines helper function to push forged tags in the tag stack.
"
"------------------------------------------------------------------------
" History:
"       v4.6.0  Moved from lh-tags
" TODO:         «missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#tags#stack#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#tags#stack#verbose(...)
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

function! lh#tags#stack#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

" Function: lh#tags#stack#push(tagentry) {{{2
" @param {tagentry} tag entry as returned by |taglist()|,
" expected keys:
" - cmd
" - filename
" @pre s:nb_forged_entries < 1 million
let s:k_nb_digits      = 6 " works with ~1 million jumps. Should be enough
let s:k_tag_name_fmt__ = '__jump_tag__%0'.s:k_nb_digits.'d'

function! lh#tags#stack#push(tagentry) abort
  call s:Verbose("Forging entry in tagstack for %1", a:tagentry)
  call lh#assert#true(s:nb_forged_entries < eval(repeat('9', s:k_nb_digits)))
  call lh#assert#value(a:tagentry).has_key('filename').has_key('cmd')
  let filename = fnamemodify(a:tagentry.filename, ':p')
  call lh#assert#value(filename).verifies('filereadable')

  let s:nb_forged_entries += 1
  let tag_name = printf(s:k_tag_name_fmt__, s:nb_forged_entries)
  let line     = tag_name . "\t" . filename . "\t" . (a:tagentry.cmd)

  if lh#has#writefile_append()
    call writefile([line], s:tags_jump, 'a')
  else
    call add(s:lines, line)
    call writefile(s:lines, s:tags_jump)
  endif

  if exists('&l:tags')
    exe 'setlocal tags+='.s:tags_jump
  endif

  return tag_name
endfunction

" Function: lh#tags#stack#jump(tagentry [cmd = 'tag']) {{{3
function! lh#tags#stack#jump(tagentry) abort
  let tag_name = lh#tags#stack#push(a:tagentry)
  call s:Verbose('Jumping to tag %1: %2', tag_name, a:tagentry)
  let cmd = get(a:, 1, 'tag')
  exe cmd.' '.tag_name
endfunction

"------------------------------------------------------------------------
" ## Internals          {{{1
" # Internal tmp tags file {{{2
if !exists('s:tags_jump')
  let s:tags_jump = tempname()
  exe 'setg tags+='.s:tags_jump

  let s:nb_forged_entries = 0
  if ! lh#has#writefile_append()
    let s:lines = []
  endif
endif

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
