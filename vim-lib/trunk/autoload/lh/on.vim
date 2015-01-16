"=============================================================================
" $Id$
" File:         autoload/lh/on.vim                                {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" Version:      3.2.5.
let s:k_version = 325
" Created:      15th Jan 2015
" Last Update:  $Date$
"------------------------------------------------------------------------
" Description:
"
" * lh#on#exit() will register cleanup action to be executed at the end on a
" scope, and more precisally in a :finally section.
"   e.g.
"
"   # Here let suppose g:foo exists, but not g:bar
"   let cleanup = lh#on#exit()
"      \ . restore('g:foo')
"      \ . restore('g:bar')
"      \ . register('echo "The END"')
"      # note: functions can be registered as well
"    try
"      let g:foo = 1 - g:foo
"      let g:bar = 42
"      other actions that may throw
"    finally
"      call cleanup.finalize()
"    endtry
"    # Then g:foo and g:bar are restored, and "The END" has been echoed
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#on#version()
  return s:k_version
endfunction

" # Debug   {{{2
if !exists('s:verbose')
  let s:verbose = 0
endif
function! lh#on#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#on#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" # RAII/finalization {{{2

" Function: lh#on#exit() {{{3
function! lh#on#exit()
  let res = {'actions':[] }

  function! res.finalize() dict
    for Action in self.actions
      if type(Action) == type(function('has'))
        call Action()
      else
        exe Action
      endif
    endfor
  endfunction
  function! res.restore(varname) dict
    if stridx(a:varname, '~')!=-1 || exists(a:varname)
      let action = 'let '.a:varname.'='.string(eval(a:varname))
    else
      let action = 'unlet '.a:varname
    endif
    let self.actions += [action]

    return self
  endfunction
  function! res.register(action) dict
    let self.actions += [a:action]
    return self
  endfunction

  return res
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
