"=============================================================================
" File:         autoload/lh/project.vim                           {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      5.2.2
let s:k_version = '522'
" Created:      08th Sep 2016
" Last Update:  26th Sep 2020
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
"   - lh#project#_best_varname_match()
" - Use in plugins
"   - p:$ENV variables
"     - [X] lh-tags synchronous (via lh#os#system)
"     - [X] lh-tags asynchronous (via lh#async)
"     - [X] BTW synchronous (via lh#os#make)
"     - [X] BTW asynchronous (via lh#async)
"     - [ ] BTW -> QFImport b:crt_project
"     - [ ] lh-dev
"     - [ ] µTemplate
"     -> Test on windows!
"   - Have let-modeline support p:var, p:&opt, and p:$env
" - Setlocally vim options on new files
" - Simplify dictionaries
"   -> no 'parents' when there are none!
"   -> merge 'variables', 'env', 'options' in `variables`
" - Fix find_holder() to use update() code and refactor the later
" - Add VimL Syntax highlight for LetTo, LetIfUndef, p:var
" - Serialize and deserialize options from a file that'll be maintained
"   alongside a _vimrc_local.vim file.
"   Expected Caveats:
"   - How to insert a comment near each variable serialized
"   - How to computed value at the last moment (e.g. path relative to current
"     directory, and have the variable hold an absolute path)
" - Without permission lists + _local_vimrc, it seems to try to detect project
"   root each time we change buffer
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim

let g:lh#project#varname = get(g:, 'lh#project#varname', 'crt_project')
let s:project_varname    = g:lh#project#varname
let s:k_unset            = lh#option#unset()

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
" # Define a new project {{{2
" Function: lh#project#new(params) {{{3
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
function! lh#project#new(params) abort
  return lh#project#object#_new(a:params)
endfunction

" Function: lh#project#define(s:, params [, name]) {{{3
function! lh#project#define(s, params, ...) abort
  return call('lh#project#object#_define', [a:s, a:params] + a:000)
endfunction

" # Access {{{2
" Function: lh#project#is_a_project(dict) {{{3
function! lh#project#is_a_project(dict) abort
  return type(a:dict) == type({})
        \ && lh#object#is_an_object(a:dict)
        \ && a:dict.__lhvl_oo_type() == 'project'
endfunction

" Function: lh#project#is_in_a_project() {{{3
function! lh#project#is_in_a_project() abort
  let res = exists('b:'.s:project_varname)
  call lh#assert#true(!res || (lh#option#is_set(b:{s:project_varname}) && (b:{s:project_varname} != lh#option#unset())), 'b:'.s:project_varname.' shall not be unset if it exists!')
  return res
endfunction

" Function: lh#project#crt([bufid]) {{{3
function! lh#project#crt(...) abort
  if a:0 > 0
    let bufid = a:1
    let prj = lh#option#getbufvar(bufid, s:project_varname)
    return prj
  elseif lh#project#is_in_a_project()
    return b:{s:project_varname}
  else
    return s:k_unset
    " throw "The current buffer doesn't belong to a project"
  endif
endfunction

" Function: lh#project#_get_varname() {{{3
function! lh#project#_get_varname() abort
  return s:project_varname
endfunction

" Function: lh#project#crt_bufvar_name() {{{3
function! lh#project#crt_bufvar_name() abort
  if lh#project#is_in_a_project()
    return 'b:'.s:project_varname
  else
    throw "The current buffer doesn't belong to a project"
  endif
endfunction

" Function: lh#project#_crt_var_name(var [, hide_or_overwrite]) {{{3
" @return a string for variables, p:local, or b:local
" @return a dict for p:&opt, and p:$ENV
" @return a string for b:&opt
" @throw for b:$ENV
let s:k_store_for =
      \ { 'v': 'variables'
      \ , '&': 'options'
      \ , '$': 'env'
      \ }
