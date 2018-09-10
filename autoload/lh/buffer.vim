"=============================================================================
" File:		autoload/lh/buffer.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Licence:      GPLv3
" Version:	4.6.3
let s:k_version = '40603'
" Created:	23rd Jan 2007
" Last Update:	10th Sep 2018
"------------------------------------------------------------------------
" Description:
" 	Defines functions that help finding windows and handling buffers.
"
"------------------------------------------------------------------------
" History: {{{2
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
"       v3.2.14
"       (*) lh#buffer#scratch() resists to filenames with "*", "#", or "%" within
"       v3.3.8
"       (*) All :split goes through lh#window#create_window_with() is order to
"       workaround E36
"       v3.6.1
"       (*) ENH: Use new logging framework
"       v3.9.0
"       (*) ENH: lh#buffer#scratch() returns its bufnr()
"       v3.10.3
"       (*) BUG: Work around a vim bug with winbufnr() within event context
"       v4.0.0
"       (*) BUG: Fix `lh#buffer#find()` when using relative pathnames.
" }}}1
"=============================================================================


"=============================================================================
let s:cpo_save=&cpo
set cpo&vim

"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#buffer#version()
  return s:k_version
endfunction

" # Debug {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#buffer#verbose(...)
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

function! lh#buffer#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## Public {{{1

" Function: lh#buffer#find({filename}) {{{2
" If {filename} is opened in a window, jump to this window, otherwise return -1
" Moved from searchInRuntimeTime.vim
function! lh#buffer#find(filename) abort
  let b = bufwinnr(a:filename)
  " Workaround a bug in event execution: we may a have a non null buffer, but
  " with a name that doesn't match what is looked for.
  " -> "|| bufname(winbufnr(b)) != a:filename"
  " The second case is used when the filename is actually a buffer name
  if b == -1 || (fnamemodify(bufname(winbufnr(b)), ':p') != fnamemodify(a:filename, ':p') && winbufnr(b) != a:filename)
    return -1
  endif
  exe b.'wincmd w'
  return b
endfunction
function! lh#buffer#Find(filename) abort
  return lh#buffer#find(a:filename)
endfunction

" Function: lh#buffer#jump({filename},{cmd}) {{{2
function! lh#buffer#jump(filename, cmd) abort
  let b = lh#buffer#find(a:filename)
  if b != -1 || type(a:filename) == type(0) | return b | endif
  try
    call lh#window#create_window_with(a:cmd . ' ' . a:filename)
  catch /E325/
    " The file opened had a swap file...
    if bufwinnr(a:filename) != winnr()
      " but instead of chosing to open it, the user refused
      " => rethrow the error
      throw "A swap file was associated to ".a:filename.", but you rejected opening the file (".v:exception.")."
      " It seems that "abort" case cannot be recognized
    endif
  endtry
  return winnr()
endfunction
function! lh#buffer#Jump(filename, cmd) abort
  return lh#buffer#jump(a:filename, a:cmd)
endfunction

" Function: lh#buffer#scratch({bname},{where}) {{{2
function! lh#buffer#scratch(bname, where) abort
  try
    set modifiable
    call lh#window#create_window_with(a:where.' sp '.fnameescape(substitute(a:bname, '\*', '...', 'g')))
  catch /.*/
    throw "Can't open a buffer named '".a:bname."'!"
  endtry
  setlocal bt=nofile bh=wipe nobl noswf ro
  return bufnr('%')
endfunction
function! lh#buffer#Scratch(bname, where) abort
  return lh#buffer#scratch(a:bname, a:where)
endfunction

" Function: lh#buffer#get_nr({bname}) {{{2
" Returns the buffer number associated to a buffername/filename.
" If no such file is known to vim, a buffer will be locally created
" This function is required to assign a new buffer number to be used in qflist,
" after the filenames have been fixed -- see BTW's s:FixCTestOutput().
"
" Bug: this function clears syntax highlighting in some buffers if we :sp when
" bufname() != a:bname
function! lh#buffer#get_nr(bname) abort
  let nr = bufnr(a:bname)
  " nr may not always be -1 as it should => also test bname()
  if -1 == nr  || bufname(nr) != a:bname
    call lh#window#create_window_with('silent sp '.fnameescape(a:bname))
    let nr = bufnr(a:bname)
    q
  endif
  return nr
endfunction

" Function: lh#buffer#list() {{{2
function! lh#buffer#list(...) abort
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

" ## Private {{{1
" Function: lh#buffer#_loaded_buf_do(args) {{{2
function! lh#buffer#_loaded_buf_do(args) abort
  let buffers = lh#buffer#list('bufloaded')
  for b in buffers
    exe 'b '.b
    exe a:args
  endfor
endfunction

" Function: lh#buffer#_clean_empty_buffers() {{{2
function! lh#buffer#_clean_empty_buffers()
  let buffers = lh#list#copy_if(range(0, bufnr('$')), [], 'buflisted(v:1_) && empty(bufname(v:1_)) && bufwinnr(v:1_)<0')
  if !empty(buffers)
    exe 'bw '.join(buffers, ' ')
  endif
endfunction

"}}}1
"=============================================================================
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
