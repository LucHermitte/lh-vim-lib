"=============================================================================
" File:         autoload/lh/command.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      5.2.2
let s:k_version = 5.2.2
" Created:      08th Jan 2007
" Last Update:  10th Nov 2020
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

function! s:Log(...) abort
  call call('lh#log#this', a:000)
endfunction

function! s:Verbose(...) abort
  if s:verbose
    call call('s:Log', a:000)
  endif
endfunction

function! lh#command#debug(expr) abort
  return eval(a:expr)
endfunction

" # Misc {{{2
" s:getSNR([func_name]) {{{3
function! s:getSNR(...)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
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
  let tmp = substitute(a:CmdLine[: a:CursorPos-1], '\\ ', '§', 'g')
  let tokens = split(tmp, '\s\+')
  call map(tokens, 'substitute(v:val, "§", " ", "g")')
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
if exists('*getcompletion')
  function! lh#command#matching_askvim(what, lead) abort
    return getcompletion(a:lead, a:what)
  endfunction
else
  function! lh#command#matching_askvim(what, lead) abort
    let cleanup = lh#on#exit()
          \.register('delcom LHAskVimMatchingCompletion')
    try
      exe 'command! -complete='.a:what.' -nargs=* LHAskVimMatchingCompletion :echo "<args>"'
      if exists('*getcmdline')
        call cleanup
              \.restore('g:cmds')
              \.restore_buffer_mapping('µ', 'c')
              \.restore_mapping_and_clear_now('<c-a>', 'c')
        cnoremap <buffer> <expr> µ s:register()
        function! s:register()
          let g:cmds = split(getcmdline(), ' ')[1:]
          return ''
        endfunction
        silent! exe "norm :LHAskVimMatchingCompletion ".a:lead."\<c-a>µ"
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
endif

" Function: lh#command#matching_for_command(lead) {{{3
function! lh#command#matching_for_command(lead) abort
  silent! exe "norm! :".a:lead."\<c-a>\"\<home>let\ cmds=\"\<cr>"
  return split(cmds, ' ')[1:]
endfunction

" Function: lh#command#matching_bash_completion(command, lead [, dir]) {{{3
" Requires bash
function! lh#command#matching_bash_completion(command, lead, ...) abort
  if !lh#command#can_use_bash_completion()
    return a:lead
  endif

  " COMP_WORDS=('module' 'load' 'c')
  " COMP_CWORD=2 _module module load module  && echo ${COMPREPLY[@]}
  " ===> load
  " COMP_CWORD=3 _module module co load && echo ${COMPREPLY[@]}
  " ===> conda/coz...

  " Two cases:
  " 1- completion of the current word
  " 2- completion of the next word, last part in a:lead matches ^\s*$
  let lead = [a:command]
  let cur = ''
  let prev = ''
  if !empty(a:lead)
    if  type(a:lead) == type([])
      let lead += a:lead
    else
      " [[deprecated]]
      let lead += [ a:lead ]
    endif
    let last_idx = -1
    " if empty(lead[last_idx]) | let last_idx -= 1 | endif
    let cur = string(lead[last_idx])
    if len(a:lead) >= -(last_idx-1)
      let prev = string(a:lead[last_idx-1])
    endif
  endif
  call map(lead, 'string(v:val)')
  let sLead = join(lead, ' ')

  let env = {}
  let env.__shebang  = '/bin/env bash'
  let env.COMP_LINE  = sLead
  let env.COMP_POINT = lh#encoding#strlen(sLead)
  let env.COMP_WORDS = lead
  let env.COMP_CWORD = len(lead) -1

  call s:Verbose('current %1', cur)
  call s:Verbose('previous %1', prev)
  call s:Verbose('COMP_WORDS: %1',  env.COMP_WORDS)
  call s:Verbose('COMP_CWORDS: %1', env.COMP_CWORD)
  call s:Verbose('COMP_LINE "%1"', env.COMP_LINE)
  call s:Verbose('COMP_POINT %1', env.COMP_POINT)

  let commands = []
  let commands += [ '__print_completions() { printf ''%s\n'' "${COMPREPLY[@]}"; }']
  let commands += [ 'source /etc/bash_completion']
  let commands += [ 'complete -p '.a:command.' >/dev/null 2>&1 ||_completion_loader '.a:command ]
  let commands += [ 'compl_def=$(complete -p '.a:command.')' ]
  let commands += [ 'policy="${compl_def/complete -F /}"' ]
  let commands += [ 'pol_tokens=(${policy})' ]
  let commands += [ printf('${pol_tokens[0]} %s %s %s', a:command, cur, prev) ]
  if a:0 > 0
    let commands[-1] = 'cd '.shellescape(a:1). ' && ' . commands[-1] .' || echo "Invalid directory!"'
  endif
  let commands += [ '__print_completions' ]
  let commands += [ '']
  call s:Verbose('Command %1', commands)

  let script = lh#os#new_runner_script(commands, env)
  return split(script.run(), "\n")
endfunction

" Function: lh#command#can_use_bash_completion() {{{3
function! lh#command#can_use_bash_completion() abort
  return executable('bash') && filereadable('/etc/bash_completion')
endfunction

" Function: lh#command#matching_make_completion(lead [, dir]) {{{3
function! s:get_make_compl(makefile) dict abort
  let dir = fnamemodify(a:makefile, ':h')
  let completions = split(lh#command#matching_bash_completion('make', '', dir), "\n")
  call lh#list#unique_sort(completions)
  return completions
endfunction

let s:make_cache = lh#file#new_cache(function(s:getSNR('get_make_compl')))
function! lh#command#matching_make_completion(lead, ...) abort
  let makefile = (a:0 > 0 ? a:1.'/' : '') . 'Makefile'
  let makefile = fnamemodify(makefile, ':p')
  let matches = copy(s:make_cache.get(makefile))
  call filter(matches, 'v:val =~ "^".a:lead')
  return matches
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
    " echo s:{a:f1} ## don't support «echo s:f('foo')»
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
