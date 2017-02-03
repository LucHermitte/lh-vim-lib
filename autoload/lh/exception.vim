"=============================================================================
" File:         autoload/lh/exception.vim                         {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      4.0.0
let s:k_version = '4000'
" Created:      18th Nov 2015
" Last Update:  03rd Feb 2017
"------------------------------------------------------------------------
" Description:
"       Functions related to VimL Exceptions
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#exception#version()
  return s:k_version
endfunction

" # Debug   {{{2
if !exists('s:verbose')
  let s:verbose = 0
endif
function! lh#exception#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#exception#debug(expr)
  return eval(a:expr)
endfunction

" s:getSNR([func_name]) {{{2
function! s:getSNR(...)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

"------------------------------------------------------------------------
" ## Exported functions {{{1

" # Call Stack decoding {{{2

" Function: lh#exception#callstack(throwpoint) {{{3
" Return a list of:
" - "script": filename of the vimscript where the function is defined
" - "pos":    absolute line number in this script file
" - "fname":  function name
" - "fstart": line where the function is defined in the script
" - "offset": offset, from the start of the function, of the line where the
"             exception was thrown
" let g:stacks = []
function! lh#exception#callstack(throwpoint) abort
  let po_line = lh#po#context().translate('%s, line %ld')
  let po_line = substitute(po_line, '%s', '(\k+)%(', '')
  let po_line = substitute(po_line, '%ld', '(\d+)', 'g')
  let rx_line = '\v'.po_line.')=$'
  let cleanup = lh#on#exit()
        \.restore('&isk')
  try
    set isk+=#
    let stack = split(a:throwpoint, '\.\.')
    call reverse(stack)

    let function_stack = []
    let dScripts = {}
    for sFunc in stack
      " next line requires '#' in &isk for autoload function names
      let func_data = matchlist(sFunc, '\(\k\+\)\[\(\d\+\)\]')
      if empty(func_data)
        " Should support internationalized Vim PO/gettext messages w/ bash
        let func_data = matchlist(sFunc, rx_line)
      endif
      if !empty(func_data)
        let fname = func_data[1]
        if fname =~ '\v(\<SNR\>|^)\d+_'
          let script_id = matchstr(fname,  '\v(\<SNR\>|^)\zs\d+\ze_')
          let fname  = substitute(fname, '\v(\<SNR\>|^)\d+_', 's:', '')
          let script = lh#askvim#scriptname(script_id)
          if lh#option#is_unset(script)
            unlet script
            let script = ''
          endif
        else
          if fname =~ '^\d\+$' | let fname = '{'.fname.'}' | endif
          let script = lh#askvim#where_is_function_defined(fname)
        endif
        let script = substitute(script, '^\~', substitute($HOME, '\\', '/', 'g'), '')
        let offset = !empty(func_data[2]) ? func_data[2] : 0
        if !empty(script) && filereadable(script)
          if !has_key(dScripts, script)
            let dScripts[script] = reverse(readfile(script))
          endif
          let fstart = len(dScripts[script]) - match(dScripts[script], '^\s*fu\%[nction]!\=\s\+'.fname)
          let data = {'script': script, 'fname': fname, 'fstart': fstart, 'offset': offset }
          let data.pos = data.offset + fstart
        else
          let data = {'script': '???', 'fname': fname, 'fstart':0, 'offset': offset, 'pos': offset  }
        endif
        let function_stack += [data]
      endif
    endfor
    " let g:stacks += [a:throwpoint]
  finally
    call cleanup.finalize()
  endtry
  return function_stack
endfunction

" Function: lh#exception#callstack_as_qf(filter, [msg]) {{{3
function! lh#exception#callstack_as_qf(filter, ...) abort
  try
    throw "dummy"
  catch /.*/
    return call(lh#exception#decode().as_qf, [a:filter]+a:000)
  endtry
endfunction

" Function: lh#exception#decode([throwpoint]) {{{3
function! s:as_qf(filter, ...) dict abort
  let data = []
  let idx = lh#list#find_if(self.callstack, 'v:val.fname !~? "\\vlh#exception#'.a:filter.'"', 1)
  if idx >= 0
    let data = map(copy(self.callstack)[idx : ], '{"filename": v:val.script, "text": "called from here (".get(v:val,"fname", "n/a").":".get(v:val,"offset", "?").")", "lnum": v:val.pos}')
    " let data[0].text = lh#fmt#printf('function %{1.fname} line %{1.offset}: %2', self.callstack[idx], get(a:, 1, '...'))
    " let data[0].text = lh#fmt#printf('function %{1.fname} line %{1.offset}: %2', self.callstack[0], get(a:, 1, '...'))
    let data[0].text =  get(a:, 1, '...')
  endif
  return data
endfunction

function! lh#exception#decode(...) abort
  let throwpoint = get(a:, 1, v:throwpoint)
  let callstack = lh#exception#callstack(throwpoint)
  let res = lh#object#make_top_type({'callstack': callstack})
  let res.as_qf = function(s:getSNR('as_qf'))
  return res
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
