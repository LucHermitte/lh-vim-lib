"=============================================================================
" File:         autoload/lh/option.vim                                    {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      4.0.0
let s:k_version = 4000
" Created:      24th Jul 2004
" Last Update:  24th Nov 2016
"------------------------------------------------------------------------
" Description:
"       Defines the global function lh#option#get().
"       Aimed at (ft)plugin writers.
"
" History: {{{2
"       v4.0.0
"       (*) ENH: lh#option#get() functions evolve to support new `p:` project
"           variables
"       (*) BUG: `lh#option#getbufvar()` emulation for older vim version was failing.
"       (*) BUG: Keep previous value for `g:lh#option#unset`
"       (*) ENH: Extend `#to_string(#unset())` to be informative
"       (*) ENH: Extend `lh#option#get()` to take a list of names
"       (*) ENH: Add `lh#option#exists_in_buf()`
"       v3.6.1
"       (*) ENH: Use new logging framework
"       v3.2.12
"       (*) New functions: lh#option#getbufvar(), lh#option#is_set(),
"           lh#option#unset()
"       v3.2.11
"       (*) New function and variable: lh#option#is_unset() and
"           g:lh#option#unset
"       (*) Now lh#option#get() {default} parameter is optional and has the
"           default value g:lh#option#unset
"       v3.1.13
"       (*) lh#option#add() don't choke when option value contains characters that
"           means something in a regex context
"       v3.1.5
"       (*) lh#option#get() supports var names from dictionaries like "g:foo.bar"
"       v3.0.0
"       (*) GPLv3
"       v2.0.6
"       (*) lh#option#add() add values to a vim list |option|
"       v2.0.5
"       (*) lh#option#get_non_empty() manages Lists and Dictionaries
"       (*) lh#option#get() doesn't test emptyness anymore
"       v2.0.0
"       (*) Code moved from {rtp}/macros/
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim

"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#option#version()
  return s:k_version
endfunction

" # Debug {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#option#verbose(...)
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

function! lh#option#debug(expr) abort
  return eval(a:expr)
endfunction

" # Tools {{{2
" s:getSNR([func_name]) {{{3
function! s:getSNR(...)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

"=============================================================================
" ## Functions {{{1
" # Public {{{2
let s:has_default_in_getbufvar = lh#has#default_in_getbufvar()

" Function: lh#option#unset() {{{3
function! s:unset_to_string(...) dict abort
  " call assert_true(lh#option#is_unset(self))
  return '{(unset)}'
endfunction
let g:lh#option#unset = get(g:, 'lh#option#unset', lh#object#make_top_type({}))
let g:lh#option#unset._to_string = function(s:getSNR('unset_to_string'))

function! lh#option#unset() abort
  return g:lh#option#unset
endfunction


" Function: lh#option#is_unset(expr) {{{3
function! lh#option#is_unset(expr) abort
  return a:expr is g:lh#option#unset
endfunction

