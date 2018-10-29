"=============================================================================
" File:         autoload/lh/os.vim                                {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      4.6.4
let s:k_version = 40604
" Created:      10th Apr 2012
" Last Update:  29th Oct 2018
"------------------------------------------------------------------------
" Description:
"       «description»
"
"------------------------------------------------------------------------
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#os#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#os#verbose(...)
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

function! lh#os#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

" # Cygwin related functions {{{2
" Function: lh#os#is_a_cygwin_shell() {{{3
let s:cached_uname = {}
function! s:uname_o() abort
  let shell = exepath(&shell)
  if !has_key(s:cached_uname, shell)
    let s:cached_uname[shell] = lh#os#system('uname -o')
  endif
  return s:cached_uname[shell]
endfunction

function! lh#os#is_a_cygwin_shell() abort
  return lh#os#system_detected() == 'unix' && s:uname_o() ==? 'cygwin'
endfunction

" Function: lh#os#prog_needs_cygpath_translation() {{{3
let s:cached_prgs = {}
function! s:cached_prg(prg) abort
  " Expects cygwin
  if !has_key(s:cached_prgs, a:prg)
    let s:cached_prgs[a:prg] = lh#os#system(a:prg)
  endif
  return s:cached_prgs[a:prg]
endfunction
function! lh#os#prog_needs_cygpath_translation(prg) abort
  " TRUE IFF windows flavour of vim + cygwin shell + cygwin version of the program
  return lh#os#OnDOSWindows() && lh#os#is_a_cygwin_shell()
        \ && s:cached_prg('ldd $(cygpath -u '.shellescape(exepath(a:prg)).')') =~? 'cygwin'
endfunction

" # OS kind {{{2

" Function: lh#os#has_unix_layer_installed() {{{3
function! lh#os#has_unix_layer_installed() abort
  return get(g:, 'unix_layer_installed', 0)
endfunction

" Function: lh#os#system_detected() {{{3
function! lh#os#system_detected() abort
  if !exists('s:system')
    call s:DetectSystem()
  endif
  return s:system
endfunction

" Function: lh#os#OnDOSWindows() {{{3
function! lh#os#OnDOSWindows() abort
  return has('win64') || has('win16') || has('win32') || has('dos16') || has('dos32') || has('os2')
endfunction

" # builtin commands {{{2
" Function: lh#os#lcd(path) {{{3
function! lh#os#lcd(path) abort
  " Need to neutralize several characters like #, %, ...
  let path = fnameescape(a:path)
  call s:Verbose("buffer %1 -> `:lcd %2`", bufname('%'), path)
  exe 'lcd '.path
endfunction

" # External program Execution {{{2

" Function: lh#os#chomp(text) {{{3
function! lh#os#chomp(text)
  return a:text[:-2]
endfunction

" Function: lh#os#system(cmd [, apply_env]) {{{3
" @return the comp'ed result of system call
function! lh#os#system(cmd, ...)
  " Alter command to make sure $ENV variables from current project are set
  if a:0 > 0 && type(a:1) == type({})
    let env = a:1
  else
    let env = (get(a:, 1, 1) && exists('*lh#project#_environment')) ? lh#project#_environment() : {}
  endif
  let cmd = a:cmd
  if !empty(env)
    let scr = lh#os#new_runner_script(cmd, env)
    try
      let res = scr.run()
    finally
      call scr.finalize()
    endtry
  else
    call s:Verbose(cmd)
    let res = system(cmd)
  endif
  return lh#os#chomp(res)
endfunction

" Function: lh#os#make(opt) {{{3
" Prefer to use BuildToolsWrapper when possible
function! lh#os#make(opt, bang, ...) abort
  let bang
        \ = type(a:bang) == type(0) ? (a:bang ? '!' : '')
        \ : a:bang =~ '\v[1!]|bang' ? '!'
        \                           : ''
  try
    let cleanup = lh#on#exit()
          \.restore('&makeprg')
    if a:0 > 0
      let &l:makeprg = a:1
    endif
    let env = lh#project#_environment()
    if empty(env)
      exe 'make'.bang.' '.a:opt
    else
      try
        let scr = lh#os#new_runner_script(&makeprg, env)
        let &l:makeprg = &shell . ' '.scr._script_name
        exe 'make'.bang.' '.a:opt
      finally
        call scr.finalize()
      endtry
    endif
  finally
    call cleanup.finalize()
  endtry
endfunction

" Function: lh#os#sys_cd(path [, ...]) {{{3
" Builds a string to :execute
" It will change current directory for the next command executed.
" Unlike |:cd|, the new directory doesn't affect Vim, only what it executed
" through :make, system(), :!, ...
function! lh#os#sys_cd(...) abort
  let res = lh#os#SystemCmd('cd')
  let i = 0
  while i != a:0
    let i += 1
    if a:{i} =~ '^[-+]' " options
      if lh#os#system_detected() == 'msdos' && !lh#os#has_unix_layer_installed()
        if a:{i} =~ '^-h$\|^--h\%[elp]$' | let a_i = '/?'
        else
          echoerr "lh#os#sys_cd() Non portable option: ".a:{i}
          return ''
        endif
      else
        let a_i = a:{i}
      endif
    else                " files
      let a_i = lh#path#fix(a:{i})
    endif
    let res .= ' ' . a_i
  endwhile
  return res
