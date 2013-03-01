"=============================================================================
" $Id$
" File:         autoload/lh/map.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" License:      GPLv3 with exceptions
"               <URL:http://code.google.com/p/lh-vim/wiki/License>
" Version:      3.1.8
" Created:      01st Mar 2013
" Last Update:  $Date$
"------------------------------------------------------------------------
" Description:
"       Functions to handle mappings
" 
"------------------------------------------------------------------------
" Installation:
"       Drop this file into {rtp}/autoload/lh
"       Requires Vim7+
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
let s:k_version = 318
function! lh#map#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = 0
function! lh#map#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#map#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" Function: lh#map#_build_command(mapping_definition) {{{3
" @param mapping_definition is a dictionary witch the same keys than the ones
" filled by maparg()
function! lh#map#_build_command(mapping_definition)
  let cmd = a:mapping_definition.mode
  if has_key(a:mapping_definition, 'noremap') && a:mapping_definition.noremap
    let cmd .= 'nore'
  endif
  let cmd .= 'map'
  let specifiers = ['silent', 'expr', 'buffer']
  for specifier in specifiers
    if has_key(a:mapping_definition, specifier) && a:mapping_definition[specifier]
      let cmd .= ' <'.specifier.'>'
    endif
  endfor
  let cmd .= ' '.(a:mapping_definition.lhs)
  let rhs = substitute(a:mapping_definition.rhs, '<SID>', "\<SNR>".(a:mapping_definition.sid).'_', 'g')
  let cmd .= ' '.rhs
  return cmd
endfunction

" Function: lh#map#define(mapping_definition) {{{3
function! lh#map#define(mapping_definition)
  let cmd = lh#map#_build_command(a:mapping_definition)
  silent exe cmd
endfunction
"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
