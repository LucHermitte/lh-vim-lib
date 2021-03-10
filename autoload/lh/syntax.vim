"=============================================================================
" File:		autoload/lh/syntax.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:	5.3.2
let s:k_version = 5.3.2
" Created:	05th Sep 2007
" Last Update:	10th Mar 2021
"------------------------------------------------------------------------
" Description:	«description»
"
"------------------------------------------------------------------------
" TODO:
" 	function, to inject "contained", see lhVimSpell approach
"
" Issue: {{{2
" While typing new text, synID at current position isn't set yet when using
" i_CTRL-R=
" e.g. (where "^" marks the cursor position, in C++ code, '><' marks correct
" solution, 'WW' marks incorrect solution)
" * iab-<expr> case: everything works fine
"           synId(col)           synID(col-1)     synstack(col)        synstack(col-1)
"   //^     W''W                 >'cCommentL'<    W'cBlock'W           >'cCommentL' <
"   /**/^   >''<                 >''         <    >'cBlock'<           >'cBlock'    <
"   /*^*/   >'cCommentStart'<    >'cComment' <    >'cCommentStart'<    >'cComment'  <
"
" inoreab <buffer> <expr> µ printf("'%s'  '%s'  '%s'  '%s'", synIDattr(synID(line('.'),col('.'),1),'name'), synIDattr(synID(line('.'),col('.')-1,1),'name'), synIDattr(synstack(line('.'),col('.'))[-1], 'name'), synIDattr(synstack(line('.'),col('.')-1)[-1], 'name'))
"
" * iab <c-r>= case: where problems occur
"           synId(col)           synID(col-1)         synstack(col)        synstack(col-1)
"   //^     W''>                 >'cCommentL'<        W'cBlock'W           >'cCommentL'<
"   /**/^   >''<                 W'cCommentStart'W    >'cBlock'<           W'cCommentStart'W
"   /**/ ^  >''<                 >''<                 >'cBlock'<           >'cBlock'<
"   /*^*/   >'cCommentStart'<    >'cCommentStart'<    >'cCommentStart'<    >'cCommentStart'<
"
"  inoreab <silent> <buffer> µ <c-r>=printf("'%s'  '%s'  '%s'  '%s'", synIDattr(synID(line('.'),col('.'),1),'name'), synIDattr(synID(line('.'),col('.')-1,1),'name'), synIDattr(synstack(line('.'),col('.'))[-1], 'name'), synIDattr(synstack(line('.'),col('.')-1)[-1], 'name'))<cr>
"
" Unfortunatelly, we cannot use iab-<expr> as we need to move the cursor
" around...
"
" }}}1
"=============================================================================


"=============================================================================
let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#syntax#version()
  return s:k_version
endfunction

" # Debug {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#syntax#verbose(...)
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

function! lh#syntax#debug(expr) abort
  return eval(a:expr)
endfunction

