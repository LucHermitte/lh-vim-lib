"=============================================================================
" $Id$
" File:		autoload/lh/buffer.vim                               {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" Licence:      GPLv3
" Version:	3.1.15
" Created:	23rd Jan 2007
" Last Update:	$Date$
"------------------------------------------------------------------------
" Description:	
" 	Defines functions that help finding windows and handling buffers.
" 
"------------------------------------------------------------------------
" Installation:	
" 	Drop it into {rtp}/autoload/lh/
" 	Vim 7+ required.
" History:	
"	v1.0.0 First Version
" 	(*) Functions moved from searchInRuntimeTime  
" 	v2.2.0
" 	(*) new function: lh#buffer#list()
"       v3.0.0 GPLv3
"       v3.1.4
"       (*) new function: lh#buffer#get_nr()
"       v3.1.6
"       (*) lh#buffer#list(): new argument to specifies how to filter buffers
"       (*) new function: lh#buffer#_loaded_buf_do() for :LoadedBufDo
"       v3.1.10
"       (*) lh#buffer#jump() returns the number of the window opened.
"       v3.1.12
"       (*) new function lh#buffer#_clean_empty_buffers() for :CleanEmptyBuffers
"       v3.1.15
"       (*) Bug fix in lh#buffer#get_nr() that does not need to reopen the
"           buffer every time
" }}}1
"=============================================================================


"=============================================================================
let s:cpo_save=&cpo
set cpo&vim

" ## Functions {{{1
"------------------------------------------------------------------------
" # Debug {{{2
function! lh#buffer#verbose(level)
  let s:verbose = a:level
endfunction

function! s:Verbose(expr)
  if exists('s:verbose') && s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#buffer#debug(expr)
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" # Public {{{2

" Function: lh#buffer#find({filename}) {{{3
" If {filename} is opened in a window, jump to this window, otherwise return -1
" Moved from searchInRuntimeTime.vim
function! lh#buffer#find(filename)
  let b = bufwinnr(a:filename)
  if b == -1 | return b | endif
  exe b.'wincmd w'
  return b
endfunction
function! lh#buffer#Find(filename)
  return lh#buffer#find(a:filename)
endfunction

" Function: lh#buffer#jump({filename},{cmd}) {{{3
function! lh#buffer#jump(filename, cmd)
  let b = lh#buffer#find(a:filename)
  if b != -1 | return b | endif
  exe a:cmd . ' ' . a:filename
  return winnr()
endfunction
function! lh#buffer#Jump(filename, cmd)
  return lh#buffer#jump(a:filename, a:cmd)
endfunction

" Function: lh#buffer#scratch({bname},{where}) {{{3
function! lh#buffer#scratch(bname, where)
  try
    set modifiable
    silent exe a:where.' sp '.a:bname
  catch /.*/
    throw "Can't open a buffer named '".a:bname."'!"
  endtry
  setlocal bt=nofile bh=wipe nobl noswf ro
endfunction
function! lh#buffer#Scratch(bname, where)
  return lh#buffer#scratch(a:bname, a:where)
endfunction

" Function: lh#buffer#get_nr({bname}) {{{3
" Returns the buffer number associated to a buffername/filename.
" If no such file is known to vim, a buffer will be locally created
" This function is required to assign a new buffer number to be used in qflist,
" after the filenames have been fixed -- see BTW's s:FixCTestOutput().
"
" Bug: this function clears syntax highlighting in some buffers if we :sp when
" bufname() != a:bname
function! lh#buffer#get_nr(bname)
  let nr = bufnr(a:bname)
  " nr may not always be -1 as it should => also test bname()
  if -1 == nr " || bufname(nr) != a:bname
    exe 'sp '.fnameescape(a:bname)
    let nr = bufnr(a:bname)
    q
  endif
  return nr
endfunction

" Function: lh#buffer#list() {{{3
function! lh#buffer#list(...)
  let which = a:0 == 0 ? 'buflisted' : a:1 
  let all = range(1, bufnr('$'))
  " let res = lh#list#transform_if(all, [], 'v:1_', 'buflisted')
  let res = lh#list#copy_if(all, [], which)
  return res
endfunction
" Ex: Names of the buffers listed
"  -> echo lh#list#transform(lh#buffer#list(), [], "bufname")
" Ex: wipeout empty buffers listed
"  -> echo 'bw'.join(lh#list#copy_if(range(0, bufnr('$')), [], 'buflisted(v:1_) && empty(bufname(v:1_))'), ' ')

" # Private {{{2
" Function: lh#buffer#_loaded_buf_do(args) {{{3
function! lh#buffer#_loaded_buf_do(args)
  let buffers = lh#buffer#list('bufloaded')
  for b in buffers
    exe 'b '.b
    exe a:args
  endfor
endfunction

" Function: lh#buffer#_clean_empty_buffers() {{{3
function! lh#buffer#_clean_empty_buffers()
  let buffers = lh#list#copy_if(range(0, bufnr('$')), [], 'buflisted(v:1_) && empty(bufname(v:1_)) && bufwinnr(v:1_)<0')
  if !empty(buffers)
    exe 'bw '.join(buffers, ' ')
  endif
endfunction

"=============================================================================
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
