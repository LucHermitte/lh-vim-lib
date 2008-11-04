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
" 	Tests for autoload/lh/function.vim
" 
"------------------------------------------------------------------------
" Installation:	«install details»
" History:	«history»
" TODO:		«missing features»
" }}}1
"=============================================================================

runtime autoload/lh/function.vim

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
function! Test(...)
  let nb = len(a:000)
  " echo "test(".nb.':' .join(a:000, ' -- ')')'
  let i =0
  while i!= len(a:000)
    echo "Test: type(".i.")=".type(a:000[i]).' --> '. string(a:000[i])
    let i += 1
  endwhile
endfunction


if 0 " lh#function#bind + lh#function#execute
  " call Test(1,'two',3)
  " let rev3 = lh#function#bind(function('Test'), ['v:3_', 'v:2_', 'v:1_'])
  let rev4 = lh#function#bind(function('Test'), 'v:4_', 42, 'v:3_', 'v:2_', 'v:1_')
  " call lh#function#execute(rev, [1,'two',3])
  call lh#function#execute(rev4, 1,'two',rev4, [4,5])
endif


if 0 " function name as string
  call lh#function#execute('Test', 1,'two',3)
endif

if 0 " exp as string
  call lh#function#execute('Test(12,len(v:2_).v:2_, 42, v:3_, v:1_)', 1,'two',3)
endif

if 0 " calling a function()
  call lh#function#execute(function('Test'), 1,'two','v:1_',['a',42])
endif
"------------------------------------------------------------------------
if 0 " function name as string
  let rev3 = lh#function#bind('Test', 'v:3_', 'v:2_', 'v:1_')
  call lh#function#execute(rev3, 1,'two',3)
endif
"------------------------------------------------------------------------

let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
