"=============================================================================
" File:         autoload/extension/async.vim                      {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      5.0.0
let s:k_version = '050000'
" Created:      01st Sep 2016
" Last Update:  18th Feb 2020
"------------------------------------------------------------------------
" Description:
"       Airline extension for lh#async queues
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version      {{{2
function! airline#extensions#async#version()
  return s:k_version
endfunction

" # Debug        {{{2
let s:verbose = get(s:, 'verbose', 0)
function! airline#extensions#async#verbose(...)
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

function! airline#extensions#async#debug(expr) abort
  return eval(a:expr)
endfunction

" # Requirements {{{2
let s:has_jobs = lh#has#jobs()
if ! s:has_jobs
  finish
endif

"------------------------------------------------------------------------
" ## Exported functions {{{1
" # Registration {{{2
" Due to some potential rendering issues, the use of the `space` variable is
" recommended.
let s:spc = g:airline_symbols.space

" Function: airline#extensions#async#init(ext) {{{3
" First we define an init function that will be invoked from extensions.vim
function! airline#extensions#async#init(ext) abort
  " call s:Verbose('airline async init')
  " Here we define a new part for the plugin.  This allows users to place this
  " extension in arbitrary locations.
  call airline#parts#define_raw('async', '%{airline#extensions#async#get_activity()}')

  " Next up we add a funcref so that we can run some code prior to the
  " statusline getting modifed.
  call a:ext.add_statusline_func('airline#extensions#async#apply')

  " You can also add a funcref for inactive statuslines.
  " call a:ext.add_inactive_statusline_func('airline#extensions#example#unapply')
endfunction

" Function: airline#extensions#async#apply(...) {{{3
" This function will be invoked just prior to the statusline getting modified.
function! airline#extensions#async#apply(...) abort
  " call s:Verbose('airline async apply')
  " Let's say we want to append to section_b, first we check if there's
  " already a window-local override, and if not, create it off of the global
  " section_b.
  let w:airline_section_b = get(w:, 'airline_section_b', g:airline_section_b)

  " Then we just append this extenion to it, optionally using separators.
  let w:airline_section_b .= '%{airline#util#append(airline#extensions#async#get_activity(),0)}'
endfunction

" Function: airline#extensions#async#get_activity() {{{3
function! airline#extensions#async#get_activity() abort
  if !exists('*lh#async#_get_jobs')
    " lh#async hasn't been used yet => there is no jobs
    " => no need to load the autoload plugin
    return ''
  endif

  let [jobs, nb_paused] = lh#async#_get_jobs()
  let nb_jobs = len(jobs)
  if 0 == nb_jobs
    return ''
  else
    let txt = nb_paused
          \ ? '>'.nb_paused.' JOB QUEUE(S) PAUSED<'
          \ : get(jobs[0], 'txt', lh#option#unset())
    if lh#option#is_set(txt)
      let waiting = nb_jobs == 1 ? '' : ' + ' . (nb_jobs-1)
      return txt . waiting
    else
      return len(jobs)
    endif
  endif
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
