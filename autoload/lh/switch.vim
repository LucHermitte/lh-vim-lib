"=============================================================================
" File:         autoload/lh/switch.vim                            {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/blob/master/License.md>
" Version:      4.7.0.
let s:k_version = '470'
" Created:      05th Dec 2019
" Last Update:  05th Dec 2019
"------------------------------------------------------------------------
" Description:
"       Defines a switch object that can evaluate cases defined as 'cond' +
"       'func'
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
function! lh#switch#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#switch#verbose(...)
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

function! lh#switch#debug(expr) abort
  return eval(a:expr)
endfunction

" # Script ID {{{2
function! s:getSID() abort
  return eval(matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_getSID$'))
endfunction
let s:k_script_name      = s:getSID()

"------------------------------------------------------------------------
" ## Exported functions {{{1

" # Switch type
" Services:
" - add_case({'cond': XXX, 'func': YYYY})
" - evaluate(args...)

function! s:_is_true(...) dict abort " test if a case condition is fullfilled {{{3
  " TODO: support lhvl-function
  if exists('v:true')
    call lh#assert#type(self.cond).belongs_to(0, function('has'), '', v:true)
  else
    call lh#assert#type(self.cond).belongs_to(0, function('has'), '')
  endif
  if type(self.cond) == type(function('has'))
    return call(self.cond, a:000)
  elseif type(self.cond) == type('')
    return eval(self.cond)
  else
    return self.cond
  endif
endfunction

function! s:_evaluate(...) dict abort " single case evaluation {{{3
  if type(self.func) == type(function('has'))
    return call(self.func, a:000)
  else
    return eval(self.func)
  endif
endfunction

function! s:add_case(case) dict abort " add a new case to the switch {{{3
  call lh#object#inject_methods(a:case, s:k_script_name, ['_is_true', '_evaluate'])
  call add(self._cases, a:case)
endfunction

function! s:evaluate(...) dict abort " evaluate the switch {{{3
  call lh#assert#value(self._cases).not().empty()
  for c in self._cases
    if call(c._is_true, a:000, c)
      return call(c._evaluate, a:000, c)
    endif
  endfor
  call lh#assert#unexpected('Unexcepted case')
endfunction

" Function: lh#switch#new([cases...]) {{{3
function! lh#switch#new(...) abort
  let res = lh#object#make_top_type({'_cases': []})
  call lh#object#inject_methods(res, s:k_script_name, ['add_case', 'evaluate'])
  for c in a:000
    call res.add_case(c)
  endfor
  return res
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
