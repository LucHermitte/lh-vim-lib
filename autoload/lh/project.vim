"=============================================================================
" File:         autoload/lh/project.vim                           {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0.0
let s:k_version = '4000'
" Created:      08th Sep 2016
" Last Update:  10th Sep 2016
"------------------------------------------------------------------------
" Description:
"       Define new kind of variables: `p:` variables.
"       The objective if to avoid duplicating a lot of b:variables in many
"       buffers. Instead, all uffer will point to a same global variable
"       associated to the current project.
"
" Usage:
" - New project:
"   - From anywhere:
"     :let prg = lh#project#new({dict-options})
"   - From local_vimrc
"     :call lh#project#define(s:, {dict-options})
"
" - Register a buffer to the project
"     :call s:project.register_buffer([bufid])
"
" - Propose a value to a project option:
"     :LetIfUndef p:foo.bar.team 12
" - Override the value of a project option (define it if new):
"     :Let p:foo.bar.team 42
" - Get a project variable value:
"     :let val = lh#option#get('b:foo.bar.team')
"
" - Power user
"   - Get the current project variable (b:crt_project) or lh#option#undef()
"     :let prj = lh#project#get()
"   - Get a variable under the project
"     :let val = lh#project#_get('foo.bar.team')
"   - Get "b:crt_project", or lh#option#undef()
"     :let var = lh#project#crt_bufvar_name()
"
"------------------------------------------------------------------------
" History:
" @since v4.0.0
" TODO:
" - Auto detect current project root path when there is yet no project?
" - Simplify new project creation
" - Automatically remove deleted buffers
" - Have root path be official for BTW and lh-tags
" - Toggling:
"   - at global level: [a, b, c]
"   - at project level: [default value from global VS force [a, b, c]]
" - Be able to control which parent is filled with lh#let# functions
" - Doc
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim

let s:project_varname = get(g:, 'lh#project#varname', 'crt_project')
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#project#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#project#verbose(...)
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

function! lh#project#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" # Define {{{2
" - Methods {{{3
function! s:register_buffer(...) dict abort " {{{4
  let bid = a:0 > 0 ? a:1 : bufnr('%')
  " if there is already a (different project), then inherit from it
  let inherited = lh#option#getbufvar(bid, s:project_varname)
  if  lh#option#is_set(inherited) && inherited isnot self
    call self.inherit(inherited)
    " and then ovveride with new value
  endif
  call setbufvar(bid, s:project_varname, self)
  call lh#list#push_if_new(self.buffers, bid)
  " todo: register bid removing when bid is destroyed
endfunction

function! s:inherit(parent) dict abort " {{{4
  call lh#list#push_if_new(self.parents, a:parent)
endfunction

function! s:depth() dict abort " {{{4
  return 1 + max(map(copy(self.parents), 'v:val.depth()'))
endfunction

function! s:get(varname) dict abort " {{{4
  let r0 = lh#dict#get_composed(self.variables, a:varname)
  if lh#option#is_set(r0)
    " may need to interpret a reference lh#ref('g:variable')
    return r0
  else
    for p in self.parents
      let r = p.get(a:varname)
      if lh#option#is_set(r) | return r | endif
      unlet! r
    endfor
  endif
  return lh#option#unset()
endfunction

function! s:apply(action) dict abort " {{{4
  " TODO: support lhvl-functors, functions, "v:val" stuff
  for b in self.buffers
    call a:Action(b)
  endfor
endfunction

function! s:map(action) dict abort " {{{4
  " TODO: support lhvl-functors, functions, "v:val" stuff
  return map(copy(self.buffers), a:action)
endfunction

function! s:find_holder(varname) dict abort " {{{4
  if has_key(self.variables, a:varname)
    return self.variables
  else
    for p in self.parents
      silent! unlet h
      let h = p.find_holder(a:varname)
      if lh#option#is_set(h)
        return h
      endif
    endfor
  endif
  return lh#option#unset()
endfunction

" Function: lh#project#new(params) {{{3
" Typical use, in _vimrc_local.vim
"   :call lh#project#define(s:, params)
" Reserved fields:
" - "name"
" - "parents"
" - "paths.root" ?
" - "buffers"
" - "variables" <- where p:foobar will be stored
function! lh#project#new(params) abort
  let project = a:params
  call lh#dict#add_new(project,
        \ { 'buffers': []
        \ , 'variables': {}
        \ , 'parents': []
        \ })

  let project.inherit         = function(s:getSNR('inherit'))
  let project.register_buffer = function(s:getSNR('register_buffer'))
  let project.get             = function(s:getSNR('get'))
  let project.depth           = function(s:getSNR('depth'))
  let project.apply           = function(s:getSNR('apply'))
  let project.map             = function(s:getSNR('map'))
  let project.find_holder     = function(s:getSNR('find_holder'))

  " Let's automatically register the current buffer
  call project.register_buffer()
  return project
endfunction

" Function: lh#project#define(s:, params) {{{3
function! lh#project#define(s, params) abort
  if !has_key(a:s, 'project')
    let a:s.project = lh#project#new(a:params)
  endif
  return a:s.project
endfunction

" # Access {{{2
" Function: lh#project#crt() {{{3
function! lh#project#crt() abort
  if exists('b:'.s:project_varname)
    return b:{s:project_varname}
  else
    throw "The current buffer doesn't belong to a project"
  endif
endfunction

" Function: lh#project#crt_bufvar_name() {{{3
function! lh#project#crt_bufvar_name() abort
  if exists('b:'.s:project_varname)
    return 'b:'.s:project_varname
  else
    throw "The current buffer doesn't belong to a project"
  endif
endfunction

" Function: lh#project#_get(name) {{{3
function! lh#project#_get(name) abort
  if exists('b:'.s:project_varname)
    return b:{s:project_varname}.get(a:name)
  else
    return lh#option#unset()
  endif
endfunction

" }}}1
" unlet s:['project']
" unlet b:crt_project
let g:prj = lh#project#define(s:, {'name': 'test'})

"------------------------------------------------------------------------
" ## Internal functions {{{1
" # Compatibility functions {{{2
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
