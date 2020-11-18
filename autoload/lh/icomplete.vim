"=============================================================================
" File:         autoload/lh/icomplete.vim                         {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/License.md>
" Version:      4.5.0
let s:version = '4.5.0'
" Created:      03rd Jan 2011
" Last Update:  02nd Nov 2020
"------------------------------------------------------------------------
" Description:
"       Helpers functions to build |ins-completion-menu|
"
"------------------------------------------------------------------------
" Installation:
"       Drop this file into {rtp}/autoload/lh
"       Requires Vim7+
" History:
"       v4.5.0 : Reduce side effects on &complete
"       v4.0.0 : Support vim7.3
"                Stay in insert mode when there is no hook
"       v3.5.0 : Smarter completion function added
"       v3.3.10: Fix conflict with lh-brackets
"       v3.0.0 : GPLv3
"       v2.2.4 : first version
" TODO:
"       - We are not able to detect the end of the completion mode. As a
"       consequence we can't prevent c/for<space> to trigger an abbreviation
"       instead of the right template file.
"       In an ideal world, there would exist an event post |complete()|
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#icomplete#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#icomplete#verbose(...)
  if a:0 > 0
    let s:verbose = a:1
  endif
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

function! lh#icomplete#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" Function: lh#icomplete#run(startcol, matches, Hook) {{{2
function! lh#icomplete#run(startcol, matches, Hook)
  call lh#icomplete#_register_hook(a:Hook)
  call complete(a:startcol, a:matches)
  return ''
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
" Function: lh#icomplete#_clear_key_bindings() {{{2
function! lh#icomplete#_clear_key_bindings()
  iunmap <buffer> <cr>
  iunmap <buffer> <c-y>
  iunmap <buffer> <esc>
  " iunmap <space>
  " iunmap <tab>
endfunction

" Function: lh#icomplete#_restore_key_bindings() {{{2
function! lh#icomplete#_restore_key_bindings(previous_mappings)
  call s:Verbose('Restore keybindings after completion -> %1', a:previous_mappings)
  if has_key(a:previous_mappings, 'cr') && has_key(a:previous_mappings.cr, 'buffer') && a:previous_mappings.cr.buffer
    let cmd = lh#mapping#define(a:previous_mappings.cr)
  else
    iunmap <buffer> <cr>
  endif
  if has_key(a:previous_mappings, 'c_y') && has_key(a:previous_mappings.c_y, 'buffer') && a:previous_mappings.c_y.buffer
    let cmd = lh#mapping#define(a:previous_mappings.c_y)
  else
    iunmap <buffer> <c-y>
  endif
  if has_key(a:previous_mappings, 'esc') && has_key(a:previous_mappings.esc, 'buffer') && a:previous_mappings.esc.buffer
    let cmd = lh#mapping#define(a:previous_mappings.esc)
  else
    iunmap <buffer> <esc>
  endif
  " iunmap <space>
  " iunmap <tab>
endfunction

" Function: lh#icomplete#_register_hook(Hook) {{{2
function! lh#icomplete#_register_hook(Hook)
  " call s:Verbose('Register hook on completion')
  let old_keybindings = {}
  let old_keybindings.cr = maparg('<cr>', 'i', 0, 1)
  let old_keybindings.c_y = maparg('<c-y>', 'i', 0, 1)
  let old_keybindings.esc = maparg('<esc>', 'i', 0, 1)
  exe 'inoremap <buffer> <silent> <cr> <c-y><c-\><c-n>:call' .a:Hook . '()<cr>'
  exe 'inoremap <buffer> <silent> <c-y> <c-y><c-\><c-n>:call' .a:Hook . '()<cr>'
  " <c-o><Nop> doesn't work as expected...
  " To stay in INSERT-mode:
  " inoremap <silent> <esc> <c-e><c-o>:<cr>
  " To return into NORMAL-mode:
  inoremap <buffer> <silent> <esc> <c-e><esc>

  call lh#event#register_for_one_execution_at('InsertLeave',
        \ ':call lh#icomplete#_restore_key_bindings('.string(old_keybindings).')', 'CompleteGroup')
        " \ ':call lh#icomplete#_clear_key_bindings()', 'CompleteGroup')
