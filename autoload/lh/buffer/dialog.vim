"=============================================================================
" File:         autoload/lh/buffer/dialog.vim                            {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      4.7.0
let s:k_version = 40700
" Created:      21st Sep 2007
" Last Update:  12th Jan 2020
"------------------------------------------------------------------------
" Description:  «description»
"
"------------------------------------------------------------------------
" History:
"       v4.7.1
"       (*) Simplify gui/dialog API to define more mappings
"       v4.7.0
"       (*) ENH: Use the exact width available to display rulers
"       (*) BUG: Fix improper offset when selecting lines
"       v4.0.0
"       (*) ENH: Add `_to_string()` to dialog buffer
"       (*) ENH: Tags selection support visual mode
"       (*) REFACT: Several simplifications
"       (*) Add lh#buffer#dialog#update_all()
"       v3.6.1
"       (*) ENH: Use new logging framework
"       v3.2.14  Dialog buffer name may now contain a '#'
"                Lines modifications silenced
"       v3.0.0   GPLv3
"       v1.0.0   First Version
"       (*) Functions imported from Mail_mutt_alias.vim
" TODO:
"       (*) --abort-- line
"       (*) custom messages
"       (*) do not mess with search history
"       (*) support any &magic
"       (*) syntax
"       (*) add number/letters
"       (*) tag with '[x] ' instead of '* '
" }}}1
"=============================================================================


"=============================================================================
let s:cpo_save=&cpo
set cpo&vim



"=============================================================================
" ## Globals {{{1
let s:LHdialog = {}

"=============================================================================
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#buffer#dialog#version()
  return s:k_version
endfunction

" # Debug {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#buffer#dialog#verbose(...)
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

function! lh#buffer#dialog#debug(expr) abort
  return eval(a:expr)
endfunction


"=============================================================================
" ## Functions {{{1
" # Dialog functions {{{2
"------------------------------------------------------------------------
function! s:Mappings(abuffer, action) abort " {{{3
  nnoremap <silent> <buffer> <esc>         :<c-u>call lh#buffer#dialog#quit()<cr>
  nnoremap <silent> <buffer> q             :<c-u>call lh#buffer#dialog#quit()<cr>
  if type(a:action) == type('')
    nnoremap <silent> <buffer> <cr>        :<c-u>call lh#buffer#dialog#select(line('.'))<cr>
  else
    for k in keys(a:action)
      let trigger = substitute(k, '^\\<\(.*\)\\>', '<\1>', '')
      exe "nnoremap <silent> <buffer> ".trigger." :<c-u>call lh#buffer#dialog#selectV2(".string(k).", line('.'))<cr>"
    endfor
  endif
  " nnoremap <silent> <buffer> <2-LeftMouse> :silent call <sid>GrepEditFileLine(line("."))<cr>
  " nnoremap <silent> <buffer> Q          :call <sid>Reformat()<cr>
  " nnoremap <silent> <buffer> <Left>     :set tabstop-=1<cr>
  " nnoremap <silent> <buffer> <Right>    :set tabstop+=1<cr>
  if a:abuffer.support_tagging
    nnoremap <silent> <buffer> t          :silent call <sid>ToggleTag(line("."))<cr>
    nnoremap <silent> <buffer> <space>    :silent call <sid>ToggleTag(line("."))<cr>
    vnoremap <silent> <buffer> t          :<c-u>silent call <sid>ToggleTag(line("'<"), line("'>"))<cr>
    vnoremap <silent> <buffer> <space>    :<c-u>silent call <sid>ToggleTag(line("'<"), line("'>"))<cr>
  endif
  nnoremap <silent> <buffer> <tab>        :silent call <sid>NextChoice('')<cr>
  nnoremap <silent> <buffer> <S-tab>      :silent call <sid>NextChoice('b')<cr>
  exe "nnoremap <silent> <buffer> h       :silent call <sid>ToggleHelp(".a:abuffer.id.")<cr>"
endfunction

"----------------------------------------
" Tag / untag the current choice {{{3
function! s:ToggleTag(lineNum, ...) abort
  let first0 = max([a:lineNum, s:Help_NbL()+1])
  let first  = first0
  let last   = a:0 > 0 ? a:1 : a:lineNum
  while first <= last
    let idx = first - s:Help_NbL() -1
    call s:Verbose("Tagging #%1 entry at line %2: %3", idx, a:lineNum, getline(a:lineNum))
    " If tagged
    if (getline(first)[0] == '*')
      let b:dialog.NbTags -= 1
      silent exe first.'s/^\* /  /e'
      let b:dialog.tags[idx] = 0
    else
      let b:dialog.NbTags += 1
      silent exe first.'s/^  /* /e'
      let b:dialog.tags[idx] = 1
    endif
    let first += 1
  endwhile
  if first != first0
    " Move after the tag ; there is something with the two previous :s. They
    " don't leave the cursor at the same position.
    silent! normal! 3|
    call s:NextChoice('') " move to the next choice
  endif
