"=============================================================================
" File:         autoload/lh/map.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:	5.4.0
let s:version = '5.4.0'
" Created:      01st Mar 2013
" Last Update:  01st Dec 2022
"------------------------------------------------------------------------
" Description:
"       Functions to handle mappings
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
let s:k_script_name      = expand('<sfile>:p')

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
  " For debug purpose
  let g:lh#mapping#list = get(g:, 'lh#mapping#list', {})
  let g:lh#mapping#list[a:mapping_definition.lhs] = a:mapping_definition
  " Inject the right SNR instead of "<sid>"
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
function! lh#mapping#define(md) abort
  call lh#assert#value(a:md)
        \.has_key('mode')
        \.has_key('lhs')
        \.has_key('rhs')
  " In case LaTeX-Suite/IMAP is installed
  if exists('*IMAP') && a:md.mode=='i' && (a:md.lhs !~? '<bs>\|<cr>\|<up>\|<down>\|<left>\|<right>\|<M-\|<C-\|<PageDown>\|<PageUp>\|<end>\|<home>')
    let rhs = get(a:md, 'expr', 0) ? "\<c-r>=".(a:md.rhs)."\<cr>" : a:md.rhs
    call s:Verbose("Using IMAP() to define the mapping %1 -> %2", strtrans(a:md.lhs), strtrans(rhs))
    let ft = get(a:md, 'buffer', 0) ? &ft : ''
    call IMAP(a:md.lhs, rhs, ft)
  else
    let cmd = lh#mapping#_build_command(a:md)
    call s:Verbose("%1", strtrans(cmd))
    silent exe cmd
  endif
endfunction

" Function: lh#mapping#_switch_int(trigger, cases) {{{2
" @Since Version 4.3.0, moved from lh-bracket lh#brackets#_switch_int
function! lh#mapping#_switch_int(trigger, cases) abort
  for c in a:cases
    if eval(c.condition)
      return eval(c.action)
    endif
  endfor
  return lh#mapping#reinterpret_escaped_char(eval(a:trigger))
endfunction

" Function: lh#mapping#_switch(trigger, cases) {{{2
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
  let s:issues_notified.t = {}
  if has("patch-7.4.1707")
    let s:issues_notified[''] = {}
  endif
endfunction

" Function: lh#mapping#plug(keybinding, name, modes) {{{2
" Function: lh#mapping#plug(map_definition, modes)
call lh#mapping#clear()
function! lh#mapping#plug(...) abort
  let mapping = {'silent': 1, 'unique': 1}
  if type(a:1) == type({})
    let mapping = extend(mapping, a:1, "force")
    let modes = split(a:2, '\zs')
  else
    if a:0 >= 4 && type(a:4) == type({})
      let mapping = extend(mapping, a:4, "force")
    endif
    let mapping = extend(mapping, {'lhs': a:1, 'rhs': a:2})
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