function! lh#project#_crt_var_name(var, ...) abort
  if a:var =~ '^p:'
    let [all, kind, name; dummy] = matchlist(a:var, '\v^p:([&$])=(.*)')
  elseif a:var =~ '^&p:'
    let [all, kind, name; dummy] = matchlist(a:var, '\v^(\&)p:(.*)')
  else
    call lh#assert#unexpected('Unexpected variable name '.string(a:var))
  endif
  if  empty(kind)
    " In order to resist !has("patch-7.4-1707")
    let kind = 'v'
  endif
  if lh#project#is_in_a_project()
    let hide_or_overwrite = get(a:, 1, '') " empty <=> 'hide'
    call lh#assert#value(hide_or_overwrite).match('\v\c(hide|overwrite|)')
    let shall_overwrite = hide_or_overwrite =~? 'overwrite'
    " TODO: Breaks old test => need to make a choice, or intrduce a new command ...
    if shall_overwrite
      let best_name = lh#project#_best_varname_match(kind, name)
    else
      let realname = 'b:'.s:project_varname.'.'.get(s:k_store_for, kind, 'variables').'.'.name
    endif
    if kind == 'v'
      return shall_overwrite ? best_name.realname : realname
    else
      let varname = kind.name
      return shall_overwrite
            \ ? extend(best_name, {'name': varname})
            \ : { 'name'    : varname
            \   , 'realname': realname
            \   , 'project' : b:{s:project_varname}
            \   }
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

" Function: lh#project#_get(name [, bufid]) {{{3
" FIXME: break cycle between lh#project and lh#option!
function! lh#project#_get(name, ...) abort
  if a:0 > 0
    let bufid = a:1
    let prj = lh#option#getbufvar(bufid, s:project_varname)
    if lh#option#is_set(prj)
      return prj.get(a:name)
    endif
  endif
  if lh#project#is_in_a_project()
    call lh#assert#value(b:{s:project_varname}).has_key('get')
    return b:{s:project_varname}.get(a:name)
  else
    return s:k_unset
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
  if a:var =~ '^p:' && lh#project#is_in_a_project()
    return b:{s:project_varname}.exists(a:var[2:])
  else
    return exists(a:var)
  endif
endfunction

" Function: lh#project#_best_varname_match(kind, name) {{{3
" Given:
" - p{parent}:foo.bar = ...
" - p{parent}:d2      = ...
" - p{crt}:foo.b2     = ...
" Then:
" - lh#project#_best_varname_match(kind, 'foo') -> crt
" - lh#project#_best_varname_match(kind, 'foo.b2') -> crt
" - lh#project#_best_varname_match(kind, 'toto') -> crt
" - lh#project#_best_varname_match(kind, 'foo.bar') -> parent
" - lh#project#_best_varname_match(kind, 'd2') -> parent
" - lh#project#_best_varname_match(kind, 'd2.l2') -> parent
function! lh#project#_best_varname_match(kind, name) abort
  call lh#assert#true(lh#project#is_in_a_project())

  let store = get(s:k_store_for, a:kind, 'variables')
  let varname = '.'.store.'.'.a:name
  let absvarname = 'b:'.s:project_varname.varname
  let prj = b:{s:project_varname}
  let res = {'project': prj}
  let holded_name = prj.find_holder_name(a:name, store)
  if !empty(holded_name)
    let res.realname = 'b:'.s:project_varname.holded_name.a:name
    " return 'b:'.s:project_varname.holded_name.a:name
  else
    let parts = split(a:name, '\.')
    if len(parts) == 1
      " This is a the smallest part
      " return absvarname
      let res.realname = absvarname
    else
      " try for something smaller to see where it would go
      let res = lh#project#_best_varname_match(a:kind, join(parts[:-2], '.'))
      let res.realname .= '.'.parts[-1]
    endif
  endif
  " return 'b:'.s:project_varname.'.variables.'.a:name
  return res
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
  " TODO: provide an option to set the list of variables to test
  " mu-template: project_sources_dir
  let prj_dirname = lh#project#_check_project_variables(['project_sources_dir'])
  if lh#option#is_set(prj_dirname)
    return prj_dirname
  endif

  " VCS & co
  let vcs_dirname = lh#project#_check_VCS_roots()
  if lh#option#is_set(vcs_dirname)
    return vcs_dirname
  endif

  " Deduce from current path, previous project paths
  return s:GetPlausibleRoot()
endfunction

