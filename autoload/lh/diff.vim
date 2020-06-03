"=============================================================================
" File:         autoload/lh/diff.vim                              {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/blob/master/License.md>
" Version:      5.1.2.
let s:k_version = '512'
" Created:      29th Apr 2020
" Last Update:  03rd Jun 2020
"------------------------------------------------------------------------
" Description:
"       Portable API to return diff between two files/set of lines
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:
" - Support 'diffoptions' or user provided options
" - Support older versions of Vim! (lambda are used)
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#diff#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#diff#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Log(expr, ...) abort
  call call('lh#log#this',[a:expr]+a:000)
endfunction

function! s:Verbose(expr, ...) abort
  if s:verbose
    call call('s:Log',[a:expr]+a:000)
  endif
endfunction

function! lh#diff#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

" Function: lh#diff#compute(f1, f2) {{{2
" Computes the difference between two "files", either with "diff", or with
" Python difflib
" @param[in] f1 first file, or set of lines, or dictionary
" @param[in] f2 first file, or set of lines, or dictionary
" @return a |list| of lines that differ
" @since version 5.1.0
"
" The dictionary format is:
" - "file": filename
" - "lines": list of lines
" - "name": text to display when using Python
" At least "file" or "lines" shall be set.
function! lh#diff#compute(f1, f2) abort
  let f1 = s:enrich_options(a:f1)
  let f2 = s:enrich_options(a:f2)

  if exists(':pyx') && lh#python#can_import('difflib')
    return lh#diff#_compute_pydiff(f1, f2)
  elseif executable('diff') && has('unix') " && lh#has#lambda()
    " TODO: remove the dependance to lambdas!
    return lh#diff#_compute_nixdiff(f1, f2)
  else
    return lh#option#unset('Cannot compute difference on this machine')
  endif
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

function! s:enrich_options(f) abort
  if     type(a:f) == type({}) | return a:f
  elseif type(a:f) == type([]) | return {'lines': a:f}
  elseif type(a:f) == type('') | return {'file':  a:f}
  else
    call lh#assert#unexpected('Invalid option for see ":h lh#diff#compute()"')
  endif
endfunction

function! s:tmpfile(lines) abort " {{{2
  let f = tempname()
  call writefile(a:lines, f)
  return f
endfunction

" Function: lh#diff#_compute_nixdiff(f1, f2) {{{2
function! lh#diff#_compute_nixdiff(f1, f2) abort
  let cleanup = lh#on#exit()
  try
    if !has_key(a:f1, 'file') || !filereadable(a:f1.file)
      let f1 = s:tmpfile(a:f1.lines)
      " call cleanup.register({-> delete(f1)})
      " call cleanup.register({'object': f1, 'method': 'delete'})
      call cleanup.register(printf('call delete("%s")', f1))
    else
      let f1 = a:f1.file
    endif
    if !has_key(a:f2, 'file') || !filereadable(a:f2.file)
      let f2 = s:tmpfile(a:f2.lines)
      " call cleanup.register({-> delete(f2)})
      " call cleanup.register({'object': f2, 'method': 'delete'})
      call cleanup.register(printf('call delete("%s")', f2))
    else
      let f2 = a:f2.file
    endif
    let res = lh#os#system('diff -Naub '.lh#path#fix(f1).' '.lh#path#fix(f2))
    return split(res, "\n")
  finally
    call cleanup.finalize()
  endtry
endfunction

" Function: lh#diff#_compute_pydiff(f1, f2) {{{2
function! lh#diff#_compute_pydiff(f1, f2) abort
pyx <<EOF
import vim
import difflib
def getfirst(d, keys, default=None):
  for k in keys:
    if k in d:
      return d[k]
  return default

def getlines(f):
  if 'lines' in f:
    return f['lines']
  assert('file' in f)
  return vim.eval('readfile("'+f['file']+'")')

def mydiff(f1, f2):
  kw = {}
  c1 = getlines(f1)
  c2 = getlines(f2)
  kw['fromfile'] = getfirst(f1, ['text', 'file'], '')
  kw['tofile']   = getfirst(f2, ['text', 'file'], '')
  d = difflib.unified_diff(c1, c2, **kw)
  # d = difflib.context_diff(c1, c2, **kw)
  d = [l.rstrip() for l in d]
  return d
  vim.command('let res = '+str(list(d)))
EOF
  return pyxeval('mydiff(vim.eval("a:f1"), vim.eval("a:f2"))')
endfunction

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
