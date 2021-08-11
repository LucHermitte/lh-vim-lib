"=============================================================================
" File:         autoload/lh/ui.vim                                {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.6.4
let s:k_version = '40604'
" Created:      03rd Jan 2017
" Last Update:  11th Aug 2021
"------------------------------------------------------------------------
" Description:
"       Defines helper functions to interact with end user.
"
"------------------------------------------------------------------------
" History:
" v4.0.0: Factorization of plugins word_tools and ui-functions
" TODO:
" - Use |call()| to forward parameters
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#ui#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#ui#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Log(expr, ...)
  call call('lh#log#this',[a:expr]+a:000)
endfunction

function! s:Verbose(expr, ...)
  if s:verbose
    call call('s:Log',[a:expr]+a:000)
  endif
endfunction

function! lh#ui#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" # Read word around cursor {{{2
" Return the current keyword, uses spaces to delimitate {{{3
function! lh#ui#GetNearestKeyword()
  let c = col ('.')-1
  let ll = getline('.')
  let ll1 = strpart(ll,0,c)
  let ll1 = matchstr(ll1,'\k*$')
  let ll2 = strpart(ll,c,strlen(ll)-c+1)
  let ll2 = matchstr(ll2,'^\k*')
  " let ll2 = strpart(ll2,0,match(ll2,'$\|\s'))
  return ll1.ll2
endfunction

" Return the current word, uses spaces to delimitate {{{3
function! lh#ui#GetNearestWord()
  let c = col ('.')-1
  let l = line('.')
  let ll = getline(l)
  let ll1 = strpart(ll,0,c)
  let ll1 = matchstr(ll1,'\S*$')
  let ll2 = strpart(ll,c,strlen(ll)-c+1)
  let ll2 = strpart(ll2,0,match(ll2,'$\|\s'))
  ""echo ll1.ll2
  return ll1.ll2
endfunction

" Return the word before the cursor, uses spaces to delimitate {{{3
" Rem : <cword> is the word under or after the cursor
function! lh#ui#GetCurrentWord()
  let c = col ('.')-1
  let l = line('.')
  let ll = getline(l)
  let ll1 = strpart(ll,0,c)
  let ll1 = matchstr(ll1,'\S*$')
  if strlen(ll1) == 0
    return ll1
  else
    let ll2 = strpart(ll,c,strlen(ll)-c+1)
    let ll2 = strpart(ll2,0,match(ll2,'$\|\s'))
    return ll1.ll2
  endif
endfunction

" Return the keyword before the cursor, uses \k to delimitate {{{3
" Rem : <cword> is the word under or after the cursor
function! lh#ui#GetCurrentKeyword()
  let c = col ('.')-1
  let l = line('.')
  let ll = getline(l)
  let ll1 = strpart(ll,0,c)
  let ll1 = matchstr(ll1,'\k*$')
  if strlen(ll1) == 0
    return ll1
  else
    let ll2 = strpart(ll,c,strlen(ll)-c+1)
    let ll2 = matchstr(ll2,'^\k*')
    " let ll2 = strpart(ll2,0,match(ll2,'$\|\s'))
    return ll1.ll2
  endif
endfunction

" Extract the word before the cursor,  {{{3
" use keyword definitions, skip latter spaces (see "bla word_accepted ")
function! lh#ui#GetPreviousWord()
  let lig = getline(line('.'))
  let lig = strpart(lig,0,col('.')-1)
  return matchstr(lig, '\<\k*\>\s*$')
endfunction

" lh#ui#GetLikeCTRL_W() retrieves the characters that i_CTRL-W deletes. {{{3
" Initial need by Hari Krishna Dara <hari_vim@yahoo.com>
" Last ver:
" Pb: "if strlen(w) ==  " --> ") ==  " instead of just "==  ".
" There still exists a bug regarding the last char of a line. VIM bug ?
function! lh#ui#GetLikeCTRL_W()
  let lig = getline(line('.'))
  let lig = strpart(lig,0,col('.')-1)
  " treat ending spaces apart.
  let s = matchstr(lig, '\s*$')
  let lig = strpart(lig, 0, strlen(lig)-strlen(s))
  " First case : last characters belong to a "word"
  let w = matchstr(lig, '\<\k\+\>$')
  if strlen(w) == 0
    " otherwise, they belong to a "non word" (without any space)
    let w = substitute(lig, '.*\(\k\|\s\)', '', 'g')
  endif
  return w . s
endfunction

