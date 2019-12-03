"=============================================================================
" File:         autoload/lh/dict.vim                              {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      4.7.1
let s:k_version = '40701'
" Created:      26th Nov 2015
" Last Update:  03rd Dec 2019
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

" Function: lh#dict#need_ref_on(root, keys [, last_default]) {{{3
" @since Version 4.5.0
" @return the element at the key sequence. subkeys are added on the fly
" @note it'll be best for last_default to be either a dictionary or a
" list, otherwise, the result won't be a reference
function! lh#dict#need_ref_on(root, keys, ...) abort
  let keys = type(a:keys) == type([]) ? a:keys : split(a:keys, '\.')
  let last_default = get(a:, 1, {})
  let d = a:root
  for k in keys[:-2]
    if !has_key(d, k)
      let d[k] = {}
    endif
    let dk = d[k]
    unlet d
    let d = dk
    unlet dk
    call lh#assert#type(d).is({})
  endfor
  if !has_key(d, keys[-1])
    let d[keys[-1]] = last_default
  endif
  return d[keys[-1]]
endfunction

"------------------------------------------------------------------------
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
    if !empty(a:key) && a:key[0] == '['
      let [all, key, subkey ; dummy] = matchlist(a:key, '^\v\[(.{-})\]\.=(.+)=$')
    else
      let [all, key, subkey ; dummy] = matchlist(a:key, '^\v([^.[]{1,})\.=%((.+))=$')
    endif
    call s:Verbose('%1 --> key=%2 --- subkey=%3', a:key, key, subkey)
    if !lh#type#is_dict(a:dst) || !has_key(a:dst, key)
      call s:Verbose('Return default value: Key %1 not found in %2.', key, a:dst)
      return get(a:, 1, s:k_unset)
    endif
    if empty(subkey)
      return a:dst[key]
    else
      return call('lh#dict#get_composed', [a:dst[key], subkey]+a:000)
    endif
  catch /.*/
    echoerr "Cannot get ".a:key." in ".string(a:dst).": ".(v:exception .' @ '. v:throwpoint)
  endtry
endfunction

" Function: lh#dict#print_as_tree(dict, [, indent]) {{{3
" @since version 4.7.1
function! lh#dict#print_as_tree(V, ...) abort
  let indent = get(a:, 1, 0)
  if type(a:V) == type([])
    let res = ['['] + s:recurse_list(a:V, indent+4) + [repeat(' ', indent+4) . ']']
  elseif type(a:V) == type({})
    if lh#object#is_an_object(a:V)
      let res = [lh#object#to_string(a:V)]
    else
      let res = ['{'] + s:recurse_dict(a:V, indent+4) + [repeat(' ', indent+4) . '}']
    endif
  else
    let res = [string(a:V)]
  endif
  return indent == 0 ? join(res, "\n") : res
endfunction

function! s:recurse_list(list, indent) abort
  let res = []
  let lead = repeat(' ', a:indent) . '+- '
  let nb_digits = float2nr(ceil(log10(len(a:list))))
  for [k,l:V] in map(copy(a:list), {k0,v0 -> [k0,v0]})
    let sub_res = lh#dict#print_as_tree(l:V, a:indent+4)
    let sub_res[0] = printf('%s%'.nb_digits.'d -> %s', lead, k, sub_res[0])
    let res += sub_res
  endfor
  return res
endfunction

function! s:recurse_dict(dict, indent) abort
  let res = []
  let lead = repeat(' ', a:indent) . '+- '
  let max_length = max(map(keys(a:dict), {k,V -> strdisplaywidth(string(V))}))

  for [k,l:V] in items(a:dict)
    let start = lead . string(k). repeat(' ', max_length- strdisplaywidth(string(k))+1).'= '
    let sub_res = lh#dict#print_as_tree(l:V, a:indent+4)
    let sub_res[0] = start . sub_res[0]
    let res += sub_res
  endfor
  return res
endfunction

" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
