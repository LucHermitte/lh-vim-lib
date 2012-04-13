"=============================================================================
" $Id$
" File:         autoload/lh/os.vim                                {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" Version:      310
let s:k_version = 310
" Created:      10th Apr 2012
" Last Update:  $Date$
"------------------------------------------------------------------------
" Description:
"       «description»
" 
"------------------------------------------------------------------------
" Installation:
"       Drop this file into {rtp}/autoload/lh
"       Requires Vim7+
"       «install details»
" History:      «history»
" TODO:         «missing features»
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

" Function: lh#os#chomp(text) {{{3
function! lh#os#chomp(text)
  return a:text[:-2]
endfunction

" Function: lh#os#system(cmd) {{{3
" @return the comp'ed result of system call
function! lh#os#system(cmd)
  return lh#os#chomp(system(a:cmd))
endfunction

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

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