" # Interaction functions {{{2
" Function: lh#ui#if(var, then, else) {{{3
function! lh#ui#if(var,then, else) abort
  let o = s:Opt_type() " {{{4
  if     o =~ 'g\%[ui]\|t\%[ext]' " {{{5
    return a:var ? a:then : a:else
  elseif o =~ 'f\%[te]'           " {{{5
    return s:if_fte(a:var, a:then, a:else)
  else                    " {{{5
    throw "lh#ui#if(): Unkonwn user-interface style (".o.")"
  endif
endfunction

" Function: lh#ui#switch(var, case, action [, case, action] [default_action]) {{{3
function! lh#ui#switch(var, ...) abort
  let o = s:Opt_type() " {{{4
  if     o =~ 'g\%[ui]\|t\%[ext]' " {{{5
    let explicit_def = ((a:0 % 2) == 1)
    let default      = explicit_def ? a:{a:0} : ''
    let i = a:0 - 1 - explicit_def
    while i > 0
      if a:var == a:{i}
        return a:{i+1}
      endif
      let i -=  2
    endwhile
    return default
  elseif o =~ 'f\%[te]'           " {{{5
    return s:if_fte(a:var, a:then, a:else)
  else                    " {{{5
    throw "lh#ui#switch(): Unkonwn user-interface style (".o.")"
  endif
endfunction

" Function: lh#ui#confirm(text [, choices [, default [, type]]]) {{{3
function! lh#ui#confirm(text, ...) abort
  if a:0 > 4
    throw "lh#ui#confirm(): too many parameters"
    return 0
  endif
  return call('s:confirm_impl', ['none', a:text] + a:000)
endfunction

" Function: lh#ui#input(prompt [, default ]) {{{3
function! lh#ui#input(prompt, ...) abort
  " 1- Check parameters {{{4
  if a:0 > 4 " {{{5
    throw "lh#ui#input(): too many parameters"
    return 0
  endif
  " build the parameters string {{{5
  let i = 1 | let params = ''
  while i <= a:0
    if i == 1 | let params = 'a:{1}'
    else      | let params .= ',a:{'.i.'}'
    endif
    let i +=  1
  endwhile
  " 2- Choose the correct way to execute according to the option {{{4
  let o = s:Opt_type()
  if     o =~ 'g\%[ui]'  " {{{5
    exe 'return matchstr(inputdialog(a:prompt,'.params.'), ".\\{-}\\ze\\n\\=$")'
  elseif o =~ 't\%[ext]' " {{{5
    exe 'return input(a:prompt,'.params.')'
  elseif o =~ 'f\%[te]'  " {{{5
      exe 'return s:input_fte(a:prompt,'.params.')'
  else               " {{{5
    throw "lh#ui#input(): Unkonwn user-interface style (".o.")"
  endif
endfunction

" Function: lh#ui#combo(prompt, choice [, ... ]) {{{3
function! lh#ui#combo(prompt, ...) abort
  if a:0 > 4
    throw "lh#ui#combo(): too many parameters"
    return 0
  endif
  return call('s:confirm_impl', ['combo', a:prompt] + a:000)
endfunction

" Function: lh#ui#which(function, prompt, choice [, ... ]) {{{3
function! lh#ui#which(fn, prompt, ...) abort
  " 1- Check parameters {{{4
  " build the parameters string {{{5
  let i = 1
  while i <= a:0
    if i == 1
      if type(a:1) == type([])
        let choices = a:1
      else
        let choices = split(a:1, "\n")
      endif
      let params = 'a:{1}'
    else      | let params .=  ',a:{'.i.'}'
    endif
    let i +=  1
  endwhile
  " 2- Execute the function {{{4
  exe 'let which = '.a:fn.'(a:prompt,'.params.')'
  if     0 >= which | return ''
  else
    return substitute(choices[which-1], '&', '', '')
  endif
endfunction

" Function: lh#ui#check(prompt, choice [, ... ]) {{{3
function! lh#ui#check(prompt, ...) abort
  " 1- Check parameters {{{4
  if a:0 > 4 " {{{5
    throw "lh#ui#check(): too many parameters"
    return 0
  endif
  " build the parameters string {{{5
  let i = 1
  while i <= a:0
    if i == 1 | let params = 'a:{1}'
    else      | let params .=  ',a:{'.i.'}'
    endif
    let i +=  1
  endwhile
  " 2- Choose the correct way to execute according to the option {{{4
  let o = s:Opt_type()
  if     o =~ 'g\%[ui]'  " {{{5
    exe 'return s:confirm_text("check", a:prompt,'.params.')'
  elseif o =~ 't\%[ext]' " {{{5
    exe 'return s:confirm_text("check", a:prompt,'.params.')'
  elseif o =~ 'f\%[te]'  " {{{5
      exe 'return s:check_fte(a:prompt,'.params.')'
  else               " {{{5
    throw "lh#ui#check(): Unkonwn user-interface style (".o.")"
  endif
