"=============================================================================
" File:         tests/lh/UT-fixpath.vim                           {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      3.3.0.
let s:k_version = '330'
" Created:      19th Apr 2015
" Last Update:  19th Apr 2015
"------------------------------------------------------------------------
" Description:
"       Test lh#path#fix()
" }}}1
"=============================================================================

UTSuite [lh-vim-lib] Testing lh#path#fix

runtime autoload/lh/path.vim

let s:cpo_save=&cpo
set cpo&vim

"------------------------------------------------------------------------
function! s:CheckAgainst_fnameescape(path)
  let fpn = lh#path#fix(a:path)
  let fne = fnameescape(a:path)
  AssertTxt(fpn == fne,
        \ 'lh#path#fix('.a:path.')='.fpn. ' != fnameescape(...)='.fne)
endfunction
function! s:Test_Fix_PathName()
  call s:CheckAgainst_fnameescape('/home/myself/foo/bar')
  call s:CheckAgainst_fnameescape('c:/home/myself/foo/bar')
  " call s:CheckAgainst_fnameescape('c:\home\myself\foo\bar')
  call s:CheckAgainst_fnameescape('foo bar')
  call s:CheckAgainst_fnameescape('c:/home/myself/foo bar')
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
