"=============================================================================
" File:         autoload/lh/project.vim                           {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0
let s:k_version = '400'
" Created:      08th Sep 2016
" Last Update:  08th Oct 2016
"------------------------------------------------------------------------
" Description:
"       Define new kind of variables: `p:` variables.
"       The objective if to avoid duplicating a lot of b:variables in many
"       buffers. Instead, all buffers will point to a same global variable
"       associated to the current project.
"
" Usage:
"       See doc/Project.md
"
"------------------------------------------------------------------------
" History:
" @since v4.0.0
" TODO:
" - Doc
" - Have root path be official for BTW and lh-tags
" - Completion on :Let* and *Unlet
" - Toggling:
"   - at global level: [a, b, c]
"   - at project level: [default value from global VS force [a, b, c]]
" - Have menu priority + menu name in all projects in order to simplify
"   toggling definitions
" - Setlocally vim options on new files
" - Have lh-tags, lh-dev, BTW, µTemplate... use:
"   - p:$ENV variables
"   - paths.sources
" - Be able to control which parent is filled with lh#let# functions
"   -> :Project <name> :LetTo var = value
" - prj.set(plain_variable, value)
" - :Project <name> do <cmd> ...
" - :Project <name> :bw -> with confirmation!
" - :Project [<name>] :make
"   -> rely on `:Make` if it exists
" - Simplify dictionaries -> no 'parents', 'variables', 'env', 'options' when
"   there are none!
" - auto projectification of every buffer ?
" - Serialize and deserialize options from a file that'll be maintained
"   alongside a _vimrc_local.vim file.
"   Expected Caveats:
"   - How to insert a comment near each variable serialized
"   - How to computed value at the last moment (e.g. path relative to current
"     directory, and have the variable hold an absolute path)
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

function! s:Callstack(...)
  if s:verbose
    call call('lh#log#callstack',a:000)
  endif
endfunction

function! lh#project#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" # Project list {{{2

" Function: lh#project#_make_project_list() {{{3
function! lh#project#_make_project_list() abort
  let res = lh#object#make_top_type(
        \ { 'name': 'project_list'
        \ , 'projects': {}
        \ , '_next_id': 1
        \ })
  let res.new_name    = function(s:getSNR('new_name'))
  let res.add_project = function(s:getSNR('add_project'))
  let res.get         = function(s:getSNR('get_project'))
  let res.clear       = function(s:getSNR('clear_projects'))
  return res
endfunction

" Function: lh#project#_save_prj_list() {{{3
" Meant to be used from Unit Tests
function! lh#project#_save_prj_list() abort
  return s:project_list
endfunction

" Function: lh#project#_restore_prj_list(prj_list) {{{3
" Meant to be used from Unit Tests
function! lh#project#_restore_prj_list(prj_list) abort
  let s:project_list = a:prj_list
endfunction

" Function: lh#project#_clear_prj_list() {{{3
function! lh#project#_clear_prj_list() abort
  call s:project_list.clear()
endfunction

" - Methods {{{3
function! s:new_name() dict abort " {{{4
  let name = 'project'. self._next_id
  let self._next_id += 1
  return name
endfunction

function! s:add_project(project) dict abort " {{{4
  let name = a:project.name
  if !has_key(self.projects, name)
    let self.projects[name] = a:project
  endif
endfunction

