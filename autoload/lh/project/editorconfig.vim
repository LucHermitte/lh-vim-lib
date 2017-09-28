"=============================================================================
" File:         autoload/lh/project/editorconfig.vim              {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      4.0.0.
let s:k_version = '400'
" Created:      02nd Aug 2017
" Last Update:  28th Sep 2017
"------------------------------------------------------------------------
" Description:
"       Hook for editorconfig-vim
"       https://github.com/editorconfig/editorconfig-vim
"
" As editorconfig recognizes "foo: bar" as set the "foo" option to "bar" value,
" we cannot support "p:foo.bar = value". It has to be something else.
" Moreover, I'd like to keep supporting LetTo, LetIfUndef, --overwrite and
" --hide
"
" So here is the new syntax:
"   p!foo.bar = value           -> let_to
"   p!overwrite!foo.bar = value -> let_to --overwrite
"   p!hide!foo.bar = value      -> let_to --hide
"   p?foo.bar = value           -> let_if_undef
"   p#name = name               -> Project --define {name}
"
" Note: the capitalization of project $ENV variable is changed by
" editorconfig-vim. I cannot do anything about it...
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#project#editorconfig#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#project#editorconfig#verbose(...)
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

function! lh#project#editorconfig#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## functions {{{1

" Function: lh#project#editorconfig#hook(config) {{{3
function! lh#project#editorconfig#hook(config) abort
  call s:Verbose("lhvl/project: editor config hook -> %1", a:config)
  " let qf = lh#exception#callstack_as_qf('')
  " call setqflist(qf)
  " First of all, if there is a "p#name", it should be applied first
  if has_key(a:config, 'p#name')
    " Trim quotes from project name without evaluating its value with |eval()|.
    let name = substitute(a:config['p#name'], '\v([''"])(.*)\1', '\2', '')
    let name = escape(name, ' ')
    exe 'Project --define ' . name
  endif

  for [k,value] in items(a:config)
    if k =~ '\v^[wbptg][!?]'
      let [all, scope, how, varname; dummy] = matchlist(k, '\v^(\&?[wbptg])(!.*!|[!?])(.*)')
      call s:Verbose("# lh-vim-setting: %1 %2:%3 <- %4", how, scope, varname, value)
      " TODO: check whether we need to add quotes around the expression
      if len(varname) > 1 && varname[0:1] == '$$'
        " Special trick to force the environment variable into CAPS
        let varname = toupper(varname[1:])
      endif
      if     how == '!'
        call lh#let#to(scope.':'.varname.'='.value)
      elseif how == '?'
        call lh#let#if_undef(scope.':'.varname.'='.value)
      elseif how =~ '\v(hide|overwrite)'
        call lh#let#to('--'.how[1:-2].' '.scope.':'.varname.'='.value)
      else
        call lh#common#warning_msg('Warning: '.string(how).' is an invalid way to set a project option. Use "!", "?", "!hide!", or "!overwrite!" in '.string(k.'='.value))
      endif
    else
      call s:Verbose('Ignore %1=%2', k, value)
    endif
  endfor
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
