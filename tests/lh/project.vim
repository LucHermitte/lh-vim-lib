"=============================================================================
" File:         tests/lh/project.vim                              {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0.
let s:k_version = '400'
" Created:      10th Sep 2016
" Last Update:  18th Aug 2021
"------------------------------------------------------------------------
" Description:
"       Tests for lh#project
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

UTSuite [lh-vim-lib] Testing lh#project

let s:cpo_save=&cpo
set cpo&vim

" ## Dependencies {{{1
runtime autoload/lh/let.vim
runtime autoload/lh/option.vim
runtime autoload/lh/os.vim
runtime autoload/lh/project.vim

let cleanup = lh#on#exit()
      \.restore('g:force_reload_lh_project')
try
  runtime plugin/lh-project.vim
finally
  call cleanup.finalize()
endtry

let s:prj_varname = 'b:'.get(g:, 'lh#project#varname', 'crt_project')

"------------------------------------------------------------------------
" ## Fixture {{{1
function! s:Setup() " {{{2
  let s:prj_list = copy(lh#project#list#_save())
  let s:cleanup = lh#on#exit()
        \.restore('b:'.s:prj_varname)
        \.restore('s:prj_varname')
        \.restore('g:lh#project.auto_discover_root')
        " \.register({-> lh#project#list#_restore(s:prj_list)})
  LetTo g:lh#project.auto_discover_root = 'no'
  if exists('b:'.s:prj_varname)
    exe 'unlet b:'.s:prj_varname
  endif
endfunction

function! s:Teardown() " {{{2
  call s:cleanup.finalize()
  call lh#project#list#_restore(s:prj_list)
endfunction

" ## Tests {{{1
" Function: s:Test_varnames() {{{2
function! s:Test_varnames() abort
  call lh#on#_unlet(s:prj_varname)

  AssertEquals('l&:isk', lh#project#_crt_var_name('p:&isk'))
  AssertEquals('b:isk',  lh#project#_crt_var_name('p:isk'))
  AssertThrows(lh#project#_crt_var_name('p:$isk'))

  Project --define FooBar

  let var_opt = lh#project#_crt_var_name('p:&isk')
  let var_var = lh#project#_crt_var_name('p:isk')
  let var_env = lh#project#_crt_var_name('p:$isk')
  AssertEquals(var_opt.realname, s:prj_varname.'.options.isk')
  AssertEquals(var_opt.name,     '&isk'  )
  AssertEquals(var_var,          s:prj_varname.'.variables.isk')
  AssertEquals(var_env.realname, s:prj_varname.'.env.isk')
  AssertEquals(var_env.name,     '$isk'  )
endfunction

function! s:Test_create() " {{{2
  let cleanup = lh#on#exit()
        \.restore('g:test')
        \.restore('b:test')
  try
    call lh#on#_unlet(s:prj_varname)
    call lh#on#_unlet('g:test')
    call lh#on#_unlet('b:test')
    let p = lh#project#new({'name': 'ut'})
    AssertIs(p, {s:prj_varname})
    AssertEquals(p.depth(), 1)

    LetTo p:test = 'prj1'
    AssertEquals(lh#option#get('test'), 'prj1')
    LetTo b:test = 'buff'
    AssertEquals(lh#option#get('test'), 'buff')

    let g:test = 'glob'
    AssertEquals(lh#option#get('test'), 'buff')
    Unlet p:test
    AssertEquals(lh#option#get('test'), 'buff')
    LetTo p:test = 'prj1'
    Unlet b:test
    AssertEquals(lh#option#get('test'), 'prj1')
    AssertEquals(lh#let#_list_variables('p:', 1), [])
    AssertEquals(sort(lh#let#_list_variables('p:', 0)), sort(['p:test']))
    Unlet p:test
    AssertEquals(lh#option#get('test'), 'glob')

    AssertEquals(lh#let#_list_variables('p:', 1), [])
    AssertEquals(lh#let#_list_variables('p:', 0), [])

    LetTo p:dict.sub.var=42
    AssertEquals(lh#option#get('dict.sub'), {'var': 42})
    AssertEquals(lh#option#get('dict.sub.var'), 42)
    AssertEquals(sort(lh#let#_list_variables('p:', 1)), sort(['p:dict.']))
    AssertEquals(sort(lh#let#_list_variables('p:', 0)), sort(['p:dict.']))
  finally
    call cleanup.finalize()
  endtry
endfunction

function! s:Test_inherit() " {{{2
  let cleanup = lh#on#exit()
        \.restore('g:test')
        \.restore('b:test')
  try
    call lh#on#_unlet(s:prj_varname)
    call lh#on#_unlet('g:test')
    call lh#on#_unlet('b:test')
    let p1 = lh#project#new({'name': 'UT1'})
    AssertIs(p1, {s:prj_varname})
    AssertEquals(p1.depth(), 1)
    Assert lh#option#is_unset(lh#option#get('test'))
    LetTo p:test = 'prj1'
    AssertEquals(lh#option#get('test'), 'prj1')
    LetTo b:test = 'buff'
    AssertEquals(lh#option#get('test'), 'buff')

    " Set on parent project
    call p1.set('d.1.2.3', 42)
    Assert lh#option#is_set(lh#option#get('d.1.2.3'))
    AssertEquals(lh#option#get('d.1.2.3'), 42)
    AssertEquals(p1.get('d.1.2.3'), 42)
    call p1.update('d.1.2.3', 43)
    AssertEquals(lh#option#get('d.1.2.3'), 43)
    AssertEquals(p1.get('d.1.2.3'), 43)


    let p2 = lh#project#new({'name': 'UT2'})
    AssertEquals(p2.depth(), 2)
    AssertIs(p1, p2.parents[0])
    AssertIs(p2, {s:prj_varname})
    LetTo p:test = 'prj2'
    AssertEquals(lh#option#get('test'), 'buff')
    Unlet b:test
    AssertEquals(lh#option#get('test'), 'prj2')

    let g:test = 'glob'
    AssertEquals(lh#option#get('test'), 'prj2')
    Unlet p:test
    AssertEquals(lh#option#get('test'), 'prj1')
    Unlet p:test
    AssertEquals(lh#option#get('test'), 'glob')

    " Set on child project
    call p2.set('d.1.2.4', 42)
    Assert lh#option#is_set(lh#option#get('d.1.2.4'))
    AssertEquals(lh#option#get('d.1.2.4'), 42)
    AssertEquals(p2.get('d.1.2.4'), 42)

    " Update on child project
    call p2.update('d.1.2.3', 44)
    call p2.update('d.1.2.4', 44)
    AssertEquals(lh#option#get('d.1.2.3'), 44)
    AssertEquals(lh#option#get('d.1.2.4'), 44)
    AssertEquals(p1.get('d.1.2.3'), 44)
    AssertEquals(p2.get('d.1.2.4'), 44)

  finally
    call cleanup.finalize()
  endtry
endfunction

function! s:Test_create_opt() " {{{2
  " p:&opt > l:&opt > &opt
  let cleanup = lh#on#exit()
        \.restore('&isk')
  try
    call lh#on#_unlet(s:prj_varname)

    set isk&vim
    let g_isk = &isk

    call lh#on#_unlet('b:test')
    let p = lh#project#new({'name': 'UT'})
    AssertIs(p, {s:prj_varname})
    AssertEquals(p.depth(), 1)

    call p.set('&isk', '+=µ')
    AssertEquals(&isk, g_isk.',µ')

    LetTo p:&isk+=£
    AssertEquals(&isk, g_isk.',µ,£')

    AssertEquals(lh#let#_list_variables('p:', 1), [])
    AssertEquals(lh#let#_list_variables('p:', 0), ['p:&isk'])
  finally
    call cleanup.finalize()
  endtry
endfunction

function! s:Test_create_ENV() " {{{2
  " p:&opt > l:&opt > &opt
  let cleanup = lh#on#exit()
  try
    call lh#on#_unlet(s:prj_varname)
    Assert! !exists('$LH_FOOBAR')

    let p = lh#project#new({'name': 'UT'})
    AssertIs(p, {s:prj_varname})
    AssertEquals(p.depth(), 1)

    call p.set('$LH_FOOBAR', '42')
    " environment is not altered globally
    Assert !exists('$LH_FOOBAR')

    " Just it's updated on the fly
    AssertEquals(lh#os#system('echo $LH_FOOBAR'), 42)

    LetTo p:$LH_FOOBAR 28
    AssertEquals(lh#os#system('echo $LH_FOOBAR'), 28)


    AssertEquals(lh#let#_list_variables('p:', 1), [])
    AssertEquals(lh#let#_list_variables('p:', 0), ['p:$LH_FOOBAR'])
  finally
    call cleanup.finalize()
  endtry
endfunction

" Function: s:Test_let_to_best_varname_match() {{{2
function! s:Test_let_to_best_varname_match() abort
  call lh#on#_unlet(s:prj_varname)
  let parent = lh#project#new({'name': 'UT_prnt'})
  AssertIs(parent, {s:prj_varname})
  AssertEquals(parent.depth(), 1)
  let child = lh#project#new({'name': 'UT_chld'})
  AssertEquals(child.depth(), 2)
  AssertIs(parent, child.parents[0])
  AssertIs(child, {s:prj_varname})

  call parent.set('shared.shdprnt', {})
  call parent.set('parent', {})
  call parent.set('twice', 42)
  call child.set('shared.shdchld', {})
  let g:ut_parent = parent
  let g:ut_child = child

  let expected_child   = s:prj_varname.'.variables.'
  let expected_parents = s:prj_varname.'.parents[0].variables.'
  AssertEquals(lh#project#_best_varname_match('', 'newchld').realname,                expected_child.'newchld')
  AssertEquals(lh#project#_best_varname_match('', 'newchld.k').realname,              expected_child.'newchld.k')
  AssertEquals(lh#project#_best_varname_match('', 'shared').realname,                 expected_child.'shared')
  AssertEquals(lh#project#_best_varname_match('', 'shared.newkey').realname,          expected_child.'shared.newkey')
  AssertEquals(lh#project#_best_varname_match('', 'shared.shdchld').realname,         expected_child.'shared.shdchld')
  AssertEquals(lh#project#_best_varname_match('', 'shared.shdchld.newkey').realname,  expected_child.'shared.shdchld.newkey')
  AssertEquals(lh#project#_best_varname_match('', 'shared.shdchld.new.key').realname, expected_child.'shared.shdchld.new.key')

  AssertEquals(lh#project#_best_varname_match('', 'shared.shdprnt').realname,         expected_parents.'shared.shdprnt')
  AssertEquals(lh#project#_best_varname_match('', 'shared.shdprnt.newkey').realname,  expected_parents.'shared.shdprnt.newkey')
  AssertEquals(lh#project#_best_varname_match('', 'shared.shdprnt.new.key').realname, expected_parents.'shared.shdprnt.new.key')
  AssertEquals(lh#project#_best_varname_match('', 'parent').realname,                 expected_parents.'parent')
  AssertEquals(lh#project#_best_varname_match('', 'parent.newkey').realname,          expected_parents.'parent.newkey')
  AssertEquals(lh#project#_best_varname_match('', 'parent.newkey.subkey').realname,   expected_parents.'parent.newkey.subkey')

  " Now the same thing with LetTo
  LetTo --overwrite p:newchld.k              = 10
  LetTo --overwrite p:shared.newkey          = 11
  LetTo --overwrite p:shared.shdchld.newkey  = 12
  LetTo --overwrite p:shared.shdchld.new.key = 13

  LetTo --overwrite p:shared.shdprnt.newkey  = 14
  LetTo --overwrite p:shared.shdprnt.new.key = 15
  LetTo --overwrite p:parent.newkey.subkey   = 16
  LetTo --overwrite p:twice                  = 142

  AssertEquals(parent.variables, {'shared': {'shdprnt': {'newkey':14, 'new': {'key': 15}} }, 'parent': {'newkey': {'subkey': 16}}, 'twice': 142})
  AssertEquals(child.variables, {'shared': {'newkey': 11, 'shdchld': {'newkey': 12, 'new': {'key': 13} }}, 'newchld': {'k': 10}})
endfunction

" Function: s:Test_let_to_hide_varname() {{{2
function! s:Test_let_to_hide_varname() abort
  " Same test as s:Test_let_tobest_varname_match() but with the default 'hide'
  " policy.
  call lh#on#_unlet(s:prj_varname)
  let parent = lh#project#new({'name': 'UT_prnt'})
  AssertIs(parent, {s:prj_varname})
  AssertEquals(parent.depth(), 1)
  let child = lh#project#new({'name': 'UT_chld'})
  AssertEquals(child.depth(), 2)
  AssertIs(parent, child.parents[0])
  AssertIs(child, {s:prj_varname})

  call parent.set('shared.shdprnt', {})
  call parent.set('parent', {})
  call parent.set('twice', 42)
  call child.set('shared.shdchld', {})
  let g:ut_parent = parent
  let g:ut_child = child

  LetTo --hide p:newchld.k              = 10
  LetTo --hide p:shared.newkey          = 11
  LetTo --hide p:shared.shdchld.newkey  = 12
  LetTo --hide p:shared.shdchld.new.key = 13

  LetTo --hide p:shared.shdprnt.newkey  = 14
  LetTo --hide p:shared.shdprnt.new.key = 15
  LetTo --hide p:parent.newkey.subkey   = 16
  LetTo --hide p:twice                  = 142

  AssertEquals(parent.variables, {'shared': {'shdprnt': {}}, 'parent': {}, 'twice': 42})
  AssertEquals(child.variables, {'shared': {'shdprnt': {'newkey':14, 'new': {'key': 15}}, 'newkey': 11, 'shdchld': {'newkey': 12, 'new': {'key': 13}} }, 'newchld': {'k': 10}, 'parent': {'newkey': {'subkey': 16}}, 'twice': 142})
endfunction
" Function: s:Test_let_if_undef_best_varname_match() {{{2
function! s:Test_let_if_undef_best_varname_match() abort
  call lh#on#_unlet(s:prj_varname)
  let parent = lh#project#new({'name': 'UT_prnt'})
  AssertIs(parent, {s:prj_varname})
  AssertEquals(parent.depth(), 1)
  let child = lh#project#new({'name': 'UT_chld'})
  AssertEquals(child.depth(), 2)
  AssertIs(parent, child.parents[0])
  AssertIs(child, {s:prj_varname})

  call parent.set('shared.shdprnt', {})
  call parent.set('parent', {})
  call parent.set('twice', 42)
  call child.set('shared.shdchld', {})
  let g:ut_parent = parent
  let g:ut_child = child

  let expected_child   = s:prj_varname.'.variables.'
  let expected_parents = s:prj_varname.'.parents[0].variables.'
  AssertEquals(lh#project#_best_varname_match('', 'newchld').realname,                expected_child.'newchld')
  AssertEquals(lh#project#_best_varname_match('', 'newchld.k').realname,              expected_child.'newchld.k')
  AssertEquals(lh#project#_best_varname_match('', 'shared').realname,                 expected_child.'shared')
  AssertEquals(lh#project#_best_varname_match('', 'shared.newkey').realname,          expected_child.'shared.newkey')
  AssertEquals(lh#project#_best_varname_match('', 'shared.shdchld').realname,         expected_child.'shared.shdchld')
  AssertEquals(lh#project#_best_varname_match('', 'shared.shdchld.newkey').realname,  expected_child.'shared.shdchld.newkey')
  AssertEquals(lh#project#_best_varname_match('', 'shared.shdchld.new.key').realname, expected_child.'shared.shdchld.new.key')

  AssertEquals(lh#project#_best_varname_match('', 'shared.shdprnt').realname,         expected_parents.'shared.shdprnt')
  AssertEquals(lh#project#_best_varname_match('', 'shared.shdprnt.newkey').realname,  expected_parents.'shared.shdprnt.newkey')
  AssertEquals(lh#project#_best_varname_match('', 'shared.shdprnt.new.key').realname, expected_parents.'shared.shdprnt.new.key')
  AssertEquals(lh#project#_best_varname_match('', 'parent').realname,                 expected_parents.'parent')
  AssertEquals(lh#project#_best_varname_match('', 'parent.newkey').realname,          expected_parents.'parent.newkey')
  AssertEquals(lh#project#_best_varname_match('', 'parent.newkey.subkey').realname,   expected_parents.'parent.newkey.subkey')

  " Now the same thing with LetIfUndef
  LetIfUndef --overwrite p:newchld.k              = 10
  LetIfUndef --overwrite p:shared.newkey          = 11
  LetIfUndef --overwrite p:shared.shdchld.newkey  = 12
  LetIfUndef --overwrite p:shared.shdchld.new.key = 13

  LetIfUndef --overwrite p:shared.shdprnt.newkey  = 14
  LetIfUndef --overwrite p:shared.shdprnt.new.key = 15
  LetIfUndef --overwrite p:parent.newkey.subkey   = 16
  LetIfUndef --overwrite p:twice                  = 142

  AssertEquals(parent.variables, {'shared': {'shdprnt': {'newkey':14, 'new': {'key': 15}} }, 'parent': {'newkey': {'subkey': 16}}, 'twice': 42})
  AssertEquals(child.variables, {'shared': {'newkey': 11, 'shdchld': {'newkey': 12, 'new': {'key': 13} }}, 'newchld': {'k': 10}})
endfunction

" Function: s:Test_let_if_undef_hide_varname() {{{2
function! s:Test_let_if_undef_hide_varname() abort
  " Same test as s:Test_let_if_undef_best_varname_match() but with the default 'hide'
  " policy.
  call lh#on#_unlet(s:prj_varname)
  let parent = lh#project#new({'name': 'UT_prnt'})
  AssertIs(parent, {s:prj_varname})
  AssertEquals(parent.depth(), 1)
  let child = lh#project#new({'name': 'UT_chld'})
  AssertEquals(child.depth(), 2)
  AssertIs(parent, child.parents[0])
  AssertIs(child, {s:prj_varname})

  call parent.set('shared.shdprnt', {})
  call parent.set('parent', {})
  call parent.set('twice', 42)
  call child.set('shared.shdchld', {})
  let g:ut_parent = parent
  let g:ut_child = child

  LetIfUndef --hide p:newchld.k              = 10
  LetIfUndef --hide p:shared.newkey          = 11
  LetIfUndef --hide p:shared.shdchld.newkey  = 12
  LetIfUndef --hide p:shared.shdchld.new.key = 13

  LetIfUndef --hide p:shared.shdprnt.newkey  = 14
  LetIfUndef --hide p:shared.shdprnt.new.key = 15
  LetIfUndef --hide p:parent.newkey.subkey   = 16
  " Verbose let project
  LetIfUndef --hide p:twice                  = 142
  " LetIfUndef --overwrite p:twice                  = 142
  " Verbose! let project

  AssertEquals(parent.variables, {'shared': {'shdprnt': {}}, 'parent': {}, 'twice': 42})
  AssertEquals(child.variables, {'shared': {'shdprnt': {'newkey':14, 'new': {'key': 15}}, 'newkey': 11, 'shdchld': {'newkey': 12, 'new': {'key': 13}} }, 'newchld': {'k': 10}, 'parent': {'newkey': {'subkey': 16}}})
endfunction
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
