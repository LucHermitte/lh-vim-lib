"=============================================================================
" File:         autoload/lh/project/list.vim                      {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      5.2.1
let s:k_version = '521'
" Created:      08th Mar 2017
" Last Update:  07th Sep 2020
"------------------------------------------------------------------------
" Description:
"       Support function for project list management
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
function! lh#project#list#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#project#list#verbose(...)
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

function! lh#project#list#debug(expr) abort
  return eval(a:expr)
endfunction

" ## Public API         {{{1

" Function: lh#project#list#_save() {{{2
" Meant to be used from Unit Tests
function! lh#project#list#_save() abort
  return s:project_list
endfunction

" Function: lh#project#list#_restore(prj_list) {{{2
" Meant to be used from Unit Tests
function! lh#project#list#_restore(prj_list) abort
  let s:project_list = a:prj_list
endfunction

" Function: lh#project#list#_clear() {{{2
function! lh#project#list#_clear() abort
  call s:project_list.clear()
endfunction

" Function: lh#project#list#_clear_empty_projects() {{{2
function! lh#project#list#_clear_empty_projects() abort
  call s:project_list.clear_empty_projects()
endfunction

" Function: lh#project#list#_add_project(project) {{{2
function! lh#project#list#_add_project(project) abort
  return s:project_list.add_project(a:project)
endfunction

" Function: lh#project#list#_get_all_prjs() {{{2
function! lh#project#list#_get_all_prjs() abort
  return s:project_list.get()
endfunction

" Function: lh#project#list#_get(prjname) {{{2
function! lh#project#list#_get(prjname) abort
  return s:project_list.get(a:prjname)
endfunction

" Function: lh#project#list#_find_best(path) {{{2
function! lh#project#list#_find_best(path) abort
  call s:Verbose('Finding best path @ %1', a:path)
  return s:project_list.find_best(a:path)
endfunction

" Function: lh#project#list#_new_name() {{{2
function! lh#project#list#_new_name() abort
  return s:project_list.new_name()
endfunction

" Function: lh#project#list#_unload_prj(prj, buffers) {{{2
function! lh#project#list#_unload_prj(prj, buffers) abort
  call s:project_list.unload(a:prj, a:buffers)
endfunction

" Function: lh#project#list#_wipeout_prj(prj, buffers) {{{2
function! lh#project#list#_wipeout_prj(prj, buffers) abort
  call s:project_list.wipeout(a:prj, a:buffers)
endfunction

" ## List object        {{{1
" Function: lh#project#_make_project_list() {{{2
function! lh#project#list#_new() abort
  let res = lh#object#make_top_type(
        \ { 'name': 'project_list'
        \ , 'projects': {}
        \ , '_next_id': 1
        \ })
  let method_names = ['find_best', 'new_name', 'add_project', 'get', 'clear', 'clear_empty_projects', 'unload', 'wipeout', '_remove']
  call lh#object#inject_methods(res, s:k_script_name, method_names)
  return res
endfunction

" - Methods {{{2
function! s:find_best(path) dict abort " {{{3
  let prjs = filter(values(self.projects), 'v:val.get("paths.sources", "") == a:path')
  if empty(prjs)
    return lh#option#unset('No project matching '.a:path)
  endif
  call lh#assert#value(len(prjs)).eq(1)
  return prjs[0]
endfunction

function! s:new_name() dict abort " {{{3
  let name = 'project'. self._next_id
  let self._next_id += 1
  return name
endfunction

function! s:add_project(project) dict abort " {{{3
  let name = a:project.name
  if !has_key(self.projects, name)
    let self.projects[name] = a:project
  endif
endfunction

function! s:get(...) dict abort " {{{3
  if a:0 == 0
    return self.projects
  else
    if lh#option#is_unset(a:1)
      return lh#project#crt()
    else
      return get(self.projects, a:1, s:k_unset)
    endif
  endif
endfunction

function! s:clear() dict abort " {{{3
  " remove all projects
  for p in self.projects
    for b in p.buffers
      let b = getbufvar(b, '')
      " Avoid `silent!` as it messes Vim client-server mode and as a
      " consequence rspecs tests
      if has_key(b, s:project_varname)
        unlet b[s:project_varname]
      endif
    endfor
  endfor
  let self.projects = []
endfunction

function! s:clear_empty_projects() dict abort " {{{3
  " remove empty projects
  call filter(self.projects, '!empty(v:val.buffers)')
endfunction

function! s:_remove(prj, how, buffers) dict abort " {{{3
  " TODO: see whether it really makes sense to tell which buffers shall be
  " removed...
  let s:k_messages = { 'bw': 'wiping out', 'bd': 'unloading'}
  if empty(a:buffers)
    let can_proceed = lh#ui#confirm("You're on the verge of ".s:k_messages[a:how]." files belonging to `".(a:prj.name)."` project\nDo you confirm the removal?", "&Yes\n&No", 2)
    if can_proceed != '1' | return | endif
    " Don't apply to inherited buffers!!!
    let buffers = a:prj.buffers

    " We still analyse BufUnload event even when the project is removed. Indeed
    " the project being removed may only be a sub-project and not a parent
    " project. In that case, we still need to unregister the buffer from the
    " parent project.
  endif
  call s:Verbose('%1 %2', a:how, buffers)
  exe a:how.' '.join(buffers, ' ')
  if empty(a:buffers)
    " if the project has children, remove the subprojects as well,
    " recursivelly!
    let children = a:prj.children()
    let children_names = lh#list#get(children, 'name')
    call s:Verbose("'%1' children are %2", a:prj.name, children_names)
    let project_names = children_names + [a:prj.name]
    call filter(self.projects, 'index(project_names, v:key) < 0')
    call s:Verbose('Remaining projects are %1', keys(self.projects))
  endif
endfunction

function! s:unload(prj, buffers) dict abort " {{{3
  call s:Verbose("Unload `%1` project", a:prj)
  " return self._remove(a:prj, 'bd', a:buffers)
  return self._remove(a:prj, 'bd', [])
endfunction

function! s:wipeout(prj, buffers) dict abort " {{{3
  call s:Verbose("Wipeout `%1` project", a:prj)
  " return self._remove(a:prj, 'bw', a:buffers)
  return self._remove(a:prj, 'bw', [])
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" ## Globals {{{1
" # Internal globals {{{2
let s:project_list = get(s:, 'project_list', lh#project#list#_new())

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