endfunction

function! s:Help_NbL() abort " {{{3
  " return 3 (header+ruler+empty line) + nb lines of BuildHelp
  return 3 + len(b:dialog['help_'.b:dialog.help_type])
endfunction
"----------------------------------------
" Go to the Next (/previous) possible choice. {{{3
function! s:NextChoice(direction) abort
  " echomsg "next!"
  call search('^[ *]\s*\zs\S\+', a:direction)
endfunction

"------------------------------------------------------------------------

function! s:RedisplayHelp(dialog) abort " {{{3
  silent! 2,$g/^@/d_
  silent! call append(1, a:dialog['help_'.a:dialog.help_type]+a:dialog['help_ruler'])
endfunction

function! lh#buffer#dialog#update(dialog) abort " {{{3
  set noro
  silent! exe (s:Help_NbL()+1).',$d_'
  silent! call append('$', map(copy(a:dialog.choices), '"  ".v:val'))
  set ro
endfunction

function! lh#buffer#dialog#update_all(dialog) abort " {{{3
  set noro
  call s:RedisplayHelp(a:dialog)
  call lh#buffer#dialog#update(a:dialog)
  set ro
endfunction

function! s:Display(dialog, atitle) abort " {{{3
  set noro
  silent 0 put = a:atitle
  call s:RedisplayHelp(a:dialog)
  silent! call append('$', map(copy(a:dialog.choices), '"  ".v:val'))
  set ro
  " Resize to have all elements fit, up to max(15, winfixheight)
  let nl = 15 > &winfixheight ? 15 : &winfixheight
  let nl = line('$') < nl ? line('$') : nl
  exe nl.' wincmd _'
  normal! gg
  exe s:Help_NbL()+1
endfunction

function! s:ToggleHelp(bufferId) abort " {{{3
  call lh#buffer#find(a:bufferId)
  call b:dialog.toggle_help()
endfunction

function! lh#buffer#dialog#toggle_help() dict abort " {{{3
  let self.help_type
        \ = (self.help_type == 'short')
        \ ? 'long'
        \ : 'short'
  call s:RedisplayHelp(self)
endfunction

