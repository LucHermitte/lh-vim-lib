"=============================================================================
" File:         autoload/lh/exception.vim                         {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      5.2.1
let s:k_version = '50201'
" Created:      18th Nov 2015
" Last Update:  11th Sep 2020
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
  let po_line = substitute(po_line, '%ld', '(\\d+)', 'g')
  let rx_file = '\v'.substitute(po_line, '%s', '(\\f+)%(', '').')=$'
  let rx_line = '\v'.substitute(po_line, '%s', '(\\k+)%(', '').')=$'
  let cleanup = lh#on#exit()
        \.restore('&isk')
  try
    setlocal isk&vim
    setlocal isk+=#
    let stack = split(a:throwpoint, '\.\.')
    call reverse(stack)

    let function_stack = []
    let dScripts = {}
    for sFunc in stack
      " echomsg "DEBUG: ".sFunc
      " With Vim 8.2.1297, expand(<stack>) may prefix the first function w/
      " "function "
      let sFunc = substitute(sFunc, '^function ', '', '')

      " 1- Test files
      " With Vim 8.2.1297, expand(<stack>) may return filenames: "{filename}[{lineno}]"
      let file_data = matchlist(sFunc, '\v(\f+)\[(\d+)\]')
      if empty(file_data)
        " Should support internationalized Vim PO/gettext messages w/ bash
        " syntax:  "{filename}, line {lineno}"
        let file_data = matchlist(sFunc, rx_file)
      endif
      if !empty(file_data)
        let script = file_data[1]
        let script = substitute(script, '^\~', substitute($HOME, '\\', '/', 'g'), '')
        if filereadable(script)
          let offset = !empty(file_data[2]) ? file_data[2] : 0
          let data = {'script': script, 'fname': '(:source)', 'fstart': offset, 'offset': offset }
          let data.pos = offset
          let function_stack += [data]
          continue " <<<-------------- CONTINUE to break switch...
        endif
      endif

      " 2- Test functions
      " next line requires '#' in &isk for autoload function names
      let func_data = matchlist(sFunc, '\v(\k+)\[(\d+)\]')
      if empty(func_data)
        " Should support internationalized Vim PO/gettext messages w/ bash
        " syntax:  "{function}, line {lineno}"
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
          let fn_def = lh#askvim#where_is_function_defined(fname)
          let script = fn_def.script
          if has_key(fn_def, 'line')
            let fstart = fn_def.line
          endif
        endif
        let script = substitute(script, '^\~', substitute($HOME, '\\', '/', 'g'), '')
        let offset = !empty(func_data[2]) ? func_data[2] : 0
        if !empty(script) && filereadable(script)
          if !has_key(dScripts, script)
            let dScripts[script] = reverse(readfile(script))
          endif
          if !exists('fstart')
            let fstart = len(dScripts[script]) - match(dScripts[script], '^\s*fu\%[nction]!\=\s\+'.fname.'\s*(')
          endif
          let data = {'script': script, 'fname': fname, 'fstart': fstart, 'offset': offset }
          let data.pos = data.offset + fstart
        else
          let data = {'script': '???', 'fname': fname, 'fstart':0, 'offset': offset, 'pos': offset  }
        endif
        let function_stack += [data]
        if exists('fstart') | unlet fstart | endif
      endif " <<<-------------- functions
    endfor
    " let g:stacks += [a:throwpoint]
  finally
    call cleanup.finalize()
  endtry
  return function_stack
endfunction

" Function: lh#exception#get_callstack() {{{3
if has('patch-8.2.1297')
  function! lh#exception#get_callstack() abort
    let raw_stack = expand('<stack>')
    let stack = lh#exception#decode(raw_stack)
    " ignore current level => [1:]
    call stack.__pop()
    return stack
  endfunction
else
  "Note:  As of vim 8.0-314, the callstack size is always of 1 when called from a
  "script. See Vim issue#1480
  function! lh#exception#get_callstack() abort
    try
      throw "dummy"
    catch /.*/
      let stack = lh#exception#decode()
      " ignore current level => [1:]
      call stack.__pop()
      return stack
    endtry
  endfunction
endif

" Function: lh#exception#callstack_as_qf(filter, [msg]) {{{3
function! lh#exception#callstack_as_qf(filter, ...) abort
  let stack = lh#exception#get_callstack()
  return call(stack.as_qf, [a:filter]+a:000, stack)