" Function: lh#mapping#who_maps(rhs, mode) {{{2
" @since Version 4.6.0
function! lh#mapping#who_maps(rhs, mode) abort
  let maps = filter(lh#askvim#execute(a:mode . 'map'), 'v:val =~ a:rhs."$"')
  " Unfortunatelly, knowing exactly what mapping is associated to a
  " keybinding, it's best to use maparg()
  let lhs_list = map(maps, 'split(v:val)[1]')
  let mappings = map(lhs_list, 'maparg(v:val, a:mode, 0, 1)')
  call filter(mappings, 'v:val.rhs == a:rhs')
  return mappings
endfunction

" Function: lh#mapping#reinterpret_escaped_char(seq) {{{2
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

" Object: ToggableMappings {{{2
" @Since Version 5.3.0, moved from lh-bracket lh#brackets#*

" Sub-object: activation_state {{{3
function! s:make_activation_state() abort " {{{4
  let state = {
        \ 'is_active': 1,
        \ 'is_active_in_buffer': {},
        \}
  let res = lh#object#make_top_type(state)
  call lh#object#inject_methods(res, s:k_script_name, 'toggle', 'must_activate', 'must_deactivate')
  return res
endfunction

function! s:toggle() dict abort " {{{4
  let self.is_active = 1 - self.is_active
  let bid = bufnr('%')
  let self.is_active_in_buffer[bid] = self.is_active
endfunction

function! s:must_activate() dict abort " {{{4
  let bid = bufnr('%')
  if has_key(self.is_active_in_buffer, bid)
    let must = !self.is_active_in_buffer[bid]
    let why = must." <= has key, global=". (self.is_active) . ", local=".self.is_active_in_buffer[bid]
  else " first time in the buffer
    " throw "lh#mappings#must_activate() assertion failed: unknown local activation state"
    let must = 0
    let why = must." <= has not key, global=". (self.is_active)
  endif
  let self.is_active_in_buffer[bid] = self.is_active
  " echomsg "must_activate[".bid."]: ".why
  return must
endfunction

function! s:must_deactivate() dict abort " {{{4
  let bid = bufnr('%')
  if has_key(self.is_active_in_buffer, bid)
    let must = self.is_active_in_buffer[bid]
    let why = must." <= has key, global=". (self.is_active) . ", local=".self.is_active_in_buffer[bid]
  else " first time in the buffer
    " throw "lh#mappings#must_deactivate() assertion failed: unknown local activation state"
    let must = 0
    let why = must." <= has not key, global=". (self.is_active)
  endif
  let self.is_active_in_buffer[bid] = self.is_active
  " echomsg "must_deactivate[".bid."]: ".why
  return must
endfunction

" Function: lh#mapping#create_toggable_group(kind) {{{3
let s:toggable_mapping_groups = get(s:, 'toggable_mapping_groups', [])
" let s:toggable_mapping_groups = []

function! lh#mapping#create_toggable_group(kind) abort
  let grp = lh#object#make_top_type({})
  let grp.definitions = {}
  let grp._state      = s:make_activation_state()
  let grp.kind        = a:kind
  call lh#object#inject_methods(grp, s:k_script_name,
        \  'define_map', 'define_imap'
        \, 'list_mappings', 'clear_mappings', 'toggle_mappings'
        \, '_ev_buffer_enter', '_ev_buffer_leave', '_ev_buffer_delete'
        \, '_get_definitions')
  call add(s:toggable_mapping_groups, grp)
  return grp
endfunction

function! s:_get_definitions(isLocal) dict abort " {{{3
  " Fetch the brackets defined for the current buffer.
  let bid = a:isLocal ? bufnr('%') : -1
  if !has_key(self.definitions, bid)
    let self.definitions[bid] = []
  endif
  let crt_definitions = self.definitions[bid]
  return crt_definitions
endfunction

function! s:define_map(mode, lhs, rhs, isLocal, isExpr) dict abort " {{{3
  let crt_definitions = self._get_definitions(a:isLocal)
  let crt_mapping = {}
  let crt_mapping.lhs    = escape(a:lhs, '|') " need to escape bar
  let crt_mapping.mode   = a:mode
  let crt_mapping.rhs    = a:rhs
  let crt_mapping.buffer = a:isLocal ? '<buffer> ' : ''
  let crt_mapping.expr   = a:isExpr  ? '<expr> '   : ''
  if self._state.is_active
    call s:Map(crt_mapping)
  endif
  let p = lh#list#Find_if(crt_definitions,
        \ 'v:val.mode==v:1_.mode && v:val.lhs==v:1_.lhs',
        \ [crt_mapping])
  if p == -1
    call add(crt_definitions, crt_mapping)
  else
    if crt_mapping.rhs != a:rhs
      call lh#common#warning_msg("Overrriding ".a:mode."map ".a:lhs." ".crt_definitions[p].rhs."  with ".a:rhs)
    elseif &verbose >= 2
      call s:Log("(almost) Overrriding ".a:mode."map ".a:lhs." ".crt_definitions[p].rhs." with ".a:rhs)
    endif
    let crt_definitions[p] = crt_mapping
  endif
endfunction

function! s:define_imap(lhs, rhs, isLocal, ...) dict abort " {{{3
  " TODO: fatorize w/ lh#mapping#define()
  if exists('*IMAP') && a:lhs !~? '<bs>\|<cr>\|<up>\|<down>\|<left>\|<right>\|<M-\|<C-\|<PageDown>\|<PageUp>\|<end>\|<home>'
    let rhs = "\<c-r>=".a:rhs."\<cr>"
    let ft = a:isLocal ? 'ft' : ''
    call s:Verbose("Using IMAP() to define the mapping %1 -> %2", strtrans(a:lhs), strtrans(rhs))
    call IMAP(a:lhs, rhs, ft)
  else
    let nore = get(a:, '1', 1) ? 'nore' : ''
    " call s:DefineMap('inore', a:lhs, " \<c-r>=".(a:rhs)."\<cr>", a:isLocal)
    call self.define_map('i' . nore, a:lhs, a:rhs, a:isLocal, 1)
  endif
