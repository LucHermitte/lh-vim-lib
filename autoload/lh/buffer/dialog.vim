"=============================================================================
" $Id$
" File:		autoload/lh/buffer/dialog.vim                            {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" Version:	2.0.6
" Created:	21st Sep 2007
" Last Update:	$Date$
"------------------------------------------------------------------------
" Description:	«description»
" 
"------------------------------------------------------------------------
" Installation:	
" 	Drop it into {rtp}/autoload/lh/
" 	Vim 7+ required.
" History:	
"	v 1.0.0 First Version
" 	(*) Functions imported from Mail_mutt_alias.vim
" TODO:		
" 	(*) --abort-- line
" 	(*) custom messages
" 	(*) do not mess with search history
" 	(*) support any &magic
" 	(*) syntax
" 	(*) add number/letters
" 	(*) tag with '[x] ' instead of '* '
" }}}1
"=============================================================================


"=============================================================================
let s:cpo_save=&cpo
set cpo&vim

let s:LHdialog = {}
"------------------------------------------------------------------------
function! s:Mappings(abuffer)
  " map <enter> to edit a file, also dbl-click
  exe "nnoremap <silent> <buffer> <esc>         :silent call ".a:abuffer.action."(-1, ".a:abuffer.id.")<cr>"
  exe "nnoremap <silent> <buffer> q             :call <sid>Select(-1, ".a:abuffer.id.")<cr>"
  exe "nnoremap <silent> <buffer> <cr>          :call <sid>Select(line('.'), ".a:abuffer.id.")<cr>"
  " nnoremap <silent> <buffer> <2-LeftMouse> :silent call <sid>GrepEditFileLine(line("."))<cr>
  " nnoremap <silent> <buffer> Q	  :call <sid>Reformat()<cr>
  " nnoremap <silent> <buffer> <Left>	  :set tabstop-=1<cr>
  " nnoremap <silent> <buffer> <Right>	  :set tabstop+=1<cr>
  if a:abuffer.support_tagging
    nnoremap <silent> <buffer> t	  :silent call <sid>ToggleTag(line("."))<cr>
    nnoremap <silent> <buffer> <space>	  :silent call <sid>ToggleTag(line("."))<cr>
  endif
  nnoremap <silent> <buffer> <tab>	  :silent call <sid>NextChoice('')<cr>
  nnoremap <silent> <buffer> <S-tab>	  :silent call <sid>NextChoice('b')<cr>
  exe "nnoremap <silent> <buffer> h	  :silent call <sid>ToggleHelp(".a:abuffer.id.")<cr>"
endfunction

"----------------------------------------
" Tag / untag the current choice {{{
function! s:ToggleTag(lineNum)
   if a:lineNum > s:Help_NbL()
      " If tagged
      if (getline(a:lineNum)[0] == '*')
	let b:NbTags = b:NbTags - 1
	silent exe a:lineNum.'s/^\* /  /e'
      else
	let b:NbTags = b:NbTags + 1
	silent exe a:lineNum.'s/^  /* /e'
      endif
      " Move after the tag ; there is something with the two previous :s. They
      " don't leave the cursor at the same position.
      silent! normal! 3|
      call s:NextChoice('') " move to the next choice
    endif
endfunction
" }}}

function! s:Help_NbL()
  " return 1 + nb lines of BuildHelp
  return 2 + len(b:dialog['help_'.b:dialog.help_type])
endfunction
"----------------------------------------
" Go to the Next (/previous) possible choice. {{{
function! s:NextChoice(direction)
  " echomsg "next!"
  call search('^[ *]\s*\zs\S\+', a:direction)
endfunction
" }}}

"------------------------------------------------------------------------

function! s:RedisplayHelp(dialog)
  silent! 2,$g/^@/d_
  normal! gg
  for help in a:dialog['help_'.a:dialog.help_type]
    silent put=help
  endfor
endfunction

function! lh#buffer#dialog#Update(dialog)
  set noro
  exe (s:Help_NbL()+1).',$d_'
  for choice in a:dialog.choices
    silent $put='  '.choice
  endfor
  set ro