function! s:get_project(...) dict abort " {{{4
  if a:0 == 0
    return self.projects
  else
    if lh#option#is_unset(a:1)
      return lh#project#crt()
    else
      return get(self.projects, a:1, lh#option#unset())
    endif
  endif
endfunction

function! s:clear_projects() dict abort " {{{4
  " remove all projects
  for p in self.projects
    for b in p.buffers
      let b = getbufvar(b, '')
      silent! unlet b[s:project_varname]
    endfor
  endfor
  let self.projects = []
endfunction

" - :Project Command definition {{{3
function! s:As_ls(bid) abort " {{{4
  return printf('%3d%s %s'
        \ , a:bid
        \ , (buflisted(a:bid) ? ' ' : 'u')
        \ . (bufnr('%') == a:bid ? '%' : bufnr('#') == a:bid ? '#' : ' ')
        \ . (! bufloaded(a:bid) ? ' ' : bufwinnr(a:bid)<0 ? 'h' : 'a')
        \ . (! getbufvar(a:bid, "&modifiable") ? '-' : getbufvar(a:bid, "&readonly") ? '=' : ' ')
        \ . (getbufvar(a:bid, "&modified") ? '+' : ' ')
        \ , '"'.bufname(a:bid).'"')
endfunction

function! s:ls_project(prj) abort " {{{4
  let lines = map(copy(a:prj.buffers), 's:As_ls(v:val)')
  echo join(lines, "\n")
endfunction

function! s:echo_project(prj, var) abort " {{{4
  let val = a:prj.get(a:var)
  if lh#option#is_set(val)
    echo 'p:{'.a:prj.name.'}.'.a:var.' -> '.lh#object#to_string(val)
  else
    call lh#common#warning_msg('No `'.a:var.'` variable in `'.a:prj.name. '` project')
  endif
endfunction

function! s:define_project(prjname) abort " {{{4
  " 1- if there is already a project with that name
  " => only register the buffer
  " 2- else if there is a project, with another name
  " => have the new project be the root project and inherit the other one
  " register the buffer to the new root project
  " 3- else (no project at all)
  " => create a new project
  " => and register the buffer

  let new_prj = s:project_list.get(a:prjname)
  if lh#option#is_set(new_prj)
    call new_prj.register_buffer()
  else
    " If there is already a project, register_buffer (called by #new) will
    " automatically inherit from it.
    let new_prj = lh#project#new({'name': a:prjname})
  endif
endfunction

function! s:show_related_projects(...) abort " {{{4
  let prj = a:0 == 0 ? lh#project#crt() : a:1
  let lvl = a:0 == 0 ? 0                : a:2
  " Let's assume there is no recursion
  echo repeat('  ', lvl) . '- '.prj.name
  for p in prj.parents
    call s:show_related_projects(p, lvl+1)
  endfor
endfunction

" Function: lh#project#_command([prjname]) abort {{{4
let s:k_usage =
      \ [ ':Project USAGE:'
      \ , '  :Project --list           " list existing projects'
      \ , '  :Project --define <name>  " define a new project/register current buffer'
      \ , '  :Project --which          " list projects to which the current buffer belongs'
      \ , '  :Project [<name>] :ls     " list buffers belonging to the project'
      \ , '  :Project [<name>] :echo   " echo state of a project variable'
      \ ]
function! lh#project#_command(...) abort
  if     a:1 =~ '-\+u\%[sage]'  " {{{5
    call lh#common#warning_msg(s:k_usage)
  elseif a:1 =~ '-\+h\%[elp]'
    help :Project
  elseif a:1 =~ '^-\+l\%[ist]$' " {{{5
    let projects = s:project_list.get()
    if empty(projects)
      echo "(no project defined)"
    else
      echo join(keys(projects), "\n")
    endif
  elseif a:1 =~ '\v^--which$'   " {{{5
    call s:show_related_projects()
  elseif a:1 =~ '\v^--define$'  " {{{5
    if a:0 != 2
      throw "`:Project --define` expects a project-name as only argument"
    endif
    call s:define_project(a:2)
  elseif a:1 =~ '^:'            " {{{5
    let prj = lh#project#crt()
    if lh#option#is_unset(prj)
      throw "The current buffer doesn't belong to any project"
    endif
    if     a:1 =~ '\v^:l%[s]$'     " {{{6
      call s:ls_project(prj)
    elseif a:1 =~ '\v^:echo$'      " {{{6
      if a:0 != 2
        throw "Not enough arguments to `:Project :echo`"
      endif
      call s:echo_project(prj, a:2)
    elseif a:1 =~ '\v^--define$'   " {{{6
      call s:define_project(a:2)
    else
      throw "Unexpected `:Project ".a:1."` subcommand"
    endif
  else                          " {{{5

    let prj_name = a:1
    let prj = s:project_list.get(prj_name)
    if lh#option#is_unset(prj)
      throw "There is no project named `".prj_name."`"
    endif
    if a:0 < 2
      throw "Not enough arguments to `:Project name`"
    endif
    if a:2 =~ '\v^:=l%[s]$'
      call s:ls_project(prj)
    elseif a:2 =~ '\v^:=echo$'   " {{{5
      if a:0 != 3
        throw "Not enough arguments to `:Project :echo`"
      endif
      call s:echo_project(prj, a:3)
    else
      throw "Unexpected `:Project ".a:2."` subcommand"
    endif
  endif

endfunction " }}}5

" Function: lh#project#_complete_command(ArgLead, CmdLine, CursorPos) {{{4
function! lh#project#_complete_command(ArgLead, CmdLine, CursorPos) abort
  let tmp = substitute(a:CmdLine, '\\ ', '§', 'g')
  let tokens = split(tmp, '\s\+')
  call map(tokens, 'substitute(v:val, "§", " ", "g")')
  let tmp = substitute(tmp, '\s*\S*', 'Z', 'g')
  let pos = strlen(tmp) - 1
  call s:Verbose('complete(lead="%1", cmdline="%2", cursorpos=%3) -- tmp=%4, pos=%5, tokens=%6', a:ArgLead, a:CmdLine, a:CursorPos, tmp, pos, tokens)


  if     1 == pos
    let res = ['--list', '--define', '--which', '--help', '--usage', ':ls', ':echo'] + map(copy(keys(s:project_list.projects)), 'escape(v:val, " ")')
  elseif     (2 == pos && tokens[pos-1] =~ '\v^:echo$')
        \ || (3 == pos && tokens[pos-1] =~ '\v^:=echo$')
    let res = keys(s:project_list.get(pos == 3 ? tokens[pos-2] : lh#option#unset()).variables)
  elseif 2 == pos
    let res = [':ls', ':echo']
  else
    let res = []
  endif
  let res = filter(res, 'v:val =~ a:ArgLead')
  return res
endfunction

" # Define a new project {{{2
" - Methods {{{3
function! s:register_buffer(...) dict abort " {{{4
  let bid = a:0 > 0 ? a:1 : bufnr('%')
  " if there is already a (different project), then inherit from it
  let inherited = lh#option#getbufvar(bid, s:project_varname)
  if  lh#option#is_set(inherited)
        \ && inherited isnot self
        \ && !lh#list#contain_entity(lh#list#flatten(self.parents), inherited)
    call self.inherit(inherited)
    " and then override with new value
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

function! s:set(varname, value) dict abort " {{{4
  " call assert_true(!empty(a:varname))
  let varname = a:varname[1:]
  if     a:varname[0] == '&' " {{{5 -- options
    let self.options[varname] = a:value
    call self._update_option(varname)
  elseif a:varname[0] == '$' " {{{5 -- $ENV
    let self.env[varname] = a:value
  else                       " {{{5 -- Any variable
    throw "`proj.set(".a:varname.",".a:value.") -- Not implemented yet"
    " call lh#let#to(self.variables[a:varname], a:value)
  endif " }}}5
endfunction

function! s:_update_option(varname) dict abort " {{{4
  " call assert_true(find(self.buffers, bufnr('%')))
  let value = self.options[a:varname]
  exe 'setlocal '.a:varname.value
endfunction

function! s:_use_options(bid) dict abort " {{{4
  for p in self.parents
    call p._use_options(a:bid)
  endfor
  for opt in keys(self.options)
    call self._update_option(opt)
  endfor
endfunction

function! s:_remove_buffer(bid) dict abort " {{{4
  for p in self.parents
    call p._remove_buffer(a:bid)
  endfor
  call filter(self.buffers, 'v:val != a:bid')
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

function! s:exists(varname) dict abort " {{{4
  let r0 = lh#dict#get_composed(self.variables, a:varname)
  if lh#option#is_set(r0)
    " may need to interpret a reference lh#ref('g:variable')
    return true
  else
    for p in self.parents
      let r = p.get(a:varname)
      if lh#option#is_set(r) | return true | endif
      unlet! r
    endfor
  endif
  return 0
endfunction

function! s:apply(Action) dict abort " {{{4
  " TODO: support lhvl-functors, functions, "v:val" stuff
  for b in self.buffers
    call a:Action(b)
  endfor
endfunction

function! s:map(action) dict abort " {{{4
  " TODO: support lhvl-functors, functions, "v:val" stuff
  return map(copy(self.buffers), a:action)
endfunction

function! s:environment() dict abort " {{{4
  return map(items(self.env), 'v:val[0]."=".v:val[1]')
endfunction

function! s:find_holder(varname) dict abort " {{{4
  if     a:varname[0] == '$'
    return self.env
  elseif has_key(self.variables, a:varname)
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
" - "options"   <- where altered vim options will be stored
" - "env"       <- where $ENV variables will be stored
function! lh#project#new(params) abort
  " Inherits OO.to_string()
  let project = lh#object#make_top_type(a:params)
  call lh#dict#add_new(project,
        \ { 'buffers':   []
        \ , 'variables': {}
        \ , 'options':   {}
        \ , 'env':       {}
        \ , 'parents':   []
        \ })
  " If no name is provided, generate one on the fly
  if !has_key(project, 'name')
    let project.name = s:project_list.new_name()
  endif

  let project.inherit         = function(s:getSNR('inherit'))
  let project.register_buffer = function(s:getSNR('register_buffer'))
  let project.set             = function(s:getSNR('set'))
  let project.get             = function(s:getSNR('get'))
  let project.exists          = function(s:getSNR('exists'))
  let project.environment     = function(s:getSNR('environment'))
  let project.depth           = function(s:getSNR('depth'))
  let project.apply           = function(s:getSNR('apply'))
  let project.map             = function(s:getSNR('map'))
  let project.find_holder     = function(s:getSNR('find_holder'))
  let project._update_option  = function(s:getSNR('_update_option'))
  let project._use_options    = function(s:getSNR('_use_options'))
  let project._remove_buffer  = function(s:getSNR('_remove_buffer'))

  " Let's automatically register the current buffer
  call project.register_buffer()

  call s:project_list.add_project(project)

  if has_key(project, 'auto_discover_root')
    " The option can be forced through #define parameter
    let auto_discover_root = project.auto_discover_root
    unlet project.auto_discover_root
  else
    let auto_discover_root = lh#project#_auto_discover_root()
  endif

  if type(auto_discover_root) == type({}) && has_key(auto_discover_root, 'value')
    call lh#let#if_undef('p:paths.sources', auto_discover_root.value)
  elseif auto_discover_root !~? '\v^(n%[o]|0)$'
    if ! lh#project#exists('p:paths.sources')
      let root = lh#project#root()
      if !empty(root)
        call lh#let#if_undef('p:paths.sources', root[:-2])
      endif
    endif
  endif
  return project
endfunction

" Function: lh#project#define(s:, params [, name]) {{{3
function! lh#project#define(s, params, ...) abort
  let name = get(a:, 1, 'project')
  if !has_key(a:s, name)
    let a:s[name] = lh#project#new(a:params)
  else
    call a:s[name].register_buffer()
  endif
  return a:s[name]
endfunction

" # Access {{{2
" Function: lh#project#is_in_a_project() {{{3
function! lh#project#is_in_a_project() abort
  return exists('b:'.s:project_varname)
endfunction

" Function: lh#project#crt() {{{3
function! lh#project#crt() abort
  if lh#project#is_in_a_project()
    return b:{s:project_varname}
  else
    return lh#option#unset()
    " throw "The current buffer doesn't belong to a project"
  endif
endfunction

" Function: lh#project#crt_bufvar_name() {{{3
function! lh#project#crt_bufvar_name() abort
  if lh#project#is_in_a_project()
    return 'b:'.s:project_varname
  else
    throw "The current buffer doesn't belong to a project"
  endif
endfunction

" Function: lh#project#_crt_var_name(var) {{{3
function! lh#project#_crt_var_name(var) abort
  " call assert_true(a:var =~ '^p:')
  let [all, kind, name; dummy] = matchlist(a:var, '\v^p:([&$])=(.*)')
  if lh#project#is_in_a_project()
    if kind == '&'
      return
            \ { 'name'    : a:var[2:]
            \ , 'realname': 'b:'.s:project_varname.'.options.'.name
            \ , 'project' : b:{s:project_varname}
            \ }
    elseif kind == '$'
      return
            \ { 'name'    : a:var[2:]
            \ , 'realname': 'b:'.s:project_varname.'.env.'.name
            \ , 'project' : b:{s:project_varname}
            \ }
    else
      return 'b:'.s:project_varname.'.variables.'.name
    endif
  else
    if kind == '&'
      return 'l&:'.name
    elseif kind == '$'
      throw "Cannot set `".a:var."` locally without an active project"
    else
      return 'b:'.name
    endif
  endif
endfunction

" Function: lh#project#_get(name) {{{3
function! lh#project#_get(name) abort
  if lh#project#is_in_a_project()
    return b:{s:project_varname}.get(a:name)
  else
    return lh#option#unset()
  endif
endfunction

" Function: lh#project#_environment() {{{3
function! lh#project#_environment() abort
  if lh#project#is_in_a_project()
    return b:{s:project_varname}.environment()
  else
    return []
  endif
endfunction

" Function: lh#project#exists(var) {{{3
function! lh#project#exists(var) abort
  if a:var =~ '^p:'
    return b:{s:project_varname}.exists(a:var)
  else
    return exists(a:var)
  endif
endfunction

" # Find project root {{{2
let s:project_roots = get(s:, 'project_roots', [])
" Function: lh#project#root() {{{3
" @post result is empty, or result[-1] =~ [/\]
function! lh#project#root() abort
  " Will be searched in descending priority in:
  " - p:paths.sources
  " - b:project_source_dir (mu-template)
  " - Where .git/ is found is parent dirs
  " - Where .svn/ is found in parent dirs
  " - confirm box for %:p:h, and remember previous paths
  "
  " @note Once set for files in a project, it isn't expected to change.
  "
  " @warning p:paths.sources is overridden by child projects.
  let prj_dirname = lh#option#get('paths.sources')
  if lh#option#is_unset(prj_dirname)
    unlet prj_dirname
    let prj_dirname = s:FetchPrjDirname()
    if   ! isdirectory(prj_dirname)
      return ''
    elseif empty(prj_dirname)
      return prj_dirname
    endif
    " Don't update p:paths.sources from here
  endif

  let res = lh#path#to_dirname(prj_dirname)
  return res
endfunction

function! s:FetchPrjDirname() abort " {{{3
  " mu-template variable
  let project_sources_dir = lh#option#get('project_sources_dir')
  if lh#option#is_set(project_sources_dir)
    return project_sources_dir
  endif

  " VCS
  let prj_dirname = lh#vcs#get_git_root()
  if !empty(prj_dirname)
    return fnamemodify(prj_dirname, ':p:h:h')
  endif
  let prj_dirname = lh#vcs#get_svn_root()
  if !empty(prj_dirname)
    return fnamemodify(prj_dirname, ':p:h:h')
  endif

  " Deduce from current path, previous project paths
  return s:GetPlausibleRoot()
endfunction

function! s:GetPlausibleRoot() abort " {{{3
  call s:Callstack("Request plausible root")
  let crt = expand('%:p:h')
  let compatible_paths = filter(copy(s:project_roots), 'lh#path#is_in(crt, v:val)')
  if len(compatible_paths) == 1
    return compatible_paths[0]
  endif
  if len(compatible_paths) > 1
    let prj_dirname = lh#path#select_one(compatible_paths, "Project needs to know the current project root directory")
    if !empty(prj_dirname)
      return prj_dirname
    endif
  endif
  let auto_discover_root = lh#project#_auto_discover_root()
  if auto_discover_root == 'in_doubt_ask'
    let prj_dirname = INPUT("prj needs to know the current project root directory.\n-> ", expand('%:p:h'))
  elseif auto_discover_root == 'in_doubt_ignore'
    return ''
  elseif auto_discover_root == 'in_doubt_improvise'
    let prj_dirname = expand('%:p:h')
  endif
  if !empty(prj_dirname)
    call lh#path#munge(s:project_roots, prj_dirname)
  endif
  return prj_dirname
endfunction
" }}}1

"------------------------------------------------------------------------
" ## Internal functions {{{1
" # Options {{{2
" Function: lh#project#_auto_discover_root() {{{3
" Accepted vaues:
" - 1, y%[es]
" - 0, n%[o]
" - in_doubt_ask
" - in_doubt_ignore
" - in_doubt_improvise
" - { 'value': path }
function! lh#project#_auto_discover_root() abort
  return lh#option#get('lh#project.auto_discover_root', 'in_doubt_ask', 'g')
endfunction
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
" ## autocommands {{{1
" # New buffer => update options {{{2
function! lh#project#_UseProjectOptions() " {{{3
  let prj = lh#project#crt()
  if lh#option#is_set(prj)
    call prj._use_options(bufnr('%'))
  endif
endfunction

" # Remove buffer {{{2
function! lh#project#_RemoveBufferFromProjectConfig(bname) " {{{3
  let prj = lh#project#crt()
  if lh#option#is_set(prj)
    let bid = bufnr(a:bname)
    call s:Verbose('Remove buffer %1 from project %2', bid, prj)
    call prj._remove_buffer(bid)
  endif
endfunction

" # Update lcd {{{2
function! lh#project#_CheckUpdateCWD() abort " {{{3
  if lh#option#get('lh#project.autochdir', 0, 'g') == 1
    let path = lh#option#get('paths.sources')
    if lh#option#is_set(path) && path != getcwd() && isdirectory(path)
      call s:Verbose('auprjchdir %1 -> %2', expand('%'), path)
      exe 'lcd '.path
    endif
  endif
endfunction
"------------------------------------------------------------------------
" ## Internal globals {{{1
let s:project_list = get(s:, 'project_list', lh#project#_make_project_list())
"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