endfunction

function! s:list_mappings(isLocal) dict abort " {{{3
  let crt_definitions = self._get_definitions(a:isLocal)
  for m in crt_definitions
    let cmd = m.mode.'map <silent> ' . m.buffer . m.lhs .' '.m.rhs
    echomsg cmd
  endfor
endfunction

function! s:clear_mappings(isLocal) dict abort " {{{3
  let crt_definitions = self._get_definitions(a:isLocal)
  if self._state.is_active
    for m in crt_definitions
      call s:UnMap(m)
    endfor
  endif
  if !empty(crt_definitions)
    unlet crt_definitions[:]
  endif
endfunction

function! s:toggle_mappings() dict abort " {{{3
  " TODO: when entering a buffer, update the mappings depending on whether it
  " has been toggled
  if exists('*IMAP')
    let g:Imap_FreezeImap = 1 - self._state.is_active
  else
    let crt_definitions = self._get_definitions(0) + self._get_definitions(1)
    if self._state.is_active " active -> inactive
      for m in crt_definitions
        call s:UnMap(m)
      endfor
      call lh#common#warning_msg(self.kind . "mappings deactivated")
    else " inactive -> active
      for m in crt_definitions
        call s:Map(m)
      endfor
      call lh#common#warning_msg(self.kind . "mappings (re)activated")
    endif
  endif " No imaps.vim
  call self._state.toggle()
endfunction

function! s:_ev_buffer_enter() dict abort " {{{3
  " Activate or deactivate the mappings in the current buffer
  if self._state.is_active
    if self._state.must_activate()
      let crt_definitions = self._get_definitions(1)
      for m in crt_definitions
        call s:Map(m)
      endfor
    endif " active && must activate
  else " not active
    let crt_definitions = self._get_definitions(1)
    if self._state.must_deactivate()
    for m in crt_definitions
        call s:UnMap(m)
      endfor
    endif
  endif
endfunction

function! s:_ev_buffer_leave() dict abort " {{{3
  let bid = bufnr('%')
  let self._state.is_active_in_buffer[bid] = self._state.is_active
endfunction

function! s:_ev_buffer_delete() dict abort " {{{3
  let bid = bufnr('<abuf>')
  if has_key(self._state.is_active_in_buffer, bid)
    unlet self._state.is_active_in_buffer[bid]
  endif
endfunction

"# Autocommands                                                                                              {{{3
augroup LHToggableMappings
  au!
  au BufEnter  * call s:UpdateMappingsActivationE()
  au BufLeave  * call s:UpdateMappingsActivationL()
  au BufDelete * call s:UpdateMappingsActivationD()
augroup END

function! s:UpdateMappingsActivationE() abort
  for obj in s:toggable_mapping_groups
    call obj._ev_buffer_enter()
  endfor
endfunction

function! s:UpdateMappingsActivationL() abort
  for obj in s:toggable_mapping_groups
    call obj._ev_buffer_leave()
  endfor
endfunction

function! s:UpdateMappingsActivationD() abort
  for obj in s:toggable_mapping_groups
    call obj._ev_buffer_delete()
  endfor
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

function! s:callsite() " {{{2
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

" Function: s:UnMap(m)                                                                                       {{{2
function! s:UnMap(m) abort
  try
    let cmd = a:m.mode[0].'unmap '. a:m.buffer . a:m.lhs
    call s:Verbose(cmd)
    exe cmd
  catch /E31/
    call s:Verbose("%1: %2", v:exception, cmd)
  endtry
endfunction

" Function: s:Map(m)                                                                                         {{{2
function! s:Map(m) abort
  let cmd = a:m.mode.'map <silent> ' . a:m.expr . a:m.buffer . a:m.lhs .' '.a:m.rhs
  call s:Verbose(cmd)
  exe cmd
endfunction

"------------------------------------------------------------------------
" }}}1
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
