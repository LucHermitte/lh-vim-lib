"=============================================================================
" $Id$
" File:		autoload/lh/option.vim                                    {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" License:      GPLv3 with exceptions
"               <URL:http://code.google.com/p/lh-vim/wiki/License>
" Version:	3.1.13
" Created:	24th Jul 2004
" Last Update:	$Date$ (07th Oct 2006)
"------------------------------------------------------------------------
" Description:
" 	Defines the global function lh#option#get().
"       Aimed at (ft)plugin writers.
" 
"------------------------------------------------------------------------
" Installation:
" 	Drop this file into {rtp}/autoload/lh/
" 	Requires Vim 7+
" History:	
"       v3.1.13
"       (*) lh#option#add() don't choke when option value contains characters that
"           means something in a regex context
"       v3.1.5
"       (*) lh#option#get() support var names from dictionaries like "g:foo.bar"
"       v3.0.0
"       (*) GPLv3
" 	v2.0.6
" 	(*) lh#option#add() add values to a vim list |option|
" 	v2.0.5
" 	(*) lh#option#get_non_empty() manages Lists and Dictionaries
" 	(*) lh#option#get() doesn't test emptyness anymore
" 	v2.0.0
" 		Code moved from {rtp}/macros/ 
" }}}1
"=============================================================================


"=============================================================================
let s:cpo_save=&cpo
set cpo&vim

"------------------------------------------------------------------------
" ## Functions {{{1
" # Debug {{{2
function! lh#option#verbose(level)
  let s:verbose = a:level
endfunction

function! s:Verbose(expr)
  if exists('s:verbose') && s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#option#debug(expr)
  return eval(a:expr)
endfunction

" # Public {{{2
" Function: lh#option#get(name, default [, scope])            {{{3
" @return b:{name} if it exists, or g:{name} if it exists, or {default}
" otherwise
" The order of the variables checked can be specified through the optional
" argument {scope}
function! lh#option#get(name,default,...)
  let scope = (a:0 == 1) ? a:1 : 'bg'
  let name = a:name
  let i = 0
  while i != strlen(scope)
    if exists(scope[i].':'.name)
      " \ && (0 != strlen({scope[i]}:{name}))
      " This syntax doesn't work with dictionaries -> !exe
      " return {scope[i]}:{name}
      exe 'return '.scope[i].':'.name
    endif
    let i += 1
  endwhile 
  return a:default
endfunction
function! lh#option#Get(name,default,...)
  let scope = (a:0 == 1) ? a:1 : 'bg'
  return lh#option#get(a:name, a:default, scope)
endfunction

function! s:IsEmpty(variable)
  if     type(a:variable) == type('string') | return 0 == strlen(a:variable)
  elseif type(a:variable) == type(42)       | return 0 == a:variable
  elseif type(a:variable) == type([])       | return 0 == len(a:variable)
  elseif type(a:variable) == type({})       | return 0 == len(a:variable)
  else                                      | return false
  endif
endfunction

" Function: lh#option#get_non_empty(name, default [, scope])  {{{3
" @return of b:{name}, g:{name}, or {default} the first which exists and is not empty 
" The order of the variables checked can be specified through the optional
" argument {scope}
function! lh#option#get_non_empty(name,default,...)
  let scope = (a:0 == 1) ? a:1 : 'bg'
  let name = a:name
  let i = 0
  while i != strlen(scope)
    if exists(scope[i].':'.name) && !s:IsEmpty({scope[i]}:{name})
      return {scope[i]}:{name}
    endif
    let i += 1
  endwhile 
  return a:default
endfunction
function! lh#option#GetNonEmpty(name,default,...)
  let scope = (a:0 == 1) ? a:1 : 'bg'
  return lh#option#get_non_empty(a:name, a:default, scope)
endfunction

" Function: lh#option#add(name, values)                       {{{3
" Add fields to a vim option.
" @param values list of values to add
" @example let lh#option#add('l:tags', ['.tags'])
function! lh#option#add(name,values)
  let values = type(a:values) == type([])
        \ ? copy(a:values)
        \ : [a:values]
  let old = split(eval('&'.a:name), ',')
  let new = filter(values, 'match(old, escape(v:val, "\\*.")) < 0')
  let val = join(old+new, ',')
  exe 'let &'.a:name.' = val'
endfunction

" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
