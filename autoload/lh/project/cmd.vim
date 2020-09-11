"=============================================================================
" File:         autoload/lh/project/cmd.vim                       {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.7.1.
let s:k_version = '471'
" Created:      07th Mar 2017
" Last Update:  12th Sep 2020
"------------------------------------------------------------------------
" Description:
"       Define support functions for :Project
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim

let s:k_unset            = lh#option#unset()
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#project#cmd#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#project#cmd#verbose(...)
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

function! lh#project#cmd#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Support functions {{{1
function! s:As_ls(bid) abort " {{{2
  let name = bufname(a:bid)
  if empty(name)
    let name = 'Used to be known as: '.lh#project#__buffer(a:bid)
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

function! s:ls_project(prj) abort " {{{2
  if lh#option#is_unset(a:prj)
    echo '(no project specified!)'
  endif
  let lines = map(copy(a:prj.buffers), 's:As_ls(v:val)')
  echo "Buffer list of ".get(a:prj, 'name', '(unnamed)')." project:"
  echo join(lines, "\n")
endfunction

function! s:cd_project(prj, path) abort " {{{2
  if lh#option#is_unset(a:prj)
    throw "Cannot apply :cd on non existant projects"
  endif
  let path = expand(a:path)
  if a:path == '!'
    " Reset directory to project directory in current window.
    call lh#os#lcd(lh#option#get('paths.sources'))
    return
  elseif !isdirectory(path)
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
      call lh#os#lcd(lh#option#get('paths.sources'))
    endfor
  finally
    call win_gotoid(crt_win)
  endtry
endfunction

function! s:echo_project(prj, var) abort " {{{2
  let val = a:prj.get(a:var)
  if lh#option#is_set(val)
    echo 'p:{'.a:prj.name.'}.'.a:var.' -> '.lh#object#to_string(val)
  else
    call lh#common#warning_msg('No `'.a:var.'` variable in `'.a:prj.name. '` project')
  endif
endfunction

function! s:let_project(prj, var, lVal) abort " {{{2
  " TODO: support &tw += 42, and &tags+='path' => not the same let-operator
  call s:Verbose('let {%1}.%2 <- %3', a:prj.name, a:var, a:lVal)
  let value0 = join(a:lVal, ' ')
  let [all, compound, equal, value ; rem] = matchlist(value0, '\v^\s=%(([+-/*.])\=|(\=))\s*(.*)$')
  if !empty(compound)
    let old = a:prj.get(a:var)
    " debug call s:Verbose('type: old:%1, value:%2, eval value:%3', type(old), type(value), type(eval(value)))
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

function! s:doonce_project(prj, cmd) abort " {{{2
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

function! s:windo_project(prj, cmd) abort " {{{2
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

function! s:bufdo_project(prj, cmd) abort " {{{2
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

function! s:cycle_buffer_project(prj, direction, cmd, args) abort " {{{2
  if lh#option#is_unset(a:prj)
    throw "Cannot apply :bufdo on non existant projects"
  endif
  let bang = a:cmd[-1] == '!' ? '!' : ''
  let filt = ''
  if match(a:args, '\v-h|--hidden') >= 0
    let filt = ' && bufwinnr(v:val) == -1'
  endif
  let buffers = filter(copy(a:prj.buffers), 'buflisted(v:val)'.filt)
  if a:direction == 'next'
    let after = filter(copy(buffers), 'v:val > bufnr("%")')
    let buf = empty(after) ? buffers[0] : after[0]
  else
    let before = filter(copy(buffers), 'v:val < bufnr("%")')
    let buf = empty(before) ? buffers[-1] : before[-1]
  endif
  silent! exe printf('b%s %s', bang, buf)
endfunction

function! s:define_project(prjname) abort " {{{2
  " 1- if there is already a project with that name
  " => only register the buffer
  " 2- else if there is a project, with another name
  " => have the new project be the root project and inherit the other one
  " register the buffer to the new root project
  " 3- else (no project at all)
  " => create a new project
  " => and register the buffer

  let new_prj = lh#project#list#_get(a:prjname)
  if lh#option#is_set(new_prj)
    call new_prj._register_buffer()
  else
    " If there is already a project, register_buffer (called by #new) will
    " automatically inherit from it.
    let new_prj = lh#project#new({'name': a:prjname})
  endif
endfunction

function! s:show_related_projects(...) abort " {{{2
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

function! s:bd_project(prj, buffers) abort " {{{2
  " TODO: see whether it really makes sense to tell which buffers shall be
  " removed...
  call lh#assert#value(a:prj).is_set("Project expected")
  call lh#project#list#_unload_prj(a:prj, a:buffers)
endfunction

