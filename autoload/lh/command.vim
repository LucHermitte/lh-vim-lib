"=============================================================================
" File:         autoload/lh/command.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      4.0.0
let s:k_version = 400
" Created:      08th Jan 2007
" Last Update:  24th Jan 2017
"------------------------------------------------------------------------
" Description:
"       Helpers to define commands that:
"       - support subcommands
"       - support autocompletion
" }}}1
"=============================================================================


"=============================================================================
let s:cpo_save=&cpo
set cpo&vim

" ## Misc Functions     {{{1
" # Version {{{2
function! lh#command#version()
  return s:k_version
endfunction

" # Debug {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#command#verbose(...)
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

function! lh#command#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## Functions {{{1

" Tool functions {{{2
" Function: lh#command#Fargs2String(aList) {{{3
" @param[in,out] aList list of params from <f-args>
" @see tests/lh/test-Fargs2String.vim
function! lh#command#Fargs2String(aList)
  if empty(a:aList) | return '' | endif

  let quote_char = a:aList[0][0]
  let res = a:aList[0]
  call remove(a:aList, 0)
  if quote_char !~ '["'."']"
    return res
  endif
  " else
  let end_string = '[^\\]\%(\\\\\)*'.quote_char.'$'
  while !empty(a:aList) && res !~ end_string
    let res .= ' ' . a:aList[0]
    call remove(a:aList, 0)
  endwhile
  return res
endfunction

" Function: lh#command#analyse_args(ArgLead, CmdLine, CursorPos) {{{3
" Returns
" - the position of the token where the cursor is
" - all the tokens up to cursor position
function! lh#command#analyse_args(ArgLead, CmdLine, CursorPos) abort
  let tmp = substitute(a:CmdLine[: a:CursorPos-1], '\\ ', '�', 'g')
  let tokens = split(tmp, '\s\+')
  call map(tokens, 'substitute(v:val, "�", " ", "g")')
  let tmp = substitute(tmp, '\s*\S*', 'Z', 'g')
  let pos = strlen(tmp) - 1
  call s:Verbose('complete(lead="%1", cmdline="%2", cursorpos=%3) -- tmp=%4, pos=%5, tokens=%6', a:ArgLead, a:CmdLine, a:CursorPos, tmp, pos, tokens)

  return [pos, tokens, a:ArgLead, a:CmdLine, a:CursorPos]
endfunction

" Function: lh#command#matching_variables(lead [, scope=all]) {{{3
" TODO: support p:
function! lh#command#matching_variables(lead, ...) abort
  let lead = a:lead
  if a:lead =~ '^\k:'
    let scopes = [a:lead[0]]
    let lead   = a:lead[2:]
  elseif a:lead =~ '^\$'
    let scopes = [a:lead[0]]
    let lead   = a:lead[1:]
  elseif a:lead =~ '^&'
    let scopes = [a:lead[0]]
    let lead   = a:lead[1:]
  elseif a:0 > 0
    let scopes = type(a:1) == type([]) ? a:1 : split(a:1, '\zs')
  else
    let scopes = ['b', 'g', 't', 'w']
  endif
  let res = []
  for scope in scopes
    if     scope == '$'
      let res += lh#command#matching_askvim('environment', lead)
    elseif scope == '&'
      let res += lh#command#matching_askvim('option', lead)
    else
      let res += map(
            \ filter(copy(keys(eval(scope.':'))), 'v:val =~ "^".lead')
            \ ,'scope.":".v:val')
    endif
  endfor
  return res
endfunction

" Function: lh#command#matching_askvim(what, lead) {{{3
function! lh#command#matching_askvim(what, lead) abort
  let cleanup = lh#on#exit()
        \.register('delcom LHAskVimMatchingCompletion')
  try
    exe 'command! -complete='.a:what.' -nargs=* LHAskVimMatchingCompletion :echo "<args>"'
    if exists('*getcmdline')
      call cleanup
            \.restore('g:cmds')
            \.restore_buffer_mapping('�', 'c')
            \.restore_mapping_and_clear_now('<c-a>', 'c')
      cnoremap <buffer> <expr> � s:register()
      function! s:register()
        let g:cmds = split(getcmdline(), ' ')[1:]
        return ''
      endfunction
      silent! exe "norm :LHAskVimMatchingCompletion ".a:lead."\<c-a>�"
      return g:cmds
    else
      " The following may lead to problem with unescaped quotes => use
      " getcmdline() when available
      silent! exe "norm! :LHAskVimMatchingCompletion ".a:lead."\<c-a>\"\<home>let\ cmds=\"\<cr>"
      return split(cmds, ' ')[1:]
    endif
  finally
    call cleanup.finalize()
  endtry
endfunction

" Function: lh#command#matching_for_command(lead) {{{3
function! lh#command#matching_for_command(lead) abort
  silent! exe "norm! :".a:lead."\<c-a>\"\<home>let\ cmds=\"\<cr>"
  return split(cmds, ' ')[1:]
endfunction

"------------------------------------------------------------------------
" ## Experimental Functions {{{1

