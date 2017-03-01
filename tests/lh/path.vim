"=============================================================================
" File:         tests/lh/path.vim                                      {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"		<URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/Licence.md>
" Version:      4.0.0
" Created:      28th May 2009
" Last Update:  01st Mar 2017
"------------------------------------------------------------------------
" Description:
"       Tests for autoload/lh/path.vim
"       Run it with :UTRun % (see UT.vim)
"
"------------------------------------------------------------------------
" }}}1
"=============================================================================

UTSuite [lh-vim-lib] Testing lh#path functions

runtime autoload/lh/path.vim
let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
function! s:Test_simplify()
  AssertEquals(lh#path#simplify('a/b/c'), 'a/b/c')
  AssertEquals(lh#path#simplify('a/b/./c'), 'a/b/c')
  AssertEquals(lh#path#simplify('./a/b/./c'), 'a/b/c')
  AssertEquals(lh#path#simplify('./a/../b/./c'), 'b/c')
  AssertEquals(lh#path#simplify('../a/../b/./c'), '../b/c')
  AssertEquals(lh#path#simplify('a\b\c'), 'a\b\c')
  AssertEquals(lh#path#simplify('a\b\.\c'), 'a\b\c')
  AssertEquals(lh#path#simplify('.\a\b\.\c'), 'a\b\c')
  if exists('+shellslash')
    AssertEquals(lh#path#simplify('.\a\..\b\.\c'), 'b\c')
    AssertEquals(lh#path#simplify('..\a\..\b\.\c'), '..\b\c')
  endif
endfunction

function! s:Test_split()
  AssertEquals(['', 'home', 'me', 'foo', 'bar'], lh#path#split('/home/me/foo/bar'))
  AssertEquals(['', 'home', 'me', 'foo', 'bar'], lh#path#split('/home/me/foo/bar/'))
  AssertEquals(['', 'home'], lh#path#split('/home'))
  AssertEquals(['', 'home'], lh#path#split('/home/'))
  AssertEquals([''], lh#path#split('/'))
  AssertEquals([], lh#path#split(''))
endfunction

function! s:Test_join()
  " With default '/'
  AssertEquals('/home/me/foo/bar', lh#path#join(['', 'home', 'me', 'foo', 'bar']))
  AssertEquals('/home/me/foo/bar/', lh#path#join(['', 'home', 'me', 'foo', 'bar', '']))
  AssertEquals('/home', lh#path#join(['', 'home']))
  AssertEquals('/', lh#path#join(['','']))
  AssertEquals('', lh#path#join([]))
  " With forced '\', with 1
  AssertEquals('\home\me\foo\bar', lh#path#join(['', 'home', 'me', 'foo', 'bar'], 1))
  AssertEquals('\home\me\foo\bar\', lh#path#join(['', 'home', 'me', 'foo', 'bar', ''], 1))
  AssertEquals('\home', lh#path#join(['', 'home'], 1))
  AssertEquals('\', lh#path#join(['', ''], 1))
  AssertEquals('', lh#path#join([], 1))
  " With forced '/', with 0
  AssertEquals('/home/me/foo/bar', lh#path#join(['', 'home', 'me', 'foo', 'bar'], 0))
  AssertEquals('/home/me/foo/bar/', lh#path#join(['', 'home', 'me', 'foo', 'bar', ''], 0))
  AssertEquals('/home', lh#path#join(['', 'home'], 0))
  AssertEquals('/', lh#path#join(['', ''], 0))
  AssertEquals('', lh#path#join([], 0))
  " With forced '%%'
  AssertEquals('%%home%%me%%foo%%bar', lh#path#join(['', 'home', 'me', 'foo', 'bar'], '%%'))
  AssertEquals('%%home%%me%%foo%%bar%%', lh#path#join(['', 'home', 'me', 'foo', 'bar', ''], '%%'))
  AssertEquals('%%home', lh#path#join(['', 'home'], '%%'))
  AssertEquals('%%', lh#path#join(['', ''], '%%'))
  AssertEquals('', lh#path#join([], '%%'))
  " With default shellslash
  AssertEquals(substitute('/home/me/foo/bar', '/', &ssl? '\\' : '/', 'g'), lh#path#join(['', 'home', 'me', 'foo', 'bar'], 'shellslash'))
  AssertEquals(substitute('/home/me/foo/bar/', '/', &ssl? '\\' : '/', 'g'), lh#path#join(['', 'home', 'me', 'foo', 'bar', ''], 'shellslash'))
  AssertEquals(substitute('/home', '/', &ssl ? '\\' : '/', 'g'), lh#path#join(['', 'home'], 'shellslash'))
  AssertEquals(substitute('/', '/', &ssl ? '\\' : '/', 'g'), lh#path#join(['', ''], 'shellslash'))
  AssertEquals('', lh#path#join([], 'ssl'))
endfunction

function! s:Test_strip_common()
  let paths = ['foo/bar/file', 'foo/file', 'foo/foo/file']
  let expected = [ 'bar/file', 'file', 'foo/file']
  AssertEquals(lh#path#strip_common(paths), expected)

  let paths = ['foo/bar/file', 'foo/bar/file', 'foo/foo/file']
  let expected = [ 'bar/file', 'bar/file', 'foo/file']
  AssertEquals(lh#path#strip_common(paths), expected)

  let paths = ['/foo/bar/file', '/foo/bar/file', '/foo/foo/file']
  let expected = [ 'bar/file', 'bar/file', 'foo/file']
  AssertEquals(lh#path#strip_common(paths), expected)

  let paths = ['/foo/bar/', '/foo/bar']
  let expected = [ '', '']
  AssertEquals(lh#path#strip_common(paths), expected)
endfunction

function! s:Test_common()
  " Pick one ...
  AssertEquals('foo', lh#path#common(['foo/bar/dir', 'foo']))
  AssertEquals('foo/bar', lh#path#common(['foo/bar/dir', 'foo/bar']))
  AssertEquals('foo', lh#path#common(['foo/bar/dir', 'foo/bar2']))

  AssertEquals('foo', lh#path#common(['foo/bar/dir', 'foo']))
  AssertEquals('foo/bar', lh#path#common(['foo/bar/dir', 'foo/bar']))
  AssertEquals('foo', lh#path#common(['foo/bar/dir', 'foo/bar2']))
endfunction

function! s:Test_strip_start()
  let expected = 'template/bar.template'
  AssertEquals (lh#path#strip_start($HOME.'/.vim/template/bar.template',
        \ [ $HOME.'/.vim', $HOME.'/vimfiles', '/usr/local/share/vim' ])
        \ , expected)

  AssertEquals (lh#path#strip_start($HOME.'/vimfiles/template/bar.template',
        \ [ $HOME.'/.vim', $HOME.'/vimfiles', '/usr/local/share/vim' ])
        \ , expected)

  AssertEquals (lh#path#strip_start('/usr/local/share/vim/template/bar.template',
        \ [ $HOME.'/.vim', $HOME.'/vimfiles', '/usr/local/share/vim' ])
        \ , expected)
endfunction

function! s:Test_IsAbsolutePath()
  " nix paths
  Assert lh#path#is_absolute_path('/usr/local')
  Assert lh#path#is_absolute_path($HOME)
  Assert ! lh#path#is_absolute_path('./usr/local')
  Assert ! lh#path#is_absolute_path('.usr/local')

  " windows paths
  Assert lh#path#is_absolute_path('e:\usr\local')
  Assert ! lh#path#is_absolute_path('.\usr\local')
  Assert ! lh#path#is_absolute_path('.usr\local')

  " UNC paths
  Assert lh#path#is_absolute_path('\\usr\local')
  Assert lh#path#is_absolute_path('//usr/local')
endfunction

function! s:Test_IsURL()
  " nix paths
  Assert ! lh#path#is_url('/usr/local')
  Assert ! lh#path#is_url($HOME)
  Assert ! lh#path#is_url('./usr/local')
  Assert ! lh#path#is_url('.usr/local')

  " windows paths
  Assert ! lh#path#is_url('e:\usr\local')
  Assert ! lh#path#is_url('.\usr\local')
  Assert ! lh#path#is_url('.usr\local')

  " UNC paths
  Assert ! lh#path#is_url('\\usr\local')
  Assert ! lh#path#is_url('//usr/local')

  " URLs
  Assert lh#path#is_url('http://www.usr/local')
  Assert lh#path#is_url('https://www.usr/local')
  Assert lh#path#is_url('ftp://www.usr/local')
  Assert lh#path#is_url('sftp://www.usr/local')
  Assert lh#path#is_url('dav://www.usr/local')
  Assert lh#path#is_url('fetch://www.usr/local')
  Assert lh#path#is_url('file://www.usr/local')
  Assert lh#path#is_url('rcp://www.usr/local')
  Assert lh#path#is_url('rsynch://www.usr/local')
  Assert lh#path#is_url('scp://www.usr/local')
endfunction

function! s:Test_ToRelative()
  let pwd = getcwd()
  AssertEquals(lh#path#to_relative(pwd.'/foo/bar'), 'foo/bar')
  AssertEquals(lh#path#to_relative(pwd.'/./foo'), 'foo')
  AssertEquals(lh#path#to_relative(pwd.'/foo/../bar'), 'bar')

  " Does not work yet as it returns an absolute path it that case
  AssertEquals(lh#path#to_relative(pwd.'/../bar'), '../bar')
endfunction

function! s:Test_relative_path()
  AssertEquals(lh#path#relative_to('foo/bar/dir', 'foo'), '../../')
  AssertEquals(lh#path#relative_to('foo', 'foo/bar/dir'), 'bar/dir/')
  AssertEquals(lh#path#relative_to('foo/bar', 'foo/bar2/dir'), '../bar2/dir/')

  let pwd = getcwd()
  AssertEquals(lh#path#relative_to(pwd ,pwd.'/../bar'), '../bar/')
endfunction

function! s:Test_search_vimfiles()
  let expected_win = $HOME . '/vimfiles'
  let expected_nix = $HOME . '/.vim'
  let what =  lh#path#to_regex($HOME.'/').'\(vimfiles\|.vim\)'
  " Comment what
  let z = lh#path#find(&rtp,what)
  if has('win16')||has('win32')||has('win64')
    AssertEquals(z, expected_win)
  else
    AssertEquals(z, expected_nix)
  endif
endfunction

function! s:Test_path_depth()
  AssertEquals(0, lh#path#depth('.'))
  AssertEquals(0, lh#path#depth('./'))
  AssertEquals(0, lh#path#depth('.\'))
  AssertEquals(1, lh#path#depth('toto'))
  AssertEquals(1, lh#path#depth('toto/'))
  AssertEquals(1, lh#path#depth('toto\'))
  AssertEquals(1, lh#path#depth('toto/.'))
  AssertEquals(1, lh#path#depth('toto\.'))
  AssertEquals(1, lh#path#depth('toto/./.'))
  AssertEquals(1, lh#path#depth('toto\.\.'))
  AssertEquals(0, lh#path#depth('toto/..'))
  AssertEquals(1, lh#path#depth('toto/../titi'))
  AssertEquals(0, lh#path#depth('toto/../../titi'))
  AssertEquals(1, lh#path#depth('toto/../../titi/tutu'))
  if exists('+shellslash')
    AssertEquals(0, lh#path#depth('toto\..'))
  endif
  AssertEquals(2, lh#path#depth('toto/titi/'))
  AssertEquals(2, lh#path#depth('toto\titi\'))
  AssertEquals(2, lh#path#depth('/toto/titi/'))
  AssertEquals(2, lh#path#depth('c:/toto/titi/'))
  AssertEquals(2, lh#path#depth('c:\toto/titi/'))
" todo: make a choice about "negative" paths like "../../foo"
  AssertEquals(-1, lh#path#depth('../../foo'))
endfunction

function! s:Test_dirnames()
  let sl = lh#path#shellslash()
  AssertEquals('foo'.sl,          lh#path#to_dirname('foo'))
  AssertEquals('foo/',            lh#path#to_dirname('foo/'))
  AssertEquals('foo\',            lh#path#to_dirname('foo\'))
  AssertEquals('bar'.sl.'foo'.sl, lh#path#to_dirname('bar'.sl.'foo'))
  AssertEquals('bar/foo/',        lh#path#to_dirname('bar/foo/'))
  AssertEquals('bar\foo\',        lh#path#to_dirname('bar\foo\'))

  AssertEquals('foo',             lh#path#remove_dir_mark('foo'.sl))
  AssertEquals('foo',             lh#path#remove_dir_mark('foo/'))
  AssertEquals('foo',             lh#path#remove_dir_mark('foo\'))
  AssertEquals('bar'.sl.'foo',    lh#path#remove_dir_mark('bar'.sl.'foo'.sl))
  AssertEquals('bar/foo',         lh#path#remove_dir_mark('bar/foo/'))
  AssertEquals('bar\foo',         lh#path#remove_dir_mark('bar\foo\'))

  AssertEquals('',                lh#path#remove_dir_mark(''))
  " The behaviour of the following call may change in the future.
  AssertEquals('',                lh#path#remove_dir_mark(sl))
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
