"=============================================================================
" File:         autoload/lh/encoding.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      4.5.0
let s:k_version = 450
" Created:      21st Feb 2008
" Last Update:  18th Jun 2018
"------------------------------------------------------------------------
" Description:
"       Defines functions that help managing various encodings
"
"------------------------------------------------------------------------
" History:
"       v4.5.0
"       (*) ENH: Add functions to detect available glyphs
"       v3.6.1
"       (*) ENH: Use new logging framework
"       v3.0.0:
"       (*) GPLv3
"       v2.2.2:
"       (*) new mb_strings functions: strlen, strpart, at
"       v2.0.7:
"       (*) lh#encoding#Iconv() copied from map-tools
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#encoding#version()
  return s:k_version
endfunction

" # Debug {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#encoding#verbose(...)
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

function! lh#encoding#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" Function: lh#encoding#iconv(expr, from, to)  " {{{2
" Unlike |iconv()|, this wrapper returns {expr} when we know no convertion can
" be acheived.
function! lh#encoding#iconv(expr, from, to)
  " call Dfunc("s:ICONV(".a:expr.','.a:from.','.a:to.')')
  if has('multi_byte') &&
        \ ( has('iconv') || has('iconv/dyn') ||
        \ ((a:from=~'latin1\|utf-8') && (a:to=~'latin1\|utf-8')))
    " call confirm('encoding: '.&enc."\nto:".a:to, "&Ok", 1)
    " call Dret("s:ICONV convert=".iconv(a:expr, a:from, a:to))
    return iconv(a:expr,a:from,a:to)
  else
    " Cannot convert
    " call Dret("s:ICONV  no convert=".a:expr)
    return a:expr
  endif
endfunction


" Function: lh#encoding#at(mb_string, i) " {{{2
" @return i-th character in a mb_string
" @parem mb_string multi-bytes string
" @param i 0-indexed position
function! lh#encoding#at(mb_string, i)
  return matchstr(a:mb_string, '.', 0, a:i+1)
endfunction

" Function: lh#encoding#strpart(mb_string, pos, length) " {{{2
" @return {length} extracted characters from {position} in multi-bytes string.
" @parem mb_string multi-bytes string
" @param p 0-indexed position
" @param l length of the string to extract
if exists('*strcharpart')
  function! lh#encoding#strpart(mb_string, p, l)
    " call lh#assert#value(lh#encoding#strlen(a:mb_string)).is_ge(a:p+a:l)
    return strcharpart(a:mb_string, a:p, a:l)
  endfunction
else
  function! lh#encoding#strpart(mb_string, p, l)
    " call lh#assert#value(lh#encoding#strlen(a:mb_string)).is_ge(a:p+a:l)
    return matchstr(a:mb_string, '.\{,'.a:l.'}', 0, a:p+1)
  endfunction
endif

" Function: lh#encoding#strlen(mb_string) " {{{2
" @return the length of the multi-bytes string.
function! lh#encoding#strlen(mb_string)
  return strlen(substitute(a:mb_string, '.', 'a', 'g'))
endfunction

" Function: lh#encoding#previous_character() {{{2
function! lh#encoding#previous_character() abort
  return matchstr(getline('.'), '.\%'.col('.').'c')
endfunction

" Function: lh#encoding#current_character() {{{2
function! lh#encoding#current_character() abort
  return matchstr(getline('.'), '\%'.col('.').'c.')
endfunction

" Function: lh#encoding#does_support(chars [, fonts=&guifont]) {{{2
function! lh#encoding#does_support(chars, ...) abort " {{{3
  if ! lh#python#external_can_import('fontconfig') | return lh#option#unset('Cannot use python-fontconfig packet') | endif
  return call('s:does_support', [a:chars + a:000])
endfunction

let s:script_dir = expand('<sfile>:p:h')
function! s:check_does_support_with_python_fontconfig(chars, ...) abort " {{{3
  if ! lh#python#external_can_import('fontconfig')
    call s:Verbose('Abort: Cannot use fontconfig though python')
    return {}
  endif
  " TODO: support passing a true regex as "fonts"

  let def_font = has('gui_running') ? substitute(&guifont, '\s\+\d\+$\|:.*$', '', '') : ''
  let font_list = get(a:, 1, [def_font])
  if empty(font_list) ||empty(font_list[0])
    call s:Verbose('Abort: font list is empty')
    return {}
  endif
  let fonts = '('.escape(join(font_list, '|'), '|\.*+').')'
  " echomsg fonts
  " Some shells don't support passing UTF-8 glyphs through system() => convert
  " them to "U+{hexa}" from
  let chars = map(copy(a:chars), "v:val =~ '\\M^U+' ? v:val : printf('U+%x',char2nr(v:val))")
  " Use an external script to not rely on the current implementation of python
  let cmd = shellescape(s:script_dir.'/encoding_does_support.py').' '.shellescape(&enc).' '.shellescape(fonts).' '
        \ .join(map(chars, 'shellescape(v:val)'), ' ')
  " let g:cmd = cmd
  let res = eval(lh#os#system(cmd))
  if has_key(res, '_error')
    call s:Verbose('Error: %1', res._error)
    return {}
  endif
  return res
endfunction

function! s:check_does_support_with_cached_screenchar(chars, ...) abort " {{{3
  " Doesn't return anything usefull on cygwin-vim, vim-win64,
  " vim-linux64...
  " => returns the codepoint, independently of the current font
  " let g:chars = a:chars
  let res = {}
  try
    tabnew
    call setline(1, join(a:chars, ''))
    let line = map(range(1,virtcol('$')-1), 'screenchar(1,v:val)')
    call lh#assert#value(len(line)).eq(eval(join(map(copy(a:chars), 'strwidth(v:val)'),'+')))
    " call map(copy(a:chars), 'extend(res, {v:val: char2nr(v:val) == line[v:key]})')
    " TODO: support glyphs with strwidth > 1
    let idx = 1
    for c in a:chars
      call extend(res, {c: screenchar(1,idx) == char2nr(c)})
      let idx += strwidth(c)
    endfor
    undo
  finally
    tabclose
  endtry
  return res
endfunction

function! s:does_support(chars, ...) abort " {{{3
  let res = call('s:check_does_support_with_python_fontconfig', [a:chars]+a:000)
  " if empty(res)
  "   " This doesn't permit to know anything...
  "   let res = call('s:check_does_support_with_cached_screenchar', [a:chars]+a:000)
  " endif
  return res
endfunction

" Function: lh#encoding#find_best_glyph(caller, glyphs...) {{{2
" Expect last sequence to be in ASCII
function! lh#encoding#find_best_glyph(plugin_name, ...) abort
  " call lh#assert#value(a:000[*]).not().empty()
  if ! has('multi_byte') || &enc!='utf-8' || ! lh#python#external_can_import('fontconfig')
    return map(copy(a:000), 'v:val[-1]')
  endif

  let glyphs = []
  call map(copy(a:000), 'extend(glyphs, v:val[:-2])')
  let glyph_support = s:does_support(glyphs)
  if empty(glyph_support)
    " Here, we may want to ask vim and cache the result
  endif

  let glyphs_supported = map(copy(a:000),
        \ { idx, g -> filter(g[:-2], {i2, val -> get(glyph_support, val, 0)}) + [g[-1]]})
  return lh#list#get(glyphs_supported, 0)
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
