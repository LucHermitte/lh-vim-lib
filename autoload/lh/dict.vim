"=============================================================================
" File:         autoload/lh/dict.vim                              {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      4.0.0
let s:k_version = '40000'
" Created:      26th Nov 2015
" Last Update:  09th Mar 2017
"------------------------------------------------------------------------
" Description:
"       |Dict| helper functions
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
let s:k_unset = lh#option#unset()
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#dict#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#dict#verbose(...)
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

function! lh#dict#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## Exported functions {{{1
" # Dictionary modification {{{2
" Function: lh#dict#add_new(dst, src) {{{3
function! lh#dict#add_new(dst, src) abort
  return extend(a:dst, a:src, 'keep')
  " for [k,v] in items(a:src)
    " if !has_key(a:dst, k)
      " let a:dst[k] = v
    " endif
  " endfor
  " return a:dst
endfunction

" Function: lh#dict#let(dict, key, value) {{{3
function! lh#dict#let(dict, key, value) abort
  let [all, key, subkey ; dummy] = matchlist(a:key, '^\v(.{-})%(\.(.+))=$')
  call s:Verbose('%1 --> key=%2 --- subkey=%3', a:key, key, subkey)
  if empty(subkey)
    let a:dict[key] = a:value
  else
    if !has_key(a:dict, key)
      let a:dict[key] = {}
    elseif type(a:dict[key]) != type({})
      unlet a:dict[key]
      let a:dict[key] = {}
    endif
    call lh#dict#let(a:dict[key], subkey, a:value)
  endif
  return a:dict[key]
endfunction
" # Dictionary in read-only {{{2

" Function: lh#dict#key(one_key_dict) {{{3
function! lh#dict#key(one_key_dict) abort
  let it = items(a:one_key_dict)
  if len(it) != 1
    throw "[expect] The dictionary hasn't one key exactly (".string(a:one_key_dict).")"
  endif
  return it[0]
endfunction

" Function: lh#dict#subset(dict, keys) {{{3
function! lh#dict#subset(dict, keys) abort
  return filter(copy(a:dict), 'index(a:keys, v:key) >= 0')
endfunction

" Function: lh#dict#get_composed(dst, key[, def]) {{{3
" @since v4.0.0
function! lh#dict#get_composed(dst, key, ...) abort
  try
    let [all, key, subkey ; dummy] = matchlist(a:key, '^\v(.{-})%(\.(.+))=$')
    call s:Verbose('%1 --> key=%2 --- subkey=%3', a:key, key, subkey)
    if !lh#type#is_dict(a:dst) || !has_key(a:dst, key)
      call s:Verbose('Return default value: Key %1 not found in %2.', key, a:dst)
      return get(a:, 1, s:k_unset)
    endif
    if empty(subkey)
      return a:dst[a:key]
    else
      return call('lh#dict#get_composed', [a:dst[key], subkey]+a:000)
    endif
  catch /.*/
    echoerr "Cannot get ".a:key." in ".string(a:dst).": ".(v:exception .' @ '. v:throwpoint)
  endtry
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
