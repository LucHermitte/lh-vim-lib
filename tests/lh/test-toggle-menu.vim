"=============================================================================
" File:         tests/lh/project.vim                              {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0.0.
let s:k_version = '4000'
" Created:      17th Apr 2007
" Last Update:  08th Mar 2017
"------------------------------------------------------------------------
" Description:
"       Tests for lh-vim-lib . lh#menu#def_toggle_item()
"
"------------------------------------------------------------------------
" }}}1
"=============================================================================

if !exists(':Assert')
  " Direct loading
else
  UTSuite [lh-vim-lib] Testing lh#project
endif

let s:cpo_save=&cpo
set cpo&vim

" ## Dependencies {{{1
runtime autoload/lh/menu.vim
runtime autoload/lh/option.vim
runtime autoload/lh/let.vim
runtime autoload/lh/project.vim

let s:prj_varname = 'b:'.get(g:, 'lh#project#varname', 'crt_project')


" ## Fixture {{{1
function! s:Setup() " {{{2
  let s:prj_list = lh#project#list#_save()
  let s:cleanup = lh#on#exit()
        \.restore('b:'.s:prj_varname)
        \.restore('s:prj_varname')
        \.restore('g:lh#project.auto_discover_root')
        " \.register({-> lh#project#list#_restore(s:prj_list)})
  let g:lh#project = { 'auto_discover_root': 'no' }
  if exists('b:'.s:prj_varname)
    exe 'unlet b:'.s:prj_varname
  endif
endfunction

function! s:Teardown() " {{{2
  call s:cleanup.finalize()
  call lh#project#list#_restore(s:prj_list)
endfunction

" ## Definitions {{{1
" # Menu Data {{{2
" Data {{{3
let Data = {
      \ "variable": "bar",
      \ "idx_crt_value": 1,
      \ "values": [ 'a', 'b', 'c', 'd' ],
      \ "menu": { "priority": '42.50.10', "name": '&LH-Tests.&TogMenu.&bar'}
      \}
call lh#menu#def_toggle_item(Data)

" Data2 {{{3
let Data2 = {
      \ "variable": "foo",
      \ "idx_crt_value": 3,
      \ "texts": [ 'un', 'deux', 'trois', 'quatre' ],
      \ "values": [ 1, 2, 3, 4 ],
      \ "menu": { "priority": '42.50.20', "name": '&LH-Tests.&TogMenu.&foo'}
      \}
call lh#menu#def_toggle_item(Data2)

" Data3 {{{3
" No default
let Data3 = {
      \ "variable": "nodef",
      \ "texts": [ 'one', 'two', 'three', 'four' ],
      \ "values": [ 1, 2, 3, 4 ],
      \ "menu": { "priority": '42.50.30', "name": '&LH-Tests.&TogMenu.&nodef'}
      \}
call lh#menu#def_toggle_item(Data3)

" Data4 {{{3
" No default
let g:def = 2
let Data4 = {
      \ "variable": "def",
      \ "values": [ 1, 2, 3, 4 ],
      \ "menu": { "priority": '42.50.40', "name": '&LH-Tests.&TogMenu.&def'}
      \}
call lh#menu#def_toggle_item(Data4)

" What follows does not work because we can't build an exportable FuncRef on top
" of a script local function
" finish

" # Helper functions {{{2
" s:getSNR([func_name]) {{{3
function! s:getSNR(...)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

function! s:Yes()
  echomsg "Yes"
endfunction

function! s:No()
  echomsg "No"
endfunction
let Data4 = {
      \ "variable": "yesno",
      \ "values": [ 1, 2 ],
      \ "text": [ "No", "Yes" ],
      \ "actions": [ function(s:getSNR()."No"), function(s:getSNR()."Yes") ],
      \ "menu": { "priority": '42.50.20', "name": '&LH-Tests.&TogMenu.&yesno'}
      \}
call lh#menu#def_toggle_item(Data4)

" ## Tests {{{1
" Tests won't test the menus, but the toggling
"
" Function: s:Test_SimpleToggle() {{{2
function! s:Test_SimpleToggle() abort
  let idx = g:Data.idx_crt_value
  AssertEquals(g:bar, g:Data.values[idx])
  let nb = len(g:Data.values)
  for i in range(1,nb*2)
    Toggle LHTestsTogMenubar
    " As this is not 100% silent, it may fail with rake/travis
    " TODO: need a variable to silence it
    let idx = (idx+1)%nb
    AssertEquals(g:bar, g:Data.values[idx])
  endfor
endfunction

" Function: s:Test_ToggleProjectVars() {{{2
function! s:Test_ToggleProjectVars() abort
  let cleanup = lh#on#exit()
        \.restore(s:prj_varname)
  try
    silent! unlet {s:prj_varname}
    let p1 = lh#project#new({'name': 'Menu'})
    let pData = {
          \ "variable": "p:bar",
          \ "idx_crt_value": 1,
          \ "values": [lh#ref#bind('g:bar')] + g:Data.values,
          \ "texts": ['default'] + g:Data.values,
          \ "menu": { "priority": '42.50.11', "name": '&LH-Tests.&TogMenu.&p:bar'}
          \}
    Assert! lh#ref#is_bound(pData.values[0])

    let g:pData = pData
    call lh#menu#def_toggle_item(pData)

    let idx = pData.idx_crt_value
    AssertEquals(lh#option#get('bar'), pData.values[idx])
    let nb = len(pData.values)
    for i in range(1,nb)
      Toggle LHTestsTogMenupbar
      " As this is not 100% silent, it may fail with rake/travis
      " TODO: need a variable to silence it
      let idx = (idx+1)%nb
      if idx == 0
        Assert lh#ref#is_bound(p1.variables.bar)
        AssertIs(p1.variables.bar.resolve(), g:bar)
        AssertIs(lh#option#get('bar'), g:bar)
      else
        AssertEquals(lh#option#get('bar'), pData.values[idx])
      endif
    endfor
  finally
    call cleanup.finalize()
  endtry
endfunction

" Function: s:Test_ToggleWithActions() {{{3
function! s:Test_ToggleWithActions() abort
endfunction

" Function: s:Test_ToggleWithHooks() {{{3
function! s:Test_ToggleWithHooks() abort
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
