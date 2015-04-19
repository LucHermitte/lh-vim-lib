"=============================================================================
" File:         autoload/lh/os.vim                                {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/License.md>
" Version:      330
let s:k_version = 330
" Created:      10th Apr 2012
" Last Update:  19th Apr 2015
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
let s:verbose = 0
function! lh#os#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#os#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

" # OS kind {{{2

" Function: lh#os#has_unix_layer_installed() {{{3
function! lh#os#has_unix_layer_installed() abort
  return exists('g:unix_layer_installed') && g:unix_layer_installed
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

" # External program Execution {{{2

" Function: lh#os#chomp(text) {{{3
function! lh#os#chomp(text)
  return a:text[:-2]
endfunction

" Function: lh#os#system(cmd) {{{3
" @return the comp'ed result of system call
function! lh#os#system(cmd)
  return lh#os#chomp(system(a:cmd))
endfunction

" Function: lh#os#sys_cd(path [, ...]) {{{3
" Builds a string to :execute
" It will change current directory for the next command executed.
" Unlike |:cd|, the new directory doesn't affect Vim, only what it executed
" through :make, system(), :!, ...
function! lh#os#sys_cd(...) abort
  let res = s:SystemCmd('cd')
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

" Function: s:SystemCmd(cmdName) {{{2
function! s:SystemCmd(cmdName)
  " @todo add some checkings
  return s:{a:cmdName}
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
