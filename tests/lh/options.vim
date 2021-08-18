"=============================================================================
" File:         tests/lh/options.vim                              {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/blob/master/License.md>
" Version:      5.3.3.
let s:k_version = '533'
" Created:      18th Aug 2021
" Last Update:  18th Aug 2021
"------------------------------------------------------------------------
" Description:
"       Test lh#option#get() function
"       Run the test with :UTRun %
" }}}1
"=============================================================================

UTSuite [lh-vim-lib] Testing lh#option#get function

let s:cpo_save=&cpo
set cpo&vim

" ## Dependencies {{{1
runtime autoload/lh/project.vim
runtime autoload/lh/let.vim
runtime autoload/lh/option.vim
runtime autoload/lh/os.vim

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
  let s:prj_list = lh#project#list#_save()
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

"------------------------------------------------------------------------
" ## Tests {{{1
function! s:Test_global() " {{{2
  let cleanup = lh#on#exit()
        \.restore('g:foo')
        \.restore('b:foo')
        \.restore('g:bar')
        \.restore('b:bar')
  try
    Unlet g:foo
    Unlet b:foo
    Unlet p:foo
    Unlet g:bar
    Unlet b:bar
    Unlet p:bar
    let g:foo = 42
    AssertEquals(lh#option#get('foo', 12) , 42)
    AssertEquals(lh#option#get('bar', 12) , 12)

    let b:foo = 43
    AssertEquals(lh#option#get('foo', 12) , 43)

    LetTo p:foo = 44
    AssertEquals(lh#option#get('foo', 12) , 43)

    Unlet b:foo
    AssertEquals(lh#option#get('foo', 12) , 44)
  finally
    call cleanup.finalize()
  endtry
endfunction

function! s:Test_local() " {{{2
  let cleanup = lh#on#exit()
        \.restore('b:foo')
  try
    let b:foo = 43
    AssertEquals(lh#option#get('foo', 12) , 43)
  finally
    call cleanup.finalize()
  endtry
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
