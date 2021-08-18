"=============================================================================
" File:         autoload/lh/ft/option.vim                        {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/master/tree/License.md>
" Version:      5.3.3.
let s:k_version = 533
" Created:      05th Oct 2009
" Last Update:  18th Aug 2021
"------------------------------------------------------------------------
" Description:
" Notes:
" Library initially in lh-dev, but moved to lh-vim-lib
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------

" ## Misc Functions     {{{1
" # Version {{{2
function! lh#ft#option#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#ft#option#verbose(...)
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

function! lh#ft#option#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## Exported functions {{{1

" Function: lh#ft#option#get(name, filetype[, default [, scope]])  {{{2
" @return which ever exists first among: b:{name}_{ft}, or g:{name}_{ft}, or
" b:{name}, or g:{name}. {default} is returned if none exists.
" @note filetype inheritance is supported.
" The order of the scopes for the variables checked can be specified through
" the optional argument {scope}
let s:k_unset = lh#option#unset()
function! lh#ft#option#get(name, ft,...) abort
  let fts = lh#ft#option#inherited_filetypes(a:ft)
  call map(fts, 'v:val."_"')
  let fts += [ '']
  let scope = (a:0 == 2) ? a:2 : 'bpg'

  for ft in fts
    let r = lh#option#get(ft.a:name, s:k_unset, scope)
    if lh#option#is_set(r)
      return r
    endif
    unlet r
  endfor
  return a:0 > 0 ? a:1 : s:k_unset
endfunction

" Function: lh#ft#option#get_postfixed(name, filetype, [default [, scope]])  {{{2
" @return which ever exists first among: b:{name}_{ft}, or g:{name}_{ft}, or
" b:{name}, or g:{name}. {default} is returned if none exists.
" @note filetype inheritance is supported.
" The order of the scopes for the variables checked can be specified through
" the optional argument {scope}
function! lh#ft#option#get_postfixed(name, ft,...) abort
  let fts = lh#ft#option#inherited_filetypes(a:ft)
  call map(fts, '"_".v:val')
  let fts += [ '']
  let scope = (a:0 == 2) ? a:2 : 'bpg'

  for ft in fts
    let r = lh#option#get(a:name.ft, s:k_unset, scope)
    if lh#option#is_set(r)
      return r
    endif
    unlet r
  endfor
  return a:0 > 0 ? a:1 : s:k_unset
endfunction

" Function: lh#ft#option#get_all(varname [, ft]) {{{2
" Unlike lh#ft#option#get(), this time, we gather every possible value, but
" keeping the most specialized value
" This only works to gather dictionaries scatered in many specialized
" variables.
function! lh#ft#option#get_all(varname, ...) abort
  let ft = get(a:, '1', &ft)
  let fts = map(lh#ft#option#inherited_filetypes(ft), 'v:val."_"') + ['']
  call map(fts, 'v:val.a:varname')
  let scopes = ['b', 'p', 'g']
  let res = {}
  let rs = []
  for s in scopes
    let scope_res = map(copy(fts), 'lh#option#get(v:val, s:k_unset, s)')
    call filter(scope_res, 'lh#option#is_set(v:val)')
    call s:Verbose('%1:%2 -> %3', s, fts, scope_res)
    let rs += scope_res
  endfor
  " The specialized results are sorted from most specialized to more generic
  for r in rs
    call extend(res, r, 'keep')
  endfor
  return res
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

" # List of inherited properties between languages {{{2
" Function: lh#ft#option#inherited_filetypes(fts) {{{3
" - todo, this may required to be specific to each property considered
function! lh#ft#option#inherited_filetypes(fts) abort
  let res = []
  let lFts = split(a:fts, ',')
  let aux = map(copy(lFts), '[v:val] + lh#ft#option#inherited_filetypes(lh#option#get(v:val."_inherits", ""))')
  call map(aux, 'extend(res, v:val)')
  return res
endfunction

call lh#let#if_undef('g:cpp_inherits', 'c')

" }}}1
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