endfunction

" Function: lh#ui#ask(message) {{{3
function! lh#ui#ask(message) abort
  redraw! " clear the msg line
  echohl StatusLineNC
  echo "\r".a:message
  echohl None
  let key = nr2char(getchar())
  return key
endfunction

" Function: lh#ui#confirm_command(command) {{{3
" states:
" - ask
" - ignore
" - always
function! s:check() dict abort
  if     self.state == 'ignore'
    return
  elseif self.state == 'always'
    let shall_execute_command = 1
  elseif self.state == 'ask'
    try
      let cleanup = lh#on#exit()
            \.restore('&cursorline')
            \.restore_highlight('CursorLine')
      set cursorline
      hi CursorLine   cterm=NONE ctermbg=black ctermfg=white guibg=black guifg=white
      let choice = lh#ui#ask(self.message)
      if     choice == 'q'
        let self.state = 'ignore'
        let shall_execute_command = 0
        " TODO: find how not to blink
        redraw! " clear the msg line
      elseif choice == 'a'
        let self.state = 'always'
        let shall_execute_command = 1
        " TODO: find how not to blink
        redraw! " clear the msg line
      elseif choice == 'y'
        " leave state as 'ask'
        let shall_execute_command = 1
      elseif choice == 'n'
        " leave state as 'ask'
        let shall_execute_command = 0
      elseif choice == 'l'
        let shall_execute_command = 1
        let self.state = 'ignore'
      endif
    finally
      call cleanup.finalize()
    endtry
  endif

  if shall_execute_command
    execute self.command
  endif
endfunction

function! s:getSID() abort
  return eval(matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_getSID$'))
endfunction
let s:k_script_name      = s:getSID()

function! lh#ui#make_confirm_command(command, message) abort
  let res = lh#object#make_top_type(
        \ { 'state': 'ask'
        \ , 'command': a:command
        \ , 'message': a:message . ' (y/n/a/q/l/^E/^Y)'
        \ })
  call lh#object#inject_methods(res, s:k_script_name, 'check')
  return res
endfunction

" Function: lh#ui#global_confirm_command(pattern, command, message [, sep='/']) {{{3
" Exemple: to remove lines that match a pattern:
" > call lh#ui#global_confirm_command(pattern, 'd', 'delete line?')
function! lh#ui#global_confirm_command(pattern, command, message, ...) abort
  let cmd = lh#ui#make_confirm_command(a:command, a:message)
  let sep = get(a:, 1, '/')
  exe 'g'.sep.a:pattern.sep.'call cmd.check()'
endfunction

" Function: lh#ui#_confirm_global(param) {{{3
function! lh#ui#_confirm_global(param) abort
  let sep = a:param[0]
  let parts = split(a:param, sep)
  if len(parts) < 2
    throw "Not enough arguments to `ConfirmGlobal`!"
  endif
  let cmd = join(parts[1:])
  call lh#ui#global_confirm_command(parts[0], cmd, cmd . ' on line?', sep)
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
function! s:Option(name, default) " {{{2
  if     exists('b:ui_'.a:name) | return b:ui_{a:name}
  elseif exists('g:ui_'.a:name) | return g:ui_{a:name}
  else                          | return a:default
  endif
endfunction

function! s:Opt_type() " {{{2
  return s:Option('type', 'gui')
endfunction

function! s:Opt_confirm_type() " {{{2
  return s:Option('confirm_type', 'lh')
endfunction

