"=============================================================================
" $Id$
" File:		function.vim                                           {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" Version:	2.2.0
" Created:	03rd Nov 2008
" Last Update:	$Date$
"------------------------------------------------------------------------
" Description:	
" 	Implements:
" 	- lh#function#bind()
" 	- lh#function#execute()
" 	- a binded function type
" 
"------------------------------------------------------------------------
" Installation:	
" 	Drop it into {rtp}/autoload/lh/
" 	Vim 7+ required.
" History:	«history»
" TODO:		«missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------

" ## Functions {{{1
" # Debug {{{2
function! lh#function#verbose(level)
  let s:verbose = a:level
endfunction

function! s:Verbose(expr)
  if exists(s:verbose) && s:verbose
    echomsg a:expr
  endif
endfunction

" # Function: s:join(arguments...) {{{2
function! s:Join(args)
  let res = ''
  if len(a:args) > 0
    let res = string(a:args[0])
    let i = 1
    while i != len(a:args)
      let res.=','.string(a:args[i])
      let i += 1
    endwhile
  endif
  return res
endfunction

" # Function: s:DoBindList(arguments...) {{{2
function! s:DoBindList(formal, real)
  let args = []
  for arg in a:formal
    if type(arg)==type('string') && arg =~ '^v:\d\+_$'
      let new = a:real[matchstr(arg, 'v:\zs\d\+\ze_')-1]
    else
      let new = arg
    endif
    call add(args, new)
    unlet new
  endfor
  return args
endfunction

" # Function: s:DoBindString(arguments...) {{{2
function! s:DoBindString(expr, real)
  let expr = substitute(a:expr, '\<v:\(\d\+\)_\>', a:real.'[\1-1]', 'g')
  return expr
endfunction

" # Function: s:Execute(arguments...) {{{2
function! s:Execute(args) dict
  let args = s:DoBindList(self.args, a:args)
  " echomsg '##'.string(self.f).'('.join(args, ',').')'
  let res = eval(string(self.f).'('.s:Join(args).')')
  return res
endfunction

" # Function: lh#function#execute(function, arguments...) {{{2
function! lh#function#execute(Fn, ...)
  if     type(a:Fn) == type(function('exists'))
    let res = eval(string(a:Fn).'('.s:Join(a:000).')')
    return res
  elseif type(a:Fn) == type('string')
    if a:Fn =~ '^[a-zA-Z0-9_#]\+$'
      let res = eval(string(function(a:Fn)).'('.s:Join(a:000).')')
      return res
    else
      let expr = s:DoBindString(a:Fn, 'a:000')
      let res = eval(expr)
      return res
    endif
  elseif type(a:Fn) == type({}) && has_key(a:Fn, 'execute')
    return a:Fn.execute(a:000)
  endif
endfunction

" # Function: lh#function#bind(function, arguments...) {{{2
function! lh#function#bind(fn, ...)
  let binded_fn = {
	\ 'f': a:fn,
	\ 'args': copy(a:000),
	\ 'execute': function('s:Execute')
	\}
  return binded_fn
endfunction

" }}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