" Function: lh#option#is_set(expr) {{{3
function! lh#option#is_set(expr) abort
  return ! (a:expr is g:lh#option#unset)
endfunction

" Function: lh#option#get(names [, default [, scope]])            {{{3
" @return b:{name} if it exists, or g:{name} if it exists, or {default}
" otherwise
" The order of the variables checked can be specified through the optional
" argument {scope}
function! lh#option#get(names,...) abort
  let sScopes = (a:0 == 2) ? a:2 : 'bpg'
  let lScopes = split(sScopes, '\zs')
  let names = type(a:names) == type([]) ? a:names : [a:names]
  for scope in lScopes
    for name in names
      if scope == 'p'
        let r = lh#project#_get(name)
        if lh#option#is_set(r)
          call s:Verbose('p:%1 found -> %2', name, r)
          if lh#ref#is_bound(r)
            return r.resolve()
          else
            return r
          endif
        endif
      elseif exists(scope.':'.name)
        " \ && (0 != strlen({scope}:{name}))
        " This syntax doesn't work with dictionaries -> !exe
        " return {scope}:{name}
        exe 'let value='.scope.':'.name
        call s:Verbose('%1:%2 found -> %3', scope, name, value)
        if lh#ref#is_bound(value)
          return value.resolve()
        else
          return value
        endif
      endif
    endfor
  endfor
  return a:0 > 0 ? (a:1) : g:lh#option#unset
endfunction
function! lh#option#Get(names,default,...)
  let scope = (a:0 == 1) ? a:1 : 'bg'
  return lh#option#get(a:names, a:default, scope)
endfunction

" Function: lh#option#get_from_buf(bufid, name [, default [, scope]])            {{{3
" Works as lh#option#get(), except that b: scope is interpreted as from a
" specified buffer. This impacts b: and p: scopes.
" See lh#option#get() for more information
function! lh#option#get_from_buf(bufid, name,...) abort
  let scope = (a:0 == 2) ? a:2 : 'bpg'
  let name = a:name
  let i = 0
  while i != strlen(scope)
    if scope[i] == 'p'
      let r = lh#project#_get(a:name, a:bufid)
      if lh#option#is_set(r)
        call s:Verbose('p:%1 found -> %2', a:name, r)
        if lh#ref#is_bound(r)
          return r.resolve()
        else
          return r
        endif
      endif
    elseif scope[i] == 'b'
      " If the variable is a dictionary, getbufvar won't be able to return
      " anything but the first level => need to split
      let [all, key, subkey; dummy] = matchlist(name, '\v^([^.]+)%(\.(.*))=$')
      let front = lh#option#getbufvar(a:bufid, key)
      if lh#option#is_set(front)
        if !empty(subkey)
          let value = lh#dict#get_composed(front, subkey)
          if lh#option#is_set(value)
            if lh#ref#is_bound(value)
              return value.resolve()
            else
              return value
            endif
          endif
        else
          return front
        endif
      endif
    elseif scope[i] == 'g' && exists(scope[i].':'.name)
      " \ && (0 != strlen({scope[i]}:{name}))
      " This syntax doesn't work with dictionaries -> !exe
      " return {scope[i]}:{name}
      exe 'let value='.scope[i].':'.name
      call s:Verbose('%1:%2 found -> %3', scope[i], a:name, value)
      if lh#ref#is_bound(value)
        return value.resolve()
      else
        return value
      endif
    endif
    let i += 1
  endwhile
  return a:0 > 0 ? (a:1) : g:lh#option#unset
endfunction

" Function: s:IsEmpty(variable) {{{3
function! s:IsEmpty(variable)
  if     type(a:variable) == type('string') | return 0 == strlen(a:variable)
  elseif type(a:variable) == type(42)       | return 0 == a:variable
  elseif type(a:variable) == type([])       | return 0 == len(a:variable)
  elseif type(a:variable) == type({})       | return 0 == len(a:variable)
  else                                      | return false
  endif
endfunction

" Function: lh#option#get_non_empty(name [, default [, scope]])  {{{3
" @return of b:{name}, g:{name}, or {default} the first which exists and is not empty
" The order of the variables checked can be specified through the optional
" argument {scope}
function! lh#option#get_non_empty(name,...)
  let scope = (a:0 == 2) ? a:2 : 'bg'
  let name = a:name
  let i = 0
  while i != strlen(scope)
    if scope[i] == 'p'
      let r = lh#project#_get(a:name)
      if lh#option#is_set(r)
        call s:Verbose('p:%1 found -> %2', a:name, r)
        return r
      endif
    endif
    if exists(scope[i].':'.name)
      exe 'let value='.scope[i].':'.name
      call s:Verbose('%1:%2 found -> %3', scope[i], a:name, value)
      if !s:IsEmpty({scope[i]}:{name})
        " return {scope[i]}:{name}
        if lh#ref#is_bound(value)
          return value.resolve()
        else
          return value
        endif
      endif
    endif
    let i += 1
  endwhile
  return a:0 > 0 ? (a:1) : g:lh#option#unset
endfunction
function! lh#option#GetNonEmpty(name,default,...)
  let scope = (a:0 == 1) ? a:1 : 'bg'
  return lh#option#get_non_empty(a:name, a:default, scope)
endfunction

" Function: lh#option#exists_in_buf(bufid, varname) {{{3
" Return exists(varname) in bufid context
function! lh#option#exists_in_buf(bufid, varname) abort
  let bufvars = getbufvar(a:bufid, '')
  return has_key(bufvars, a:varname)
endfunction

" Function: lh#option#getbufvar(expr, name [, default])            {{{3
" This is an encapsulation of
"   getbufvar(expr, name, g:lh#option#unset)
" This function ensures g:lh#option#unset is known (the lazy-loading mecanism
" of autoload plugins doesn't apply to variables, only to functions)
if s:has_default_in_getbufvar
  function! lh#option#getbufvar(buf, name,...)
    let def = a:0 == 0 ? g:lh#option#unset : a:1
    return getbufvar(a:buf, a:name, def)
  endfunction
else
  function! lh#option#getbufvar(buf, name,...)
    let res = getbufvar(a:buf, a:name)
    if (type(res) == type('')) && empty(res)
      " Check whether this is really empty, or whether the variable doesn't
      " exist
      try
        let b = bufnr('%')
        exe 'buf '.a:buf
        if !exists('b:'.a:name)
          unlet res
          let res = a:0 == 0 ? g:lh#option#unset : a:1
        endif
      finally
        exe 'buf '.b
      endtry
    endif
    return res
  endfunction
endif

" Function: lh#option#getbufglobvar(expr, name [, default]) {{{3
if s:has_default_in_getbufvar
  function! lh#option#getbufglobvar(expr, name, ...) abort
    return getbufvar(a:expr, a:name, get(g:, a:name, g:lh#option#unset))

    let res = call('lh#option#getbufvar', [a:expr, a:name, g:lh#option#unset])
    if lh#option#is_unset(res)
      let def = a:0 == 0 ? g:lh#option#unset : a:1
      return get(g:, a:name, def)
    endif
    return res
  endfunction
else
  function! lh#option#getbufglobvar(expr, name, ...) abort
    return lh#option#getbufvar(a:expr, a:name, get(g:, a:name, g:lh#option#unset))
  endfunction
endif

" Function: lh#option#add(name, values)                       {{{3
" Add fields to a vim option.
" @param values list of values to add
" @example let lh#option#add('l:tags', ['.tags'])
function! lh#option#add(name,values)
  let values = type(a:values) == type([])
        \ ? copy(a:values)
        \ : [a:values]
  let old = split(eval('&'.a:name), ',')
  let new = filter(values, 'match(old, escape(v:val, "\\*.")) < 0')
  let val = join(old+new, ',')
  exe 'let &'.a:name.' = val'
endfunction

" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
