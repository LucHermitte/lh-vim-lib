"=============================================================================
" File:         autoload/lh/let.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      4.0.0
let s:k_version = 4000
" Created:      10th Sep 2012
" Last Update:  08th Sep 2016
"------------------------------------------------------------------------
" Description:
"       Defines a command :LetIfUndef that sets a variable if undefined
"------------------------------------------------------------------------
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#let#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#let#verbose(...)
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

function! lh#let#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
"
" # Let* {{{2
" Function: s:BuildPublicVariableName(var) {{{3
function! s:BuildPublicVariableName(var)
  if a:var !~ '^[wbptg]:'
    throw "Invalid variable name `".a:var."`: It should be scoped like in g:foobar"
  elseif a:var =~ '^p:'
    " It's a p:roject variable
    let var = substitute(a:var, '^p:', lh#project#crt_bufvar_name().".variables.", '')
  else
    let var = a:var
  endif
  return var
endfunction

" Function: s:BuildPublicVariableNameAndValue(string|var, value) {{{3
function! s:BuildPublicVariableNameAndValue(...)
  if len(a:000) == 1
    let [all, var, value ; dummy] = matchlist(a:1, '^\v(\S{-})%(\s*\=\s*|\s+)(.*)')
    let value = string(eval(value))
  else
    let var = a:1
    let value = string(a:2)
  endif
  let var = s:BuildPublicVariableName(var)
  return [var, value]
endfunction

" Function: lh#let#if_undef(var, value) {{{3
" Syntax used to directly call the function
" @param[in] var
" @param[in] value
" Syntax use by :LetIfUndef
" @param[in] string: 'var = value'
function! s:LetIfUndef(var, value) abort " {{{4
    let [all, dict, key ; dummy] = matchlist(a:var, '^\v(.{-})%(\.([^.]+))=$')
    call s:Verbose('%1 --> dict=%2 --- key=%3', a:var, dict, key)
    " echomsg a:var." --> dict=".dict." --- key=".key
    if !empty(key)
      " Dictionaries
      let dict2 = s:LetIfUndef(dict, string({}))
      if !has_key(dict2, key)
        let dict2[key] = type(a:value) == type(function('has')) ? (a:value) : eval(a:value)
        call s:Verbose("let %1.%2 = %3", dict, key, dict2[key])
      endif
      return dict2[key]
    else
      " other variables
      if !exists(a:var)
        let {a:var} = type(a:value) == type(function('has')) ? (a:value) : eval(a:value)
        call s:Verbose("let %1 = %2", a:var, {a:var})
      endif
      return {a:var}
    endif
endfunction

function! lh#let#if_undef(...) abort " {{{4
  call s:Verbose('let_if_undef(%1)', a:000)
  try
    let [var,value] = call('s:BuildPublicVariableNameAndValue', a:000)
    return s:LetIfUndef(var, value)
  catch /.*/
    echoerr "Cannot set ".string(a:000).": ".(v:exception .' @ '. v:throwpoint)
  endtry
endfunction

" Function: lh#let#to(var, value) {{{3
" Syntax used to directly call the function
" @param[in] var
" @param[in] value
" Syntax use by :LetIfUndef
" @param[in] string: 'var = value'
" Unline lh#let#if_undef, always reset the variable value!
" @since v4.0.0
function! s:LetTo(var, value) abort " {{{4
  " Here, project variables have already been resolved.
  let [all, dict, key ; dummy] = matchlist(a:var, '^\v(.{-})%(\.([^.]+))=$')
  " echomsg a:var." --> dict=".dict." --- key=".key
  if !empty(key)
    " Dictionaries
    let dict2 = s:LetIfUndef(dict, string({})) " Don't override the dict w/ s:LetTo()!
    let dict2[key] = type(a:value) == type(function('has')) ? (a:value) : eval(a:value)
    call s:Verbose("let %1.%2 = %3", dict, key, dict2[key])
    return dict2[key]
  else
    " other variables
    let {a:var} = type(a:value) == type(function('has')) ? (a:value) : eval(a:value)
    call s:Verbose("let %1 = %2", a:var, {a:var})
    return {a:var}
  endif
endfunction

function! lh#let#to(...) abort " {{{4
  try
    let [var,value] = call('s:BuildPublicVariableNameAndValue', a:000)
    return s:LetTo(var, value)
  catch /.*/
    echoerr "Cannot set ".string(a:000).": ".(v:exception .' @ '. v:throwpoint)
  endtry
endfunction

" Function: lh#let#unlet(var) {{{3
function! s:Unlet(var) abort " {{{4
  " Here, project variables have already been resolved.
  let [all, dict, key ; dummy] = matchlist(a:var, '^\v(.{-})%(\.([^.]+))=$')
  " echomsg a:var." --> dict=".dict." --- key=".key
  if !empty(key)
    " Dictionaries
    if !has_key(dict, key)
      return s:Unlet(dict[key])
    endif
    let dict2 = s:LetIfUndef(dict, string({})) " Don't override the dict w/ s:LetTo()!
    let dict2[key] = type(a:value) == type(function('has')) ? (a:value) : eval(a:value)
    call s:Verbose("let %1.%2 = %3", dict, key, dict2[key])
    return dict2[key]
  else
    " other variables
    unlet {a:var}
    call s:Verbose("unlet %1", a:var)
    return {a:var}
  endif
endfunction

function! lh#let#unlet(var) abort " {{{4
  try
    let var = s:BuildPublicVariableName(a:var)
    " The following doesn't work with dictionaries
    " unlet {var}
    exe 'unlet '.var
    call s:Verbose("unlet %1", var)
  catch /.*/
    echoerr "Cannot unset ".a:var.": ".(v:exception .' @ '. v:throwpoint)
  endtry
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
" # PushOptions {{{2
"
" Function: lh#let#_push_options(variable, ...) {{{3
function! lh#let#_push_options(variable, ...) abort
  let var = lh#let#if_undef(a:variable, [])
  for val in a:000
    call lh#list#push_if_new(var, val)
  endfor
  return var
endfunction

" Function: lh#let#_pop_options(variable, ...) {{{3
function! lh#let#_pop_options(variable, ...) abort
  let options = '\v^'.join(a:000, '|').'$'
  return filter(eval(a:variable), 'v:val !~ options')
endfunction

" Function: lh#let#_list_all_list_variables_in_scope(scope) {{{3
function! lh#let#_list_all_list_variables_in_scope(scope) abort
  let vars = map(keys({a:scope}), 'a:scope.v:val')
  " Keep only lists and dictionaries
  call filter(vars, 'type({v:val}) == type([]) || type({v:val}) == type({})')
  return vars
endfunction

" Function: lh#let#_list_variables(lead) {{{3
function! lh#let#_list_variables(lead) abort
  if empty(a:lead)
    " No variable specified yet
    let vars
          \ = lh#let#_list_all_list_variables_in_scope('g:')
          \ + lh#let#_list_all_list_variables_in_scope('b:')
          \ + lh#let#_list_all_list_variables_in_scope('w:')
          \ + lh#let#_list_all_list_variables_in_scope('t:')
  elseif stridx(a:lead, '.') >= 0
    " Dictionary
    let [all, dict, key ; trail] = matchlist(a:lead, '\v(.*)\.(.*)')
    let vars = keys({dict})
    call filter(vars, 'type({dict}[v:val]) == type([]) || type({dict}[v:val]) == type({})')
    call map(vars, 'v:val. (type({dict}[v:val])==type({})?".":"")')
    call map(vars, 'dict.".".v:val')
    return vars
  else
    " Simple variables
    if         (len(a:lead) == 1 && a:lead    =~ '[gbwt]')
          \ || (len(a:lead) > 1  && a:lead[1] == ':')
      let scope = a:lead[0]
      let filter_scope = ''
    else
      let scope = 'g'
      let filter_scope = 'g:'
    endif
    let vars = lh#let#_list_all_list_variables_in_scope(scope.':')
    call filter(vars, 'v:val =~ "^".filter_scope.a:lead')
  endif
  " Add dot to identified dictionaries
  call map(vars, 'v:val. (type({v:val})==type({})?".":"")')
  return vars
endfunction

" Function: lh#let#_push_options_complete(ArgLead, CmdLine, CursorPos) {{{3
call lh#let#if_undef('g:acceptable_options_for', {})

function! lh#let#_push_options_complete(ArgLead, CmdLine, CursorPos) abort
  let tmp = substitute(a:CmdLine, '\s*\S*', 'Z', 'g')
  let pos = strlen(tmp)

  call s:Verbose('complete(lead="%1", cmdline="%2", cursorpos=%3)', a:ArgLead, a:CmdLine, a:CursorPos)

  if     2 == pos
    " First argument: a variable name
    return lh#let#_list_variables(a:ArgLead)
  elseif pos >= 3
    " Doesn't handle 'foo\ bar', but we don't need this to fetch a variable
    " name
    let args = split(a:CmdLine, '\s\+')
    let varname = args[1]
    call s:Verbose('complete: varname=%1', varname)
    " Other arguments: acceptable values
    let acceptable_values = get(g:acceptable_options_for, varname, [])
    let crt_val = '\v^'.join(exists(varname)? eval(varname) : [], '|').'$'
    let acceptable_values = filter(copy(acceptable_values), 'v:val !~ crt_val')
    return acceptable_values
  endif
endfunction

" Function: lh#let#_pop_options_complete(ArgLead, CmdLine, CursorPos) {{{3
function! lh#let#_pop_options_complete(ArgLead, CmdLine, CursorPos) abort
  let tmp = substitute(a:CmdLine, '\s*\S*', 'Z', 'g')
  let pos = strlen(tmp)

  call s:Verbose('complete(lead="%1", cmdline="%2", cursorpos=%3)', a:ArgLead, a:CmdLine, a:CursorPos)

  if     2 == pos
    " First argument: a variable name
    return lh#let#_list_variables(a:ArgLead)
  elseif pos >= 3
    " Doesn't handle 'foo\ bar', but we don't need this to fetch a variable
    " name
    let args = split(a:CmdLine, '\s\+')
    let varname = args[1]
    call s:Verbose('complete: varname=%1', varname)
    return eval(varname)

    " Other arguments: acceptable values
    let acceptable_values = get(g:acceptable_options_for, varname, [])
    let crt_val = '\v^'.join(exists(varname)? eval(varname) : [], '|').'$'
    let acceptable_values = filter(copy(acceptable_values), 'v:val !~ crt_val')
    return acceptable_values
  endif
endfunction

"------------------------------------------------------------------------
" }}}1
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
