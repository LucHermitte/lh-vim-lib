"=============================================================================
" File:         autoload/lh/on.vim                                {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib/>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/License.md>
" Version:      3.10.2.
let s:k_version = 3102
" Created:      15th Jan 2015
" Last Update:  24th May 2016
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
let s:verbose = get(s:, 'verbose', 0)
function! lh#on#verbose(...)
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

function! lh#on#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" # RAII/finalization {{{2

" Function: lh#on#exit() {{{3
function! lh#on#exit()
  let res = {'actions':[] }

  let res.finalize = function(s:getSNR('finalize'))

  function! res.restore(varname) dict abort " {{{4
    " unlet if always required in case the type changes
    let self.actions += ['call lh#on#_unlet('.string(a:varname).')']
    if a:varname =~ '[~@]' || exists(a:varname)
      let action = 'let '.a:varname.'='.string(eval(a:varname))
      let self.actions += [action]
    endif

    return self
  endfunction
  function! res.restore_option(varname, ...) dict abort " {{{4
    let scopes = a:0 > 0 ? a:1 : 'wbg'
    let actions = []
    let lScopes = split(scopes, '\s*')
    for scope in lScopes
      let varname = scope . ':' . a:varname
      let actions += ['call lh#on#_unlet('.string(varname).')']
      if stridx(varname, '~')!=-1 || exists(varname)
        let action = 'let '.varname.'='.string(eval(varname))
        let actions += [action]
        " break
      endif
    endfor
    " if empty(actions)
      " let actions = map(lScopes, '":silent! unlet ".v:val.":".a:varname')
    " endif

    let self.actions += actions
    return self
  endfunction
  function! res.register(action) dict abort " {{{4
    let self.actions += [a:action]
    return self
  endfunction

  function! res.restore_buffer_mapping(key, mode) dict abort " {{{4
    let keybinding = maparg(a:key, a:mode, 0, 1)
    if get(keybinding, 'buffer', 0)
      let self.actions += [ 'silent! call lh#mapping#define('.string(keybinding).')']
    else
      let self.actions += [ 'silent! '.a:mode.'unmap <buffer> '.a:key ]
    endif
    return self
  endfunction

  " return {{{4
  return res
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

" # finalizer methods {{{2
function! s:finalize() dict " {{{4
  " This function shall not fail!
  for Action in self.actions
    try
      if type(Action) == type(function('has'))
        call Action()
      elseif !empty(Action)
        exe Action
      endif
    catch /.*/
      call lh#log#this('Error occured when running action (%1)', Action)
      call lh#log#exception()
    finally
      unlet Action
    endtry
  endfor
endfunction

" # misc functions {{{2
" s:getSNR([func_name]) {{{3
function! s:getSNR(...)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

" Function: lh#on#_unlet(varname) {{{3
function! lh#on#_unlet(varname) abort
  " Avoid `silent!` as it messes Vim client-server mode and as a consequence
  " rspecs tests
  " Note: vim options, and environment variables cannot be unset
  " call assert_true(!empty(a:varname))
  if a:varname[0] == '$'
    " Cannot use {a:varname} syntax with environment variables
    if exists(a:varname)
      exe "let ".a:varname." = ''"
    endif
  elseif exists(a:varname) && a:varname !~ '[&]'
    unlet {a:varname}
  endif
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
