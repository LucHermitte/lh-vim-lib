"=============================================================================
" File:         autoload/lh/encoding.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      3.6.1
let s:k_version = 361
" Created:      21st Feb 2008
" Last Update:  13th Jun 2018
"------------------------------------------------------------------------
" Description:
"       Defines functions that help managing various encodings
"
"------------------------------------------------------------------------
" History:
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

" Function: lh#encoding#previous_character() {{{3
function! lh#encoding#previous_character() abort
  return matchstr(getline('.'), '.\%'.col('.').'c')
endfunction

" Function: lh#encoding#current_character() {{{3
function! lh#encoding#current_character() abort
  return matchstr(getline('.'), '\%'.col('.').'c.')
endfunction

" Function: lh#encoding#does_support(chars [, fonts=&guifont]) {{{3
function! lh#encoding#does_support(chars, ...) abort
  if ! lh#python#can_import('fontconfig') | return lh#option#unset('Cannot use python-fontconfig packet') | endif
  let fonts = '('.escape(join(get(a:, 1, [substitute(&guifont, '\s\+\d\+$', '', '')]), '|'), '|\.*+').')'
  " echomsg fonts
  let res = {}
python << EOF
import fontconfig, re, sys, vim

# https://stackoverflow.com/questions/22665667/python-2-7-6-splits-single-high-unicode-code-point-in-two
def code_points(text):
    import struct
    utf32 = text.encode('UTF-32LE')
    return struct.unpack('<{}I'.format(len(utf32) // 4), utf32)

regexp = re.compile(vim.bindeval('l:')['fonts'])
chars  = vim.bindeval('a:')['chars']
fonts = fontconfig.query()
fonts = [path for path in fonts if re.search(regexp, path) ]
enc = vim.eval('&enc')
res = vim.bindeval('l:')['res']

for c in chars:
    #if c.startswith('U+'):
    #    c =  ('\\U%08x' % int(search[2:], 16)).decode('unicode-escape')
    #else:
    #    c = c.decode(enc)
    # print(c)
    c_dec = c.decode(enc) if isinstance(c, bytes) else c
    cp = code_points(c_dec)
    # print(cp)
    if sys.maxunicode < cp[0]:
        # With some python versions, we cannot decode "high" unicode code points
        # even if the CP has a glyph in the current fontset :(
        res.update({c: 0})
        continue
    for path in fonts:
        font = fontconfig.FcFont(path)
        # print('%s ' % (c_dec, ))
        if font.has_char(c_dec):
            # print('%s -> OK in %s' % (c_dec, font))
            res.update({c: 1})
            break
    else:
      res.update({c: 0})
EOF
  return res
endfunction

" Function: lh#encoding#find_best_glyph(glyphs...) {{{3
" Expect last sequence to be in ASCII
function! lh#encoding#find_best_glyph(...) abort
  " call lh#assert#value(a:000[*]).not().empty()
  if ! has('multi_byte') || &enc!='utf-8' || ! lh#python#can_import('fontconfig')
    return map(copy(a:000), 'v:val[-1]')
  endif
  let glyphs = []
  call map(copy(a:000), 'extend(glyphs, v:val[:-2])')
  " let glyphs = a:glyphs[: -2]
  let glyph_support = lh#encoding#does_support(glyphs)
  let glyphs_supported = map(copy(a:000),
        \ { idx, g -> filter(g[:-2], {i2, val -> get(glyph_support, val, 0)}) + [g[-1]]})
  return lh#list#get(glyphs_supported, 0)
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