function! s:confirm_impl(box, text, ...) abort " {{{2
  " 1- Check parameters {{{3
  call lh#assert#value(a:0).is_le(4)
  " build the parameters string {{{4
  let i = 1
  while i <= a:0
    if i == 1
      if type(a:1) == type([])
        let params = string(join(a:1, "\n"))
      else
        let params = 'a:{1}'
      endif
    else      | let params .= ',a:{'.i.'}'
    endif
    let i +=  1
  endwhile
  " 2- Choose the correct way to execute according to the option {{{3
  let o = s:Opt_type()
  if o !~ '\v^(g%[ui]|t%[ext]|v%[te])$'
    call lh#notify#once("lh#ui#confirm(): Unkonwn user-interface style (".o.")")
  endif
  if     o =~ '\vf%[te]'                                                                                        " {{{4
    exe 'return s:confirm_fte(a:text,'.params.')'
  elseif o =~ '\vg%[ui]' && has('gui_running')                                                                  " {{{4
    exe 'return confirm(a:text,'.params.')'
  elseif o =~ '\v(t%[ext]|g%[ui])' && has('dialog_con') && s:Opt_confirm_type() == 'std' && !has('gui_running') " {{{4
    " confirm() in plain Vim doesn't work that well => permit to override it
    " with a version that works well
    exe 'return confirm(a:text,'.params.')'
  else                                                                                                          " {{{4
    exe 'return s:confirm_text(a:box, a:text,'.params.')'
  endif
endfunction

" Function: s:status_line(prompt, current, hl [, choices] ) {{{2
"     a:current: current item
"     a:hl     : Generic, Warning, Error
function! s:status_line(prompt, current, hl, ...) abort
  " Highlightning {{{3
  if     a:hl == "Generic"  | let hl = '%1*'
  elseif a:hl == "Warning"  | let hl = '%2*'
  elseif a:hl == "Error"    | let hl = '%3*'
  elseif a:hl == "Info"     | let hl = '%4*'
  elseif a:hl == "Question" | let hl = '%5*'
  else                      | let hl = '%1*'
  endif

  " Build the string {{{3
  let sl_choices = '' | let i = 1
  while i <= a:0
    if i == a:current
      let sl_choices .=  ' '. hl .
            \ substitute(a:{i}, '&\(.\)', '%6*\1'.hl, '') . '%* '
    else
      let sl_choices .=  ' ' .
            \ substitute(a:{i}, '&\(.\)', '%6*\1%*', '') . ' '
    endif
    let i +=  1
  endwhile
  " }}}3

  " Display the prompt only if it fits
  let maw_width = winwidth('%')
  let raw_msg = a:prompt . join(a:000, ' ')
  return lh#encoding#strlen(raw_msg) >= maw_width ? sl_choices : a:prompt.sl_choices
endfunction