" # Misc {{{2
function! s:getSID() abort
  return eval(matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_getSID$'))
endfunction
let s:k_script_name      = s:getSID()

"=============================================================================
" ## Functions {{{1
" # Public {{{2
" Functions: Show name of the syntax kind of a character               {{{3
function! lh#syntax#name_at(l,c, ...)
  let what = a:0 > 0 ? a:1 : 0
  return synIDattr(synID(a:l, a:c, what),'name')
endfunction
function! lh#syntax#NameAt(l,c, ...)
  let what = a:0 > 0 ? a:1 : 0
  return lh#syntax#name_at(a:l, a:c, what)
endfunction

function! lh#syntax#name_at_mark(mark, ...)
  let what = a:0 > 0 ? a:1 : 0
  return lh#syntax#name_at(line(a:mark), col(a:mark), what)
endfunction
function! lh#syntax#NameAtMark(mark, ...)
  let what = a:0 > 0 ? a:1 : 0
  return lh#syntax#name_at_mark(a:mark, what)
endfunction

" Functions: skip string, comment, character, doxygen                  {{{3
func! lh#syntax#skip_at(l,c)
  return lh#syntax#name_at(a:l,a:c) =~? '\vstring|comment|character|doxygen'
endfun
func! lh#syntax#SkipAt(l,c)
  return lh#syntax#skip_at(a:l,a:c)
endfun

func! lh#syntax#skip()
  return lh#syntax#skip_at(line('.'), col('.'))
endfun
func! lh#syntax#Skip()
  return lh#syntax#skip()
endfun

func! lh#syntax#skip_at_mark(mark)
  return lh#syntax#skip_at(line(a:mark), col(a:mark))
endfun
func! lh#syntax#SkipAtMark(mark)
  return lh#syntax#skip_at_mark(a:mark)
endfun

" Command: :SynShow Show current syntax kind                           {{{3
command! SynShow echo 'hi<'.lh#syntax#name_at_mark('.',1).'> trans<'
      \ lh#syntax#name_at_mark('.',0).'> lo<'.
      \ synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name').'>   ## '
      \ map(synstack(line("."), col(".")), 'synIDattr(v:val, "name")')

" Function: lh#syntax#list_raw(name) : string                          {{{3
function! lh#syntax#list_raw(name)
  let a_save = @a
  try
    redir @a
    exe 'silent! syn list '.a:name
    redir END
    let res = @a
  finally
    let @a = a_save
  endtry
  return res
endfunction

" Function: lh#syntax#list(name) : List                                {{{3
function! lh#syntax#list(name)
  let raw = lh#syntax#list_raw(a:name)
  let res = []
  let lines = split(raw, '\n')
  let started = 0
  for l in lines
    if started
      let li = (l =~ 'links to') ? '' : l
    elseif l =~ 'xxx'
      let li = matchstr(l, 'xxx\s*\zs.*')
      let started = 1
    else
      let li = ''
    endif
    if !empty(li)
      let li = substitute(li, 'contained\S*\|transparent\|nextgroup\|skipwhite\|skipnl\|skipempty', '', 'g')
      let kinds = split(li, '\s\+')
      call extend(res, kinds)
    endif
  endfor
  return res
endfunction

" Function: lh#syntax#match_at(syn_pattern, l, c) : bool               {{{3
" @since Version 4.0.0
function! lh#syntax#match_at(syn_pattern, l, c) abort
  try
    let stack = synstack(a:l, a:c)
    let names = map(stack, 'synIDattr(v:val, "name")')
    let idx = match(names, a:syn_pattern)
    return idx >= 0
  catch /.*/
    throw "Cannot fetch synstack at line:".a:l.", col:".a:c
  endtry
  return 0
endfunction

" Function: lh#syntax#is_a_comment(mark) : bool                        {{{3
function! lh#syntax#is_a_comment(mark) abort
  return lh#syntax#is_a_comment_at(line(a:mark), col(a:mark))
endfunction

" Function: lh#syntax#is_a_comment_at(l,c) : bool                      {{{3
function! lh#syntax#is_a_comment_at(l,c) abort
  return lh#syntax#match_at('\c\vcomment|doxygen', a:l, a:c)
endfunction

" Function: lh#syntax#next_hl({name},[{trans}=1])                      {{{3
" @param {name}    Name of the highlight group
" @param {trans}   See |synID()| -> {trans} ; default = 1
" @return 1 if found, 0 otherwose
" @post move the cursor to the next word which highlight group has {name} for
" name.
function! lh#syntax#next_hl(name, ...) abort
  " Facultative parameters
  let trans = (a:0 > 0) ? a:1 : 1

  " Cache the searched group id
  let groupid = hlID(a:name)
  " Remember where the search started
  let lastline= line("$")
  let curcol  = 0
  let pos = line('.').'normal! '.virtcol('.').'|'

  silent! norm! w

  " skip words until we find next error
  while synID(line("."),col("."),trans) != groupid
    silent! norm! w
    if line(".") == lastline
      let prvcol=curcol
      let curcol=col(".")
      if curcol == prvcol
        exe pos
        " call s:ErrorMsg ('No other catch() by value found')
        return 0
      endif
    endif
  endwhile
  return 1
endfunction

" Function: lh#syntax#prev_hl({name},[{trans}=1])                      {{{3
" @param {name}    Name of the highlight group
" @param {trans}   See |synID()| -> {trans} ; default = 1
" @return 1 if found, 0 otherwose
" @post move the cursor to the previous word which highlight group has {name}
" for name.
function! lh#syntax#prev_hl(name, ...) abort
  " Facultative parameters
  let trans = (a:0 > 0) ? a:1 : 1

  " Cache the searched group id
  let groupid = hlID(a:name)
  " Remember where the search started
  let curcol  = 0
  let pos = line('.').'normal! '.virtcol('.').'|'

  silent! norm! b

  " skip words until we find next error
  while synID(line("."),col("."),trans) != groupid
    silent! norm! b
    if line(".") == 1
      let prvcol=curcol
      let curcol=col(".")
      if curcol == prvcol
        exe pos
        " call s:ErrorMsg ('No other catch() by value found')
        return 0
      endif
    endif
  endwhile
  return 1
endfunction

" Function: lh#syntax#getline_not_matching(linenr, syn_pattern) : string {{{3
" @since Version 4.0.0
" @warning col(['.', '$']) doesn't work!, so linenr shall be a number
function! lh#syntax#getline_not_matching(linenr, syn_pattern) abort
  call lh#assert#type(a:linenr).is(42)
  let valid =  map(range(col([a:linenr, '$'])-1), '! lh#syntax#match_at(a:syn_pattern, a:linenr, v:val+1) ? v:val : -1')
  call filter(valid, 'v:val >= 0')
  let line = getline(a:linenr)
  " join is required to merge bytes back into multibyte-characters
  let res = join(map(copy(valid), 'line[v:val]'), '')
  return res
endfunction

" Function: lh#syntax#getline_matching(linenr, syn_pattern) : string {{{3
" @since Version 4.0.0
" @warning col(['.', '$']) doesn't work!, so linenr shall be a number
" @warning This could be quite slow :( ...
function! lh#syntax#getline_matching(linenr, syn_pattern) abort
  " call lh#assert#type(a:linenr).is(42)
  let valid =  map(range(col([a:linenr, '$'])-1), 'lh#syntax#match_at(a:syn_pattern, a:linenr, v:val+1) ? v:val : -1')
  call filter(valid, 'v:val >= 0')
  let line = getline(a:linenr)
  " join is required to merge bytes back into multibyte-characters
  let res = join(map(copy(valid), 'line[v:val]'), '')
  return res
endfunction

" Function: lh#syntax#line_filter(syn_pattern) : object {{{3
function! s:match(id) dict abort " {{{4
  if has_key(self.ids, a:id)
    return self.ids[a:id]
  endif
  let name = synIDattr(a:id, "name")
  let self.ids[a:id] = match(name, self.pattern) >= 0
  return self.ids[a:id]
endfunction

function! s:getline_matching(linenr) dict abort " {{{4
  let valid =  map(range(col([a:linenr, '$'])-1), 'self.match(synID(a:linenr, v:val+1, 1)) ? v:val : -1')
  call filter(valid, 'v:val >= 0')
  let line = getline(a:linenr)
  let res = join(map(copy(valid), 'line[v:val]'), '')
  return res
endfunction

function! s:getline_not_matching(linenr) dict abort " {{{4
  let valid =  map(range(col([a:linenr, '$'])-1), '! self.match(synID(a:linenr, v:val+1, 1)) ? v:val : -1')
  call filter(valid, 'v:val >= 0')
  let line = getline(a:linenr)
  let res = join(map(copy(valid), 'line[v:val]'), '')
  return res
endfunction

function! lh#syntax#line_filter(syn_pattern) abort " {{{4
  let obj = lh#object#make_top_type({})
  let obj.pattern = a:syn_pattern
  let obj.ids = {}

  call lh#object#inject_methods(obj, s:k_script_name, ['match', 'getline_matching', 'getline_not_matching'])

  return obj
endfunction

" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
