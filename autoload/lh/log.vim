"=============================================================================
" File:         autoload/lh/log.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.00.0.
" let s:k_version = '4000'
let s:k_version = '4000'
" Created:      23rd Dec 2015
" Last Update:  25th May 2018
"------------------------------------------------------------------------
" Description:
"       Logging facilities
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
function! lh#log#version()
  return s:k_version
endfunction

" # Debug   {{{2
if !exists('s:verbose')
  let s:verbose = 0
endif
function! lh#log#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr) abort
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#log#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

" # Create new log object {{{2

" Function: lh#log#new(where, kind) {{{3
" DOC: {{{4
" - where: "vert"/""/filename
" - kind:  "qf" / "loc" for loclist / "file"
" NOTE: In order to obtain the name of the calling function, an exception is
" thrown and the backtrace is analysed.
" In order to work, this trick requires:
" - a reasonable callstack size (past a point, vim shortens the names returned
"   by v:throwpoint
" - named functions ; i.e. functions defined on dictionaries (and not attached
"   to them) will have their names mangled (actually it'll be a number) and
"   lh#exception#callstack() won't be able to decode them.
"   i.e.
"      function s:foo() dict abort
"         logger.log("here I am");
"      endfunction
"      let dict.foo = s:function('foo')
"   will work correctly fill the quicklist/loclist, but
"      function dict.foo() abort
"         logger.log("here I am");
"      endfunction
"   won't
" TODO: add verbose levels
" }}}4
function! lh#log#new(where, kind) abort
  let log = lh#object#make_top_type({ 'winnr': bufwinnr('%'), 'kind': a:kind, 'where': a:where, 'lines':[]})

  " open loc/qf window {{{4
  function! s:open() abort dict
    try
      let buf = bufnr('%')
      exe 'silent! '.(self.where). ' '.(self.kind == 'loc' ? 'l' : 'c').'open'
    finally
      call lh#buffer#find(buf)
    endtry
  endfunction

  " add {{{4
  function! s:add_loc(msg) abort dict
    call setloclist(self.winnr, [a:msg], 'a')
  endfunction
  function! s:add_qf(msg) abort dict
    call setqflist([a:msg], 'a')
  endfunction
  if has('patch-7.4-503')
    function! s:add_file(msg) abort dict
      call writefile([lh#fmt#printf("%1:%2: %3", get(a:msg,'filename', ''), get(a:msg,'lnum', ''), a:msg.text)], self.where, 'a')
    endfunction
  else
    function! s:add_file(msg) abort dict
      let self.lines += [lh#fmt#printf("%1:%2: %3", get(a:msg,'filename', ''), get(a:msg,'lnum', ''), a:msg.text)]
      call writefile(self.lines, self.where)
    endfunction
  endif

  " clear {{{4
  function! s:clear_loc() abort dict
    call setloclist(self.winnr, [])
    lclose
  endfunction
  function! s:clear_qf() abort dict
    call setqflist([])
    cclose
  endfunction
  function! s:clear_file() abort dict
    call writefile([], self.where)
  endfunction

  " log {{{4
  function! s:log(msg) abort dict
    let data = { 'text': a:msg }
    try
      throw "dummy"
    catch /.*/
      let bt = lh#exception#callstack(v:throwpoint)
      " Find the right level.
      " 0 is the current function
      " And every other level named s:log or s:verbose or callstack shall be ignored as
      " well.
      let idx = lh#list#find_if(bt, 'v:val.fname !~? "\\vlog|verbose|callstack"', 1)
      if idx > 0
        let data.filename = bt[idx].script
        let data.lnum     = bt[idx].pos
      endif
    endtry
    call self._add(data)
  endfunction

  " log_trace {{{4
  function! s:log_trace(msg) abort dict
    call self._add(a:msg)
  endfunction

  " reset {{{4
  function! s:reset() dict abort
    call self.clear()
    call self.open()
    return self
  endfunction

  " register methods {{{4
  let log.open      = s:function('open')
  let log._add      = s:function('add_'.a:kind)
  let log.clear     = s:function('clear_'.a:kind)
  let log.log       = s:function('log')
  let log.log_trace = s:function('log_trace')
  let log.reset     = s:function('reset')

  " open the window {{{4
  call log.reset()
  return log
endfunction

" Function: lh#log#none() {{{3
" @return a log object that does nothing
function! lh#log#none() abort
  let log = lh#object#make_top_type({'kind': '(none)'})
  function! log.log(...) dict
  endfunction
  function! log.reset() dict
    return self
  endfunction
  return log
endfunction
"------------------------------------------------------------------------
" Function: lh#log#echomsg() {{{3
" @return a log object that prints errors with ":echomsg"
function! lh#log#echomsg() abort
  let log = lh#object#make_top_type({'kind': '(echomsg)'})
  function! log.log(msg) dict
    let msg = type(a:msg) == type([]) || type(a:msg) == type({})
          \ ?  lh#object#to_string(a:msg)
          \ : a:msg
    echomsg msg
  endfunction
  function! log.reset() dict
    return self
  endfunction
  return log
endfunction
"------------------------------------------------------------------------
" # Global logger {{{2
" Function: lh#log#set_logger(kind) {{{3
" Supported kinds:
" - "none": traces are dumped
" - "echomsg": default
" - "qf" / "loc" (quickfix/loclist)
function! lh#log#set_logger(kind, ...) abort
  if a:kind ==? "none"
    let s:logger = lh#log#none()
  elseif a:kind ==? "echomsg"
    let s:logger = lh#log#echomsg()
  elseif a:kind =~? '\vqf|loc'
    let s:logger = lh#log#new(get(a:, 1, ''), a:kind)
  elseif a:kind =~? 'file'
    let s:logger = lh#log#new(a:1, a:kind)
  else
    throw "Invalid logger required"
  endif
  return s:logger
endfunction

" Function: lh#log#get() {{{3
function! lh#log#get() abort
  return s:logger
endfunction

" let s:logger = get(s:, 'logger', lh#log#echomsg())
let s:logger = lh#log#echomsg()

" Function: lh#log#clear() {{{3
function! lh#log#clear() abort
  return s:logger.reset()
endfunction

" Function: lh#log#this(format, params) {{{3
function! lh#log#this(fmt, ...) abort
  " Data in qf format need a special handling
  if type(a:fmt) == type([])
    for msg in a:fmt
      call call('lh#log#this', [msg]+a:000)
    endfor
  elseif type(a:fmt) == type({}) && has_key(a:fmt, 'lnum')
    " dictionaries that aren't quickfix item are errors
    if has_key(s:logger, 'log_trace')
      call s:logger.log_trace(a:fmt)
    else
      let msg = lh#fmt#printf("%1:%2: %3", a:fmt.filename, a:fmt.lnum, a:fmt.text)
      call s:logger.log(msg)
    endif
  else
    let msg = call('lh#fmt#printf', [a:fmt] + a:000)
    call s:logger.log(msg)
  endif
endfunction

" Function: lh#log#exception([exception [,throwpoint]]) {{{3
function! lh#log#exception(...) abort
  let exception  = a:0 > 0 ? a:1 : v:exception
  let throwpoint = a:0 > 1 ? a:2 : v:throwpoint
  let bt = lh#exception#callstack(throwpoint)
  " let g:bt = bt
  if !empty(bt)
    " TODO: ignore function from this plugin!
    let data = map(copy(bt), '{"filename": v:val.script, "text": "called from here (".get(v:val,"fname", "n/a").")", "lnum": v:val.pos}')
    let data[0].text = v:exception
    call lh#log#this(data)
  else
    call lh#log#this(exception)
  endif
endfunction

" Function: lh#log#callstack(msg) {{{3
" @since Version 3.13.0
function! lh#log#callstack(msg) abort
  try
    throw a:msg
  catch /.*/
    call lh#log#exception()
  endtry
endfunction

" ## Internal functions {{{1
" # SNR
" s:getSNR([func_name]) {{{2
function! s:getSNR(...) abort
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

" s:function(funcname) {{{2
function! s:function(funcname) abort
  return function(s:getSNR(a:funcname))
endfunction

" # LHLog support functions {{{2
" Function: lh#log#_log(cmd [, where]) {{{3
function! lh#log#_log(cmd, ...) abort
  if a:cmd == 'clear'
    call lh#log#clear()
  else
    call call('lh#log#set_logger',[a:cmd] + a:000)
  endif
endfunction

" Function: lh#log#_set_logger_complete(ArgLead, CmdLine, CursorPos) {{{3
let s:k_lhlog_cmds = [ 'none', 'echomsg', 'qf', 'loc', 'clear', 'file']
function! lh#log#_set_logger_complete(ArgLead, CmdLine, CursorPos) abort
  return filter(copy(s:k_lhlog_cmds), 'v:val =~ "^".a:ArgLead.".*"')
endfunction

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