function! s:bw_project(prj, buffers) abort " {{{2
  " TODO: see whether it really makes sense to tell which buffers shall be
  " removed...
  call lh#assert#value(a:prj).is_set("Project expected")
  call lh#project#list#_wipeout_prj(a:prj, a:buffers)
endfunction

" ## :Project command definition {{{1
" Function: lh#project#cmd#execute([prjname]) abort {{{2
let s:k_usage =
      \ [ ':Project USAGE:'
      \ , '  :Project --list                 " list existing projects'
      \ , '  :Project --define <name>        " define a new project/register current buffer'
      \ , '  :Project --which                " list projects to which the current buffer belongs'
      \ , '  :Project [<name>] :ls           " list buffers belonging to the project'
      \ , '  :Project [<name>] :cd <path>    " change directory to <path> -- "!" -> reset to project directory'
      \ , '  :Project [<name>] :echo         " echo state of a project variable'
      \ , '  :Project [<name>] :let          " set state of a project variable'
      \ , '  :Project [<name>] :bufdo[!]     " execute a command on all buffers belonging to the project'
      \ , '  :Project [<name>] :windo[!]     " execute a command on all opened windows belonging to the project'
      \ , '  :Project [<name>] :doonce       " execute a command on the first opened window found which belongs to the project'
      \ , '  :Project [<name>] :bnext[!]     " Goes to the next buffer in project buffer list'
      \ , '  :Project [<name>] :bprevious[!] " Goes to the previous buffer in project buffer list'
      \ , '  :Project <name>   :bdelete      " unload all buffers related to a project, and remove the project'
      \ , '  :Project <name>   :bwipeout     " wipeout all buffers related to a project, and remove the project'
      \ ]
function! lh#project#cmd#execute(...) abort
  if     a:1 =~ '-\+u\%[sage]'  " {{{3
    call lh#common#warning_msg(s:k_usage)
  elseif a:1 =~ '-\+h\%[elp]'
    help :Project
  elseif a:1 =~ '^-\+l\%[ist]$' " {{{3
    let projects = lh#project#list#_get_all_prjs()
    if empty(projects)
      echo "(no project defined)"
    else
      echo join(keys(projects), "\n")
    endif
  elseif a:1 =~ '\v^--which$'   " {{{3
    call s:show_related_projects()
  elseif a:1 =~ '\v^--define$'  " {{{3
    if a:0 != 2
      throw "`:Project --define` expects a project-name as only argument"
    endif
    call s:define_project(a:2)
  elseif a:1 =~ '^:'            " -- commands {{{3
    let prj = lh#project#crt()
    if lh#option#is_unset(prj)
      throw "The current buffer doesn't belong to any project"
    endif
    call s:dispatch_cmd_on_project(prj, '', a:000)
  else                          " -- project name specified {{{3
    let prj_name = a:1
    let prj = lh#project#list#_get(prj_name)
    if lh#option#is_unset(prj)
      throw "There is no project named `".prj_name."`"
    endif
    if a:0 < 2
      throw "Not enough arguments to `:Project name`"
    endif
    if     a:2 =~ '\v^:=bd%[elete]$'  " {{{4
      call s:bd_project(prj, a:000[3:])
    elseif a:2 =~ '\v^:=bw%[ipeout]$' " {{{4
      call s:bw_project(prj, a:000[3:])
    else                             " -- dispatch {{{4
      call s:dispatch_cmd_on_project(prj, prj_name.' ', a:000[1:])
    endif
  endif

  " }}}5
endfunction

