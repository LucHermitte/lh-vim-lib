"=============================================================================
" File:		autoload/lh/event.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:	3.10.3
let s:k_version = 3103
" Created:	15th Feb 2008
" Last Update:	25th May 2016
"------------------------------------------------------------------------
" Description:
" 	Function to help manage vim |autocommand-events|
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim

"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#event#version()
  return s:k_version
endfunction

" # Debug {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#event#verbose(...)
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

function! lh#event#debug(expr) abort
  return eval(a:expr)
endfunction


"=============================================================================
" ## Functions {{{1
"------------------------------------------------------------------------
" # Event Registration {{{2
function! s:RegisteredOnce(cmd, group) abort
  call s:Verbose('Registered event group=%1, executing: %2', a:group, a:cmd)
  " We can't delete the current augroup autocommand => increment a counter
  if !exists('s:'.a:group) || s:{a:group} == 0
    let s:{a:group} = 1
    try
      if type(a:cmd) == type(function('has'))
        call a:cmd()
      else
        exe a:cmd
      endif
    finally
      " But we can clean the group
      exe 'augroup '.a:group
      au!
      augroup END
    endtry
  endif
endfunction

function! lh#event#register_for_one_execution_at(event, cmd, group, ...)
  let pattern = a:0 == 0 ? expand('%:p') : a:1
  let group = a:group.'_once'
  let s:{group} = 0
  exe 'augroup '.group
  au!
  exe 'au '.a:event.' '.pattern.' call s:RegisteredOnce('.string(a:cmd).','.string(group).')'
  augroup END
  call s:Verbose('au '.a:event.' '.pattern.' call s:RegisteredOnce('.string(a:cmd).','.string(group).')')
endfunction
function! lh#event#RegisterForOneExecutionAt(event, cmd, group)
  return lh#event#register_for_one_execution_at(a:event, a:cmd, a:group)
endfunction
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
