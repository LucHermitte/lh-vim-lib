"=============================================================================
" File:         autoload/lh/project.vim                           {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0
let s:k_version = '400'
" Created:      08th Sep 2016
" Last Update:  01st Dec 2016
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
" - :Project [<name>] :make
"   -> rely on `:Make` if it exists, `:make` otherwise
" - Toggling:
"   - at global level: [a, b, c]
"   - at project level: [default value from global VS force [a, b, c]]
" - Have menu priority + menu name in all projects in order to simplify
"   toggling definitions
" - Completion on :Let* and :Unlet for inherited p:variables
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
"   - paths.sources
" - Be able to control which parent is filled with lh#let# functions
" - Setlocally vim options on new files
" - :Project <name> :bw -> with confirmation!
" - Simplify dictionaries
"   -> no 'parents' when there are none!
"   -> merge 'variables', 'env', 'options' in `variables`
" - Fix find_holder() to use update() code and refactor the later
" - Have let-modeline support p:var, p:&opt, and p:$env
" - Add convinience functions to fill permission lists
" - Add VimL Syntax highlight from LetTo, LetIfUndef, p:var
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
" # Project list {{{2

" Function: lh#project#_make_project_list() {{{3
function! lh#project#_make_project_list() abort
  let res = lh#object#make_top_type(
        \ { 'name': 'project_list'
        \ , 'projects': {}
        \ , '_next_id': 1
        \ })
  let res.new_name             = function(s:getSNR('new_name'))
  let res.add_project          = function(s:getSNR('add_project'))
  let res.get                  = function(s:getSNR('get_project'))
  let res.clear                = function(s:getSNR('clear_projects'))
  let res.clear_empty_projects = function(s:getSNR('clear_empty_projects'))
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

" Function: lh#project#_clear_empty_projects() {{{3
function! lh#project#_clear_empty_projects() abort
  call s:project_list.clear_empty_projects()
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
      return get(self.projects, a:1, s:k_unset)
    endif
  endif
endfunction

function! s:clear_projects() dict abort " {{{4
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

function! s:clear_empty_projects() dict abort " {{{4
  " remove empty projects
  call filter(self.projects, '!empty(v:val.buffers)')
endfunction

" # :Project Command definition {{{2
function! s:As_ls(bid) abort " {{{3
  let name = bufname(a:bid)
  if empty(name)
    let name = 'Used to be known as: '.get(s:buffers, a:bid, '???')
  endif
  return printf('%3d%s %s'
        \ , a:bid
        \ , (buflisted(a:bid) ? ' ' : 'u')
        \ . (bufnr('%') == a:bid ? '%' : bufnr('#') == a:bid ? '#' : ' ')
        \ . (! bufloaded(a:bid) ? ' ' : bufwinnr(a:bid)<0 ? 'h' : 'a')
        \ . (! getbufvar(a:bid, "&modifiable") ? '-' : getbufvar(a:bid, "&readonly") ? '=' : ' ')
        \ . (getbufvar(a:bid, "&modified") ? '+' : ' ')
        \ , '"'.name.'"')
endfunction

function! s:ls_project(prj) abort " {{{3
  if lh#option#is_unset(a:prj)
    echo '(no project specified!)'
  endif
  let lines = map(copy(a:prj.buffers), 's:As_ls(v:val)')
  echo "Buffer list of ".get(a:prj, 'name', '(unnamed)')." project:"
  echo join(lines, "\n")
endfunction