endfunction

" Function: lh#os#new_runner_script(command, env) {{{3
function! lh#os#new_runner_script(command, env) abort
  let tmpname = tempname()
  let result = lh#on#exit()
        \.register(':call delete('.string(tmpname).')')
  let result._script_name = tmpname
  let result.run = function(s:getSNR('run_script'))
  try
    let success = 0
    " store lines for debug purpose
    let result._lines = []
    let env = copy(a:env)
    if has_key(env, '__shebang')
      let result._lines += ['#!'.(env.__shebang)]
      unlet env.__shebang
    endif
    if lh#os#OnDOSWindows() && ! lh#os#system_detected() == 'unix'
      let result._lines += map(items(env), 'set v:val[0]."=".v:val[1]')
    else
      let result._lines += map(items(env), '"export ".v:val[0]."=".s:as_string(v:val[1])')
    endif
    let result._lines += type(a:command) == type([]) ? a:command : [ a:command ]
    call writefile(result._lines, tmpname)
    call s:Verbose('Store in runner script %1 the command %2, completed w/ the environment variables: %3', result._script_name, result._lines, a:env)
    let success = 1
    return result
  finally
    if !success
      call result.finalize()
    endif
  endtry
endfunction

function! s:run_script() dict abort
  call s:Verbose("%1", self._lines)
  let r = system(&shell . ' ' . self._script_name)
  return r
endfunction

" # CPUs {{{2
" Function: lh#os#cpu_number() {{{3
function! lh#os#cpu_number()
  if filereadable('/proc/cpuinfo')
    let procs = lh#os#system('cat /proc/cpuinfo | grep processor|wc -l')
    return str2nr(procs)
  elseif has('win32') || has('win64')
    return str2nr($NUMBER_OF_PROCESSORS)
    " let procs = lh#os#system('wmic cpu get NumberOfCores')
    " return matchstr(procs, ".*[\r\n]\\zs.*$" )
  else " default: no idea
    return -1
  endif
endfunction

" Function: lh#os#cpu_cores_number() {{{3
" @return
function! lh#os#cpu_cores_number()
  if filereadable('/proc/cpuinfo')
    let procs = str2nr(lh#os#system('fgrep -m 1 "cpu cores" /proc/cpuinfo | cut -d " " -f 3'))
    return procs
  else " default: no idea
    return -1
  endif
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
" Function: s:DetectSystem()                 {{{2
function! s:DetectSystem()
  " if                *nix-like systems {{{3
  if &shell =~ 'sh' || lh#os#has_unix_layer_installed()
    if &shell !~ 'sh'
      let s:bin_path = ''
      let s:system = 'msdos'
    else
      " Problem: how to distinguish the use of unixutils-Zsh over cygwin-bash?
      if ($OSTYPE == "cygwin") || ($TERM == "cygwin") || ($CYGWIN != '')
        let s:bin_path = '/usr/bin/'
      else
        let s:bin_path = '\'
      endif
      let s:system = 'unix'
    endif
    let s:print  = s:bin_path.'cat'
    let s:remove = s:bin_path.'rm'
    let s:touch  = s:bin_path.'touch'
    let s:copy   = s:bin_path.'cp -p'
    let s:copydir= s:bin_path.'cp -pr'
    let s:move   = s:bin_path.'mv'
    let s:rmdir  = s:bin_path.'rm -r'
    let s:mkdir  = s:bin_path.'mkdir'
    let s:sort   = s:bin_path.'sort'
    let s:cd     = 'cd'

  " elseif            Windows & dos-like systems {{{3
  elseif lh#os#OnDOSWindows()
    let s:system = 'msdos'
    let s:print  = 'type'
    let s:remove = 'del'
    let s:touch  = 'gvim -c wq'
    let s:copy   = 'copy'
    let s:copydir= 'xcopy /E/I'
    let s:move   = 'ren'
    let s:rmdir  = 'rd /S/Q'
    let s:mkdir  = 'md'
    let s:sort   = 'sort'
    let s:cd     = 'cd /D'
  else              " Other systems {{{3
    let s:system = 'unknown'
    call lh#common#error_msg(
          \ "I don't know the typical system-programs for your configuration."
          \."\nAny solution is welcomed! ".
          \ "Please, contact me at <hermitte"."@"."free.fr>")
  endif " }}}3
endfunction

" Function: lh#os#SystemCmd(cmdName) {{{2
function! lh#os#SystemCmd(cmdName)
  if !exists('s:'.a:cmdName)
    call lh#os#system_detected()
  endif
  " @todo add some checkings
  return s:{a:cmdName}
endfunction

" Function: s:getSNR([func_name]) {{{2
function! s:getSNR(...)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

function! s:as_string(value) abort " {{{2
  " Meant to be used as alternative to shellescape
  if type(a:value) == type([])
    return '('.join(map(copy(a:value), 'shellescape(v:val)'), ' ').')'
  else
    call lh#assert#type(a:value).not().is({})
    return shellescape(a:value)
  endif
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
