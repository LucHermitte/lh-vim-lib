"=============================================================================
" File:         plugin/ui-functions.vim                                  {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/blob/master/License.md>
" Version:      3.3.21
" Created:      18th nov 2002
" Last Update:  04th Jan 2017
"------------------------------------------------------------------------
" Description:  Functions for the interaction with a User Interface.
"               The UI can be graphical or textual.
"               At first, this was designed to ease the syntax of
"               mu-template's templates.
"
" Option:       {{{2
"       {[bg]:ui_type}
"               = "g\%[ui]",
"               = "t\%[ext]" ; the call must not be |:silent|
"               = "f\%[te]"
" }}}2
"------------------------------------------------------------------------
" Installation: Drop this into one of your {rtp}/plugin/ directories.
" History:      {{{2
"    v3.3.21
"       (*) Add highlight to CONFIRM()
"    v3.0.0  GPLv3
"    v2.2.6
"       (*) CONFIRM() and WHICH() accept lists of {choices}
"    v2.2.0
"       (*) menu to switch the ui_type
"    v0.06
"       (*) :s/echoerr/throw/ => vim7 only
"    v0.05
"       (*) In vim7e, inputdialog() returns a trailing '\n'. INPUT() strips the
"           NL character.
"    v0.04
"       (*) New function: WHICH()
"    v0.03
"       (*) Small bug fix with INPUT()
"    v0.02
"       (*) Code "factorisations"
"       (*) Help on <F1> enhanced.
"       (*) Small changes regarding the parameter accepted
"       (*) Function SWITCH
"    v0.01 Initial Version
"
" TODO:         {{{2
"       (*) Modernize the code to Vim7 Lists and dicts
"           Move to autoload plugin
"       (*) Save the hl-User1..9 before using them
"       (*) Possibility other than &statusline:
"           echohl User1 |echon "bla"|echohl User2|echon "bli"|echohl None
"       (*) Wraps too long choices-line (length > term-width)
"       (*) Add to the documentation: "don't use CTRL-C to abort !!"
"       (*) Look if I need to support 'wildmode'
"       (*) 3rd mode: return string for FTE
"       (*) 4th mode: interaction in a scratch buffer
"
" }}}1
"=============================================================================
" Avoid reinclusion {{{1
"
if exists("g:loaded_ui_functions") && !exists('g:force_reload_ui_functions')
  finish
endif
let g:loaded_ui_functions = 1
let s:cpo_save=&cpo
set cpo&vim
" }}}1
"------------------------------------------------------------------------
" External functions {{{1
" Function: IF(var, then, else) {{{2
function! IF(var,then, else) abort
  return lh#ui#if(a:var, a:then, a:else)
endfunction

" Function: SWITCH(var, case, action [, case, action] [default_action]) {{{2
function! SWITCH(var, ...) abort
  return call('lh#ui#switch', [a:var]+a:000)
endfunction

" Function: CONFIRM(text [, choices [, default [, type]]]) {{{2
function! CONFIRM(text, ...) abort
  return call('lh#ui#confirm', [a:text]+a:000)
endfunction

" Function: INPUT(prompt [, default ]) {{{2
function! INPUT(prompt, ...) abort
  return call('lh#ui#input', [a:prompt]+a:000)
endfunction

" Function: COMBO(prompt, choice [, ... ]) {{{2
function! COMBO(prompt, ...) abort
  return call('lh#ui#combo', [a:prompt]+a:000)
endfunction

" Function: WHICH(function, prompt, choice [, ... ]) {{{2
function! WHICH(fn, prompt, ...) abort
  return call('lh#ui#which', [a:fn, a:prompt]+a:000)
endfunction

" Function: CHECK(prompt, choice [, ... ]) {{{2
function! CHECK(prompt, ...) abort
  return call('lh#ui#check', [a:prompt]+a:000)
endfunction

" }}}1
"------------------------------------------------------------------------
" Options setting {{{1
let s:OptionData = {
      \ "variable": "ui_type",
      \ "idx_crt_value": 1,
      \ "values": ['gui', 'text', 'fte'],
      \ "menu": { "priority": '500.2700', "name": '&Plugin.&LH.&UI type'}
      \}

call lh#menu#def_toggle_item(s:OptionData)

" }}}1
"------------------------------------------------------------------------
" Functions that insert fte statements {{{1
" Function: s:if_fte(var, then, else) {{{2
" Function: s:confirm_fte(text, [, choices [, default [, type]]]) {{{2
" Function: s:input_fte(prompt [, default]) {{{2
" Function: s:combo_fte(prompt, choice [, ...]) {{{2
" Function: s:check_fte(prompt, choice [, ...]) {{{2
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
