"=============================================================================
" File:         autoload/lh/askvim.vim                                    {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      5.2.0
let s:k_version = 50200
" Created:      17th Apr 2007
" Last Update:  18th Jul 2020
"------------------------------------------------------------------------
" Description:
"       Defines functions that asks vim what it is relinquish to tell us
"       - menu
" }}}1
"=============================================================================


"=============================================================================
let s:cpo_save=&cpo
set cpo&vim

"------------------------------------------------------------------------
" ## Functions {{{1
" # Version {{{2
function! lh#askvim#version()
  return s:k_version
endfunction

" # Debug {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#askvim#verbose(...)
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

function! lh#askvim#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" # Public {{{2
" Function: lh#askvim#exe(command) {{{3
function! lh#askvim#Exe(command) abort
  echomsg 'lh#askvim#Exe() is deprecated, use lh#askvim#exe()'
  return lh#askvim#exe(a:command)
endfunction

function! lh#askvim#exe(command) abort
  let save_a = @a
  try
    silent! redir @a
    silent! exe a:command
    redir END
  finally
    " Always restore everything
    let res = @a
    let @a = save_a
  endtry
  return res
endfunction

" Function: lh#askvim#execute(command) {{{3
" @since Version 4.0.0
if exists('*execute')
  function! lh#askvim#execute(command) abort
    return split(execute(a:command), "\n")
  endfunction
