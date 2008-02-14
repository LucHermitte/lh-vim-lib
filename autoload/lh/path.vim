"=============================================================================
" $Id$
" File:		path.vim                                           {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" Version:	2.0.5
" Created:	23rd Jan 2007
" Last Update:	11th Feb 2008
"------------------------------------------------------------------------
" Description:	«description»
" 
"------------------------------------------------------------------------
" Installation:	«install details»
" History:	
"	v 1.0.0 First Version
" 	(*) Functions moved from searchInRuntimeTime  
" 	v 2.0.1
" 	(*) lh#path#Simplify() becomes like |simplify()| except for trailing
" 	v 2.0.2
" 	(*) lh#path#SelectOne() 
" 	(*) lh#path#ToRelative() 
" 	v 2.0.3
" 	(*) lh#path#GlobAsList() 
" 	v 2.0.4
" 	(*) lh#path#StripStart()
" 	v 2.0.5
" 	(*) lh#path#StripStart() interprets '.' as getcwd()
" TODO:		«missing features»
" }}}1
"=============================================================================


"=============================================================================
" Avoid global reinclusion {{{1
let s:cpo_save=&cpo
set cpo&vim
"=============================================================================

" Function: lh#path#Simplify({pathname}) {{{3
" Like |simplify()|, but also strip the leading './'
function! lh#path#Simplify(pathname)
  let pathname = simplify(a:pathname)
  let pathname = substitute(a:pathname, '^\%(\./\)\+', '', '')
  return pathname
endfunction
"
" Function: lh#path#StripCommon({pathnames}) {{{3
" Find the common leading path between all pathnames, and strip it
function! lh#path#StripCommon(pathnames)
  " assert(len(pathnames)) > 1
  let common = a:pathnames[0]
  let i = 1
  while i < len(a:pathnames)
    let fcrt = a:pathnames[i]
    " pathnames should not contain @
    let common = matchstr(common.'@@'.fcrt, '^\zs\(.*[/\\]\)\ze.\{-}@@\1.*$')
    if strlen(common) == 0
      " No need to further checks
      return a:pathnames
    endif
    let i = i + 1
  endwhile
  let l = strlen(common)
  let pathnames = a:pathnames
  call map(pathnames, 'strpart(v:val, '.l.')' )
  return pathnames
endfunction

" Function: lh#path#IsAbsolutePath({path}) {{{3
function! lh#path#IsAbsolutePath(path)
  return a:path =~ '^/'
	\ . '\|^[a-zA-Z]:%\(/\|\\\)'
	\ . '\|^[/\\]\{2}'
  "    Unix absolute path 
  " or Windows absolute path
  " or UNC path
endfunction

" Function: lh#path#IsURL({path}) {{{3
function! lh#path#IsURL(path)
  " todo: support UNC paths and other urls
  return a:path =~ '^\%(https\=\|s\=ftp\|dav\|fetch\|file\|rcp\|rsynch\|scp\)://'
endfunction

" Function: lh#path#SelectOne({pathnames},{prompt}) {{{3
function! lh#path#SelectOne(pathnames, prompt)
  if len(a:pathnames) > 1
    let simpl_pathnames = deepcopy(a:pathnames) 
    let simpl_pathnames = lh#path#StripCommon(simpl_pathnames)
    let simpl_pathnames = [ '&Cancel' ] + simpl_pathnames
    " Consider guioptions+=c is case of difficulties with the gui
    let selection = confirm(a:prompt, join(simpl_pathnames,"\n"), 1, 'Question')
    let file = (selection == 1) ? '' : a:pathnames[selection-2]
    return file
  elseif len(a:pathnames) == 0
    return ''
  else
    return a:pathnames[0]
  endif
endfunction

" Function: lh#path#ToRelative({pathname}) {{{3
function! lh#path#ToRelative(pathname)
  let newpath = fnamemodify(a:pathname, ':p:.')
  return newpath
endfunction

" Function: lh#path#GlobAsList({pathslist}, {expr}) {{{3
function! s:GlobAsList(pathslist, expr)
  let sResult = globpath(a:pathslist, a:expr)
  let lResult = split(sResult, '\n')
  return lResult
endfunction

function! lh#path#GlobAsList(pathslist, expr)
  if type(a:expr) == type('string')
    return s:GlobAsList(a:pathslist, a:expr)
  elseif type(a:expr) == type([])
    let res = []
    for expr in a:expr
      call extend(res, s:GlobAsList(a:pathslist, expr))
    endfor
    return res
  else
    throw "Unexpected type for a:expression"
  endif
endfunction

" Function: lh#path#StripStart({pathname}, {pathslist}) {{{3
" Strip occurrence of paths from {pathslist} in {pathname}
" @param[in] {pathname} name to simplify
" @param[in] {pathslist} list of pathname (can be a |string| of pathnames
" separated by ",", of a |List|).
function! lh#path#StripStart(pathname, pathslist)
  if type(a:pathslist) == type('string')
    " let strip_re = escape(a:pathslist, '\\.')
    " let strip_re = '^' . substitute(strip_re, ',', '\\|^', 'g')
    let pathslist = split(a:pathslist, ',')
  elseif type(a:pathslist) == type([])
    let pathslist = deepcopy(a:pathslist)
  else
    throw "Unexpected type for a:pathname"
  endif

  " apply a realpath like operation
  let nb_paths = len(pathslist) " set before the loop
  let i = 0
  while i != nb_paths
    if pathslist[i] =~ '^\.\%(/\|$\)'
      let path2 = getcwd().pathslist[i][1:]
      call add(pathslist, path2)
    endif
    let i = i + 1
  endwhile
  " replace path separators by a regex that can match them
  call map(pathslist, 'substitute(v:val, "[\\\\/]", "[\\\\/]", "g")')
  " echomsg string(pathslist)
  " escape .
  call map(pathslist, '"^".escape(v:val, ".")')
  " build the strip regex
  let strip_re = join(pathslist, '\|')
  " echomsg strip_re
  let res = substitute(a:pathname, '\%('.strip_re.'\)[/\\]\=', '', '')
  return res
endfunction

"=============================================================================
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
