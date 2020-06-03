"=============================================================================
" File:         autoload/lh/python.vim                            {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      5.1.2.
let s:k_version = '512'
" Created:      13th Jun 2018
" Last Update:  03rd Jun 2020
"------------------------------------------------------------------------
" Description:
"       Utility function to use python from vim
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
" # Version {{{2
function! lh#python#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#python#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Log(expr, ...) abort
  call call('lh#log#this',[a:expr]+a:000)
endfunction

function! s:Verbose(expr, ...) abort
  if s:verbose
    call call('s:Log',[a:expr]+a:000)
  endif
endfunction

function! lh#python#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## Exported functions {{{1
" Function: lh#python#best_still_avail() {{{3
" @post 'pyxversion' will be updated accordingly
function! lh#python#best_still_avail(...) abort
  if has('python_compiled') && has('python3_compiled')
    " On the first succesful has('python'), or has('python3'), the other one
    " will return false!
    " Hence this case
    let order = get(a:, 1, ['python3', 'python'])
    let tests = map(copy(order), 'has(v:val) ? v:val : ""')
    let tests = filter(tests, '!empty(v:val)') + ['']
    if tests[0] == 'python3'
      set pyxversion=3
    elseif tests[0] == 'python'
      set pyxversion=2
    endif
    return tests[0]
  elseif has('python3')
    if exists(':pyx')
      set pyxversion=3
    endif
    return 'python3'
  elseif has('python')
    if exists(':pyx')
      set pyxversion=2
    endif
    return 'python'
  else
    return ''
  endif
endfunction

" Function: lh#python#has() {{{3
function! lh#python#has() abort
  return has('python_compiled') || has('python3_compiled')
endfunction

" Function: lh#python#can_import(module) {{{3
function! lh#python#can_import(module) abort
  let flavour = lh#python#best_still_avail()
  if empty(flavour) | return 0 | endif
  try
    exe flavour.' import '.a:module
  catch /.*/
    return 0
  endtry
    return 1
endfunction

" Function: lh#python#external_can_import(module) {{{3
function! lh#python#external_can_import(module) abort
  try
    let r = system('python -c '.shellescape('import '.a:module))
  catch /.*/
    return 0
  endtry
  return v:shell_error == 0
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
