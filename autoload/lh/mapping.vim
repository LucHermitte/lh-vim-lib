"=============================================================================
" File:         autoload/lh/map.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:	4.0.0
let s:version = '4.0.0'
" Created:      01st Mar 2013
" Last Update:  15th Feb 2017
"------------------------------------------------------------------------
" Description:
"       Functions to handle mappings
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#mapping#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#mapping#verbose(...)
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

function! lh#mapping#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" Function: lh#mapping#_build_command(mapping_definition) {{{2
" @param mapping_definition is a dictionary witch the same keys than the ones
" filled by maparg()
function! lh#mapping#_build_command(mapping_definition)
  call lh#assert#value(a:mapping_definition)
        \.has_key('mode')
        \.has_key('lhs')
        \.has_key('rhs')
  let cmd = a:mapping_definition.mode
  if get(a:mapping_definition, 'noremap', 0)
    let cmd .= 'nore'
  endif
  let cmd .= 'map'
  let specifiers = ['silent', 'expr', 'buffer', 'unique', 'nowait']
  let cmd .= join(map(copy(specifiers), 'get(a:mapping_definition, v:val, 0) ? " <".v:val.">" :""'),'')
  " for specifier in specifiers
    " if get(a:mapping_definition, specifier, 0)
      " let cmd .= ' <'.specifier.'>'
    " endif
  " endfor
  let cmd .= ' '.(a:mapping_definition.lhs)
  let rhs = substitute(a:mapping_definition.rhs, '<SID>', "\<SNR>".get(a:mapping_definition, 'sid', 'SID_EXPECTED').'_', 'g')
  let cmd .= ' '.rhs
  return cmd
endfunction

" Function: lh#mapping#define(mapping_definition) {{{2
function! lh#mapping#define(mapping_definition)
  let cmd = lh#mapping#_build_command(a:mapping_definition)
  call s:Verbose("%1", strtrans(cmd))
  silent exe cmd
endfunction

" Function: lh#mapping#plug(keybinding, name, modes) {{{3
function! lh#mapping#plug(keybinding, name, modes) abort
  let modes = split(a:modes, '\zs')
  for mode in modes
    if !hasmapto(a:name, mode) && (mapcheck(a:keybinding, mode) == "")
      try
        exe mode.'map <silent> <unique> '.a:keybinding.' '.a:name
      catch /E226:.*/
        throw 'E226: a ('.mode.')mapping already exists for '.strtrans(a:keybinding)
      catch /.*/
        echo lh#exception#callstack(v:throwpoint)
        throw 'E227: a ('.mode.')mapping already exists for '.strtrans(a:keybinding)
      endtry
    endif
  endfor
endfunction
"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
