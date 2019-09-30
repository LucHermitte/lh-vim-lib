"=============================================================================
" File:		autoload/lh/common.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:	4.7.0
let s:k_version = 470
" Created:	07th Oct 2006
" Last Update:	30th Sep 2019
"------------------------------------------------------------------------
" Description:
" 	Some common functions for:
" 	- displaying error messages
" 	- checking dependencies
"
"------------------------------------------------------------------------
" Requirements:
" 	ruby, or python enabled for lh#common#rand()
" History:
"       v4.7.0:
"       - ENH: Add optional ColorHL to lh#common#warning_msg
"       v4.5.0:
"       - REFACT: Try to use the the best python flavour available
"       v4.0.0:
"       - ENH: Define other implementations of lh#common#rand
"       v3.6.1
"       - ENH: Use new logging framework
"       v3.1.17
"       - Fix lh#common#echomsg_multilines() to accept lists
"       v3.0.1
"       - lh#common#rand
"       v3.0.0
"       - GPLv3
" 	v2.1.1
" 	- New function: lh#common#echomsg_multilines()
" 	- lh#common#warning_msg() supports multilines messages
"
" 	v2.0.0:
" 	- Code moved from other plugins
" }}}1
"=============================================================================


"=============================================================================
let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" Functions {{{1

" Function: lh#common#echomsg_multilines {{{2
function! lh#common#echomsg_multilines(text)
  let lines = type(a:text) == type([]) ? a:text : split(a:text, "[\n\r]")
  for line in lines
    echomsg line
  endfor
endfunction
function! lh#common#echomsgMultilines(text)
  return lh#common#echomsg_multilines(a:text)
endfunction

" Function: lh#common#error_msg {{{2
function! lh#common#error_msg(text)
  if has('gui_running')
    call confirm(a:text, '&Ok', '1', 'Error')
  else
    " echohl ErrorMsg
    echoerr a:text
    " echohl None
  endif
endfunction
function! lh#common#ErrorMsg(text)
  return lh#common#error_msg(a:text)
endfunction

" Function: lh#common#warning_msg {{{2
function! lh#common#warning_msg(text, ...)
  let hl = get(a:, 1, 'WarningMsg')
  exe 'echohl '.hl
  " echomsg a:text
  call lh#common#echomsg_multilines(a:text)
  echohl None
endfunction
function! lh#common#WarningMsg(text)
  return lh#common#warning_msg(a:text)
endfunction

" Dependencies {{{2
function! lh#common#check_deps(Symbol, File, path, plugin) " {{{3
  if !exists(a:Symbol)
    exe "runtime ".a:path.a:File
    if !exists(a:Symbol)
      call lh#common#error_msg( a:plugin.': Requires <'.a:File.'>')
      return 0
    endif
  endif
  return 1
endfunction

function! lh#common#CheckDeps(Symbol, File, path, plugin) " {{{3
  echomsg "lh#common#CheckDeps() is deprecated, use lh#common#check_deps() instead."
  return lh#common#check_deps(a:Symbol, a:File, a:path, a:plugin)
endfunction

" Function: lh#common#rand(max) {{{2
" This function requires ruby, and it may move to another autoload plugin
if has('ruby')
  function! lh#common#rand_ruby(max)
    ruby << EOF
    rmax = VIM::evaluate("a:max")
    rmax = nil if rmax == ""
    VIM::command("return #{rand(rmax).inspect}")
EOF
  endfunction
  let s:random = get(s:, 'random', 'ruby')
endif

if !exists('s:random')
  let py_flavour = lh#python#best_still_avail()
  if !empty(py_flavour)
    function! lh#common#rand_python3(max)
python3 << EOF
import vim, random
rmax = eval(vim.eval("a:max")) - 1
# rmax = nil if rmax == ""
res = random.randint(0, rmax)
vim.command("return %d" % (res,))
EOF
    endfunction
    function! lh#common#rand_python(max)
python << EOF
import vim, random
rmax = eval(vim.eval("a:max")) - 1
# rmax = nil if rmax == ""
res = random.randint(0, rmax)
vim.command("return %d" % (res,))
EOF
    endfunction
    let s:random = get(s:, 'random', py_flavour)
  endif
endif

if lh#os#system_detected() == 'unix'
  " This flavour is very slow, and best avoided!
  function! lh#common#rand_unix(max)
    let nb_bytes = float2nr(log(a:max-1)/s:k_lg256)+1
    let rnd = matchstr(system('echo $RANDOM'), '\d\+')
    let res = rnd % a:max
    return res
  endfunction
  let s:random = get(s:, 'random', 'dev_unix')
endif

if lh#os#system_detected() == 'windows'
  " This flavour is very slow, and best avoided!
  function! lh#common#rand_unix(max)
    let nb_bytes = float2nr(log(a:max-1)/s:k_lg256)+1
    let rnd = matchstr(system('echo %RANDOM%'), '\d\+')
    let res = rnd % a:max
    return res
  endfunction
  let s:random = get(s:, 'random', 'dev_windows')
endif

if filereadable('/dev/urandom') && has('float')
  " This flavour is very slow!
  let s:k_lg256 = log(256)
  function! lh#common#rand_dev_urandom(max)
    let nb_bytes = float2nr(log(a:max-1)/s:k_lg256)+1
    let rnd = matchstr(system('od -A n -t d -N '.nb_bytes.' /dev/urandom'), '\d\+')
    let res = rnd % a:max
    return res
  endfunction
  let s:random = get(s:, 'random', 'dev_urandom')
endif

function! lh#common#rand(max)
  call lh#assert#value(s:).has_key('random')
  return lh#common#rand_{s:random}(a:max)
endfunction
" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
