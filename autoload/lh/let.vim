"=============================================================================
" File:         autoload/lh/let.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      4.6.4
let s:k_version = 40604
" Created:      10th Sep 2012
" Last Update:  29th Oct 2018
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
" Function: s:BuildPublicVariableName(var, hide_or_overwrite, must_keep_previous) {{{3
function! s:BuildPublicVariableName(var, hide_or_overwrite, must_keep_previous) abort
  if a:var !~ '\v^[wbptgP]:|[$&]'
    throw "Invalid variable name `".a:var."`: It should be scoped like in g:foobar"
  elseif a:var =~ '^P:'
    " P: -> It's either a project variable if there is a project, or a buffer
    " variable otherwise
    if lh#project#is_in_a_project()
      if a:must_keep_previous
        let l:Value = lh#project#crt().get(matchstr(a:var, '\v^p\&=:\zs.*'))
        if lh#option#is_set(l:Value)
          call s:Verbose('s:BuildPublicVariableName:       %1 is set!', l:Value)
          call s:Verbose("%1 is defined somewhere => no need to build its name, let's abort", a:var)
          return extend(copy(lh#option#unset()), {'_value': l:Value})
          " No need to check anything,
        endif
      endif
      let var = lh#project#_crt_var_name('p'.a:var[1:], a:hide_or_overwrite)
    elseif a:var =~ '^P:[&$]'
      throw "Options and environment variable names like `".a:var."` are not supported. Use `p:` or plain variables."
    else
      let var = 'b'.a:var[1:]
    endif
  elseif a:var =~ '\v^p:|^\&p:'
    " It's a p:roject variable, or a project option
    if a:must_keep_previous && lh#project#is_in_a_project()
      let l:Value = lh#project#crt().get(matchstr(a:var, '\v^p\&=:\zs.*'))
      if lh#option#is_set(l:Value)
        call s:Verbose("%1 is defined somewhere => no need to build its name, let's abort", a:var)
        return extend(copy(lh#option#unset()), {'_value': l:Value})
        " No need to check anything,
      endif
    endif
    let var = lh#project#_crt_var_name(a:var, a:hide_or_overwrite)
  else
    let var = a:var
  endif
  return var
endfunction

" Function: s:BuildPublicVariableNameAndValue(must_keep_previous ; string|var, value) {{{3
let s:k_hide_or_overwite = '--(hide|overwrite)'
function! s:BuildPublicVariableNameAndValue(must_keep_previous, ...) abort
  if len(a:000) == 1
    " Strip --overwrite/--hide option
    let [all, hide_or_overwrite, expr ; tail] = matchlist(a:1, '\v^%('.s:k_hide_or_overwite.'\s*)=(.*)$')
    " Analyse the expression
    if expr =~ '^p:&'
      " options need a special handling
      let [all, var, assign, value0 ; dummy] = matchlist(expr, '^\v(\S{-})\s*([+-]=\=)\s*(.*)')
      let l:Value = assign.value0
    else
      let [all, var, value0 ; dummy] = matchlist(expr, '^\v(\S{-})%(\s*\=\s*|\s+)(.*)')
      " string+eval loses references, and it doesn't seem required.

      " Handle comments and assign value, but this seems to mess with error
      " messages...
      try
        exe 'let l:Value = '.value0
      catch /.*/
        throw "Cannot assign `".string(value0)."`  into ".var.": ".v:exception
      endtry
      " The following
      "    " Simplified handling of comments
      "    :let value0 = substitute(value0, '\v^("[^"]*"|[^"])*\zs"[^"]*$', '', '')
      "    :let l:Value = eval(value0)
      " won't work with:
      "    :LetIfUndef g:c_import_pattern      '^#\s*include\s*["<]${module}\>'
    endif
  else
    let var               = a:1
    let l:Value           = a:2
    let hide_or_overwrite = get(a:, 3, '')
    " let value = string(a:2)
  endif
  let resvar = s:BuildPublicVariableName(var, hide_or_overwrite, a:must_keep_previous)
  return [resvar, l:Value]
endfunction

" Function: lh#let#if_undef(var, value) {{{3
" Syntax used to directly call the function
" @param[in] var
" @param[in] value
" Syntax use by :LetIfUndef
" @param[in] string: 'var = value'
function! s:LetIfUndef(var, value) abort " {{{4
    " let [all, dict, key, subscript ; dummy] = matchlist(a:var, '^\v(.{-})%(\.([^.]+))=$')
    let [all, dict, key, subscript ; dummy] = matchlist(a:var, '^\v(.{-})%(\.([^.]{-})%(\[(.{-})\])=)=$')
    call s:Verbose('%1 --> dict=%2 --- key=%3 --- subscript=%4', a:var, dict, key, subscript)
    if !empty(subscript)
      if subscript =~ '^\v\d+$'
        " Corner case found. Expect an already initialized array => don't
        " populated it on the fly yet
        call lh#assert#value({dict}).has_key(key)
        call lh#assert#type({dict}[key]).is([])
        return {dict}[key][subscript]
      else
        " TODO: may need to use [] syntax instead...
        let dict = dict.'.'.key
        let key = subscript
      endif
    endif
    if !empty(key)
      " Dictionaries
      let dict2 = s:LetIfUndef(dict, {})
      if !has_key(dict2, key)
        " let dict2[key] = type(a:value) == type(function('has')) ? (a:value) : eval(a:value)
        call s:Verbose("let %1.%2 = %3", dict, key, a:value)
        let dict2[key] = a:value
      else
        call s:Verbose("(LetIfUndef) %1.%2 exists => abort recursion", dict, key)
      endif
      return dict2[key]
    else
      " other variables
      if !exists(a:var)
        if a:var =~ '^\$'
          " Environment variables are not supposed to receive anything but
          " strings. And they don't support `let {var} = value`
          exe 'let '.a:var.' = '.string(a:value)
          call s:Verbose("let %1 = %2", a:var, a:value)
        else
          " let {a:var} = type(a:value) == type(function('has')) ? (a:value) : eval(a:value)
          let {a:var} = a:value
          call s:Verbose("let %1 = %2", a:var, {a:var})
        endif
      else
        call s:Verbose("(LetIfUndef) %1 exists => abort recursion", a:var)
      endif
      exe 'return '.a:var
      " return {a:var} " syntax not supported with environment variables
    endif
endfunction

function! lh#let#if_undef(...) abort " {{{4
  call s:Verbose('let_if_undef(%1)', a:000)
  " try
    let [var,Value] = call('s:BuildPublicVariableNameAndValue', [1] + a:000)
    if lh#option#is_unset(var)
      call s:Verbose("Notification that %1 is already set, receive => abort let#if_undef", a:000)
      " but this return the value
      return var._value
    elseif type(var) == type({}) && has_key(var, 'project')
      " Special case for p:& options (and may be someday to p:$var)
      return var.project.set(var.name, Value)
    else
      return s:LetIfUndef(var, Value)
    endif
  " catch /.*/
    " throw "Cannot set ".string(a:000).": ".(v:exception .' @ '. v:throwpoint)
  " endtry
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
  let [all, dict, key, subscript ; dummy] = matchlist(a:var, '^\v(.{-})%(\.([^\[.]{-})%(\[(.{-})\])=)=$')
  call lh#assert#value(subscript).empty("Case not yet handled")
  if !empty(key)
    " Dictionaries
    let dict2 = s:LetIfUndef(dict, {}) " Don't override the dict w/ s:LetTo()!
    " call lh#assert#type(dict2).belongs_to({}, []) " We cannot expect this, as it may be an error from the end user...

    " let dict2[key] = type(a:value) == type(function('has')) ? (a:value) : eval(a:value)
    call s:Verbose("let %1.%2 = %3 %4 // %1=%5", dict, key, a:value, !empty(subscript) ? '@['.subscript.']' : '', dict2)
    if ! lh#type#is_dict(dict2)
      throw "E689: Type mismatch: Can only index a List or Dictionary."
    endif
    let dict2[key] = a:value
    return dict2[key]
  elseif a:var =~ '^\$'
    " Environment variables are not supposed to receive anything but
    " strings. And they don't support `let {var} = value` syntax
    exe 'let '.a:var.' = '.string(a:value)
    exe 'return '.a:var
  else
    " other variables
    if a:var !~ '&' && exists(a:var)
      unlet {a:var} " required until vim 7.4-1546
    endif
    " let {a:var} = type(a:value) == type(function('has')) ? (a:value) : eval(a:value)
    " let {a:var} = a:value
    exe 'let '.a:var.' = a:value'
    call s:Verbose("let %1 = %2", a:var, eval(a:var))
    return eval(a:var)
  endif
endfunction

function! lh#let#to(...) abort " {{{4
  call s:Verbose('let_to(%1)', a:000)
  " try
    let [var,Value] = call('s:BuildPublicVariableNameAndValue', [0] + a:000)
    call lh#assert#value(var).is_set(var)
    if type(var) == type({}) && has_key(var, 'project')
      " Special case for p:& options (and may be someday to p:$var)
      call var.project.set(var.name, Value)
    else
      return s:LetTo(var, Value)
    endif
  " catch /.*/
    " throw "Cannot set ".string(a:000).": ".(v:exception .' @ '. v:throwpoint)
  " endtry
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
    let dict2 = s:LetIfUndef(dict, {}) " Don't override the dict w/ s:LetTo()!
    " let dict2[key] = type(a:value) == type(function('has')) ? (a:value) : eval(a:value)
    let dict2[key] = a:value
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
    if a:var =~ '^p:'
      " It's a p:roject variable
      let prj = lh#project#crt()
      if lh#option#is_unset(prj)
        call s:Verbose("Current buffer isn't under a project. => There is no ".a:var." variable found to be unlet!")
        return
      endif
      let suffix = a:var[2:]
      if empty(suffix)
        throw "Invalid empty variable name. It cannot be unlet!"
      endif
      let h = prj.find_holder(suffix)
      if lh#option#is_unset(h)
        call s:Verbose("No ".a:var." variable found to be unlet!")
        return
      endif
      unlet h[suffix[0] == '$' ? suffix[1:] : suffix]
      call s:Verbose("unlet %1.%2", h, suffix)
    elseif exists(a:var)
      exe 'unlet '.a:var
      call s:Verbose("unlet %1", a:var)
      " let var = s:BuildPublicVariableName(a:var)
      " The following doesn't work with dictionaries
      " unlet {var}
      " exe 'unlet '.var
    endif
  catch /.*/
    throw "Cannot unset ".a:var.": ".(v:exception .' @ '. v:throwpoint)
  endtry
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
" # Common helpers {{{2
" Function: lh#let#_list_all_variables_in_scope(scope) {{{3
function! lh#let#_list_all_variables_in_scope(scope) abort
  if a:scope == 'p:'
    let prj = lh#project#crt()
    if lh#option#is_unset(prj)
      return a:scope
    endif
    let vars = prj.get_names()
  else
    let vars = keys({a:scope})
  endif
  call map(vars, 'a:scope.v:val')
  return vars
endfunction

" Function: s:IsDictOrList(var) {{{3
function! s:IsDictOrList(var)
  " call assert_true(type(a:var) == type(''))
  if a:var =~ '^p:'
    let instance = lh#project#_get(a:var[2:])
    return type(instance) == type([]) || type(instance) == type({})
  else
    let Val = eval(a:var)
    return type(Val) == type([]) || type(Val) == type({})
  endif
endfunction

" Function: s:IsDict(var) {{{3
function! s:IsDict(var)
  " call assert_true(type(a:var) == type(''))
  if a:var =~ '^p:'
    if a:var =~ '^p:[$&]'
      return 0
    elseif a:var =~ '^p:'
      let sub    = a:var[2:]
      return lh#type#is_dict(lh#project#_get(sub))
    endif
  else
    let Val = eval(a:var)
    return type(Val) == type({})
  endif
endfunction

" Function: lh#let#_list_all_list_variables_in_scope(scope) {{{3
function! lh#let#_list_all_list_variables_in_scope(scope) abort
  let vars = lh#let#_list_all_variables_in_scope(a:scope)
  " Keep only lists and dictionaries
  call filter(vars, 's:IsDictOrList(v:val)')
  return vars
endfunction

" Function: lh#let#_list_variables(lead) {{{3
function! lh#let#_list_variables(lead, keep_only_dicts_and_lists) abort
  let ListVarsFn = function(a:keep_only_dicts_and_lists ? 'lh#let#_list_all_list_variables_in_scope' : 'lh#let#_list_all_variables_in_scope')
  if empty(a:lead)
    " No variable specified yet
    let vars
          \ = ListVarsFn('g:')
          \ + ListVarsFn('b:')
          \ + ListVarsFn('w:')
          \ + ListVarsFn('t:')
          \ + ListVarsFn('p:')
  elseif stridx(a:lead, '.') >= 0
    " Dictionary
    let [all, sDict0, key ; trail] = matchlist(a:lead, '\v(.*)\.(.*)')
    let sDict = sDict0
    if sDict =~ '^p:'
      " TODO: find inherited variables
      " let sDict = substitute(sDict, 'p:', lh#project#crt_bufvar_name().'.variables.', '')
      let dict = lh#project#_get(sDict[2:])
    else
      let dict = eval(sDict)
    endif
    let vars = keys(dict)
    if a:keep_only_dicts_and_lists
      call filter(vars, 's:IsDictOrList(sDict.".".v:val)')
    endif
    call map(vars, 'v:val. (type(dict[v:val])==type({})?".":"")')
    call map(vars, 'sDict0.".".v:val')
    let l = len(a:lead) - 1
    call filter(vars, 'v:val[:l] == a:lead')
    return vars
  else
    " Simple variables
    if         (len(a:lead) == 1 && a:lead    =~ '[gbwtp]')
          \ || (len(a:lead) > 1  && a:lead[1] == ':')
      let scope = a:lead[0]
      let filter_scope = ''
    else
      let scope = 'g'
      let filter_scope = 'g:'
    endif
    let vars = ListVarsFn(scope.':')
    call filter(vars, 'v:val =~ "^".filter_scope.a:lead')
  endif
  " Add dot to identified dictionaries
  call map(vars, 'v:val. (s:IsDict(v:val)?".":"")')
  return vars
endfunction

" # PushOptions {{{2
"
" Function: lh#let#_push_options(variable, ...) {{{3
function! lh#let#_push_options(variable, ...) abort
  let var = lh#let#if_undef(a:variable, [])
  call map(copy(a:000), 'lh#list#push_if_new(var, v:val)')
  return var
endfunction

" Function: lh#let#_pop_options(variable, ...) {{{3
function! lh#let#_pop_options(variable, ...) abort
  let options = '\v^'.join(a:000, '|').'$'
  return filter(eval(a:variable), 'v:val !~ options')
endfunction

" Function: lh#let#_push_options_complete(ArgLead, CmdLine, CursorPos) {{{3
call lh#let#if_undef('g:acceptable_options_for', {})

function! lh#let#_push_options_complete(ArgLead, CmdLine, CursorPos) abort
  let tmp = substitute(a:CmdLine, '\s*\S*', 'Z', 'g')
  let pos = strlen(tmp)

  call s:Verbose('complete(lead="%1", cmdline="%2", cursorpos=%3)', a:ArgLead, a:CmdLine, a:CursorPos)

  if     2 == pos
    " First argument: a variable name
    return lh#let#_list_variables(a:ArgLead, 1)
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

  call s:Verbose('complete(lead="%1", cmdline="%2", cursorpos=%3, pos=%4)', a:ArgLead, a:CmdLine, a:CursorPos, pos)

  if     2 == pos
    " First argument: a variable name
    return lh#let#_list_variables(a:ArgLead, 1)
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

" # Completions for :Let* and *:Unlet {{{2
" Function: lh#let#_complete_let(ArgLead, CmdLine, CursorPos) {{{3
" :LetTo, :Unlet -> anything
" :LetIfUndef -> only dicts
" :Unlet: only one parameter
function! lh#let#_complete_let(ArgLead, CmdLine, CursorPos) abort
  let [pos, tokens, ArgLead, CmdLine, CursorPos] = lh#command#analyse_args(a:ArgLead, a:CmdLine, a:CursorPos)

  let is_dest_specified = (pos >= 2) && (tokens[1] =~ '^--')
  let relpos = pos - is_dest_specified

  if     (1 == relpos)
    " First argument: a variable name
    if a:CmdLine =~ '\vLetI%[fUndef]'
      " todo: don't return the final '.'
      let vars = lh#let#_list_variables(a:ArgLead, 1)
    elseif a:CmdLine =~ '\vLetT%[o]'
      let vars = lh#let#_list_variables(a:ArgLead, 0)
      " return any variable starting with Arglead, without the final '.'?
      if  (1==pos) && lh#project#is_in_a_project() && (lh#project#crt().depth() > 1)
        let vars = filter(['--hide', '--overwrite'], 'v:val =~ "^".ArgLead.".*"') + vars
      endif
    else " :LetTo and Unlet
      let vars = lh#let#_list_variables(a:ArgLead, 0)
      " return any variable starting with Arglead, without the final '.'?
    endif
    return vars
  elseif a:CmdLine =~ '\vUnl%[et]'
    return ''
  elseif relpos >= 2
    " Doesn't handle 'foo\ bar', but we don't need this to fetch a variable
    " name
    let varname = tokens[1+is_dest_specified]
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