endfunction

" Why is it triggered even before entering the completion ?
function! lh#icomplete#_register_hook2(Hook)
  " call lh#event#register_for_one_execution_at('InsertLeave',
  call lh#event#register_for_one_execution_at('CompleteDone',
        \ ':debug call'.a:Hook.'()<cr>', 'CompleteGroup')
        " \ ':call lh#icomplete#_clear_key_bindings()', 'CompleteGroup')
endfunction

" s:getSNR([func_name]) {{{2
function! s:getSNR(...)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

" s:function(func_name]) {{{2
function! s:function(funcname)
  return function(s:getSNR(a:funcname))
endfunction

"------------------------------------------------------------------------
" ## Smart completion {{{1
" Example:
" see mu-template autoload/lh/mut.vim
" TODO:
" - permit to choose between completion and omnicompletion
" - support options like:
"   - characters used to cycle
"   - autoclose preview window
"   - ...
" Function: lh#icomplete#new(startcol, matches, hook) {{{2
function! lh#icomplete#new(startcol, matches, hook) abort
  silent! unlet b:complete_data
  let augroup = 'IComplete'.bufnr('%').'Done'
  let b:complete_data = lh#on#exit()
        \.restore('&l:completefunc')
        \.restore('&l:complete')
        \.restore('&l:omnifunc')
        \.restore('&completeopt')
        \.register('au! '.augroup)
        \.register('call s:Verbose("finalized! (".getline(".").")")')
  setlocal complete=
  " TODO: actually, remove most options but preview
  set completeopt-=menu
  set completeopt-=longest
  set completeopt+=menuone
  let b:complete_data.startcol        = a:startcol
  let b:complete_data.all_matches     = map(copy(a:matches), 'type(v:val)==type({}) ? v:val : {"word": v:val}')
  let b:complete_data.matches         = {'words': [], 'refresh': 'always'}
  let b:complete_data.hook            = a:hook
  let b:complete_data.cursor_pos      = []
  let b:complete_data.last_content    = [line('.'), getline('.')]
  let b:complete_data.no_more_matches = 0
  call lh#log#clear()

  if has('patch-7.4-314')
    " Neutralize messages like "Match 1 of 7"/"Back at original"
    call b:complete_data
        \.restore('&shortmess')
    set shortmess+=c
  endif

  " Keybindings {{{3
  call b:complete_data
        \.restore_buffer_mapping('<cr>', 'i')
        \.restore_buffer_mapping('<c-y>', 'i')
        \.restore_buffer_mapping('<esc>', 'i')
        \.restore_buffer_mapping('<tab>', 'i')
        \.restore_buffer_mapping('<s-tab>', 'i')
  if empty(a:hook) " Then stay in insert mode
    inoremap <buffer> <silent> <cr>  <c-y><c-r>=b:complete_data.conclude()<cr>
    inoremap <buffer> <silent> <c-y> <c-y><c-r>=b:complete_data.conclude()<cr>
  else " Let the hook do whatever it wished
    inoremap <buffer> <silent> <cr>  <c-y><c-\><c-n>:call b:complete_data.conclude()<cr>
    inoremap <buffer> <silent> <c-y> <c-y><c-\><c-n>:call b:complete_data.conclude()<cr>
  endif
  " Unlike usual <tab> behaviour, this time, <tab> cycle through the matches
  inoremap <buffer> <silent> <tab> <down>
  inoremap <buffer> <silent> <s-tab> <up>
  " <c-o><Nop> doesn't work as expected...
  " To stay in INSERT-mode:
  " inoremap <silent> <esc> <c-e><c-o>:<cr>
  " To return into NORMAL-mode:
  inoremap <buffer> <silent> <esc> <c-e><esc>
  " TODO: see to have <Left>, <Right>, <Home>, <End> abort

  " Group {{{3
  exe 'augroup '.augroup
    au!
    " Emulate InsertCharPost
    " au CompleteDone <buffer> call b:complete_data.logger.log("Completion done")
    au InsertLeave  <buffer> call b:complete_data.finalize()
    au CursorMovedI <buffer> call b:complete_data.cursor_moved()
  augroup END

  function! s:start_completion() abort dict "{{{3
    " <c-x><c-o>: start omni completion
    " <c-p>       remove the first completion item
    " <down>      but do select the first completion item
    silent! call feedkeys( "\<C-X>\<C-O>\<C-P>\<Down>", 'n' )
  endfunction
  let b:complete_data.start_completion = s:function('start_completion')

  function! s:cursor_moved() abort dict "{{{3
    if self.no_more_matches
      call self.finalize()
      return
    endif
    if !self.has_text_changed_since_last_move()
      call s:Verbose("cursor %1 just moved (text hasn't changed)", string(getpos('.')))
      return
    endif
    call s:Verbose('cursor moved %1 and text has changed -> relaunch completion', string(getpos('.')))
    call self.start_completion()
  endfunction
  let b:complete_data.cursor_moved = s:function('cursor_moved')

  function! s:has_text_changed_since_last_move() abort dict "{{{3
    let l = line('.')
    let line = getline('.')
    try
      if l != self.last_content[0]  " moved vertically
        let self.no_more_matches = 1
        call s:Verbose("Vertical move => stop")
        return 0
        " We shall leave complete mode now!
      endif
      call s:Verbose("line was: %1, and becomes: %2; has_changed?%3", self.last_content[1], line, line != self.last_content[1])
      return line != self.last_content[1] " text changed
    finally
      let self.last_content = [l, line]
    endtry
  endfunction
  let b:complete_data.has_text_changed_since_last_move = s:function('has_text_changed_since_last_move')

  function! s:complete(findstart, base) abort dict "{{{3
    call s:Verbose('findstart?%1 -> %2', a:findstart, a:base)
    if a:findstart
      if self.no_more_matches
        call s:Verbose("no more matches -> -3")
        return -3
        call self.finalize()
      endif
      if self.cursor_pos == lh#position#getcur()
        call s:Verbose("cursor hasn't moved -> -2")
        return -2
      endif
      let self.cursor_pos = lh#position#getcur()
      return self.startcol
    else
      return self.get_completions(a:base)
    endif
  endfunction
  let b:complete_data.complete = s:function('complete')

  function! s:get_completions(base) abort dict "{{{3
    let matching = filter(copy(self.all_matches), 'v:val.word =~ join(split(a:base, ".\\zs"), ".*")')
    let self.matches.words = matching
    call s:Verbose("'%1' matches: %2", a:base, string(self.matches))
    if empty(self.matches.words)
      call s:Verbose("No more matches...")
      let self.no_more_matches = 1
    endif
    return self.matches
  endfunction
  let b:complete_data.get_completions = s:function('get_completions')

  function! s:conclude() abort dict " {{{3
    let selection = getline('.')[self.startcol : col('.')-1]
    call s:Verbose("Successful selection of <".selection.">")
    try
      if !empty(self.hook)
        return lh#function#execute(self.hook, selection)
      endif
      return ''
    finally
      call self.finalize()
    endtry
  endfunction
  let b:complete_data.conclude = s:function('conclude')

  " Register {{{3
  " call b:complete_data
        " \.restore('b:complete_data')
  " setlocal completefunc=lh#icomplete#func
  setlocal omnifunc=lh#icomplete#func

  " Return {{{3
  return b:complete_data
endfunction "}}}4

" Function: lh#icomplete#new_on(pattern, matches, hook) {{{2
function! lh#icomplete#new_on(pattern, matches, hook) abort
  let l = getline('.')
  let startcol = match(l[0:col('.')-1], '\v'.a:pattern.'+$')
  if startcol == -1
    let startcol = col('.')-1
  endif
  return lh#icomplete#new(startcol, a:matches, a:hook)
endfunction

" Function: lh#icomplete#func(startcol, base) {{{2
function! lh#icomplete#func(findstart, base) abort
  return b:complete_data.complete(a:findstart, a:base)
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