function! lh#buffer#dialog#new(bname, title, where, support_tagging, action, choices) abort " {{{3
  " The ID will be the buffer id
  let res = lh#object#make_top_type({})
  let where_it_started = getpos('.')
  let where_it_started[0] = bufnr('%')
  let res.where_it_started = where_it_started

  try
    call lh#buffer#scratch(a:bname, a:where)
  catch /.*/
    echoerr v:exception
    return res
  endtry
  let res.id              = bufnr('%')
  let b:dialog            = res
  let s:LHdialog[res.id]  = res
  let res.help_long       = []
  let res.help_short      = []
  let res.help_ruler      = []
  let res.help_type       = 'short'
  let res.support_tagging = a:support_tagging
  let res.action          = a:action
  let res.selection       = function(s:getSNR('selection'))
  let res.reset_choices   = function(s:getSNR('reset_choices'))
  call res.reset_choices(a:choices)

  " Long help
  call lh#buffer#dialog#add_help(res, '@| <cr>, <double-click>    : select this', 'long')
  call lh#buffer#dialog#add_help(res, '@| <esc>, q                : Abort', 'long')
  if a:support_tagging
    call lh#buffer#dialog#add_help(res, '@| <t>, <space>            : Tag/Untag the current item', 'long')
  endif
  call lh#buffer#dialog#add_help(res, '@| <up>/<down>, <tab>, +/- : Move between entries', 'long')
  call lh#buffer#dialog#add_help(res, '@|', 'long')
  " call lh#buffer#dialog#add_help(res, '@| h                       : Toggle help', 'long')
  " Short Help
  " call lh#buffer#dialog#add_help(res, '@| h                       : Toggle help', 'short')

  let window_width = lh#window#text_width(bufwinnr(res.id))
  call lh#buffer#dialog#add_help(res, '@+'.repeat('-', window_width-3), 'ruler')
  let res.toggle_help = function("lh#buffer#dialog#toggle_help")
  let title = '@  ' . a:title
  let helpstr = '| Toggle (h)elp'
  let title = title
        \ . repeat(' ', window_width-lh#encoding#strlen(title)-lh#encoding#strlen(helpstr)-1)
        \ . helpstr
  call s:Display(res, title)

  call s:Mappings(res, a:action)
  return res
endfunction

function! s:reset_choices(choices, ...) dict abort " {{{3
  " a:1: (optional) matching tags associated to updated choices
  let self.NbTags  = 0
  let self.choices = a:choices
  if self.support_tagging
    if a:0 > 0
      let self.tags    = a:1
      let self.NbTags  = count(self.tags, 1)
    else
      let self.tags    = repeat([0], len(a:choices))
    endif
  endif
endfunction

function! lh#buffer#dialog#add_help(abuffer, text, help_type) abort " {{{3
  call add(a:abuffer['help_'.a:help_type],a:text)
endfunction

"=============================================================================
function! lh#buffer#dialog#quit() abort " {{{3
  let bufferId = b:dialog.where_it_started[0]
  echohl WarningMsg
  echo "Abort"
  echohl None
  quit
  call lh#buffer#find(bufferId)
endfunction

function! s:selection() dict abort " {{{3
  " Require Vim8 lambda
  if self.NbTags == 0
    let lnum = getbufinfo(self.id)[0].lnum
    call s:Verbose('No tag selected -> return crt line: %1-%2', lnum, s:Help_NbL()-1)
    return [lnum - s:Help_NbL()-1]
  else
    let lines = copy(self.tags)
    call map(lines, {idx, val -> val ? idx : -1})
    call filter(lines, 'v:val >= 0')
    call s:Verbose('Multiple tags selected -> %1', lines)
    return lines
  endif
endfunction

" Function: lh#buffer#dialog#selectV2(key, line) " {{{3
function! lh#buffer#dialog#selectV2(key, line) abort
  if a:line == -1
    call lh#buffer#dialog#quit()
    return
  " elseif a:line <= s:Help_NbL() + 1
  elseif a:line <= s:Help_NbL()
    echoerr "Unselectable item"
    return
  else
    let dialog = b:dialog
    call lh#assert#value(dialog).has_key('action')
    let l:Action = dialog.action[a:key]
    let results = { 'dialog' : dialog, 'selection' : []  }

    if b:dialog.NbTags == 0
      " -1 because first index is 0
      " let results = [ dialog.choices[a:line - s:Help_NbL() - 1] ]
      let results.selection = [ a:line - s:Help_NbL() - 1 ]
    else
      silent g/^* /call add(results.selection, line('.')-s:Help_NbL()-1)
    endif
  endif

  call call(l:Action, [results])
endfunction

" Function: lh#buffer#dialog#select(line [,overriden-action]) " {{{3
function! lh#buffer#dialog#select(line, ...) abort
  if a:line == -1
    call lh#buffer#dialog#quit()
    return
  " elseif a:line <= s:Help_NbL() + 1
  elseif a:line <= s:Help_NbL()
    echoerr "Unselectable item"
    return
  else
    let dialog = b:dialog
    call lh#assert#value(dialog).has_key('action')
    let results = { 'dialog' : dialog, 'selection' : []  }

    if b:dialog.NbTags == 0
      " -1 because first index is 0
      " let results = [ dialog.choices[a:line - s:Help_NbL() - 1] ]
      let results.selection = [ a:line - s:Help_NbL() - 1 ]
    else
      silent g/^* /call add(results.selection, line('.')-s:Help_NbL()-1)
    endif
  endif

  if a:0 > 0 " action overriden
    exe 'call '.dialog.action.'(results, a:000)'
  else
    exe 'call '.dialog.action.'(results)'
  endif
endfunction
function! lh#buffer#dialog#Select(...) abort
  call lh#notify#deprecated('lh#buffer#dialog#Select()', 'lh#buffer#dialog#select()')
  return call ('lh#buffer#dialog#select', a:000)
endfunction

function! lh#buffer#dialog#action(results) abort " {{{3
" TODO: Check where it's used!
  let dialog = a:results.dialog
  call lh#common#echomsg_multilines(map(copy(dialog.choices), '"-> ".v:val'))
endfunction

" s:getSNR([func_name]) {{{3
function! s:getSNR(...)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction
" }}}1
"=============================================================================
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