" Function: s:confirm_text(box, text [, choices [, default [, type]]]) {{{2
function! s:confirm_text(box, text, ...) abort
  let help = "/<esc>/<s-tab>/<tab>/<left>/<right>/<cr>/<F1>"
  " 1- Retrieve the parameters       {{{3
  let choices = ((a:0>=1) ? a:1 : '&Ok')
  let default = ((a:0>=2) ? a:2 : (('check' == a:box) ? 0 : 1))
  let type    = ((a:0>=3) ? a:3 : 'Generic')
  if     'none'  == a:box | let prefix = ''
  elseif 'combo' == a:box | let prefix = '( )_'
  elseif 'check' == a:box | let prefix = '[ ]_'
    let help = '/ '.help
  else                    | let prefix = ''
  endif


  " 2- Retrieve the proposed choices {{{3
  " Prepare the hot keys
  let i = 0
  while i != 26
    let hotkey_{nr2char(i+65)} = 0
    let i += 1
  endwhile
  let hotkeys = '' | let help_k = '/'
  " Parse the choices
  let i = 0
  while choices != ""
    let i +=  1
    let item    = matchstr(choices, "^.\\{-}\\ze\\(\n\\|$\\)")
    let choices = matchstr(choices, "\n\\zs.*$")
    " exe 'anoremenu ]'.a:text.'.'.item.' :let s:choice ='.i.'<cr>'
    if ('check' == a:box) && (strlen(default)>=i) && (1 == default[i-1])
      " let choice_{i} = '[X]' . substitute(item, '&', '', '')
      let choice_{i} = '[X]_' . item
    else
      " let choice_{i} = prefix . substitute(item, '&', '', '')
      let choice_{i} = prefix . item
    endif
    if i == 1
      let list_choices = 'choice_{1}'
    else
      let list_choices .=  ',choice_{'.i.'}'
    endif
    " Update the hotkey.
    if choice_{i} =~ '&[A-Za-z]'
      let key = toupper(matchstr(choice_{i}, '&\zs.\ze'))
      let hotkey_{key} = i
      let hotkeys .=  tolower(key) . toupper(key)
      let help_k .=  tolower(key)
    endif
  endwhile
  let nb_choices = i
  if default > nb_choices | let default = nb_choices | endif

  " 3- Run an interactive text menu  {{{3
  " Note: emenu can not be used through ":exe" {{{4
  " let wcm = &wcm
  " set wcm=<tab>
  " exe ':emenu ]'.a:text.'.'."<tab>"
  " let &wcm = wcm
  " 3.1- Preparations for the statusline {{{4
  " save the statusline
  let cleanup = lh#on#exit()
        \.restore('&l:statusline')
  try
    " Color schemes for selected item {{{5
    :hi User1 term=inverse,bold cterm=inverse,bold ctermfg=Yellow
          \ guifg=Black guibg=Yellow
    :hi User2 term=inverse,bold cterm=inverse,bold ctermfg=LightRed
          \ guifg=Black guibg=LightRed
    :hi User3 term=inverse,bold cterm=inverse,bold ctermfg=Red
          \ guifg=Black guibg=Red
    :hi User4 term=inverse,bold cterm=inverse,bold ctermfg=Cyan
          \ guifg=Black guibg=Cyan
    :hi User5 term=inverse,bold cterm=inverse,bold ctermfg=LightYellow
          \ guifg=Black guibg=LightYellow
    :hi User6 term=inverse,bold cterm=inverse,bold ctermfg=LightGray
          \ guifg=DarkRed guibg=LightGray
    :hi User7 term=inverse,bold cterm=inverse,bold ctermfg=LightCyan
          \ guifg=Black guibg=LightCyan
    " }}}5

    " 3.2- Interactive loop                {{{4
    let help =  "\r-- Keys available (".help_k.help.")"
    " item selected at the start
    let i = ('check' != a:box) ? default : 1
    let direction = 0 | let toggle = 0
    while 1
      if 'combo' == a:box
        let choice_{i} = substitute(choice_{i}, '^( )', '(*)', '')
      endif
      " Colored statusline
      " Note: unfortunately the 'statusline' is a global option, {{{
      " not a local one. I the hope that may change, as it does not provokes any
      " error, I use '&l:statusline'. }}}
      exe 'let &l:statusline=s:status_line('.string(a:text).', i, type,'. list_choices .')'
      if has(':redrawstatus')
        redrawstatus!
      else
        redraw!
      endif
      " Echo the current selection
      echohl Question
      echon "\r". a:text
      echohl ModeMsg
      echon  ' '.substitute(choice_{i}, '&', '', '')
      echohl None
      " Wait the user to hit a key
      let key=getchar()
      let complType=nr2char(key)
      " If the key hit matched awaited keys ...
      if -1 != stridx(" \<tab>\<esc>\<enter>".hotkeys,complType) ||
            \ (key =~ "\<F1>\\|\<right>\\|\<left>\\|\<s-tab>")
        if key           == "\<F1>"                       " Help      {{{5
          redraw!
          echohl StatusLineNC
          echo help
          echohl None
          let key=getchar()
          let complType=nr2char(key)
        endif
        " TODO: support CTRL-D
        if     complType == "\<enter>"                    " Validate  {{{5
          break
        elseif complType == " "                           " check box {{{5
          let toggle = 1
        elseif complType == "\<esc>"                      " Abort     {{{5
          let i = -1 | break
        elseif complType == "\<tab>" || key == "\<right>" " Next      {{{5
          let direction = 1
        elseif key =~ "\<left>\\|\<s-tab>"                " Previous  {{{5
          let direction = -1
        elseif -1 != stridx(hotkeys, complType )          " Hotkeys   {{{5
          if '' == complType  | continue | endif
          let direction = hotkey_{toupper(complType)} - i
          let toggle = 1
          " else
        endif
        " }}}5
      endif
      if direction != 0 " {{{5
        if 'combo' == a:box
          let choice_{i} = substitute(choice_{i}, '^(\*)', '( )', '')
        endif
        let i +=  direction
        if     i > nb_choices | let i = 1
        elseif i == 0         | let i = nb_choices
        endif
        let direction = 0
      endif
      if toggle == 1    " {{{5
        if 'check' == a:box
          let choice_{i} = ((choice_{i}[1] == ' ')? '[X]' : '[ ]')
                \ . strpart(choice_{i}, 3)
        endif
        let toggle = 0
      endif
    endwhile " }}}4

  finally " 4- Terminate                     {{{3
    " Clear screen
    redraw!
    " Restore statusline
    call cleanup.finalize()
  endtry
  " Return
  if (i == -1) || ('check' != a:box)
    return i
  else
    let r = '' | let i = 1
    while i <= nb_choices
      let r .=  ((choice_{i}[1] == 'X') ? '1' : '0')
      let i +=  1
    endwhile
    return r
  endif
endfunction

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
