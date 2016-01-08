"=============================================================================
" File:		autoload/lh/syntax.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:	3.6.1
let s:k_version = 361
" Created:	05th Sep 2007
" Last Update:	08th Jan 2016
"------------------------------------------------------------------------
" Description:	«description»
"
"------------------------------------------------------------------------
" TODO:
" 	function, to inject "contained", see lhVimSpell approach
" }}}1
"=============================================================================


"=============================================================================
let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#syntax#version()
  return s:k_version
endfunction

" # Debug {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#syntax#verbose(...)
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

function! lh#syntax#debug(expr) abort
  return eval(a:expr)
endfunction


"=============================================================================
" ## Functions {{{1
" # Public {{{2
" Functions: Show name of the syntax kind of a character {{{3
function! lh#syntax#name_at(l,c, ...)
  let what = a:0 > 0 ? a:1 : 0
  return synIDattr(synID(a:l, a:c, what),'name')
endfunction
function! lh#syntax#NameAt(l,c, ...)
  let what = a:0 > 0 ? a:1 : 0
  return lh#syntax#name_at(a:l, a:c, what)
endfunction

function! lh#syntax#name_at_mark(mark, ...)
  let what = a:0 > 0 ? a:1 : 0
  return lh#syntax#name_at(line(a:mark), col(a:mark), what)
endfunction
function! lh#syntax#NameAtMark(mark, ...)
  let what = a:0 > 0 ? a:1 : 0
  return lh#syntax#name_at_mark(a:mark, what)
endfunction

" Functions: skip string, comment, character, doxygen {{{3
func! lh#syntax#skip_at(l,c)
  return lh#syntax#name_at(a:l,a:c) =~? 'string\|comment\|character\|doxygen'
endfun
func! lh#syntax#SkipAt(l,c)
  return lh#syntax#skip_at(a:l,a:c)
endfun

func! lh#syntax#skip()
  return lh#syntax#skip_at(line('.'), col('.'))
endfun
func! lh#syntax#Skip()
  return lh#syntax#skip()
endfun

func! lh#syntax#skip_at_mark(mark)
  return lh#syntax#skip_at(line(a:mark), col(a:mark))
endfun
func! lh#syntax#SkipAtMark(mark)
  return lh#syntax#skip_at_mark(a:mark)
endfun

" Command: :SynShow Show current syntax kind                      {{{3
command! SynShow echo 'hi<'.lh#syntax#name_at_mark('.',1).'> trans<'
      \ lh#syntax#name_at_mark('.',0).'> lo<'.
      \ synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name').'>   ## '
      \ lh#list#transform(synstack(line("."), col(".")), [], 'synIDattr(v:1_, "name")')


" Function: lh#syntax#list_raw(name) : string                     {{{3
function! lh#syntax#list_raw(name)
  let a_save = @a
  try
    redir @a
    exe 'silent! syn list '.a:name
    redir END
    let res = @a
  finally
    let @a = a_save
  endtry
  return res
endfunction

" Function: lh#syntax#list(name) : List                           {{{3
function! lh#syntax#list(name)
  let raw = lh#syntax#list_raw(a:name)
  let res = []
  let lines = split(raw, '\n')
  let started = 0
  for l in lines
    if started
      let li = (l =~ 'links to') ? '' : l
    elseif l =~ 'xxx'
      let li = matchstr(l, 'xxx\s*\zs.*')
      let started = 1
    else
      let li = ''
    endif
    if strlen(li) != 0
      let li = substitute(li, 'contained\S*\|transparent\|nextgroup\|skipwhite\|skipnl\|skipempty', '', 'g')
      let kinds = split(li, '\s\+')
      call extend(res, kinds)
    endif
  endfor
  return res
endfunction

" Function: lh#syntax#is_a_comment(mark) : bool                   {{{3
function! lh#syntax#is_a_comment(mark) abort
  return lh#syntax#is_a_comment_at(line(a:mark), col(a:mark))
endfunction


" Function: lh#syntax#is_a_comment_at(l,c) : bool                  {{{3
function! lh#syntax#is_a_comment_at(l,c) abort
  try
    let stack = synstack(a:l, a:c)
    for syn in stack
      if synIDattr(syn, 'name') =~? 'comment\|doxygen'
        return 1
      endif
    endfor
  catch /.*/
    throw "Cannot fetch synstack at line:".a:l.", col:".a:c
  endtry
  return 0
endfunction


" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
