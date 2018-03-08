"=============================================================================
" File:         autoload/lh/on.vim                                {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib/>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/License.md>
" Version:      4.01.0.
let s:k_version = 4010
" Created:      15th Jan 2015
" Last Update:  08th Mar 2018
"------------------------------------------------------------------------
" Description:
"
" * lh#on#exit() will register cleanup action to be executed at the end on a
" scope, and more precisally in a :finally section.
"   e.g.
"
"   # Here let suppose g:foo exists, but not g:bar
"   # and b:opt1 exists, and g:opt2 exists, but b:opt2, g:opt3 not b:opt3 exist
"   let l:d = {'a': 1}
"   let cleanup = lh#on#exit()
"      \ . restore('g:foo')
"      \ . restore('g:bar')
"      \ . restore(l:d, 'a')
"      \ . restore(l:d, 'b')
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
"      let l:d.a  = 12
"      let l:d.b  = 13
"    finally
"      call cleanup.finalize()
"    endtry
"    # Then g:foo and g:bar are restored, "The END" has been echoed
"    # b:opt1, g:opt2 are restored, b:opt2, b:opt3 and g:opt3 are "!unlet"
"    # Keys "a" and "b" of dictionary l:d are restored
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

" - Methods {{{3
function! s:restore(varname, ...) dict abort " {{{4
  let is_dict = type(a:varname) == type({})
  call lh#assert#true((type(a:varname) == type(''))
        \ || (is_dict && a:0 == 1),
        \ "lh#on#exit().restore() expects a variable name or a dictionary key, not a variable!"
        \ )
  if is_dict
    let args = [function(s:getSNR('var_restorer')), a:varname, string(a:1)]
    if has_key(a:varname, a:1)
      let args += [ string(a:varname[a:1]) ]
    endif

    let clean = call('lh#function#bind', args)
    let self.actions += [clean]
  else
    let varname = a:varname

    " unlet is always required in case the type changes
    let self.actions += ['call lh#on#_unlet('.string(varname).')']
    if lh#option#is_set_locally(varname)
      let varname = '&l:'.varname[1:]
    endif
    if varname =~ '[~@]' || exists(varname)
      let action = 'let '.varname.'='.string(eval(varname))
      let self.actions += [action]
    endif
  endif

  return self
endfunction

function! s:restore_option(varname, ...) dict abort " {{{4
  if type(a:varname) != type('')
    throw "lh#on#exit().restore_option() expects a variable name, not a variable!"
  endif
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

function! s:register(Action, ...) dict abort " {{{4
  if get(a:, '1', 0) == 'priority'
    let self.actions = [a:Action] + self.actions
  else
    let self.actions += [a:Action]
  endif
  return self
endfunction

function! s:restore_buffer_mapping(key, mode) dict abort " {{{4
  let keybinding = maparg(a:key, a:mode, 0, 1)
  if get(keybinding, 'buffer', 0)
    let self.actions += [ 'silent! call lh#mapping#define('.string(keybinding).')']
  else
    let self.actions += [ 'silent! '.a:mode.'unmap <buffer> '.a:key ]
  endif
  return self
endfunction

function! s:restore_mapping_and_clear_now(key, mode) dict abort " {{{4
  " <buffer> mapping hide non buffer one => first handle the buffer one
  call self.restore_buffer_mapping(a:key, a:mode)
  exe 'silent! '.a:mode.'unmap <buffer> '.a:key

  let keybinding = maparg(a:key, a:mode, 0, 1)
  call lh#assert#equal(0, get(keybinding, 'buffer', 0))
  if !empty(keybinding)
    let self.actions += [ 'silent! call lh#mapping#define('.string(keybinding).')']
    exe 'silent! '.a:mode.'unmap '.a:key
  else
    let self.actions += [ 'silent! '.a:mode.'unmap '.a:key ]
  endif
  return self
endfunction

function! s:restore_highlight(hlname) dict abort " {{{4
  let def = lh#askvim#execute('hi '.a:hlname)[0]
  let action = substitute(def, '^'.a:hlname.'\s\+\zsxxx\s\+', '', '')
  let self.actions += [ 'silent! hi '.action]
  return self
endfunction

function! s:restore_cursor() dict abort " {{{4
  let crt_pos = lh#position#getcur()
  call self.register('call setpos(".", '.string(crt_pos).')')
  return self
endfunction

" Function: lh#on#exit() {{{3
function! lh#on#exit()
  let res = lh#object#make_top_type({'actions':[] })

  let res.finalize                       = function(s:getSNR('finalize'))
  let res.restore                        = function(s:getSNR('restore'))
  let res.restore_option                 = function(s:getSNR('restore_option'))
  let res.register                       = function(s:getSNR('register'))
  let res.restore_buffer_mapping         = function(s:getSNR('restore_buffer_mapping'))
  let res.restore_mapping_and_clear_now  = function(s:getSNR('restore_mapping_and_clear_now'))
  let res.restore_highlight              = function(s:getSNR('restore_highlight'))
  let res.restore_cursor                 = function(s:getSNR('restore_cursor'))

  return res
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

" # finalizer methods {{{2
function! s:finalize() dict " {{{4
  " This function shall not fail!
  for l:Action in self.actions
    try
      if type(l:Action) == type(function('has'))
        call l:Action()
      elseif type(l:Action) == type({})
        if has_key(l:Action, 'object')
          " Trick to work without Partials in old vim versions
          call lh#assert#value(l:Action).has_key('method')
          call call(l:Action.method, [], l:Action.object)
        elseif has_key(l:Action, 'execute')
          call l:Action.execute([])
        else
          call lh#assert#unexpected(lh#fmt#printf("Doesn't know how to evaluate this dictionary: %1", l:Action"))
        endif
      elseif !empty(l:Action)
        exe l:Action
      endif
    catch /.*/
      call lh#log#this('Error occured when running action (%1): %2', l:Action, v:exception)
      call lh#log#exception()
    finally
      unlet l:Action
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

" s:var_restorer(var, key [, old]) {{{3
function! s:var_restorer(var, key, ...) abort
  if has_key(a:var, a:key)
    unlet a:var[a:key]
  endif
  if a:0 > 0
    let a:var[a:key] = a:1
  endif
endfunction

" Function: lh#on#_unlet(varname) {{{3
function! lh#on#_unlet(varname) abort
  " Avoid `silent!` as it messes Vim client-server mode and as a consequence
  " rspecs tests
  " Note: vim options, and environment variables cannot be unset
  call lh#assert#not_empty(a:varname)
  if a:varname[0] == '$'
    " Cannot use {a:varname} syntax with environment variables
    if exists(a:varname)
      exe "let ".a:varname." = ''"
    endif
  elseif exists(a:varname) && a:varname !~ '[&]'
    " unlet {a:varname}
    exe 'unlet '.a:varname
  endif
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
