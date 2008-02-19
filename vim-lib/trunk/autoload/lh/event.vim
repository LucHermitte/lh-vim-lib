"============================================================================= "=============================================================================
" $Id$
" File:		event.vim                                           {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" Version:	2.0.6
" Created:	15th Feb 2008
" Last Update:	$Date$
"------------------------------------------------------------------------
" Description:	
" 	Function to help manage vim |autocommand-events|
" 
"------------------------------------------------------------------------
" Installation:
" 	Drop it into {rtp}/autoload/lh/
" 	Vim 7+ required.
" History:
" 	v2.0.6:
" 		Creation
" TODO:		
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
function! s:RegisteredOnce(cmd, group)
  " We can't delete the current augroup autocommand => increment a counter
  if !exists('s:'.a:group) || s:{a:group} == 0 
    let s:{a:group} = 1
    exe a:cmd
  endif
endfunction

function! lh#event#RegisterForOneExecutionAt(event, cmd, group)
  let group = a:group.'_once'
  let s:{group} = 0
  exe 'augroup '.group
  au!
  exe 'au '.a:event.' '.expand('%:p').' call s:RegisteredOnce('.string(a:cmd).','.string(group).')'
  augroup END
endfunction
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
