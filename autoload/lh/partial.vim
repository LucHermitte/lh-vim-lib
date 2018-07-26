"=============================================================================
" File:         autoload/lh/partial.vim                           {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/blob/master/License.md>
" Version:      4.6.0.
let s:k_version = '460'
" Created:      26th Jul 2018
" Last Update:  26th Jul 2018
"------------------------------------------------------------------------
" Description:
"       Portable function that emulate partials
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
function! lh#partial#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#partial#verbose(...)
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

function! lh#partial#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

" Function: lh#partial#has() {{{3
function! lh#partial#has() abort
  return lh#has#partials()
endfunction
let s:has_partials = lh#has#partials()

" # When partials are implemented {{{2
" Return a real partial
if s:has_partials
  " Function: lh#partial#make(func, args) {{{3
  function! lh#partial#make(func, args) abort
    let l:Res = function(a:func, a:args)
    return l:Res
  endfunction

  " Function: lh#partial#execute(Cb) {{{3
  function! lh#partial#execute(Cb, ...) abort
    call s:Verbose('Execute %1+%2', a:Cb, a:000)
    return call(a:Cb, a:000)
  endfunction
endif

" # When partials are not implemented {{{2
" Return something to be evaluated with |call()|
if ! s:has_partials
  " Function: lh#partial#make(func, args) {{{3
  function! lh#partial#make(func, args) abort
    " TODO: Use an OO type to detect whether what is received is an
    " emulated partial
    return type(a:func) == type([]) ? [a:func[0], a:func[1]+a:args]: [a:func, a:args]
  endfunction

  " Function: lh#partial#execute(Cb) {{{3
  function! lh#partial#execute(Cb, ...) abort
    call s:Verbose('Execute %1(%2)', a:Cb[0], a:Cb[1]+a:000)
    return call(a:Cb[0], a:Cb[1]+a:000)
  endfunction
endif

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
