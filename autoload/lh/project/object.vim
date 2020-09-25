"=============================================================================
" File:         autoload/lh/project/object.vim                    {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      5.2.2.
let s:k_version = '522'
" Created:      08th Mar 2017
" Last Update:  26th Sep 2020
"------------------------------------------------------------------------
" Description:
"       Defines project object
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim

let s:k_unset            = lh#option#unset()
function! s:getSID() abort
  return eval(matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_getSID$'))
endfunction
let s:k_script_name      = s:getSID()

"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#project#object#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#project#object#verbose(...)
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

function! lh#project#object#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Public API         {{{1
" # Define a new project {{{2
" Function: lh#project#object#_new(params) {{{3
" Typical use, in _vimrc_local.vim
"   :call lh#project#define(s:, params)
" Reserved fields:
" - "name"
" - "parents"
" - "buffers"
" - "variables" <- where p:foobar will be stored
"   - "paths"
"     - "sources" <- @inv absolute path when defined
" - "options"   <- where altered vim options will be stored
" - "env"       <- where $ENV variables will be stored
function! lh#project#object#_new(params) abort
  " Inherits OO.to_string()
  let project = lh#object#make_top_type(a:params)
  call lh#dict#add_new(project,
        \ { 'buffers':   []
        \ , 'variables': {}
        \ , 'options':   {}
        \ , 'env':       {}
        \ , '_menus':    []
        \ , 'parents':   []
        \ })
  " If no name is provided, generate one on the fly
  if empty(get(project, 'name', ''))
    let project.name = lh#project#list#_new_name()
  endif
  let method_names = [
        \  '__lhvl_oo_type'
        \, '_inherit'
        \, '_register_buffer'
        \, '_remove_buffer'
        \, '_update_option'
        \, '_use_options'
        \, '_register_local_menus'
        \, '_register_local_menus_for_crt_prj'
        \, 'apply'
        \, 'children'
        \, 'depth'
        \, 'environment'
        \, 'exists'
        \, 'find_holder'
        \, 'find_holder_name'
        \, 'get'
        \, 'get_names'
        \, 'map'
        \, 'set'
        \, 'update'
        \ ]
  call lh#object#inject_methods(project, s:k_script_name, method_names)

  " Let's automatically register the current buffer
  call project._register_buffer()

  call lh#project#list#_add_project(project)

  if has_key(project, 'auto_discover_root')
    " The option can be forced through #define parameter
    let auto_discover_root = project.auto_discover_root
    call s:Verbose("prj#new(%2): auto_discover_root set in options: %1", auto_discover_root, project.name)
    unlet project.auto_discover_root
  else
    let auto_discover_root = lh#project#_auto_discover_root()
    call s:Verbose("prj#new(%2): auto_discover_root computed: %1", auto_discover_root, project.name)
  endif

  if type(auto_discover_root) == type({}) && has_key(auto_discover_root, 'value')
    call s:Verbose("prj#new(%2): auto_discover_root set in options: %1", auto_discover_root.value, project.name)
    call lh#let#if_undef('p:paths.sources', fnamemodify(auto_discover_root.value, ':p'))
  elseif auto_discover_root !~? '\v^(n%[o]|0)$'
    if ! lh#project#exists('p:paths.sources')
      let root = lh#project#root()
      call s:Verbose("prj#new(%2): root found: %1", root, project.name)
      if !empty(root)
        call lh#let#if_undef('p:paths.sources', fnamemodify(root[:-2], ':p'))
      endif
    endif
  endif
  call s:Verbose("prj#new => %1", project)
  return project
endfunction

" Function: lh#project#object#_define(s:, params [, name]) {{{3
function! lh#project#object#_define(s, params, ...) abort
  if !lh#project#is_eligible() | return s:k_unset  | endif
  call lh#assert#not_equal(&ft, 'qf', "Don't run lh#project#define() from qf window!")
  let name = get(a:, 1, 'project')
  call lh#assert#value(name).match('^[a-zA-Z_][a-zA-Z0-9_]*$', 'Project name shall be a valid variable name unlike "'.name.'"')
  if !has_key(a:s, name)
    let a:s[name] = lh#project#object#_new(a:params)
  else
    call a:s[name]._register_buffer()
  endif
  return a:s[name]
endfunction