function! s:GetPlausibleRoot() abort " {{{3
  call s:Callstack("Request plausible root")
  let crt = expand('%:p:h')
  call s:Verbose('s:GetPlausibleRoot() -- project roots: %1', s:project_roots)
  let compatible_paths = filter(copy(s:project_roots), 'lh#path#is_in(crt, v:val)')
  call s:Verbose('s:GetPlausibleRoot() -- Compatible paths: %1', compatible_paths)
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
  call s:Verbose('s:GetPlausibleRoot() -- auto discover root: %1', auto_discover_root)
  if auto_discover_root == 'in_doubt_ask'
    if s:permission_lists.check_paths([ expand('%:p')])
      let prj_dirname = lh#ui#input("prj needs to know the current project root directory.\n-> ", expand('%:p:h'))
    else
      let prj_dirname = ''
    endif
  elseif auto_discover_root == 'in_doubt_ignore'
    return ''
  elseif auto_discover_root == 'in_doubt_improvise'
    let prj_dirname = expand('%:p:h')
  endif
  if !empty(prj_dirname)
    call lh#path#munge(s:project_roots, prj_dirname)
  endif
  call s:Verbose('s:GetPlausibleRoot -> %1', prj_dirname)
  return prj_dirname
endfunction

" Function: lh#project#_check_project_variables(varnames) {{{3
" Different plugins will use different variables to store where the
" sources of their project is stored.
" This function will search which variable is set
" @since Version 4.6.0
let s:k_unset_no_prj_var = lh#option#unset('No project variable detected')
function! lh#project#_check_project_variables(varnames) abort
  for varname in a:varnames
    let simple_case = type(varname) == type('string')
    let the_varname = simple_case ? varname : varname[0]
    let dirname = lh#option#get(the_varname)
    call s:Verbose("get(%1) -> %2", the_varname, dirname)
    if lh#option#is_set(dirname)
      if ! simple_case
        let dirname2 = lh#dict#get_composed(dirname, varname[1])
        if lh#option#is_unset(dirname2)
          call lh#common#warning_msg(varname[0].' is set, but `'.join(varname, '.').'` is empty')
          unlet dirname2
          continue
        endif
      endif
      return dirname
    endif
    unlet varname
    unlet dirname
  endfor
  return s:k_unset_no_prj_var
endfunction