endfunction

function! s:Display(dialog, atitle)
  set noro
  0 put = a:atitle
  call s:RedisplayHelp(a:dialog)
  for choice in a:dialog.choices
    silent $put='  '.choice
  endfor
  set ro
  exe s:Help_NbL()+1
endfunction

function! s:ToggleHelp(bufferId)
  call lh#buffer#Find(a:bufferId)
  call b:dialog.toggle_help()
endfunction

function! lh#buffer#dialog#toggle_help() dict
  let self.help_type 
	\ = (self.help_type == 'short')
	\ ? 'long'
	\ : 'short'
  call s:RedisplayHelp(self)
endfunction

function! lh#buffer#dialog#new(bname, title, where, support_tagging, action, choices)
  " The ID will be the buffer id
  let res = {}

  try
    call lh#buffer#Scratch(a:bname, a:where)
  catch /.*/
    echoerr v:exception
    return res
  endtry
  let res.id              = bufnr('%')
  let b:NbTags            = 0
  let b:dialog            = res
  let s:LHdialog[res.id]  = res
  let res.help_long       = []
  let res.help_short      = []
  let res.help_type       = 'short'
  let res.support_tagging = a:support_tagging
  let res.action	  = a:action
  let res.choices	  = a:choices

  " Long help
  call lh#buffer#dialog#add_help(res, '@| <cr>, <double-click>    : select this', 'long')
  call lh#buffer#dialog#add_help(res, '@| <esc>, q                : Abort', 'long')
  if a:support_tagging
    call lh#buffer#dialog#add_help(res, '@| <t>, <space>            : Tag/Untag the current item', 'long')
  endif
  call lh#buffer#dialog#add_help(res, '@| <up>/<down>, <tab>, +/- : Move between entries', 'long')
  call lh#buffer#dialog#add_help(res, '@|', 'long')
  " call lh#buffer#dialog#add_help(res, '@| h                       : Toggle help', 'long')
  call lh#buffer#dialog#add_help(res, '@+'.repeat('-', winwidth(bufwinnr(res.id))-3), 'long')
  " Short Help
  " call lh#buffer#dialog#add_help(res, '@| h                       : Toggle help', 'short')
  call lh#buffer#dialog#add_help(res, '@+'.repeat('-', winwidth(bufwinnr(res.id))-3), 'short')

  let res.toggle_help = function("lh#buffer#dialog#toggle_help")
  let title = '@  ' . a:title
  let helpstr = '| Toggle (h)elp'
  let title = title 
	\ . repeat(' ', winwidth(bufwinnr(res.id))-strlen(title)-strlen(helpstr)-1)
	\ . helpstr
  call s:Display(res, title)
 
  call s:Mappings(res)
  return res
endfunction

function! lh#buffer#dialog#add_help(abuffer, text, help_type)
  call add(a:abuffer['help_'.a:help_type],a:text)
endfunction

"=============================================================================
function! lh#buffer#dialog#Quit()
  echohl WarningMsg
  echo "Abort"
  echohl None
  quit
endfunction

function! s:Select(line, bufferId)
  if a:line == -1
    call lh#buffer#dialog#Quit()
    return
  " elseif a:line <= s:Help_NbL() + 1
  elseif a:line <= s:Help_NbL() 
    echoerr "Unselectable item"
    return 
  else
    let dialog = s:LHdialog[a:bufferId]
    let results = { 'dialog' : dialog, 'selection' : []  }

    if b:NbTags == 0
      " -1 because first index is 0
      " let results = [ dialog.choices[a:line - s:Help_NbL() - 1] ]
      let results.selection = [ a:line - s:Help_NbL() - 1 ]
    else
      silent g/^* /call add(results.selection, line('.')-s:Help_NbL()-1)
    endif
  endif

  exe 'call '.dialog.action.'(results)'
endfunction

function! Action(results)
  let dialog = a:results.dialog
  let choices = dialog.choices
  for r in a:results.selection
    echomsg '-> '.choices[r]
  endfor
endfunction


"=============================================================================
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
