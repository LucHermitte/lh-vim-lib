"=============================================================================
" File:         autoload/lh/qf.vim                                {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/blob/master/License.md>
" Version:      5.2.2.
let s:k_version = '522'
" Created:      26th Jun 2018
" Last Update:  18th Nov 2020
"------------------------------------------------------------------------
" Description:
"       Defines functions related to quickfix feature
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
function! lh#qf#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#qf#verbose(...)
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

function! lh#qf#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" # Context object {{{2
" Function: lh#qf#make_context_map() {{{3
" Create a map that'll (externally) associate context to qf lists.
" As other plugins may use that context for their own need, let's use another
" approach
function! s:getSID() abort
  return eval(matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_getSID$'))
endfunction

let s:k_script_name      = s:getSID()
if lh#has#properties_in_qf()
  function! lh#qf#make_context_map(required) abort
    let res = lh#object#make_top_type({'_contexts': {}})
    call lh#object#inject_methods(res, s:k_script_name
          \, 'get_id'
          \, '_context'
          \, 'get'
          \, 'set'
          \ )
    return res
  endfunction
else
  function! lh#qf#make_context_map(required) abort
    call lh#assert#true(! a:required, "Sorry this feature isn't available in Vim ".v:version)
    let res = lh#object#make_top_type({})
    call lh#object#inject(res, 'get_id',   'dummy', s:k_script_name)
    call lh#object#inject(res, '_context', 'dummy', s:k_script_name)
    call lh#object#inject(res, 'get',      'dummy', s:k_script_name)
    call lh#object#inject(res, 'set',      'dummy', s:k_script_name)
    return res
  endfunction
endif

function! s:dummy(...) abort
endfunction

function! s:get_id() dict abort
  return getqflist({'id': 0}).id
endfunction

function! s:_context(...) dict abort
  let id = a:0 > 0 ? a:1 : self.get_id()
  return lh#dict#need_ref_on(self._contexts, id, {})
  "if ! has_key(self._contexts, id)
  "  let self._contexts[id] = {}
  "endif
  "return self._contexts[id]
endfunction

function! s:get(key, ...) dict abort
  let id = a:0 > 0 ? a:1 : self.get_id()
  return get(self._context(id), a:key)
endfunction

function! s:set(key, value, ...) dict abort
  let id = a:0 > 0 ? a:1 : self.get_id()
  let ctx = self._context(id)
  let ctx[a:key] = a:value
  return ctx[a:key]
endfunction

" # Misc functions {{{2
" Function: lh#qf#get_metrics()      {{{3
" @Since version 4.7.0, moved for build-tools-wrappers
function! lh#qf#get_metrics() abort
  let qf = getqflist()
  let recognized = filter(qf, 'get(v:val, "valid", 1)')
  " TODO: support other locales, see lh#po#context().tranlate()
  let errors   = filter(copy(recognized), 'v:val.type == "E" || v:val.text =~ "\\v^ *(error|erreur)"')
  let warnings = filter(copy(recognized), 'v:val.type == "W" || v:val.text =~ "\\v^ *(warning|attention)"')
  let res = { 'all': len(qf), 'errors': len(errors), 'warnings': len(warnings) }
  return res
endfunction

" Function: lh#qf#get_title()        {{{3
" @since V4.5.0
if lh#has#properties_in_qf()
  function! lh#qf#get_title() abort
    return getqflist({'title':1}).title
  endfunction
else
  function! lh#qf#get_title() abort
    let winnr = lh#qf#get_winnr()
    return winnr == 0 ? '' : getwinvar(winnr, 'quickfix_title')
  endfunction
endif

" Function: lh#qf#set_title()        {{{3
" @since V5.1.0
if lh#has#properties_in_qf()
  function! lh#qf#set_title(title) abort
    call setqflist([], 'a', {'title': a:title})
  endfunction
else
  function! lh#qf#set_title(title) abort
    let winnr = lh#qf#get_winnr()
    return winnr == 0 ? '' : setwinvar(winnr, 'quickfix_title', a:title)
  endfunction
endif

" Function: lh#qf#get_winnr()        {{{3
" @since V4.5.0
if lh#has#patch('patch-7.4-2215') " && exists('*getwininfo')
  function! lh#qf#get_winnr() abort
    let wins = filter(getwininfo(), 'v:val.quickfix && !v:val.loclist')
    " assert(len(wins) <= 1)
    return empty(wins) ? 0 : wins[0].winnr
  endfunction
else
  let s:k_msg_qflist = lh#po#context().translate('[Quickfix List]')
  function! lh#qf#get_winnr() abort
    let buffers = lh#askvim#execute('ls!')
    call filter(buffers, 'v:val =~ "\\V".s:k_msg_qflist')
    " :cclose removes the buffer from the list (in my config only??)
    " assert(len(buffers) <= 1)
    return empty(buffers) ? 0 : eval(matchstr(buffers[0], '\v^\s*\zs\d+'))
  endfunction
endif

" Function: lh#qf#is_displayed()     {{{3
function! lh#qf#is_displayed() abort
  return lh#qf#get_winnr() ? 1 : 0
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
