"=============================================================================
" File:         tests/lh/switch.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/blob/master/License.md>
" Version:      4.7.0.
let s:k_version = '470'
" Created:      05th Dec 2019
" Last Update:  13th Dec 2019
"------------------------------------------------------------------------
" Description:
"       Unit tests for lh#switch
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

UTSuite [lh-vim-lib] Testing lh/switch.vim

runtime autoload/lh/switch.vim

let s:cpo_save=&cpo
set cpo&vim

"------------------------------------------------------------------------
function! s:Test_string_string()
  let switch = lh#switch#new()
  call switch.add_case({'cond': 'a:1.conv', 'func': '"converting constructor from ".a:1.params[0].spelling'})
  call switch.add_case({'cond': 'a:1.ctr',  'func': '"a constructor"'})
  call switch.add_case({'cond': 'a:1.dtr',  'func': '"a destructor"'})
  call switch.add_case({'cond': 1        ,  'func': '"0"'})

  let ctr = {'name': 'MyClass', 'params': [{'spelling': 'double'}], 'ctr': 1, 'dtr': 0}
  AssertEqual (switch.evaluate(extend(copy(ctr), {'conv': 1})), 'converting constructor from double')
  AssertEqual (switch.evaluate(extend(copy(ctr), {'conv': 0})), 'a constructor')
  AssertEqual (switch.evaluate({'conv': 0, 'ctr':0, 'dtr': 1}), 'a destructor')
  AssertEqual (switch.evaluate({'conv': 0, 'ctr':0, 'dtr': 0}), '0')
endfunction

function! s:Test_func_string()
  if lh#has#lambda()
    let switch = lh#switch#new()
    call switch.add_case({'cond': {d -> d.conv}, 'func': '"converting constructor from ".a:1.params[0].spelling'})
    call switch.add_case({'cond': {d -> d.ctr},  'func': '"a constructor"'})
    call switch.add_case({'cond': {d -> d.dtr},  'func': '"a destructor"'})
    call switch.add_case({'cond': 1           ,  'func': '"0"'})

    let ctr = {'name': 'MyClass', 'params': [{'spelling': 'double'}], 'ctr': 1, 'dtr': 0}
    AssertEqual (switch.evaluate(extend(copy(ctr), {'conv': 1})), 'converting constructor from double')
    AssertEqual (switch.evaluate(extend(copy(ctr), {'conv': 0})), 'a constructor')
    AssertEqual (switch.evaluate({'conv': 0, 'ctr':0, 'dtr': 1}), 'a destructor')
    AssertEqual (switch.evaluate({'conv': 0, 'ctr':0, 'dtr': 0}), '0')
  endif
endfunction

function! s:Test_func_func()
  if lh#has#lambda()
    let switch = lh#switch#new()
    call switch.add_case({'cond': {d -> d.conv}, 'func': {d -> 'converting constructor from '.d.params[0].spelling}})
    call switch.add_case({'cond': {d -> d.ctr},  'func': {d -> 'a constructor'}})
    call switch.add_case({'cond': {d -> d.dtr},  'func': {d -> 'a destructor'}})
    call switch.add_case({'cond': 1           ,  'func': '"0"'})

    let ctr = {'name': 'MyClass', 'params': [{'spelling': 'double'}], 'ctr': 1, 'dtr': 0}
    AssertEqual (switch.evaluate(extend(copy(ctr), {'conv': 1})), 'converting constructor from double')
    AssertEqual (switch.evaluate(extend(copy(ctr), {'conv': 0})), 'a constructor')
    AssertEqual (switch.evaluate({'conv': 0, 'ctr':0, 'dtr': 1}), 'a destructor')
    AssertEqual (switch.evaluate({'conv': 0, 'ctr':0, 'dtr': 0}), '0')
  endif
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