endfunction

" Function: lh#exception#decode([throwpoint]) {{{3
function! s:as_qf(filter, ...) dict abort
  let data = []
  let idx = lh#list#find_if(self.callstack, 'v:val.fname !~? "\\vlh#exception#'.a:filter.'"')
  " let idx = lh#list#find_if(self.callstack, 'v:val.fname !~? "\\vlh#exception#'.a:filter.'"', 1)
  if idx >= 0
    let data = map(copy(self.callstack)[idx : ], '{"type": "I", "filename": v:val.script, "text": "called from here (".get(v:val,"fname", "n/a").":".get(v:val,"offset", "?").")", "lnum": v:val.pos}')
    " let data[0].text = lh#fmt#printf('function %{1.fname} line %{1.offset}: %2', self.callstack[idx], get(a:, 1, '...'))
    " let data[0].text = lh#fmt#printf('function %{1.fname} line %{1.offset}: %2', self.callstack[0], get(a:, 1, '...'))
  elseif !empty(self.callstack)
    let idx = 0
    let data = map(copy(self.callstack), '{"type": "I", "filename": v:val.script, "text": "called from here (".get(v:val,"fname", "n/a").":".get(v:val,"offset", "?").")", "lnum": v:val.pos}')
  endif
  if !empty(data)
    let data[0].text =  get(a:, 1, "... (".get(self.callstack[idx],"fname", "n/a").":".get(self.callstack[idx],"offset", "?").")")
    let data[0].type = 'E'
  endif
  return data
endfunction

function! s:__pop() dict abort
  " Don't call lh#assert as assertions rely on lh#exception
  call remove(self.callstack, 0)
endfunction

function! lh#exception#decode(...) abort
  let throwpoint = get(a:, 1, v:throwpoint)
  let callstack = lh#exception#callstack(throwpoint)
  let res = lh#object#make_top_type({'callstack': callstack})
  let res.as_qf = function(s:getSNR('as_qf'))
  let res.__pop = function(s:getSNR('__pop'))
  return res
endfunction

" Function: lh#exception#say_what() {{{3
" Function inspired by https://github.com/tweekmonster/exception.vim
" A neat way to use it is:
"   command! WTF call lh#exception#say_what()
"
" The differences are:
" - Support for localized messages
" - Support for autoloaded functions, even when `#` isn't in &isk (that may
"   happen depending on the filetype of the current buffer)
" - Use a framework that have been here for little time for other topics
"   (logging, unit testing)
" - As few loops as possible -- I hate debugging them
function! lh#exception#say_what(...) abort
  let po_ctx = lh#po#context()
  let po_err_detected = po_ctx.translate('Error detected while processing %s:')
  let rx_err_detected = '^\v'.printf(po_err_detected, '\zs.*\ze').'$'

  let po_in_line = lh#po#context().translate('line %4ld:')
  let rx_in_line = '^\v'.substitute(po_in_line, '%4ld', '\\s*\\zs\\d+\\ze', '')

  let po_out_line = lh#po#context().translate('%s, line %ld')

  let messages = reverse(lh#askvim#execute('messages'))
  " There may be noise like missing endif, endwhile, etc
  " => loop
  let qf = []

  let nb_errors_to_decode = eval(get(a:, 1, 1))
  let nb_errors_found     = 0
  let i = 0
  while 1
    let i = match(messages, rx_err_detected, i+1)
    if (i < 2) && (nb_errors_found == 0)
      throw "No error detected!"
    endif
    let throwpoint = matchstr(messages[i], rx_err_detected)
    let line = matchstr(messages[i-1], rx_in_line)
    call lh#assert#not_empty(line)

    let throwpoint = printf(po_out_line, throwpoint, line)

    let e_qf = lh#exception#decode(throwpoint).as_qf('')
    let e_qf[0].text = substitute(e_qf[0].text, '^\.\.\.', messages[i-2], '')
    call lh#assert#not_empty(e_qf)
    call extend(qf, reverse(e_qf))
    if messages[i-2] !~ '^E171:\|^E170'
      let nb_errors_found += 1
      if nb_errors_found == nb_errors_to_decode
        break
      endif
    endif
  endwhile

  call setqflist(reverse(qf))
  if exists(':Copen')
    Copen
  else
    copen
  endif
  copen
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