" ## :Project command completion {{{1
" Function: lh#project#cmd#_complete(ArgLead, CmdLine, CursorPos) {{{2
function! lh#project#cmd#_complete(ArgLead, CmdLine, CursorPos) abort
  let [pos, tokens; dummy] = lh#command#analyse_args(a:ArgLead, a:CmdLine, a:CursorPos)

  if     1 == pos
    let res = ['--list', '--define', '--which', '--help', '--usage', ':ls', ':echo', ':let', ':cd', ':doonce', ':bufdo', ':windo', ':bnext', ':bprevious'] + map(copy(keys(lh#project#list#_get_all_prjs())), 'escape(v:val, " ")')
  elseif s:token_matches(tokens, pos, '(echo|let)')
    let prj = lh#project#list#_get(pos == 3 ? tokens[pos-2] : s:k_unset)
    let res = s:list_var_for_complete(prj, a:ArgLead)
  elseif s:token_matches(tokens, pos, '(bn%[ext]|bp%[previous])')
    let res = ['-h', '--hidden']
  elseif s:token_matches(tokens, pos, 'cd')
    let res = lh#path#glob_as_list(getcwd(), a:ArgLead.'*')
    call filter(res, 'isdirectory(v:val)')
    let res += ['!']
    call map(res, 'lh#path#strip_start(v:val, [getcwd()])')
  elseif s:token_matches(tokens, pos, '(doonce|bufdo|windo)')
    let res = lh#command#matching_askvim('command', a:ArgLead)
  elseif     (2 <  pos && tokens[1] =~ '\v^:(doonce|bufdo|windo)$')
        \ || (3 <  pos && tokens[2] =~ '\v^:=(doonce|bufdo|windo)$')
    let lead = matchstr(a:CmdLine[: a:CursorPos-1], '\v^.{-}:=(doonce|bufdo|windo)\s*\zs.*')
    let res = lh#command#matching_for_command(lead)
  elseif 2 == pos
    let res = [':ls', ':echo', ':cd', ':let', ':doonce', ':bufdo', ':windo', ':bnext', ':bprevious', ':bdelete', ':bwipeout']
  else
    let res = []
  endif
  let res = filter(res, 'v:val =~ a:ArgLead')
  return res
endfunction

" ## Internal functions {{{1

" # :Project command definition {{{2
function! s:dispatch_cmd_on_project(prj, lead, args) abort " {{{3
  let nb_args = len(a:args)
  call lh#assert#value(nb_args).is_gt(0)
  let cmd     = a:args[0]

  if     cmd =~ '\v^:=l%[s]$'       " {{{4
    call s:ls_project(a:prj)
  elseif cmd =~ '\v^:=echo$'        " {{{4
    if nb_args != 2
      throw "Not enough arguments to `:Project ".a:lead.":echo`"
    endif
    call s:echo_project(a:prj, a:args[1])
  elseif cmd =~ '\v^:=let$'         " {{{4
    if nb_args < 3
      throw "Not enough arguments to `:Project ".a:lead.":let`"
    endif
    call s:let_project(a:prj, a:args[1], a:args[2:])
  elseif cmd =~ '\v^:=cd$'          " {{{4
    if nb_args != 2
      throw "Not enough arguments to `:Project ".a:lead.":cd`"
    endif
    call s:cd_project(a:prj, a:args[1])
  elseif cmd =~ '\v^:=doonce'       " {{{4
    if nb_args < 2
      throw "Not enough arguments to `:Project ".a:lead.":doonce`"
    endif
    call s:doonce_project(a:prj, a:args[1:])
  elseif cmd =~ '\v^:=bufdo'        " {{{4
    if nb_args < 2
      throw "Not enough arguments to `:Project ".a:lead.":bufdo`"
    endif
    call s:bufdo_project(a:prj, a:args[1:])
  elseif cmd =~ '\v^:=windo'        " {{{4
    if nb_args < 2
      throw "Not enough arguments to `:Project ".a:lead.":windo`"
    endif
    call s:windo_project(a:prj, a:args[1:])
  elseif cmd =~ '\v^:=bn%[ext]'     " {{{4
    if nb_args < 1
      throw "Not enough arguments to `:Project ".a:lead.":bnext`"
    endif
    call s:cycle_buffer_project(a:prj, 'next', cmd, a:args[1:])
  elseif cmd =~ '\v^:=bp%[revious]' " {{{4
    if nb_args < 1
      throw "Not enough arguments to `:Project ".a:lead.":bprevous`"
    endif
    call s:cycle_buffer_project(a:prj, 'prev', cmd, a:args[1:])
  elseif cmd =~ '\v^--define$'      " {{{4
    call s:define_project(a:args[1])
  else                            " -- unknown command {{{4
    throw "Unexpected `:Project ".a:lead.cmd."` subcommand"
  endif
endfunction

"------------------------------------------------------------------------
" # :Project command completion {{{2
function! s:token_matches(tokens, pos, what) abort " {{{3
  return     (2 == a:pos && a:tokens[a:pos-1] =~ '\v^:'.a:what.'$')
        \ || (3 == a:pos && a:tokens[a:pos-1] =~ '\v^:='.a:what.'$')
endfunction

function! s:list_var_for_complete(prj, ArgLead) abort " {{{3
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
    if exists(sDict)
      let dict = eval(sDict)
      let vars = keys(dict)
      call filter(vars, 'type(dict[v:val]) != type(function("has"))')
      call map(vars, 'v:val. (type(dict[v:val])==type({})?".":"")')
      call map(vars, 'sDict0.".".v:val')
      let l = len(a:ArgLead) - 1
      call filter(vars, 'v:val[:l] == a:ArgLead')
    else
      let vars = []
    endif
  endif
  if empty(a:ArgLead)
    let vars += s:list_var_for_complete(a:prj, '$')
    let vars += s:list_var_for_complete(a:prj, '&')
  endif
  " Check into inherited projects
  call map(copy(prj.parents), 'extend(vars, s:list_var_for_complete(v:val, a:ArgLead))')
  let res = vars
  return vars
endfunction


"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
