"=============================================================================
" File:         autoload/lh/object.vim                            {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0.
let s:k_version = '400'
" Created:      12th Sep 2016
" Last Update:  08th Mar 2017
"------------------------------------------------------------------------
" Description:
"       OO functions and helpers
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
function! lh#object#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#object#verbose(...)
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

function! lh#object#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Top Type {{{1
" Used to bring a specialized to#string function that doesn't display methods

" # Entry point: #make_top_type() {{{2
" Function: lh#object#make_top_type(params) {{{3
function! lh#object#make_top_type(params) abort
  let res = copy(a:params)
  let res.__lhvl_oo_type = function(s:getSNR('lhvl_oo_type'))
  let res._to_string     = function(s:getSNR('to_string'))
  return res
endfunction

" # Methods definitions {{{2
" Function: s:lhvl_oo_type() dict {{{3
function! s:lhvl_oo_type() dict
  return ''
endfunction

" Function: s:to_string() dict {{{3
let s:k_fun_type = type(function('type'))
function! s:to_string(...) dict abort
  let handled_list = a:0 > 0 ? a:1 : []
  let attributes = filter(copy(self), 'type(v:val) != s:k_fun_type')
  " TODO: recursivelly call to_string() on dict/list elements, unless they
  " are circular references
  if s:verbose > 0
    let methods = filter(copy(self), 'type(v:val) == s:k_fun_type')
    call extend(attributes, { '%%methods%%': sort(keys(methods))})
  endif
  return lh#object#_to_string(attributes, handled_list)
endfunction

" ## Exported functions {{{1
" # Type Information {{{2
" Function: lh#object#is_an_object(var) {{{3
function! lh#object#is_an_object(var) abort
  return has_key(a:var, '__lhvl_oo_type')
endfunction

" # Stringification  {{{2
" Function: lh#object#to_string(object) {{{3
function! lh#object#to_string(object) abort
  return lh#object#_to_string(a:object, [])
endfunction

" # Reflection       {{{2
" Function: lh#object#inject(object, method_name, function_name, snr) {{{3
function! lh#object#inject(object, method_name, function_name, snr) abort
  if type(a:snr) == type('')
    let snr = lh#askvim#scriptid(a:snr)
  else
    let snr = a:snr
  endif
  let a:object[a:method_name] = function('<SNR>'.snr.'_'.a:function_name)
endfunction

" Function: lh#object#inject_methods(object, snr, ...) {{{3
function! lh#object#inject_methods(object, snr, ...) abort
  if type(a:snr) == type('')
    let snr = lh#askvim#scriptid(a:snr)
  else
    let snr = a:snr
  endif
  call lh#assert#value(a:0).is_gt(0, "At least one method name is expected")
  let method_names = lh#type#is_list(a:1) ? a:1 : a:000
  let methods = {}
  call map(copy(method_names), 'extend(methods, { v:val : function("<SNR>".snr."_".v:val) })')
  return extend(a:object, methods)
endfunction
"------------------------------------------------------------------------
" ## Internal functions {{{1
" # Stringification {{{2
" Function: lh#object#_to_string(object, handled_list) {{{3
function! lh#object#_to_string(object, handled_list) abort
  if     type(a:object) == type([])
    if s:is_already_handled(a:object, a:handled_list) | return '[...]' | endif
    call extend(a:handled_list, [a:object])
    let res = '['. join(map(copy(a:object), 'lh#object#_to_string(v:val, a:handled_list)'), ', ') .']'
    return res
  elseif type(a:object) == type({})
    if s:is_already_handled(a:object, a:handled_list) | return '{...}' | endif
    call extend(a:handled_list, [a:object])
    if lh#object#is_an_object(a:object)
      return a:object._to_string(a:handled_list)
    elseif has_key(a:object, 'to_string')
      " Let's hope there is no recursion
      return a:object.to_string()
    elseif has_key(a:object, '_to_string')
      " Let's hope there is no recursion
      return a:object._to_string()
    else
      let res = '{'. join(map(items(a:object), 'string(v:val[0]).": ".lh#object#_to_string(v:val[1], a:handled_list)'), ', ') .'}'
      return res
    endif
  elseif type(a:object) == type('') || type(a:object) == type(function('has'))
    return string(a:object)
  else
    return a:object
  endif
endfunction

" Function: s:is_already_handled(object, handled_list) abort {{{3
function! s:is_already_handled(object, handled_list) abort
  return lh#list#contain_entity(a:handled_list, a:object)
endfunction

" # Misc {{{2
" s:getSNR([func_name]) {{{3
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