" Function: lh#project#_check_VCS_roots() {{{3
" @since Version 4.6.0
let s:k_unset_no_VCS_dir = lh#option#unset('No VCS directory detected')
function! lh#project#_check_VCS_roots() abort
  let possible_prj_dirnames = map(copy(g:lh#project.root_patterns), '[v:val, lh#path#find_upward(v:val)]')
  call filter(possible_prj_dirnames, '!empty(v:val[1])')
  " TODO: permit to sort result by depth instead of patterns order
  if !empty(possible_prj_dirnames)
    call s:Verbose("s:FetchPrjDirname() -> %1 found in %2", possible_prj_dirnames[0][0], possible_prj_dirnames[0][1])
    return possible_prj_dirnames[0][1]
  endif
  return s:k_unset_no_VCS_dir
endfunction

" # Permission lists management {{{2
" Function: lh#project#lists() {{{3
function! lh#project#permission_lists() abort
  return g:lh#project.permissions
endfunction

" Function: lh#project#munge(listname, path) {{{3
function! lh#project#munge(listname, path) abort
  return lh#path#munge(g:lh#project.permissions[a:listname], a:path)
endfunction

" Function: lh#project#filter_list(listname, expr) {{{3
function! lh#project#filter_list(listname, expr) abort
  return filter(g:lh#project.permissions[a:listname], a:expr)
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
" # Misc {{{2
" Function: lh#project#is_eligible([bid]) {{{3
function! lh#project#is_eligible(...) abort
  if a:0 > 0
    return (lh#option#getbufvar(a:1, '&ft', '') != 'qf') && ! lh#path#is_distant_or_scratch(bufname(a:1))
  else
    return (&ft != 'qf') && ! lh#path#is_distant_or_scratch(expand('%:p'))
  endif
endfunction

" Function: lh#project#__buffer(bid) {{{3
function! lh#project#__buffer(bid) abort
  return get(s:buffers, a:bid, '???')
endfunction

" Function: lh#project#__register_buffer(bid, value) {{{3
function! lh#project#__register_buffer(bid, value) abort
  let s:buffers[a:bid] = a:value
endfunction

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
" ## autocommands {{{1
" # Post local vimrc hook {{{2
" Function: lh#project#_post_local_vimrc() {{{3
function! lh#project#_post_local_vimrc() abort
  call s:Verbose('lh#project#_post_local_vimrc() {')
  call lh#project#_auto_detect_project()
  call lh#project#_UseProjectOptions()
  call s:Verbose('lh#project#_post_local_vimrc() }')
endfunction

" Function: lh#project#_auto_detect_project() {{{3
function! lh#project#_auto_detect_project() abort
  call s:Verbose('lh#project#_auto_detect_project')
  let auto_detect_projects = lh#option#get('lh#project.auto_detect', 0, 'g')
  " If there already is a project defined
  " Or if this is the quickfix window
  " => abort
  if auto_detect_projects && ! lh#project#is_in_a_project() && lh#project#is_eligible()
    let root = lh#project#root()
    if !empty(root) && s:permission_lists.check_paths([root]) == 1
      let prj = lh#project#list#_find_best(root)
      if lh#option#is_set(prj) " Reuse the existing project
        call prj._register_buffer()
      else " Detect where the project is
        " TODO: recognize patterns such as src|source to search the project in
        " the upper directory
        let repo_path = lh#vcs#decode_github_url(lh#vcs#get_url(root))
        if !empty(repo_path)
          let name = repo_path[-1]
        else
          let name = fnamemodify(root, ':h:t')
        endif
        let name = (name[0] =~ '\d' ? '_' : '') . substitute(name, '[^A-Za-z0-9_]', '_', 'g')
        let opt = {'name': name}
        let opt.auto_discover_root = {'value':  root}
        call lh#project#define(s:, opt, name)
      endif
    endif
  endif
  if lh#project#is_in_a_project() && lh#project#is_eligible()
    call lh#assert#true(index(lh#project#crt().buffers, eval(bufnr('%'))) >= 0)
  endif
endfunction

function! lh#project#_UseProjectOptions() " {{{3
  call s:Verbose('lh#project#_UseProjectOptions')
  " # New buffer => update options
  let prj = lh#project#crt()
  if lh#option#is_set(prj)
    let bid = bufnr('%')
    call prj._use_options(bid)
    call prj._register_local_menus(bid)
  endif
endfunction

" # Remove buffer {{{2
function! lh#project#_RemoveBufferFromProjectConfig(bnum) " {{{3
  let bid = eval(a:bnum) " Be sure this is a number and not a string!
  let prj = lh#project#crt(bid)
  if lh#option#is_set(prj)
    call s:Verbose('Remove buffer %1 from project %2', bid, prj)
    call prj._remove_buffer(bid)
    let b_vars = getbufvar(bid, '')
    call remove(b_vars, lh#project#_get_varname())
  endif
endfunction

" # Update lcd {{{2
function! lh#project#_CheckUpdateCWD() abort " {{{3
  if lh#option#get('lh#project.auto_chdir', 0, 'g') == 1
    let path = lh#option#get('paths.sources')
    if lh#option#is_set(path) && path != getcwd() && isdirectory(path)
      call s:Verbose('auto prj chdir %1 -> %2', expand('%'), path)
      call lh#os#lcd(path)
    endif
  endif
endfunction
"------------------------------------------------------------------------
" ## globals {{{1
" # Public globals {{{2
" - patterns where to search root directories {{{3
" Files must be added without a trailing slash
LetIfUndef g:lh#project.root_patterns = ['.git/', '.svn/', '.hg/', '_darcs/', '.bzr/']

" - blacklists & co for auto_detect_projects {{{3
LetIfUndef g:lh#project.permissions             {}
LetIfUndef g:lh#project.permissions.whitelist   []
LetIfUndef g:lh#project.permissions.blacklist   []
LetIfUndef g:lh#project.permissions.asklist     []
LetIfUndef g:lh#project.permissions.sandboxlist []
LetIfUndef g:lh#project.permissions._action_name = 'recognize a project at'

" Accept $HOME, but nothing from parent directories
if         index(g:lh#project.permissions.whitelist, $HOME)   < 0
      \ && index(g:lh#project.permissions.blacklist, $HOME)   < 0
      \ && index(g:lh#project.permissions.sandboxlist, $HOME) < 0
  call lh#project#munge('asklist', $HOME)
endif
call lh#project#munge('blacklist', fnamemodify('/', ':p'))
" TODO: add other disks in windows

" The directories where projects (we trust) are stored shall be added into
" whitelist

" # Internal globals {{{2
let s:permission_lists = lh#path#new_permission_lists(g:lh#project.permissions)
" s:buffers is debug variable used to track disapearing buffers
let s:buffers = get(s:, 'buffers', {})

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
