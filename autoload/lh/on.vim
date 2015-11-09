"=============================================================================
" File:         autoload/lh/on.vim                                {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/lh-vim-lib/>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/License.md>
" Version:      3.3.9.
let s:k_version = 339
" Created:      15th Jan 2015
" Last Update:  09th Nov 2015
"------------------------------------------------------------------------
" Description:
"
" * lh#on#exit() will register cleanup action to be executed at the end on a
" scope, and more precisally in a :finally section.
"   e.g.
"
"   # Here let suppose g:foo exists, but not g:bar
"   # and b:opt1 exists, and g:opt2 exists, but b:opt2, g:opt3 not b:opt3 exist
"   let cleanup = lh#on#exit()
"      \ . restore('g:foo')
"      \ . restore('g:bar')
"      \ . register('echo "The END"')
"      \ . restore_option('opt1')
"      \ . restore_option('opt2')
"      \ . restore_option('opt3')
"      # note: functions can be registered as well
"    try
"      let g:foo = 1 - g:foo
"      let g:bar = 42
"      other actions that may throw
"      let b:opt1 = 'foo'
"      let g:opt2 = 'bar'
"      let b:opt2 = 'foobar'
"      let b:opt3 = 'bar'
"    finally
"      call cleanup.finalize()
"    endtry
"    # Then g:foo and g:bar are restored, "The END" has been echoed
"    # b:opt1, g:opt2 are restored, b:opt2, b:opt3 and g:opt3 are "!unlet"
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
  function! res.restore_option(varname, ...) dict
    let scopes = a:0 > 0 ? a:1 : 'wbg'
    let actions = []
    let lScopes = split(scopes, '\s*')
    for scope in lScopes
      let varname = scope . ':' . a:varname
      if stridx(varname, '~')!=-1 || exists(varname)
        let action = 'let '.varname.'='.string(eval(varname))
        let actions += [action]
        break
      endif
    endfor
    if empty(actions)
      let actions = map(lScopes, '":silent! unlet ".v:val.":".a:varname')
    endif

    let self.actions += actions
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