else
  function! lh#askvim#execute(command) abort
    return s:beware_running_through_client_server ? [] : split(lh#askvim#exe(a:command), "\n")
  endfunction
endif

" Function: lh#askvim#scriptnames() {{{3
function! lh#askvim#scriptnames() abort
  let scripts = lh#askvim#execute('scriptnames')
  let s:scripts = map(copy(scripts), 'split(v:val, "\\v:=\\s+")')
  call lh#list#map_on(s:scripts, 1, 'fnamemodify(v:val, ":p")')
  return s:scripts
endfunction

" Function: lh#askvim#scriptname(id) {{{3
function! lh#askvim#scriptname(id) abort
  if !exists('s:scripts') || len(s:scripts) <= eval(a:id)
    call lh#askvim#scriptnames()
    if len(s:scripts) < eval(a:id)
      return lh#option#unset()
    endif
  endif
  return s:scripts[a:id - 1][1]
endfunction

" Function: lh#askvim#scriptid(name) {{{3
function! lh#askvim#scriptid(name, ...) abort
  let last_change = get(a:, 1, 0)
  if last_change || !exists('s:scripts')
    call lh#askvim#scriptnames()
  endif
  let matches = filter(copy(s:scripts), 'v:val[1] =~ a:name')
  if len(matches) > 1
    throw "Too many scripts match `".a:name."`: ".string(matches)
  elseif empty(matches)
    if last_change
      throw "No script match `".a:name."`"
    else
      return lh#askvim#scriptid(a:name, 1)
    endif
  endif
  return matches[0][0]
endfunction

" Function: lh#askvim#where_is_function_defined(funcname) {{{3
" @since Version 4.0.0
" @since Version 4.6.4: return a dictionary
function! lh#askvim#where_is_function_defined(funcname) abort
  if has('*execute') || ! s:beware_running_through_client_server
    let cleanup = lh#lang#set_message_temporarily('C')
          \.restore('&isfname')
    try
      setlocal isfname+=@-@
      " Makes sure the language is C in order to be able to extract the file
      " name.
      " We cannot simply extract the last part as since Vim 8.1.??? the new
      " verbose message is now "Last set from <filename> line <number>"
      " Using lh#po#xx() is quite complex as the string is
      " "\n\tLast set from " which is quite difficult to inject into bash...
      " Beside this is not portable to Windows...
      let definition = lh#askvim#execute('verbose function '.a:funcname)
    finally
      call cleanup.finalize()
    endtry
    if empty(definition)
      throw "Cannot find a definition for ".a:funcname
    endif
    let script = matchstr(definition[1], '\v.{-}Last set from \zs\f+')
    let res = {'script': script}
    let line = matchstr(definition[1], '\v line \zs\d+\ze')
    if !empty(line)
      " Information available starting w/ Vim 8.1.0362+
      let res.line = line
    endif
    return res
  elseif a:funcname =~ '#'
    " autoloaded function
    let script = substitute(a:funcname, '#', '/', 'g')
    let script = 'autoload/'.substitute(script, '.*\zs/.*$', '.vim', '')
    let scripts = lh#path#glob_as_list(&rtp, script)
    return {'script': empty(scripts) ? '' : fnamemodify(scripts[0], ':.')}
  else
    return {'script': ''}
  endif
endfunction

" Function: lh#askvim#menu(menuid) {{{3
function! s:AskOneMenu(menuact, res) abort
  let lKnown_menus = lh#askvim#execute(a:menuact)
  " echo string(lKnown_menus)

  " 1- search for the menuid
  " todo: fix the next line to correctly interpret "stuff\.stuff" and
  " "stuff\\.stuff".
  let menuid_parts = split(a:menuact, '\.')

  let simplifiedKnown_menus = deepcopy(lKnown_menus)
  call map(simplifiedKnown_menus, 'substitute(v:val, "&", "", "g")')
  " let idx = lh#list#match(simplifiedKnown_menus, '^\d\+\s\+'.menuid_parts[-1])
  let idx = match(simplifiedKnown_menus, '^\d\+\s\+'.menuid_parts[-1])
  if idx == -1
    " echo "not found"
    return
  endif
  " echo "l[".idx."]=".lKnown_menus[idx]

  if empty(a:res)
    let a:res.priority = matchstr(lKnown_menus[idx], '\d\+\ze\s\+.*')
    let a:res.name     = matchstr(lKnown_menus[idx], '\d\+\s\+\zs.*')
    let a:res.actions  = {}
  " else
  "   what if the priority isn't the same?
  endif

  " 2- search for the menu definition
  let idx += 1
  while idx != len(lKnown_menus)
    echo "l[".idx."]=".lKnown_menus[idx]
    " should not happen
    if lKnown_menus[idx] =~ '^\d\+' | break | endif

    " :h showing-menus
    " -> The format of the result of the call to Exe() seems to be:
    "    ^ssssMns-sACTION$
    "    s == 1 whitespace
    "    M == mode (inrvcs)
    "    n == noremap(*)/script(&)
    "    - == disable(-)/of not
    let act = {}
    let menu_def = matchlist(lKnown_menus[idx],
          \ '^\s*\([invocs]\)\([&* ]\) \([- ]\) \(.*\)$')
    if len(menu_def) > 4
      let act.mode        = menu_def[1]
      let act.nore_script = menu_def[2]
      let act.disabled    = menu_def[3]
      let act.action      = menu_def[4]
    else
      echomsg string(menu_def)
      echoerr "lh#askvim#menu(): Cannot decode ``".lKnown_menus[idx]."''"
    endif

    let a:res.actions["mode_" . act.mode] = act

    let idx += 1
  endwhile

  " n- Return the result
  return a:res
endfunction

function! lh#askvim#menu(menuid, modes) abort
  let res = {}
  let i = 0
  while i != strlen(a:modes)
    call s:AskOneMenu(a:modes[i].'menu '.a:menuid, res)
    let i += 1
  endwhile
  return res
endfunction

" Function: lh#askvim#is_valid_call(fcall) {{{3
function! lh#askvim#is_valid_call(fcall) abort
  try
    call eval(a:fcall)
    return 1
  catch /.*/
    return 0
  endtry
endfunction

" Function: lh#askvim#_beware_running_through_client_server() {{{3
" @since Version 4.0.0
" I use this odd function to tell this autoload plugin that `:redir` will mess
" up what the remote instance of vim return through the client-server channel
let s:beware_running_through_client_server = get(s:, 'beware_running_through_client_server', 0)
function! lh#askvim#_beware_running_through_client_server() abort
  let s:beware_running_through_client_server = 1
endfunction

" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
