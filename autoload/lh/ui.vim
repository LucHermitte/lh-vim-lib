"=============================================================================
" File:         autoload/lh/ui.vim                                {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0.0.
let s:k_version = '4000'
" Created:      03rd Jan 2017
" Last Update:  03rd Jan 2017
"------------------------------------------------------------------------
" Description:
"       Defines helper functions to interact with end user.
"
"------------------------------------------------------------------------
" History:
" v4.0.0: Factorization of plugins word_tools and ui-functions
" TODO:         «missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#ui#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#ui#verbose(...)
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

function! lh#ui#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" # Read word around cursor {{{2
" Return the current keyword, uses spaces to delimitate {{{3
function! lh#ui#GetNearestKeyword()
  let c = col ('.')-1
  let ll = getline('.')
  let ll1 = strpart(ll,0,c)
  let ll1 = matchstr(ll1,'\k*$')
  let ll2 = strpart(ll,c,strlen(ll)-c+1)
  let ll2 = matchstr(ll2,'^\k*')
  " let ll2 = strpart(ll2,0,match(ll2,'$\|\s'))
  return ll1.ll2
endfunction

" Return the current word, uses spaces to delimitate {{{3
function! lh#ui#GetNearestWord()
  let c = col ('.')-1
  let l = line('.')
  let ll = getline(l)
  let ll1 = strpart(ll,0,c)
  let ll1 = matchstr(ll1,'\S*$')
  let ll2 = strpart(ll,c,strlen(ll)-c+1)
  let ll2 = strpart(ll2,0,match(ll2,'$\|\s'))
  ""echo ll1.ll2
  return ll1.ll2
endfunction

" Return the word before the cursor, uses spaces to delimitate {{{3
" Rem : <cword> is the word under or after the cursor
function! lh#ui#GetCurrentWord()
  let c = col ('.')-1
  let l = line('.')
  let ll = getline(l)
  let ll1 = strpart(ll,0,c)
  let ll1 = matchstr(ll1,'\S*$')
  if strlen(ll1) == 0
    return ll1
  else
    let ll2 = strpart(ll,c,strlen(ll)-c+1)
    let ll2 = strpart(ll2,0,match(ll2,'$\|\s'))
    return ll1.ll2
  endif
endfunction

" Return the keyword before the cursor, uses \k to delimitate {{{3
" Rem : <cword> is the word under or after the cursor
function! lh#ui#GetCurrentKeyword()
  let c = col ('.')-1
  let l = line('.')
  let ll = getline(l)
  let ll1 = strpart(ll,0,c)
  let ll1 = matchstr(ll1,'\k*$')
  if strlen(ll1) == 0
    return ll1
  else
    let ll2 = strpart(ll,c,strlen(ll)-c+1)
    let ll2 = matchstr(ll2,'^\k*')
    " let ll2 = strpart(ll2,0,match(ll2,'$\|\s'))
    return ll1.ll2
  endif
endfunction

" Extract the word before the cursor,  {{{3
" use keyword definitions, skip latter spaces (see "bla word_accepted ")
function! lh#ui#GetPreviousWord()
  let lig = getline(line('.'))
  let lig = strpart(lig,0,col('.')-1)
  return matchstr(lig, '\<\k*\>\s*$')
endfunction

" lh#ui#GetLikeCTRL_W() retrieves the characters that i_CTRL-W deletes. {{{3
" Initial need by Hari Krishna Dara <hari_vim@yahoo.com>
" Last ver:
" Pb: "if strlen(w) ==  " --> ") ==  " instead of just "==  ".
" There still exists a bug regarding the last char of a line. VIM bug ?
function! lh#ui#GetLikeCTRL_W()
  let lig = getline(line('.'))
  let lig = strpart(lig,0,col('.')-1)
  " treat ending spaces apart.
  let s = matchstr(lig, '\s*$')
  let lig = strpart(lig, 0, strlen(lig)-strlen(s))
  " First case : last characters belong to a "word"
  let w = matchstr(lig, '\<\k\+\>$')
  if strlen(w) == 0
    " otherwise, they belong to a "non word" (without any space)
    let w = substitute(lig, '.*\(\k\|\s\)', '', 'g')
  endif
  return w . s
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
