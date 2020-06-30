"=============================================================================
" File:         autoload/lh/vcs.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      5.2.0
let s:k_version = '5.02.0'
" Created:      11th Mar 2015
" Last Update:  01st Jul 2020
"------------------------------------------------------------------------
" Description:
"       API VCS detection
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#vcs#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#vcs#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Log(...)
  call call('lh#log#this', a:000)
endfunction

function! s:Verbose(...)
  if s:verbose
    call call('s:Log', a:000)
  endif
endfunction

function! lh#vcs#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

" # VCS root detection {{{2

" Function: lh#vcs#get_svn_root([path]) {{{3
function! lh#vcs#get_svn_root(...) abort
  let path = a:0 == 0 ? expand('%:p:h') : a:1
  return finddir('.svn', path. ';')
endfunction

" Function: lh#vcs#get_git_root([path]) {{{3
function! lh#vcs#get_git_root(...) abort
  let path = a:0 == 0 ? expand('%:p:h') : a:1
  return finddir('.git', path. ';')
endfunction

" # VCS kind detection {{{2

" Function: lh#vcs#is_svn([path]) {{{3
function! lh#vcs#is_svn(...) abort
  let path = a:0 == 0 ? expand('%:p:h') : a:1
  return !empty(lh#vcs#get_svn_root(path))
endfunction

" Function: lh#vcs#is_git([path]) {{{3
function! lh#vcs#is_git(...) abort
  let path = a:0 == 0 ? expand('%:p:h') : a:1
  return !empty(lh#vcs#get_git_root(path))
endfunction

" Function: lh#vcs#get_type([path]) {{{3
function! lh#vcs#get_type(...) abort
  let path = a:0 == 0 ? expand('%:p:h') : a:1
  let kind
        \ = exists('*VCSCommandGetVCSType') ?  substitute(VCSCommandGetVCSType(path), '.', '\l&', 'g')
        \ : lh#vcs#is_svn(path)             ? 'svn'
        \ : lh#vcs#is_git(path)             ? 'git'
        \ :                                   'unknown'
  return kind
endfunction

" # VCS URL decoding {{{2

" Function: lh#vcs#get_url() {{{3
function! lh#vcs#get_url(...) abort
  let cd
        \ = a:0 == 0               ? ''
        \ :                          'cd ' . lh#path#fix(a:1) . ' && '
  if lh#vcs#is_git()
    let url = lh#os#system(cd.'git config --get remote.origin.url', 0)
    return url
  else
    return lh#option#unset()
  endif
endfunction

" Function: lh#vcs#decode_github_url(url) {{{3
" Regex stolen and adapted from fugitive
function! lh#vcs#decode_github_url(url) abort
  let domain_pattern = 'github\.com'
  let domains = exists('g:fugitive_github_domains') ? g:fugitive_github_domains : []
  let domains += ['[^/]\+'] " Let's decode any domain!
  for domain in domains
    let domain_pattern .= '\|' . escape(split(domain, '://')[-1], '.')
  endfor
  let repo = matchlist(a:url, '^\%(\(ssh\)://\|https\=://\|git://\|git@\)\=\zs\(\%(\1\.\)\='.domain_pattern.'\)[/:]\(.\{-}\)/\(.\{-\}\)\ze\%(\.git\)\=$')
  return !empty(repo) ? lh#list#subset(repo, [1, 3,4]) : []
endfunction

" Function: lh#vcs#as_http(...) {{{3
function! lh#vcs#as_http(...) abort
  let url = ''
  try
    let url = call('lh#vcs#get_url', a:000)
    if lh#vcs#is_git()
      let repo = lh#vcs#decode_github_url(url)
      if !empty(repo)
        return 'http://github.com/'.repo[1].'/'.repo[2]
      endif
    endif
  catch /.*/
  endtry
  if !empty(url)
    return url
  else
    return get(g:, 'url', lh#marker#txt('repo_url'))
  endif
endfunction
"------------------------------------------------------------------------
" ## Internal functions {{{1

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