function! s:cd_project(prj, path) abort " {{{3
  if lh#option#is_unset(a:prj)
    throw "Cannot apply :cd on non existant projects"
  endif
  let path = expand(a:path)
  if !isdirectory(path)
    throw "Invalid directory `".path."`!"
  endif
  call lh#dict#add_new(a:prj.variables, {'paths': {}})
  " Explicit :cd => force the path
  let a:prj.variables.paths.sources = fnamemodify(lh#path#simplify(path), ':p')
  " Then, for all windows displaying a buffer from the project: update :lcd
  let windows = filter(range(1, winnr('$')), 'index(a:prj.buffers, winbufnr(v:val)) >= 0')
  call map(windows, 'win_getid(v:val)')
  let crt_win = win_getid()
  try
    for w in windows
      call win_gotoid(w)
      " We must use the most precise path.
      exe 'lcd '.lh#option#get('paths.sources')
    endfor
  finally
    call win_gotoid(crt_win)
  endtry
endfunction

function! s:echo_project(prj, var) abort " {{{3
  let val = a:prj.get(a:var)
  if lh#option#is_set(val)
    echo 'p:{'.a:prj.name.'}.'.a:var.' -> '.lh#object#to_string(val)
  else
    call lh#common#warning_msg('No `'.a:var.'` variable in `'.a:prj.name. '` project')
  endif
endfunction

function! s:let_project(prj, var, lVal) abort " {{{3
  let value0 = join(a:lVal, ' ')
  let [all, compound, equal, value ; rem] = matchlist(value0, '\v^\s=%(([+-/*.])\=|(\=))\s*(.*)$')
  if !empty(compound)
    let old = a:prj.get(a:var)
    if compound == '*'
      exe 'let old = old * '.value
    elseif compound == '/'
      exe 'let old = old / '.value
    else
      exe 'let old '.compound.'= '.value
    endif
    call a:prj.update(a:var, old)
  else
    call a:prj.set(a:var, eval(value))
  endif
endfunction

function! s:doonce_project(prj, cmd) abort " {{{3
  if lh#option#is_unset(a:prj)
    throw "Cannot apply :doonce on non existant projects"
  endif
  " In case of bug in lh#project#_RemoveBufferFromProjectConfig(), keep only
  " listed buffers.
  let buffers = filter(copy(a:prj.buffers), 'buflisted(v:val)')
  if empty(buffers)
    throw "Project has no active buffer => abort (".string(a:cmd).')'
  endif
  if index(buffers, bufnr('%')) >= 0
    call s:Verbose('Execute once in current windows: %1', a:cmd)
    exe join(a:cmd, ' ')
  else
    let crt_win = win_getid()
    let cleanup = lh#on#exit()
          \.register('call win_gotoid('.crt_win.')')
    try
      let windows = filter(range(1, winnr('$')), 'index(buffers, winbufnr(v:val)) >= 0')
      if ! empty(windows)
        call map(windows, 'win_getid(v:val)')
        call win_gotoid(windows[0])
        call s:Verbose('Execute once in windows %2 (%3): %1', a:cmd, windows[0], bufnr('%'))
        exe join(a:cmd, ' ')
      else
        " No buffer from the project is opened in any window, and yet the
        " project has buffers => open a buffer in a new window and execute
        call lh#window#create_window_with('sp '.bufname(buffers[0]))
        call cleanup.register(':silent! q', 'priority')
        call s:Verbose('Execute once in a window created for the occasion (%2): %1', a:cmd, bufnr('%'))
        exe join(a:cmd, ' ')
      endif
    finally
      call cleanup.finalize()
    endtry
  endif
endfunction

function! s:windo_project(prj, cmd) abort " {{{3
  if lh#option#is_unset(a:prj)
    throw "Cannot apply :windo on non existant projects"
  endif
  " In case of bug in lh#project#_RemoveBufferFromProjectConfig(), keep only
  " listed buffers.
  let buffers = filter(copy(a:prj.buffers), 'buflisted(v:val)')
  if empty(buffers)
    throw "Project has no active buffer => abort (".string(a:cmd).')'
  endif
  let crt_win = win_getid()
  let cleanup = lh#on#exit()
        \.register('call win_gotoid('.crt_win.')')
  try
    let windows = filter(range(1, winnr('$')), 'index(buffers, winbufnr(v:val)) >= 0')
    if empty(windows)
      call lh#common#warning_msg('Project '.a:prj.name.' has no active window => nothing is executed')
    endif
    call map(windows, 'win_getid(v:val)')
    for win in windows
      call win_gotoid(win)
      call s:Verbose('Execute in windows %2 (%3): %1', a:cmd, win, bufnr('%'))
      exe join(a:cmd, ' ')
    endfor
  finally
    call cleanup.finalize()
  endtry
endfunction

function! s:bufdo_project(prj, cmd) abort " {{{3
  if lh#option#is_unset(a:prj)
    throw "Cannot apply :bufdo on non existant projects"
  endif
  " In case of bug in lh#project#_RemoveBufferFromProjectConfig(), keep only
  " listed buffers.
  let buffers = filter(copy(a:prj.buffers), 'buflisted(v:val)')
  if empty(buffers)
    throw "Project has no active buffer => abort (".string(a:cmd).')'
  endif
  try
    call lh#window#create_window_with('sp '.bufname(buffers[0]))
    let cleanup = lh#on#exit()
          \.register(':silent! q')
    call s:Verbose('Execute in a window created for the occasion (%2): %1', a:cmd, bufnr('%'))
    exe join(a:cmd, ' ')
    for buf in buffers[1:]
      silent! exe 'b ' . buf
      exe join(a:cmd, ' ')
    endfor
  finally
    call cleanup.finalize()
  endtry
endfunction

function! s:define_project(prjname) abort " {{{3
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

function! s:show_related_projects(...) abort " {{{3
  let prj = a:0 == 0 ? lh#project#crt() : a:1
  if lh#option#is_unset(prj)
    echo "(current buffer is under no project)"
    return
  endif
  let lvl = a:0 == 0 ? 0                : a:2
  " Let's assume there is no recursion
  echo repeat('  ', lvl) . '- '.prj.name
  for p in prj.parents
    call s:show_related_projects(p, lvl+1)
  endfor
endfunction

" Function: lh#project#_command([prjname]) abort {{{3
let s:k_usage =
      \ [ ':Project USAGE:'
      \ , '  :Project --list              " list existing projects'
      \ , '  :Project --define <name>     " define a new project/register current buffer'
      \ , '  :Project --which             " list projects to which the current buffer belongs'
      \ , '  :Project [<name>] :ls        " list buffers belonging to the project'
      \ , '  :Project [<name>] :cd <path> " change directory to <path>'
      \ , '  :Project [<name>] :echo      " echo state of a project variable'
      \ , '  :Project [<name>] :let       " set state of a project variable'
      \ , '  :Project [<name>] :bufdo[!]  " execute a command on all buffers belonging to the project'
      \ , '  :Project [<name>] :windo[!]  " execute a command on all opened windows belonging to the project'
      \ , '  :Project [<name>] :doonce    " execute a command on the first opened window found which belongs to the project'
      \ ]
function! lh#project#_command(...) abort
  " TODO: Merge cases.
  if     a:1 =~ '-\+u\%[sage]'  " {{{4
    call lh#common#warning_msg(s:k_usage)
  elseif a:1 =~ '-\+h\%[elp]'
    help :Project
  elseif a:1 =~ '^-\+l\%[ist]$' " {{{4
    let projects = s:project_list.get()
    if empty(projects)
      echo "(no project defined)"
    else
      echo join(keys(projects), "\n")
    endif
  elseif a:1 =~ '\v^--which$'   " {{{4
    call s:show_related_projects()
  elseif a:1 =~ '\v^--define$'  " {{{4
    if a:0 != 2
      throw "`:Project --define` expects a project-name as only argument"
    endif
    call s:define_project(a:2)
  elseif a:1 =~ '^:'            " -- commands {{{4
    let prj = lh#project#crt()
    if lh#option#is_unset(prj)
      throw "The current buffer doesn't belong to any project"
    endif
    if     a:1 =~ '\v^:l%[s]$'     " {{{5
      call s:ls_project(prj)
    elseif a:1 =~ '\v^:echo$'      " {{{5
      if a:0 != 2
        throw "Not enough arguments to `:Project :echo`"
      endif
      call s:echo_project(prj, a:2)
    elseif a:1 =~ '\v^:let$'       " {{{5
      if a:0 < 3
        throw "Not enough arguments to `:Project :let`"
      endif
      call s:let_project(prj, a:2, a:000[2:])
    elseif a:1 =~ '\v^:cd$'        " {{{5
      if a:0 != 2
        throw "Not enough arguments to `:Project :cd`"
      endif
      call s:cd_project(prj, a:2)
    elseif a:1 =~ '\v^:doonce'     " {{{5
      if a:0 < 2
        throw "Not enough arguments to `:Project :doonce`"
      endif
      call s:doonce_project(prj, a:000[1:])
    elseif a:1 =~ '\v^:bufdo'      " {{{5
      if a:0 < 2
        throw "Not enough arguments to `:Project :bufdo`"
      endif
      call s:bufdo_project(prj, a:000[1:])
    elseif a:1 =~ '\v^:windo'      " {{{5
      if a:0 < 2
        throw "Not enough arguments to `:Project :windo`"
      endif
      call s:windo_project(prj, a:000[1:])
    elseif a:1 =~ '\v^--define$'   " {{{5
      call s:define_project(a:2)
    else                           " -- unknown command {{{5
      throw "Unexpected `:Project ".a:1."` subcommand"
    endif
  else                          " -- project name specified {{{4

    let prj_name = a:1
    let prj = s:project_list.get(prj_name)
    if lh#option#is_unset(prj)
      throw "There is no project named `".prj_name."`"
    endif
    if a:0 < 2
      throw "Not enough arguments to `:Project name`"
    endif
    if     a:2 =~ '\v^:=l%[s]$'    " {{{5
      call s:ls_project(prj)
    elseif a:2 =~ '\v^:=echo$'     " {{{5
      if a:0 != 3
        throw "Not enough arguments to `:Project <name> :echo`"
      endif
      call s:echo_project(prj, a:3)
    elseif a:2 =~ '\v^:=let$'      " {{{5
      if a:0 < 4
        throw "Not enough arguments to `:Project <name> :let`"
      endif
      call s:let_project(prj, a:3, a:000[3:])
    elseif a:2 =~ '\v^:=cd$'       " {{{5
      if a:0 != 3
        throw "Not enough arguments to `:Project <name> :cd`"
      endif
      call s:cd_project(prj, a:3)
    elseif a:2 =~ '\v^:=doonce$'   " {{{5
      if a:0 < 3
        throw "Not enough arguments to `:Project <name> :doonce`"
      endif
      call s:doonce_project(prj, a:000[2:])
    elseif a:2 =~ '\v^:=bufdo$'    " {{{5
      if a:0 < 3
        throw "Not enough arguments to `:Project <name> :bufdo`"
      endif
      call s:bufdo_project(prj, a:000[2:])
    elseif a:2 =~ '\v^:=windo$'    " {{{5
      if a:0 < 3
        throw "Not enough arguments to `:Project <name> :windo`"
      endif
      call s:windo_project(prj, a:000[2:])
    else                           " -- unknown command {{{5
      throw "Unexpected `:Project ".a:2."` subcommand"
    endif
  endif

  " }}}5
endfunction

" Function: lh#project#_complete_command(ArgLead, CmdLine, CursorPos) {{{3
function! lh#project#_complete_command(ArgLead, CmdLine, CursorPos) abort
  let [pos, tokens; dummy] = lh#command#analyse_args(a:ArgLead, a:CmdLine, a:CursorPos)

  if     1 == pos
    let res = ['--list', '--define', '--which', '--help', '--usage', ':ls', ':echo', ':let', ':cd', ':doonce', ':bufdo', ':windo'] + map(copy(keys(s:project_list.projects)), 'escape(v:val, " ")')
  elseif     (2 == pos && tokens[pos-1] =~ '\v^:echo$')
        \ || (3 == pos && tokens[pos-1] =~ '\v^:=echo$')
    let prj = s:project_list.get(pos == 3 ? tokens[pos-2] : s:k_unset)
    let res = s:list_var_for_complete(prj, a:ArgLead)
  elseif     (2 == pos && tokens[pos-1] =~ '\v^:let$')
        \ || (3 == pos && tokens[pos-1] =~ '\v^:=let$')
    let prj = s:project_list.get(pos == 3 ? tokens[pos-2] : s:k_unset)
    let res = s:list_var_for_complete(prj, a:ArgLead)
  elseif     (2 == pos && tokens[pos-1] =~ '\v^:cd$')
        \ || (3 == pos && tokens[pos-1] =~ '\v^:=cd$')
    let res = lh#path#glob_as_list(getcwd(), a:ArgLead.'*')
    call filter(res, 'isdirectory(v:val)')
    call map(res, 'lh#path#strip_start(v:val, [getcwd()])')
  elseif     (2 == pos && tokens[1] =~ '\v^:(doonce|bufdo|windo)$')
        \ || (3 == pos && tokens[2] =~ '\v^:=(doonce|bufdo|windo)$')
    let res = lh#command#matching_askvim('command', a:ArgLead)
  elseif     (2 <  pos && tokens[1] =~ '\v^:(doonce|bufdo|windo)$')
        \ || (3 <  pos && tokens[2] =~ '\v^:=(doonce|bufdo|windo)$')
    let lead = matchstr(a:CmdLine[: a:CursorPos-1], '\v^.{-}:=(doonce|bufdo|windo)\s*\zs.*')
    let res = lh#command#matching_for_command(lead)
  elseif 2 == pos
    let res = [':ls', ':echo', ':cd', ':let', ':doonce', ':bufdo', 'windo']
  else
    let res = []
  endif
  let res = filter(res, 'v:val =~ a:ArgLead')
  return res
endfunction

function! s:list_var_for_complete(prj, ArgLead) " {{{3
  let prj = a:prj
  if !empty(a:ArgLead) && a:ArgLead[0] == '$'
    let vars = map(keys(prj.env), '"$".v:val')
  elseif !empty(a:ArgLead) && a:ArgLead[0] == '&'
    let vars = map(keys(prj.options), '"&".v:val')
  elseif stridx(a:ArgLead, '.') < 0
    let sDict = 'prj.variables'
    let dict = eval(sDict)
    let vars = keys(dict)
    call filter(vars, 'type(dict[v:val]) != type(function("has"))')
    call map(vars, 'v:val. (type(dict[v:val])==type({})?".":"")')
  else
    let [all, sDict0, key ; trail] = matchlist(a:ArgLead, '\v(.*)(\..*)')
    let sDict = 'prj.variables.'.sDict0
    let dict = eval(sDict)
    let vars = keys(dict)
    call filter(vars, 'type(dict[v:val]) != type(function("has"))')
    call map(vars, 'v:val. (type(dict[v:val])==type({})?".":"")')
    call map(vars, 'sDict0.".".v:val')
    let l = len(a:ArgLead) - 1
    call filter(vars, 'v:val[:l] == a:ArgLead')
  endif
  if empty(a:ArgLead)
    let vars += s:list_var_for_complete(a:prj, '$')
    let vars += s:list_var_for_complete(a:prj, '&')
  endif
  let res = vars
  " TODO: support var.sub.sub and inherited projects
  return vars
endfunction

" # Define a new project {{{2
" - Methods {{{3
" s:buffers is debug variable used to track disapearing buffers
let s:buffers = get(s:, 'buffers', {})
function! s:register_buffer(...) dict abort " {{{4
  let bid = a:0 > 0 ? a:1 : bufnr('%')
  if !empty(bufname(bid))
    let s:buffers[bid] = bufname(bid).' -- ft:'.getbufvar(bid, '&ft', '???')
  endif
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
endfunction

function! s:inherit(parent) dict abort " {{{4
  call lh#list#push_if_new(self.parents, a:parent)
endfunction

function! s:depth() dict abort " {{{4
  return 1 + max(map(copy(self.parents), 'v:val.depth()'))
endfunction

function! s:set(varname, value) dict abort " {{{4
  call s:Verbose('%1.set(%2 <- %3)', self.name, a:varname, a:value)
  call lh#assert#true(!empty(a:varname))
  let varname = a:varname[1:]
  if     a:varname[0] == '&' " {{{5 -- options
    let self.options[varname] = a:value
    call self._update_option(varname)
  elseif a:varname[0] == '$' " {{{5 -- $ENV
    let self.env[varname] = a:value
  else                       " {{{5 -- Any variable
    " This part is very similar to lh#let#to instead we don't have a variable
    " name => need to do the same work, but differently
    call lh#dict#let(self.variables, a:varname, a:value)
  endif " }}}5
endfunction

function! s:update(varname, value, ...) dict abort " {{{4
  " @param[in] {optional: is_recursing} => don't set on parent level, but on
  " child one
  " like s:set, but find first where the option is already set (i.e.
  " possibily in a parent project), and update the "old" setting instead of
  " overridding it.
  call lh#assert#true(!empty(a:varname))
  call s:Verbose('%1.set(%2 <- %3, %4)', self.name, a:varname, a:value, a:000)
  let varname = a:varname[1:]
  if     a:varname[0] == '&' " {{{5 -- options
    if has_key(self.options, varname)
      call self._update_option(a:varname)
      return 1
    endif
  elseif a:varname[0] == '$' " {{{5 -- $ENV
    if has_key(self.env, varname)
      let self.env[varname] = a:value
      return 1
    endif
  else                       " {{{5 -- Any variable
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

function! s:do_update_option(bid, varname, value) " {{{4
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

function! s:_update_option(varname, ...) dict abort " {{{4
  let value = self.options[a:varname]
  call s:Verbose('%1._update_option(%2 <- %3)', self.name, a:varname, value)
  if a:0 == 0
    " Apply to all buffers
    for b in self.buffers
      call s:do_update_option(b, '&'.a:varname, value)
    endfor
  else
    call s:do_update_option(a:1, '&'.a:varname, value)
  endif
endfunction

function! s:_use_options(bid) dict abort " {{{4
  call s:Verbose('%1._use_options(%2)', self.name, a:bid)
  for p in self.parents
    call p._use_options(a:bid)
  endfor
  for opt in keys(self.options)
    call self._update_option(opt, a:bid)
  endfor
endfunction

function! s:_remove_buffer(bid) dict abort " {{{4
  for p in self.parents
    call p._remove_buffer(a:bid)
  endfor
  if getbufvar(a:bid, '&ft') != 'qf'
    " Quickfix buffers may not be registered to projects
    call lh#assert#not_equal(-1, index(self.buffers, a:bid), "Buffer ".a:bid.'('.bufname(a:bid).') doesn''t belong to project '.self.name.' '.string(self.buffers) )
  endif
  call filter(self.buffers, 'v:val != a:bid')
endfunction

function! s:get(varname, ...) dict abort " {{{4
  if     a:varname[0] == '$' && has_key(self.env, a:varname[1:])
    let r0 = self.env[a:varname[1:]]
  elseif a:varname[0] == '&' && has_key(self.options, a:varname[1:])
    let r0 = self.options[a:varname[1:]]
  elseif a:varname[0] !~ '[&$]'
    let r0 = lh#dict#get_composed(self.variables, a:varname)
  endif
  if exists('r0') && lh#option#is_set(r0)
    " may need to interpret a reference lh#ref('g:variable')
    return r0
  else
    for p in self.parents
      let r = p.get(a:varname)
      if lh#option#is_set(r) | return r | endif
      unlet! r
    endfor
  endif
  return get(a:, 1, s:k_unset)
endfunction

function! s:exists(varname) dict abort " {{{4
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
  let env = {}
  for p in self.parents
    call extend(env, p.environment(), 'force')
  endfor
  call extend(env, self.env, 'force')
  return env
  " return map(items(self.env), 'v:val[0]."=".v:val[1]')
endfunction

function! s:find_holder(varname) dict abort " {{{4
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

function! s:__lhvl_oo_type() dict abort " {{{4
  return 'project'
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
"   - "paths"
"     - "sources" <- @inv absolute path when defined
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
  if empty(get(project, 'name', ''))
    let project.name = s:project_list.new_name()
  endif

  let project.inherit         = function(s:getSNR('inherit'))
  let project.register_buffer = function(s:getSNR('register_buffer'))
  let project.set             = function(s:getSNR('set'))
  let project.update          = function(s:getSNR('update'))
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
  let project.__lhvl_oo_type  = function(s:getSNR('__lhvl_oo_type'))

  " Let's automatically register the current buffer
  call project.register_buffer()

  call s:project_list.add_project(project)

  if has_key(project, 'auto_discover_root')
    " The option can be forced through #define parameter
    let auto_discover_root = project.auto_discover_root
    call s:Verbose("prj#new: auto_discover_root set in options: %1", auto_discover_root)
    unlet project.auto_discover_root
  else
    let auto_discover_root = lh#project#_auto_discover_root()
    call s:Verbose("prj#new: auto_discover_root computed: %1", auto_discover_root)
  endif

  if type(auto_discover_root) == type({}) && has_key(auto_discover_root, 'value')
    call s:Verbose("prj#new: auto_discover_root set in options: %1", auto_discover_root.value)
    call lh#let#if_undef('p:paths.sources', fnamemodify(auto_discover_root.value, ':p'))
  elseif auto_discover_root !~? '\v^(n%[o]|0)$'
    if ! lh#project#exists('p:paths.sources')
      let root = lh#project#root()
      call s:Verbose("prj#new: root found: %1", root)
      if !empty(root)
        call lh#let#if_undef('p:paths.sources', fnamemodify(root[:-2], ':p'))
      endif
    endif
  endif
  return project
endfunction

" Function: lh#project#define(s:, params [, name]) {{{3
function! lh#project#define(s, params, ...) abort
  if !lh#project#is_eligible() | return s:k_unset  | endif
  call lh#assert#not_equal(&ft, 'qf', "Don't run lh#project#define() from qf window!")
  let name = get(a:, 1, 'project')
  if !has_key(a:s, name)
    let a:s[name] = lh#project#new(a:params)
  else
    call a:s[name].register_buffer()
  endif
  return a:s[name]
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

" Function: lh#project#_crt_var_name(var) {{{3
function! lh#project#_crt_var_name(var) abort
  call lh#assert#match('^p:', a:var)
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
    call lh#assert#true(has_key(b:{s:project_varname}, 'get'))
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
  call s:Verbose('s:FetchPrjDirname() -- project_sources_dir: %1', project_sources_dir)
  if lh#option#is_set(project_sources_dir)
    return project_sources_dir
  endif

  " VCS
  let prj_dirname = lh#vcs#get_git_root()
  if !empty(prj_dirname)
    call s:Verbose("s:FetchPrjDirname() -> git: %1 -> %2", prj_dirname, fnamemodify(prj_dirname, ':p:h:h'))
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
    if s:permission_lists.check_paths([ expand('%:p:h')])
      let prj_dirname = INPUT("prj needs to know the current project root directory.\n-> ", expand('%:p:h'))
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
    return (getbufvar(a:1, '&ft') != 'qf') && ! lh#path#is_distant_or_scratch(bufname(a:1))
  else
    return (&ft != 'qf') && ! lh#path#is_distant_or_scratch(expand('%:p'))
  endif
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
" # Post local vimrc hook {{{2
" Function: lh#project#_post_local_vimrc() {{{3
function! lh#project#_post_local_vimrc() abort
  call s:Verbose('lh#project#_post_local_vimrc()')
  call lh#project#_auto_detect_project()
  call lh#project#_UseProjectOptions()
endfunction

" Function: lh#project#_auto_detect_project() {{{3
function! lh#project#_auto_detect_project() abort
  let auto_detect_projects = lh#option#get('lh#project.auto_detect', 0, 'g')
  " If there already is a project defined
  " Or if this is the quickfix window
  " => abort
  if auto_detect_projects && ! lh#project#is_in_a_project() && lh#project#is_eligible()
    let root = lh#project#root()
    if !empty(root) && s:permission_lists.check_paths([root]) == 1
      " TODO: recognize patterns such as src|source to search the project in
      " the upper directory
      let name = fnamemodify(root, ':h:t')
      let name = substitute(name, '[^A-Za-z0-9_]', '_', 'g')
      let opt = {'name': name}
      let opt.auto_discover_root = {'value':  root}
      call lh#project#define(s:, opt, name)
    endif
  endif
  if lh#project#is_in_a_project() && lh#project#is_eligible()
    call lh#assert#true(index(lh#project#crt().buffers, eval(bufnr('%'))) >= 0)
  endif
endfunction

function! lh#project#_UseProjectOptions() " {{{3
  " # New buffer => update options
  let prj = lh#project#crt()
  if lh#option#is_set(prj)
    call prj._use_options(bufnr('%'))
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
      exe 'lcd '.path
    endif
  endif
endfunction
"------------------------------------------------------------------------
" ## globals {{{1
" # Public globals {{{2
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
  call lh#path#munge(g:lh#project.permissions.asklist, $HOME)
endif
call lh#path#munge(g:lh#project.permissions.blacklist, fnamemodify('/', ':p'))
" TODO: add other disks in windows

" The directories where projects (we trust) are stored shall be added into
" whitelist

" # Internal globals {{{2
let s:project_list = get(s:, 'project_list', lh#project#_make_project_list())
let s:permission_lists = lh#path#new_permission_lists(g:lh#project.permissions)

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
