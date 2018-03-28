"=============================================================================
" File:         autoload/lh/map.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:	4.3.1
let s:version = '4.3.1'
" Created:      01st Mar 2013
" Last Update:  28th Mar 2018
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
" Function: lh#mapping#_build_rhs(mapping_definition) {{{2
" Transforms the {rhs} part of a mapping definition obtained with
" maparg(dict=1) into a something than can be used to define another mapping.
"
" @param mapping_definition is a dictionary witch the same keys than the ones
" filled by maparg()
" @since Version 4.3.0
function! lh#mapping#_build_rhs(mapping_definition) abort
  call lh#assert#value(a:mapping_definition)
        \.has_key('rhs')
  let g:mappings = get(g:, 'mappings', {})
  let g:mappings[a:mapping_definition.lhs] = a:mapping_definition
  let rhs = substitute(a:mapping_definition.rhs, '\c<SID>', "\<SNR>".get(a:mapping_definition, 'sid', 'SID_EXPECTED').'_', 'g')
  return rhs
endfunction

" Function: lh#mapping#_build_command(mapping_definition) {{{2
" @param mapping_definition is a dictionary witch the same keys than the ones
" filled by maparg()
function! lh#mapping#_build_command(mapping_definition) abort
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
  let rhs = lh#mapping#_build_rhs(a:mapping_definition)
  let cmd .= ' '.rhs
  return cmd
endfunction

" Function: lh#mapping#define(mapping_definition) {{{2
function! lh#mapping#define(mapping_definition)
  let cmd = lh#mapping#_build_command(a:mapping_definition)
  call s:Verbose("%1", strtrans(cmd))
  silent exe cmd
endfunction

" Function: lh#mapping#_switch_int(trigger, cases) {{{3
" @Since Version 4.3.0, moved from lh-bracket lh#brackets#_switch_int
function! lh#mapping#_switch_int(trigger, cases) abort
  for c in a:cases
    if eval(c.condition)
      return eval(c.action)
    endif
  endfor
  return lh#mapping#reinterpret_escaped_char(eval(a:trigger))
endfunction

" Function: lh#mapping#_switch(trigger, cases) {{{3
" @Since Version 4.3.0, moved from lh-bracket lh#brackets#_switch
function! lh#mapping#_switch(trigger, cases) abort
  return lh#mapping#_switch_int(a:trigger, a:cases)
  " debug return lh#mapping#_switch_int(a:trigger, a:cases)
endfunction

" Function: lh#mapping#clear() {{{2
function! lh#mapping#clear() abort
  let s:issues_notified = {}
  let s:issues_notified.n = {}
  let s:issues_notified.v = {}
  let s:issues_notified.o = {}
  let s:issues_notified.i = {}
  let s:issues_notified.c = {}
  let s:issues_notified.s = {}
  let s:issues_notified.x = {}
  let s:issues_notified.l = {}
  if has("patch-7.4-1707")
    let s:issues_notified[''] = {}
  endif
endfunction

" Function: lh#mapping#plug(keybinding, name, modes) {{{2
" Function: lh#mapping#plug(map_definition, modes)
call lh#mapping#clear()
function! lh#mapping#plug(...) abort
  if type(a:1) == type({})
    let mapping = extend(a:1, {'silent': 1, 'unique': 1})
    let modes = split(a:2, '\zs')
  else
    let mapping = {'silent': 1, 'unique': 1, 'lhs': a:1, 'rhs': a:2}
    let modes = split(a:3, '\zs')
  endif

  for mode in modes
    let mapping.mode = mode
    if hasmapto(mapping.rhs, mode)
      call s:Verbose('There is already a %{1.mode}map to %{1.rhs} -> ignoring', mapping)
      continue
    endif
    let previous_map = maparg(mapping.lhs, mode, 0, 1)
    if !empty(previous_map)
      call lh#assert#value(s:issues_notified).has_key(mode)
      if !has_key(s:issues_notified[mode], mapping.lhs) || s:verbose
        let s:issues_notified[mode][mapping.lhs] = 1
        let current = s:callsite()
        let origin = has_key(previous_map, 'sid') ?  'in '.lh#askvim#scriptname(previous_map.sid) : 'manually'
        let glob_loc = get(previous_map, 'buffer') ? 'local' : 'global'
        call lh#common#warning_msg(lh#fmt#printf('Warning: Cannot define %{2.mode}map `%1` to `%{2.rhs}`%3: a previous %5 mapping on `%1` was defined %4.',
              \ strtrans(mapping.lhs), mapping, current, origin, glob_loc))
      endif
    else
      let m_check = mapcheck(mapping.lhs, mode)
      if !empty(m_check)
        let current = s:callsite()
        " TODO: ask vim which mapping has the same start
        call lh#common#warning_msg(lh#fmt#printf('Warning: While defining %{2.mode}map `%1` to `%{2.rhs}`%3: there already exists another mapping starting as `%1` to `%4`.',
              \ strtrans(mapping.lhs), mapping, current, strtrans(m_check)))
      endif
      call lh#mapping#define(mapping)
    endif
  endfor
endfunction

" Function: lh#mapping#reinterpret_escaped_char(seq) {{{3
" This function transforms '\<cr\>', '\<esc\>', ... '\<{keys}\>' into the
" interpreted sequences "\<cr>", "\<esc>", ...  "\<{keys}>".
" It is meant to be used by fonctions like MapNoContext(), InsertSeq(), ... as
" we can not define mappings (/abbreviations) that contain "\<{keys}>" into the
" sequence to insert.
" Note:	It accepts sequences containing double-quotes.
" @version 4.0.0, moved from lh-dev lh#dev#reinterpret_escaped_char()
function! lh#mapping#reinterpret_escaped_char(seq) abort
  let seq = escape(a:seq, '"\')
  " let seq = (substitute( seq, '\\\\<\(.\{-}\)\\\\>', "\\\\<\\1>", 'g' ))
  " exe 'return "'.seq.'"'
  exe 'return "' .
        \   substitute( seq, '\\\\<\(.\{-}\)\\\\>', '"."\\<\1>"."', 'g' ) .  '"'
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
"
function! s:callsite()
  let stack = lh#exception#get_callstack()
  call stack.__pop() " remove this call site from the callstack
  if len(stack.callstack) <= 1
    " manually in the command line
    let current = ''
  else
    " As of vim 8.0-314, the callstack size is always of 1 when
    " called from a script. See Vim issue#1480
    let current = lh#fmt#printf(' in %{1.fname}:%{1.lnum}', stack.callstack[1])
  endif
  return current
endfunction

"------------------------------------------------------------------------
" }}}1
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