" Internal functions        {{{2
" Function: s:SaveData({Data})                             {{{3
" @param Data Command definition
" Saves {Data} as s:Data{s:data_id++}. The definition will be used by
" automatically generated commands.
" @return s:data_id
let s:data_id = 0
function! s:SaveData(Data)
  if has_key(a:Data, "command_id")
    " Avoid data duplication
    return a:Data.command_id
  else
    let s:Data{s:data_id} = a:Data
    let id = s:data_id
    let s:data_id += 1
    let a:Data.command_id = id
    return id
  endif
endfunction

" lh#command#complete(ArgLead, CmdLine, CursorPos):      Auto-complete {{{3
function! lh#command#complete(ArgLead, CmdLine, CursorPos)
  let tmp = substitute(a:CmdLine, '\s*\S*', 'Z', 'g')
  let pos = strlen(tmp)
  if 0
    call confirm( "AL = ". a:ArgLead."\nCL = ". a:CmdLine."\nCP = ".a:CursorPos
          \ . "\ntmp = ".tmp."\npos = ".pos
          \, '&Ok', 1)
  endif

  if     2 == pos
    " First argument: a command
    return s:commands
  elseif 3 == pos
    " Second argument: first arg of the command
    if     -1 != match(a:CmdLine, '^BTW\s\+echo')
      return s:functions . "\n" . s:variables
    elseif -1 != match(a:CmdLine, '^BTW\s\+\%(help\|?\)')
    elseif -1 != match(a:CmdLine, '^BTW\s\+\%(set\|add\)\%(local\)\=')
      " Adds a filter
      " let files =         globpath(&rtp, 'compiler/BT-*')
      " let files = files . globpath(&rtp, 'compiler/BT_*')
      " let files = files . globpath(&rtp, 'compiler/BT/*')
      let files = s:FindFilter('*')
      let files = substitute(files,
            \ '\(^\|\n\).\{-}compiler[\\/]BTW[-_\\/]\(.\{-}\)\.vim\>\ze\%(\n\|$\)',
            \ '\1\2', 'g')
      return files
    elseif -1 != match(a:CmdLine, '^BTW\s\+remove\%(local\)\=')
      " Removes a filter
      return substitute(s:FiltersList(), ',', '\n', 'g')
    endif
  endif
  " finally: unknown
  echoerr 'BTW: unespected parameter ``'. a:ArgLead ."''"
  return ''
endfunction

function! s:BTW(command, ...)
  " todo: check a:0 > 1
  if     'set'      == a:command | let g:BTW_build_tool = a:1
    if exists('b:BTW_build_tool')
      let b:BTW_build_tool = a:1
    endif
  elseif 'setlocal'     == a:command | let b:BTW_build_tool = a:1
  elseif 'add'          == a:command | call s:AddFilter('g', a:1)
  elseif 'addlocal'     == a:command | call s:AddFilter('b', a:1)
    " if exists('b:BTW_filters_list') " ?????
    " call s:AddFilter('b', a:1)
    " endif
  elseif 'remove'       == a:command | call s:RemoveFilter('g', a:1)
  elseif 'removelocal'  == a:command | call s:RemoveFilter('b', a:1)
  elseif 'rebuild'      == a:command " wait for s:ReconstructToolsChain()
  elseif 'echo'         == a:command | exe "echo s:".a:1
    " echo s:{a:f1} ## don't support �echo s:f('foo')�
  elseif 'reloadPlugin' == a:command
    let g:force_reload_BuildToolsWrapper = 1
    let g:BTW_BTW_in_use = 1
    exe 'so '.s:sfile
    unlet g:force_reload_BuildToolsWrapper
    unlet g:BTW_BTW_in_use
    return
  elseif a:command =~ '\%(help\|?\)'
    call s:Usage()
    return
  endif
  call s:ReconstructToolsChain()
endfunction

" ##############################################################
" Public functions          {{{2

function! s:FindSubcommand(definition, subcommand)
  for arg in a:definition.arguments
    if arg.name == a:subcommand
      return arg
    endif
  endfor
  throw "NF"
endfunction

function! s:execute_function(definition, params)
    if len(a:params) < 1
      throw "(lh#command) Not enough arguments"
    endif
  let l:Fn = a:definition.action
  echo "calling ".string(l:Fn)
  echo "with ".string(a:params)
  " call remove(a:params, 0)
  call l:Fn(a:params)
endfunction

function! s:execute_sub_commands(definition, params)
  try
    if len(a:params) < 1
      throw "(lh#command) Not enough arguments"
    endif
    let subcommand = s:FindSubcommand(a:definition, a:params[0])
    call remove(a:params, 0)
    call s:int_execute(subcommand, a:params)
  catch /NF.*/
    throw "(lh#command) Unexpected subcommand `".a:params[0]."'."
  endtry
endfunction

function! s:int_execute(definition, params)
  echo "params=".string(a:params)
  call s:execute_{a:definition.arg_type}(a:definition, a:params)
endfunction

function! s:execute(definition, ...)
  try
    let params = copy(a:000)
    call s:int_execute(a:definition, params)
  catch /(lh#command).*/
    echoerr v:exception . " in `".a:definition.name.' '.join(a:000, ' ')."'"
  endtry
endfunction

function! lh#command#new(definition)
  let cmd_name = a:definition.name
  " Save the definition as an internal script variable
  let id = s:SaveData(a:definition)
  exe "command! -nargs=* ".cmd_name." :call s:execute(s:Data".id.", <f-args>)"
endfunction

" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
