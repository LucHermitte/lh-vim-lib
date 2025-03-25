"=============================================================================
" File:         autoload/lh/notify.vim                            {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      5.5.0
let s:k_version = '550'
" Created:      24th Jul 2017
" Last Update:  25th Mar 2025
"------------------------------------------------------------------------
" Description:
"       API to notify things once
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
function! lh#notify#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#notify#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Log(expr, ...)
  call call('lh#log#this',[a:expr]+a:000)
endfunction

function! s:Verbose(expr, ...)
  if s:verbose
    call call('s:Log',[a:expr]+a:000)
  endif
endfunction

function! lh#notify#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

" Function: lh#notify#clear_notifications() {{{2
function! lh#notify#clear_notifications() abort
  let s:notifications = {}
endfunction
call lh#notify#clear_notifications()

" Function: lh#notify#once(id [, text]) {{{2
function! lh#notify#once(id, ...) abort
  let result = get(s:notifications, a:id, 0)
  if ! result
    let msg = a:0 > 0 ? call('lh#fmt#printf', a:000) : a:id
    call s:Verbose('%1', msg)
    call lh#common#warning_msg(msg)
    let s:notifications[a:id] = 1
  endif
  return result
endfunction

" Function: lh#notify#deprecated(old, new) {{{2
function! lh#notify#deprecated(old, new) abort
  " TODO: add feature to know where the call has been made
  call lh#notify#once(a:old, 'Warning %1 is deprecated, use %2 now.', a:old, a:new)
endfunction

" Function: lh#notify#error(message, exception, throwpoint) {{{3
function! s:callback(choice) abort
  if a:choice == 'q' || a:choice == 2
    let s:bt_qf = lh#exception#decode(s:last_error.throwpoint).as_qf('')
    let s:bt_qf[0].text = substitute(s:bt_qf[0].text, '\.\.\.', s:last_error.exception, '')
    call setqflist(s:bt_qf)
    if exists(':Copen')
      Copen
    else
      copen
    endif
  elseif a:choice == 'q' || a:choice == 3
    let error = printf("%s: %s\n%s", s:last_error.message, s:last_error.exception, s:last_error.throwpoint)
    call lh#common#warning_msg(error)
  endif
endfunction

function! lh#notify#error(message, exception, throwpoint) abort
  let s:last_error = {'exception': a:exception, 'throwpoint': a:throwpoint, 'message': a:message}

  call lh#ui#confirm_callback(
        \ a:message,
        \ ['&Ignore', 'Send to &quickfix', '&Trace'], #{
        \   callback: { choice -> s:callback(choice) },
        \   ui_type: exists('*popup_menu') ? 'popup' : 'text',
        \ })
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
