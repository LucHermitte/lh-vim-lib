" File:		plugin/words_tools.vim
" Author:	Luc Hermitte <hermitte {at} free {dot} fr>
" 		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/Licence.md>
" Version:      4.0.0
" Last Update:	03rd Jan 2017
" Purpose:	Define functions better than expand("<cword>")
"
" Note:		They are expected to be used in insert mode (thanks to <c-r>
"               or <c-o>)
"
" Deprecated:   Use the functions from autoload/lh/ui.vim instead
"===========================================================================

" Return the current keyword, uses spaces to delimitate {{{1
function! GetNearestKeyword()
  return lh#ui#GetNearestKeyword()
endfunction

" Return the current word, uses spaces to delimitate {{{1
function! GetNearestWord()
  return lh#ui#GetNearestWord()
endfunction

" Return the word before the cursor, uses spaces to delimitate {{{1
" Rem : <cword> is the word under or after the cursor
function! GetCurrentWord()
  return lh#ui#GetCurrentWord()
endfunction

" Return the keyword before the cursor, uses \k to delimitate {{{1
" Rem : <cword> is the word under or after the cursor
function! GetCurrentKeyword()
  return lh#ui#GetCurrentKeyword()
endfunction

" Extract the word before the cursor,  {{{1
" use keyword definitions, skip latter spaces (see "bla word_accepted ")
function! GetPreviousWord()
  return lh#ui#GetPreviousWord()
endfunction

" GetLikeCTRL_W() retrieves the characters that i_CTRL-W deletes. {{{1
" Initial need by Hari Krishna Dara <hari_vim@yahoo.com>
" Last ver:
" Pb: "if strlen(w) ==  " --> ") ==  " instead of just "==  ".
" There still exists a bug regarding the last char of a line. VIM bug ?
function! GetLikeCTRL_W()
  return lh#ui#GetLikeCTRL_W()
endfunction

" }}}1
"========================================================================
" vim60: set fdm=marker:
