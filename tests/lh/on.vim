"=============================================================================
" File:         tests/lh/on.vim                                   {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0
let s:k_version = '400'
" Created:      23rd Dec 2015
" Last Update:  20th Jan 2017
"------------------------------------------------------------------------
" Description:
"       UT for lh#on#exit()
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

UTSuite [lh-vim-lib] Testing lh/on.vim

runtime autoload/lh/on.vim
runtime autoload/lh/log.vim
runtime autoload/lh/exception.vim

let s:cpo_save=&cpo
set cpo&vim

"------------------------------------------------------------------------
" Non throwing finalization {{{2
" TODO: test
" - &isk
" - &l:isk
" - b:foobar
" - (gb):foobar
" Function: s:Test_restore() {{{3
function! s:Test_restore()
  silent! unlet g:foobar
  let cleanup = lh#on#exit()
        \.restore('g:foobar')
  let g:foobar = 1
  Assert exists('g:foobar')
  call cleanup.finalize()
  Assert !exists('g:foobar')
endfunction

"------------------------------------------------------------------------
" Function: s:Test_restore_dict() {{{3
function! s:Test_restore_dict()
  let l:foobar = {'a': 1}
  let cleanup = lh#on#exit()
        \.restore(l:foobar, 'a')
        \.restore(l:foobar, 'b')
  let l:foobar.a = 5
  let l:foobar.b = 6
  let l:foobar.c = 42
  Assert exists('l:foobar')
  call cleanup.finalize()
  AssertEquals(l:foobar.a, 1)
  Assert !has_key(l:foobar, 'b')
  AssertEquals(l:foobar.c, 42)
endfunction

"------------------------------------------------------------------------
" Function: s:Test_restore_buffer_option_was_none() {{{3
function! s:Test_restore_buffer_option_was_none() abort
  " Test when there is no mapping
  silent! iunmap <buffer> <esc>
  silent! iunmap <esc>
  Assert empty(mapcheck('<esc>', 'i'))
  let cleanup = lh#on#exit()
        \.restore_buffer_mapping('<esc>', 'i')
  inoremap <buffer> <esc>  <esc>:echo "toto"<cr>
  Assert !empty(mapcheck('<esc>', 'i'))
  call cleanup.finalize()
  Assert empty(mapcheck('<esc>', 'i'))
endfunction

"------------------------------------------------------------------------
" Function: s:Test_restore_buffer_option_was_global() {{{3
function! s:Test_restore_buffer_option_was_global() abort
  " Test where there was a global mapping
  silent! iunmap <buffer> <esc>
  inoremap <esc>  <esc>:echo "toto"<cr>
  let old = maparg('<esc>', 'i')
  Assert !empty(old)
  let cleanup = lh#on#exit()
        \.restore_buffer_mapping('<esc>', 'i')
  inoremap <buffer> <esc>  <esc>:echo "tutu"<cr>
  Assert !empty(mapcheck('<esc>', 'i'))
  AssertDiffer(old, maparg('<esc>', 'i'))
  call cleanup.finalize()
  AssertEqual(old, maparg('<esc>', 'i'))
endfunction

"------------------------------------------------------------------------
" Function: s:Test_restore_buffer_option_was_buffer() {{{3
function! s:Test_restore_buffer_option_was_buffer() abort
  " Test where there was a buffer mapping
  silent! iunmap <esc>
  inoremap <buffer> <esc>  <esc>:echo "toto"<cr>
  let old = maparg('<esc>', 'i')
  Assert !empty(old)
  let cleanup = lh#on#exit()
        \.restore_buffer_mapping('<esc>', 'i')
  inoremap <buffer> <esc>  <esc>:echo "tutu"<cr>
  Assert !empty(mapcheck('<esc>', 'i'))
  AssertDiffer(old, maparg('<esc>', 'i'))
  call cleanup.finalize()
  AssertEqual(old, maparg('<esc>', 'i'))

  " Test where there was a global mapping
  " Test where there was a buffer mapping
endfunction

"------------------------------------------------------------------------
" Throwing finalization {{{2
" Likelly to fail with vimrunner
" Function: s:Test_throw_finalize() {{{3
function! s:Test_throw_finalize_msg() abort
  if 0 && !exists('*VimrunnerEvaluateCommandOutput')
    silent! unlet g:foobar
    let cleanup = lh#on#exit()
          \.register('throw "Error"')
          \.restore('g:foobar')
    let g:foobar = 1
    call lh#log#set_logger('none')
    call cleanup.finalize()
    Assert !exists('g:foobar')
  endif
endfunction

function! s:Test_throw_finalize() abort
  if 0 && !exists('*VimrunnerEvaluateCommandOutput')
    silent! unlet g:foobar
    let cleanup = lh#on#exit()
          \.register('throw "Error"')
          \.restore('g:foobar')
    let g:foobar = 1
    call lh#log#set_logger('qf', 'vert')
    call cleanup.finalize()
    let msgs = getqflist()
    AssertEquals(msgs[0].text, 'Error')
    AssertMatches(bufname(msgs[0].bufnr), 'autoload/lh/on.vim')
    Assert !exists('g:foobar')
  endif
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