"------------------------------------------------------------------------
" ## Methods            {{{1
function! s:_register_buffer(...) dict abort " {{{2
  let bid = a:0 > 0 ? a:1 : bufnr('%')
  if !empty(bufname(bid))
    call lh#project#__register_buffer(bid, bufname(bid).' -- ft:'.lh#option#getbufvar(bid, '&ft', '???'))
  endif
  " if there is already a (different project), then inherit from it
  let inherited = lh#option#getbufvar(bid, g:lh#project#varname)
  if  lh#option#is_set(inherited)
        \ && inherited isnot self
        \ && !lh#list#contain_entity(lh#list#flatten(self.parents), inherited)
    call self._inherit(inherited)
    " and then override with new value
  endif
  call setbufvar(bid, g:lh#project#varname, self)
  call lh#list#push_if_new(self.buffers, bid)
endfunction

function! s:_inherit(parent) dict abort " {{{2
  call lh#list#push_if_new(self.parents, a:parent)
endfunction

function! s:depth() dict abort " {{{2
  return 1 + max(map(copy(self.parents), 'v:val.depth()'))
endfunction

function! s:children() dict abort " {{{2
  let children = filter(copy(values(lh#project#list#_get_all_prjs())), 'lh#list#find_entity(v:val.parents, self) >= 0')
  return lh#list#flat_extend(children, filter(map(copy(children), 'v:val.children()'), '!empty(v:val)'))
endfunction

function! s:get_names() dict abort " {{{2
  let local_variables = keys(self.variables)
        \ + map(keys(self.env), '"$".v:val')
        \ + map(keys(self.options), '"&".v:val')
  "TODO: see whether we could avoid lh#list#flatten()
  return lh#list#flatten(local_variables + map(copy(self.parents), 'v:val.get_names()'))
endfunction

function! s:set(varname, value) dict abort " {{{2
  call s:Verbose('%1.set(%2 <- %3)', self.name, a:varname, a:value)
  call lh#assert#not_empty(a:varname)
  let varname = a:varname[1:]
  if     a:varname[0] == '&' " {{{3 -- options
    let self.options[varname] = a:value
    call self._update_option(varname)
    return self.options[varname]
  elseif a:varname[0] == '$' " {{{3 -- $ENV
    let self.env[varname] = a:value
    return self.env[varname]
  else                       " {{{3 -- Any variable
    " This part is very similar to lh#let#to instead we don't have a variable
    " name => need to do the same work, but differently
    return lh#dict#let(self.variables, a:varname, a:value)
  endif " }}}5
endfunction

function! s:update(varname, value, ...) dict abort " {{{2
  " @param[in] {optional: is_recursing} => don't set on parent level, but on
  " child one
  " like s:set, but find first where the option is already set (i.e.
  " possibily in a parent project), and update the "old" setting instead of
  " overridding it.
  call lh#assert#not_empty(a:varname)
  call s:Verbose('%1.set(%2 <- %3, %4)', self.name, a:varname, a:value, a:000)
  let varname = a:varname[1:]
  if     a:varname[0] == '&' " {{{3 -- options
    if has_key(self.options, varname)
      call self._update_option(varname)
      return 1
    endif
  elseif a:varname[0] == '$' " {{{3 -- $ENV
    if has_key(self.env, varname)
      let self.env[varname] = a:value
      return 1
    endif
  else                       " {{{3 -- Any variable
    let r0 = lh#dict#get_composed(self.variables, a:varname)
    if lh#option#is_set(r0)
      call lh#dict#let(self.variables, a:varname, a:value)
      return 1
    endif
  endif " }}}5
  " The variable is unknown locally => search in parents
  for p in self.parents
    " Search in parent, but don't set new variables
    if p.update(a:varname, a:value, 1)
      return 1
    endif
  endfor
  " Unknown at parent level as well => set it locally
  if a:0 == 0 || a:1 == 0
    call self.set(a:varname, a:value)
    return 1
  endif
  return 0
endfunction

function! s:do_update_option(bid, varname, value) abort " {{{2
  if     a:value =~ '^+='
    let lValue = split(getbufvar(a:bid, a:varname), ',')
    call lh#list#push_if_new_elements(lValue, split(a:value[2:], ','))
    let value = join(lValue, ',')
  elseif a:value =~ '^-='
    let lValue = split(getbufvar(a:bid, a:varname), ',')
    let toRemove = split(a:value[2:], ',')
    call filter(lValue, 'index(toRemove, v:val) >= 0')
    let value = join(lValue, ',')
  elseif a:value =~ '^='
    let value = a:value[1:]
  else
    let value = a:value
  endif
  call s:Verbose('setlocal{%1} %2%3 -> %4', a:bid, a:varname, a:value, value)
  call setbufvar(a:bid, a:varname, value)
endfunction

function! s:_update_option(varname, ...) dict abort " {{{2
  call lh#assert#value(a:varname[0]).differ('&')
  let value = self.options[a:varname]
  call s:Verbose('%1._update_option(%2 <- %3)', self.name, a:varname, value)
  if a:0 == 0
    " Apply to all buffers
    cal map(copy(self.buffers), 's:do_update_option(v:val, "&".a:varname, value)')
  else
    call s:do_update_option(a:1, '&'.a:varname, value)
  endif
endfunction

function! s:_use_options(bid) dict abort " {{{2
  call s:Verbose('%1._use_options(%2)', self.name, a:bid)
  for p in self.parents
    call p._use_options(a:bid)
  endfor
  for opt in keys(self.options)
    call self._update_option(opt, a:bid)
  endfor
endfunction

function! s:_register_local_menus_for_crt_prj(bid) dict abort " {{{2
  call s:Verbose('%1._register_local_menus_for_crt_prj(%2)', self.name, a:bid)
  for opt in keys(self.options)
    call self._register_local_menus_for_crt_prj(opt, a:bid)
  endfor
endfunction

function! s:_register_local_menus(bid) dict abort " {{{2
  call s:Verbose('%1._register_local_menus(%2)', self.name, a:bid)
  for menu in self._menus
    call call('lh#menu#make', menu)
  endfor
endfunction

function! s:_remove_buffer(bid) dict abort " {{{2
  for p in self.parents
    call p._remove_buffer(a:bid)
  endfor
  if getbufvar(a:bid, '&ft') != 'qf'
    " Quickfix buffers may not be registered to projects
    call lh#assert#not_equal(-1, index(self.buffers, a:bid), "Buffer ".a:bid.'('.bufname(a:bid).') doesn''t belong to project '.self.name.' '.string(self.buffers) )
  endif
  call filter(self.buffers, 'v:val != a:bid')
endfunction

function! s:get(varname, ...) dict abort " {{{2
  if     a:varname[0] == '$' && has_key(self.env, a:varname[1:])
    let l:R0 = self.env[a:varname[1:]]
  elseif a:varname[0] == '&' && has_key(self.options, a:varname[1:])
    let l:R0 = self.options[a:varname[1:]]
  elseif a:varname[0] !~ '[&$]'
    let l:R0 = lh#dict#get_composed(self.variables, a:varname)
  endif
  if exists('l:R0') && lh#option#is_set(l:R0)
    " may need to interpret a reference lh#ref('g:variable')
    return l:R0
  else
    for p in self.parents
      let r = p.get(a:varname)
      if lh#option#is_set(r) | return r | endif
      unlet! r
    endfor
  endif
  return get(a:, 1, s:k_unset)
endfunction

function! s:exists(varname) dict abort " {{{2
  let r0 = lh#dict#get_composed(self.variables, a:varname)
  if lh#option#is_set(r0)
    " may need to interpret a reference lh#ref('g:variable')
    return 1
  else
    for p in self.parents
      let r = p.get(a:varname)
      if lh#option#is_set(r) | return 1 | endif
      unlet! r
    endfor
  endif
  return 0
endfunction

function! s:apply(Action) dict abort " {{{2
  " TODO: support lhvl-functors, functions, "v:val" stuff
  for b in self.buffers
    call a:Action(b)
  endfor
endfunction

function! s:map(action) dict abort " {{{2
  " TODO: support lhvl-functors, functions, "v:val" stuff
  return map(copy(self.buffers), a:action)
endfunction

function! s:environment() dict abort " {{{2
  let env = {}
  for p in self.parents
    call extend(env, p.environment(), 'force')
  endfor
  call extend(env, self.env, 'force')
  return env
  " return map(items(self.env), 'v:val[0]."=".v:val[1]')
endfunction

function! s:find_holder(varname) dict abort " {{{2
  if     a:varname[0] == '$'
    return self.env
  elseif has_key(self.variables, a:varname)
    return self.variables
  else
    for p in self.parents
      let h = p.find_holder(a:varname)
      if lh#option#is_set(h)
        return h
      endif
      unlet h
    endfor
  endif
  return s:k_unset
endfunction

function! s:find_holder_name(varname, store) dict abort " {{{2
  if     a:varname[0] == '$'
    return '.env.'
  else
    let r0 = lh#dict#get_composed(self[a:store], a:varname)
    if lh#option#is_set(r0)
    " if has_key(self.variables, a:varname)
      " if varname is made of multiple part, has_key cannot work!
      return '.'.a:store.'.'
    else
      for p in range(len(self.parents))
        let h = self.parents[p].find_holder_name(a:varname, a:store)
        if !empty(h)
          return '.parents['.p.']'.h
        endif
      endfor
    endif
  endif
  return ''
endfunction

function! s:__lhvl_oo_type() dict abort " {{{2
  return 'project'
endfunction


"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
