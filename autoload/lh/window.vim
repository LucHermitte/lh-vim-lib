"=============================================================================
" File:         autoload/lh/window.vim                            {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      4.7.0.
let s:k_version = '40700'
" Created:      29th Oct 2015
" Last Update:  15th Nov 2019
"------------------------------------------------------------------------
" Description:
" 	Defines functions that help finding handling windows.
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version          {{{2
function! lh#window#version()
  return s:k_version
endfunction

" # Debug            {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#window#verbose(...)
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

function! lh#window#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" # Window Splitting {{{2
" Function: lh#window#create_window_with(cmd) {{{3
" Since a few versions, vim throws a lot of E36 errors around:
" everythime we try to split from a windows where its height equals &winheight
" (the minimum height)
function! lh#window#create_window_with(cmd) abort
  try
    exe a:cmd
  catch /E36:/
    " Try again after an increase of the current window height
    resize +1
    exe a:cmd
  endtry
endfunction

" Function: lh#window#split(bufname) {{{3
function! lh#window#split(...) abort
  call call('lh#window#create_window_with',[join(['split']+a:000, ' ')])
endfunction

" Function: lh#window#new(bufname) {{{3
function! lh#window#new(bufname) abort
  call call('lh#window#create_window_with',[join(['new']+a:000, ' ')])
endfunction

" # Window Id        {{{2
" Function: lh#window#getid() {{{3
" @since version 3.9.0
let s:has_win_getid = exists('*win_getid')
if s:has_win_getid
  function! lh#window#getid(...) abort
    return call('win_getid', a:000)
  endfunction
else
  let s:does_getwinvar_support_default = lh#askvim#is_valid_call('getwinvar(1, "shouldnotexist", -1)')
  " Emulated version, the id will be attributed on-the-fly
  " TODO: accept a tab parameter
  let s:last_id = get(s:, 'last_id', 0)
  " TODO: check patch-number!
  if s:does_getwinvar_support_default
    function! lh#window#getid(...) abort
      let nr = a:0 == 1 ? a:1 : winnr()
      let id = getwinvar(nr, 'id', lh#option#unset())
      if lh#option#is_unset(id)
        let s:last_id += 1
        call setwinvar(nr, 'id', s:last_id)
        return s:last_id
      endif
      return id
    endfunction
  else
    function! lh#window#getid(...) abort
      let nr = a:0 == 1 ? a:1 : winnr()
      let id = getwinvar(nr, 'id')
      if empty(id)
        let s:last_id += 1
        call setwinvar(nr, 'id', s:last_id)
        return s:last_id
      endif
      return id
    endfunction
  endif
endif

" Function: lh#window#gotoid(id) {{{3
" @since version 3.9.0
if s:has_win_getid
  function! lh#window#gotoid(id) abort
    call win_gotoid(a:id)
  endfunction
else
  " Emulated version, id will be searched in all windows in all tabs
  function! lh#window#gotoid(id) abort
    for tabnr in range(1, tabpagenr('$'))
      for winnr in range(1, tabpagewinnr(tabnr, '$'))
        if gettabwinvar(tabnr, winnr, 'id') == a:id
          exe 'tabnext '.tabnr
          exe winnr.'wincmd w'
          return [tabnr, winnr]
        endif
      endfor
    endfor
    throw "No window found of id ".a:id
  endfunction
endif

" Function: lh#window#text_width(...) {{{3
" @return the actual width available to display text in the current window:
"    -> winwidth() - &foldcolumn - (&signcolumn * 2)
" @since Version 4.7.0
function! lh#window#text_width(...) abort
  let winnr = get(a:, 1, 0)
  return winwidth(winnr)
        \ - getwinvar(winnr, '&foldcolumn')
        \ - (getwinvar(winnr, '&signcolumn') != 'no' ? 2 : 0)
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
