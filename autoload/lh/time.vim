"=============================================================================
" File:         autoload/lh/time.vim                              {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      4.6.4
let s:k_version = '40604'
" Created:      01st Dec 2015
" Last Update:  18th Oct 2018
"------------------------------------------------------------------------
" Description:
"       «description»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#time#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#time#verbose(...)
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

function! lh#time#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

" # Bench {{{2
" Function: lh#time#bench(F) {{{3
if exists('*reltimefloat')
  function! lh#time#bench(F, ...) abort
    let t0 = reltime()
    let res = call(a:F, a:000)
    let t = reltime()
    return [res, reltimefloat(reltime(t0, t))]
  endfunction
elseif exists('*reltime')
  function! lh#time#bench(F, ...) abort
    let t0 = reltime()
    let res = call(a:F, a:000)
    let t = reltime()
    return [res, eval(reltimestr(reltime(t0, t)))]
  endfunction
else
  function! lh#time#bench(F, ...) abort
    let res = call(a:F, a:000)
    return [res, 0]
  endfunction
endif

" Function: lh#time#bench_n(n, F, ...) {{{3
function! lh#time#bench_n(n, F, ...) abort
  let tot = 0
  for i in range(1, a:n)
    let [res, b] = call('lh#time#bench', [a:F] + deepcopy(a:000))
    let tot += b
  endfor
  return [res, tot]
endfunction
" # Stamps {{{2
" Function: lh#time#date() {{{3
function! lh#time#date() abort
  let day   = strftime("%d")
  let mod = day % 10
  if (day / 10) == 1 | let th='th'      " 11, 12, 13
  elseif mod == 1    | let th = 'st'
  elseif mod == 2    | let th = 'nd'
  elseif mod == 3    | let th = 'rd'
  else               | let th = 'th'
  endif
  if get(g:, 'EnsureEnglishDate', 1)
    if exists('v:lc_time')
      let v_lang = v:lc_time
    else
      let v_lang = lh#askvim#exe('language time')
      let v_lang = matchstr(v_lang, '"\v%(LC_TIME\=)=\zs[a-zA-Z.0-9_-]*\ze.*"')
    endif
    silent! language time C
    " let m = substitute(strftime("%m"), '^0', '', '')
    " let month = strpart('jan feb mar apr may jun jul aug sep oct nov dec', 4*(m-1), 3)
  endif
  let month = strftime("%b")
  if get(g:, 'EnsureEnglishDate', 1)
    exe 'silent! language time '.v_lang
  endif
  let year  = strftime(" %Y")
  return day . th . ' ' . month . year
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
