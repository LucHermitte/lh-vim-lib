"=============================================================================
" File:         autoload/lh/path.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      5.2.1
let s:k_version = 50201
" Created:      23rd Jan 2007
" Last Update:  16th Sep 2020
"------------------------------------------------------------------------
" Description:
"       Functions related to the handling of pathnames
"
"------------------------------------------------------------------------
" Installation:
"       Drop this file into {rtp}/autoload/lh
"       Requires Vim7+
" History:
"       v 1.0.0 First Version
"       (*) Functions moved from searchInRuntimeTime
"       v 2.0.1
"       (*) lh#path#Simplify() becomes like |simplify()| except for trailing
"       v 2.0.2
"       (*) lh#path#SelectOne()
"       (*) lh#path#ToRelative()
"       v 2.0.3
"       (*) lh#path#GlobAsList()
"       v 2.0.4
"       (*) lh#path#StripStart()
"       v 2.0.5
"       (*) lh#path#StripStart() interprets '.' as getcwd()
"       v 2.2.0
"       (*) new functions: lh#path#common(), lh#path#to_dirname(),
"           lh#path#depth(), lh#path#relative_to(), lh#path#to_regex(),
"           lh#path#find()
"       (*) lh#path#simplify() fixed
"       (*) lh#path#to_relative() use simplify()
"       v 2.2.2
"       (*) lh#path#strip_common() fixed
"       (*) lh#path#simplify() new optional parameter: make_relative_to_pwd
"       v 2.2.5
"       (*) fix lh#path#to_dirname('') -> return ''
"       v 2.2.6
"       (*) fix lh#path#glob_as_list() does not return the same path several
"           times
"       v 2.2.7
"       (*) fix lh#path#strip_start() to strip as much as possible.
"       (*) lh#path#glob_as_list() changed to handle **
"       v 3.0.0
"       (*) GPLv3
"       v 3.1.0
"       (*) lh#path#glob_as_list accepts a new option: mustSort which value
"       true by default.
"       v 3.1.1
"       (*) lh#path#strip_start() shall support very big lists of dirnames now.
"       v 3.1.4
"       (*) Force to display numerous choices from lh#path#select_one()
"       vertically
"       v 3.1.9
"       (*) lh#path#is_in() that resolves symbolic links to tell wheither a
"       file is within a directory
"       (*) lh#path#readlink() that resolves symbolic links (where readlink is
"       available)
"       v 3.1.11
"       (*) lh#path#strip_start() can find the best match in the middle of a
"       sequence. This fixes a bug in Mu-Template: the filetype of
"       template-files wasn't always correctly working.
"       v 3.1.12
"       (*) New function: lh#path#add_path_if_exists()
"       v 3.1.14
"       (*) New functions: lh#path#split() and lh#path#join()
"       (*) lh#path#common() fixed as matchstr('^\zs\(.*\)\ze.\{-}@@\1.*$')
"           doesn't work as expected
"       v 3.1.17
"       (*) Fix lh#start#strip_start() to work under windows
"       v 3.2.0
"       (*) New function lh#path#find_in_parents() used in local_vimrc
"       v 3.2.1
"       (*) Bug fix: lh#path#find_in_parents() no more infinite recursion
"           possible
"       v 3.2.2
"       (*) Bug fix: lh#path#find_in_parents() better handling of some paths
"       (see Issue #50)
"       (*) New function lh#path#shellslash()
"       (*) Several functions fixed to take &shellslash into account
"       v3.2.4:
"       (*) new function lh#path#munge()
"       v3.3.0:
"       (*) Steal functions from system-tools
"       v3.3.11
"       (*) Fix lh#path#to_relative() and lh#path#depth()
"       v3.6.1
"       (*) ENH: Use new logging framework
"       v3.6.2
"       (*) BUG: Support comma-separated lists in lh#path#munge()
"       v3.10.4
"       (*) PERF: Optimize lh#path#glob_as_list()
"       v3.13.2
"       (*) ENH: Add `lh#path#remove_dir_mark()`
"       v4.0.0
"       (*) TST: Fix `lh#path#find()` to always work w/ vimrunner
"       (*) Move Permission lists code from local_vimrc
"       (*) Add `p:var` support to `lh#path#add_path_if_exists()`
"       (*) Escape `_` in `lh#path#select_one()` confirm box
"       (*) Support `lh#path#glob_as_list(list`
"       (*) Add `lh#path#is_distant_or_scratch()`
"       (*) Add `lh#path#is_up_to_date()`
"       (*) Improve `lh#path#strip_start()` performances
"       (*) lh#path#split('/foo') will now return 2 elements
"       (*) Recognize empty name buffer as scratch/distant
"       (*) PERF: Improve performances
"       v4.6.1
"       (*) PORT: Provide `lh#path#exe()`
"       v4.6.3
"       (*) PORT: Use `lh#ui#confirm()`
"       v4.6.4
"       (*) BUG: Apply `readlink()` to `munge()`
"       v4.7.0
"       (*) BUG: Fix local_vimrc issue with mswin pathnames
"       v5.2.1
"       (*) BUG: Fix permission lists behaviour
"       (*) ENH: Returns the number of handled files in permission list
" TODO:
"       (*) Fix #simplify('../../bar')
" }}}1
"=============================================================================


"=============================================================================
" Avoid global reinclusion {{{1
let s:cpo_save=&cpo
set cpo&vim

"=============================================================================
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#path#version()
  return s:k_version
endfunction

" # Debug {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#path#verbose(...)
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

function! lh#path#debug(expr) abort
  return eval(a:expr)
endfunction


"=============================================================================
" ## Exported functions {{{1
" # Public {{{2

" Function: lh#path#fix(pathname [, shellslash [, quote_char ]]) {{{3
" This function was FixEnsurePath from system_tools
function! lh#path#fix(pathname, ...) abort
  " Parameters       {{{4
  " Ignore the last slash or backslash character, if any
  let pathname   = matchstr(a:pathname, '^.*[^/\\]')
  " Default value for the quote character
  let quote_char = ''
  " Determine if 'shellslash' exists (dos-like platforms)
  if lh#os#OnDOSWindows()
    if lh#os#system_detected() == 'msdos'
      let shellslash = 0
    else
      let shellslash = &shellslash
    endif
  else "unix
    let shellslash = 1
  endif
  " Determine if we will use slashes or backslashes to distinguish directories
  if a:0 >= 1   "
    let shellslash = a:1
    if a:0 >= 2
      let quote_char = a:2
    endif
  endif

  " Smart definition of quote chars for $COMSPEC
  if (lh#os#system_detected() == 'msdos') && !shellslash && (''==quote_char)
    if (&shell =~ 'command\.com')
      if pathname =~ ' '
        " should also test long directory-names...
        " Best: AVOID command.com !!!
        if &verbose >= 1
          call lh#common#error_msg('lh#path#fix: '.
                \ 'Problem expected because of the space in <'.pathname.'>')
        endif
      else
        let quote_char = ''
      endif
    else
      let quote_char = '"'
    endif
  endif

  " Fix the pathname {{{4
  if shellslash
    " return substitute(dname, '\\\([^ ]\|$\)', '/\1', 'g')
    let res = substitute(
          \ substitute(pathname, '\\\([^ ]\|$\)', '/\1', 'g'),
          \ '\(^\|[^\\]\) ', '\1\\ ', 'g')
  else
    " return substitute(
          " \ substitute(pathname, '\([^\\]\) ', '\1\\ ', 'g'),
          " \ '/', '\\', 'g')
    let res = substitute(
          \ substitute(pathname, '\\ ', ' ', 'g'),
          \ '/', '\\', 'g')
  endif
  " Note: problem to take care (that explains the complex substition schemes):
  " sometimes the path passed to the function mix the two writtings, e.g.:
  " "c:\Program Files/longpath/some\ spaces/foo"
  " }}}4
  return quote_char . res . quote_char
endfunction

" Function: lh#path#simplify({pathname}, [make_relative_to_pwd=true]) {{{3
" Like |simplify()|, but also strip the leading './'
" It seems unable to simplify '..\' when compiled without +shellslash
function! lh#path#simplify(pathname, ...) abort
  let make_relative_to_pwd = a:0 == 0 || a:1 == 1
  let pathname = simplify(a:pathname)
  let pathname = substitute(pathname, '^\%(\.[/\\]\)\+', '', '')
  let pathname = substitute(pathname, '\([/\\]\)\%(\.[/\\]\)\+', '\1', 'g')
  if make_relative_to_pwd
    let pwd = getcwd().'/'
    let pathname = substitute(pathname, '^'.lh#path#to_regex(pwd), '', 'g')
  endif
  return pathname
endfunction
function! lh#path#Simplify(pathname)
  return lh#path#simplify(a:pathname)
endfunction

" Function: lh#path#split(pathname) {{{3
" Split pathname parts: "/home/me/foo/bar" -> [ "home", "me", "foo", "bar" ]
function! lh#path#split(pathname) abort
  let parts = (strpart(a:pathname, 0, 1) =~ '[/\\]' ? [''] : [])
        \ + split(a:pathname, '[/\\]')
  return parts
endfunction

" Function: lh#path#join(pathparts, {path_separator}) {{{3
function! lh#path#join(pathparts, ...) abort
  let sep
        \ = (a:0) == 0                       ? '/'
        \ : type(a:1)==type(0) && (a:1) == 0 ? '/'
        \ : (a:1) == 1                       ? '\'
        \ : (a:1) =~ 'shellslash\|ssl'       ? (&ssl ? '\' : '/')
        \ :                                    (a:1)
  return join(a:pathparts, sep)
endfunction

" Function: lh#path#common({pathnames}) {{{3
" Find the common leading path between all pathnames
function! lh#path#common(pathnames) abort
  call lh#assert#not_empty(a:pathnames)
  let common = a:pathnames[0]
  let lCommon = lh#path#split(common)
  let i = 1
  while i < len(a:pathnames)
    let fcrt = a:pathnames[i]
    " Can't make it work => split paths, and test each subdir manually...
    " let common = matchstr(common.'@@'.fcrt, '^\zs\(.*[/\\]\)\ze.\{-}@@\1.*$')
    " let common = matchstr(common.'@@'.fcrt, '^\zs\(.*\>\)\ze.\{-}@@\1\>.*$')
    let lFcrt = lh#path#split(fcrt)
    let Mcrt = len(lFcrt)
    let Mcom = len(lCommon)
    let p = 0
    while 1
      if p == Mcom
        break
      elseif p==Mcrt || lCommon[p] != lFcrt[p]
        call remove(lCommon, p, -1)
        break
      endif
      let p += 1
    endwhile
    if len(lCommon) == 0 " No need to further checks
      break
    endif
    let i += 1
  endwhile
  return join(lCommon, '/')
endfunction

" Function: lh#path#strip_common({pathnames}) {{{3
" Find the common leading path between all pathnames, and strip it
function! lh#path#strip_common(pathnames) abort
  call lh#assert#not_empty(a:pathnames)
  let common = lh#path#common(a:pathnames)
  let common = lh#path#to_dirname(common)
  let l = strlen(common)
  if l == 0
    return a:pathnames
  else
    let pathnames = a:pathnames
    call map(pathnames, 'strpart(v:val, '.l.')' )
    call map(pathnames, 'substitute(v:val, "^/", "", "")' )
    return pathnames
  endif
endfunction
function! lh#path#StripCommon(pathnames)
  return lh#path#strip_common(a:pathnames)
endfunction

" Function: lh#path#is_absolute_path({path}) {{{3
function! lh#path#is_absolute_path(path) abort
  return a:path =~ '^/'
        \ . '\|^[a-zA-Z]:[/\\]'
        \ . '\|^[/\\]\{2}'
  "    Unix absolute path
  " or Windows absolute path
  " or UNC path
endfunction
function! lh#path#IsAbsolutePath(path)
  return lh#path#is_absolute_path(a:path)
endfunction

" Function: lh#path#is_url({path}) {{{3
function! lh#path#is_url(path) abort
  " todo: support UNC paths and other urls
  return a:path =~ '^\%(https\=\|s\=ftp\|dav\|fetch\|file\|rcp\|rsynch\|scp\)://'
endfunction
function! lh#path#IsURL(path)
  return lh#path#is_url(a:path)
endfunction

" Function: lh#path#is_distant_or_scratch(path) {{{3
function! lh#path#is_distant_or_scratch(path) abort
  return a:path =~ '\v://|^//|^\\\\|^$'
        \ || getbufvar(bufnr(a:path), '&buftype') =~ 'nowrite\|nofile\|quickfix'
endfunction

" Function: lh#path#select_one({pathnames},{prompt}) {{{3
function! lh#path#select_one(pathnames, prompt) abort
  if len(a:pathnames) > 1
    let simpl_pathnames = deepcopy(a:pathnames)
    let simpl_pathnames = lh#path#strip_common(simpl_pathnames)
    let simpl_pathnames = [ '&Cancel' ] + map(simpl_pathnames, 'substitute(v:val, "_", "&&", "g")')
    " Consider guioptions+=c in case of difficulties with the gui
    try
      let guioptions_save = &guioptions
      set guioptions+=v
      let selection = lh#ui#confirm(a:prompt, join(simpl_pathnames,"\n"), 1, 'Question')
    finally
      let &guioptions = guioptions_save
    endtry
    let file = (selection == 1) ? '' : a:pathnames[selection-2]
    return file
  elseif len(a:pathnames) == 0
    return ''
  else
    return a:pathnames[0]
  endif
endfunction
function! lh#path#SelectOne(pathnames, prompt)
  return lh#path#select_one(a:pathnames, a:prompt)
endfunction

" Function: lh#path#to_relative({pathname}) {{{3
" Notes:
" - ":p:." turns getcwd().'/../bar' into an absolute path
" - ":~:." turns getcwd().'/../bar' into "../bar"
" - ":p:." turns getcwd().'/./foo' into "foo"
" - ":~:." turns getcwd().'/./foo' into "./foo"
" Hence lh#path#simplify() executed at the end.
function! lh#path#to_relative(pathname) abort
  " let newpath = fnamemodify(a:pathname, ':p:.')
  let newpath = fnamemodify(a:pathname, ':~:.')
  let newpath = lh#path#simplify(newpath)
  return newpath
endfunction
function! lh#path#ToRelative(pathname) abort
  return lh#path#to_relative(a:pathname)
endfunction

" Function: lh#path#to_dirname({dirname}) {{{3
function! lh#path#to_dirname(dirname) abort
  let dirname = a:dirname . (empty(a:dirname) || a:dirname[-1:] =~ '[/\\]'
        \ ? '' : lh#path#shellslash())
  return dirname
endfunction

" Function: lh#path#remove_dir_mark(dirname) {{{3
function! lh#path#remove_dir_mark(dirname) abort
  return substitute(a:dirname, '\v.{-}\zs[/\\]$', '', '')
endfunction

" Function: lh#path#depth({dirname}) {{{3
" todo: make a choice about "negative" paths like "../../foo"
function! lh#path#depth(dirname) abort
  if empty(a:dirname) | return 0 | endif
  let dirname = lh#path#to_dirname(a:dirname)
  let dirname = lh#path#simplify(dirname)
  if lh#path#is_absolute_path(dirname)
    let dirname = matchstr(dirname, '.\{-}[/\\]\zs.*')
  endif
  let parts = split(dirname, '[/\\]')
  let depth = len(parts) - 2 * count(parts, '..')
  return depth
endfunction

" Function: lh#path#relative_to({from}, {to}) {{{3
" @param two directories
" @return a directories delta that ends with a '/' (may depends on
" &shellslash)
function! lh#path#relative_to(from, to) abort
  " let from = fnamemodify(a:from, ':p')
  " let to   = fnamemodify(a:to  , ':p')
  let from = lh#path#to_dirname(a:from)
  let to   = lh#path#to_dirname(a:to  )
  let [from, to] = lh#path#strip_common([from, to])
  let nb_up =  lh#path#depth(from)
  return repeat('..'.lh#path#shellslash(), nb_up).to

  " cannot rely on :cd (as it alters things, and doesn't work with
  " non-existant paths)
  let pwd = getcwd()
  call lh#path#cd_without_sideeffects(a:to)
  let res = lh#path#to_relative(a:from)
  call lh#path#cd_without_sideeffects(pwd)
  return res
endfunction

" Function: lh#path#glob_as_list({pathlist}, {expr} [, mustSort=1]) {{{3
if has("patch-7.4.279") || (v:version == 704 && has('patch279'))
  " Either version >= 7.4.237 and `has('patch-7.4.279')` detects correctly, or
  " we can fall back to old detection, assuming that we still need to test v 7.4,
  function! s:DoGlobPath(pathlist, expr) abort
    let pathlist = type(a:pathlist) == type([]) ? join(a:pathlist, ',') : a:pathlist
    return globpath(pathlist, a:expr, 1, 1)
  endfunction
else
  function! s:DoGlobPath(pathlist, expr) abort
    let pathlist = type(a:pathlist) == type([]) ? join(a:pathlist, ',') : a:pathlist
    let sResult = globpath(pathlist, a:expr, 1)
    let lResult = split(sResult, '\n')
    return lResult
  endfunction
endif

function! s:GlobAsList(pathlist, expr,  mustSort) abort
  let lResult = s:DoGlobPath(a:pathlist, a:expr)
  " workaround a non feature of wildignore: it does not ignore directories
  let ignored_directories = filter(split(&wildignore, ','), 'stridx(v:val, "/")!=-1')
  if !empty(ignored_directories)
    let ignored_directories_pat = '\v'.join(ignored_directories, '|')
    call filter(lResult, 'v:val !~ ignored_directories_pat')
  endif
  return a:mustSort ? lh#list#unique_sort(lResult) : lResult
endfunction

function! lh#path#glob_as_list(pathlist, expr, ...) abort
  let mustSort = (a:0 > 0) ? (a:1) : 0
  if type(a:expr) == type('string')
    return s:GlobAsList(a:pathlist, a:expr, mustSort)
  elseif type(a:expr) == type([])
    let res = []
    call map(copy(a:expr), 'extend(res, s:GlobAsList(a:pathlist, v:val, mustSort))')
    " for expr in a:expr
      " call extend(res, s:GlobAsList(a:pathlist, expr, mustSort))
    " endfor
    return res
  else
    throw "Unexpected type for a:expression"
  endif
endfunction
function! lh#path#GlobAsList(pathlist, expr)
  return lh#path#glob_as_list(a:pathlist, a:expr)
endfunction

" Function: lh#path#strip_start({pathname}, {pathlist}) {{{3 abort
" Strip occurrence of paths from {pathlist} in {pathname}
" @param[in] {pathname} name to simplify
" @param[in] {pathlist} list of pathname (can be a |string| of pathnames
" separated by ",", of a |List|).
" @note Unfortunatelly, this function is quite slow
function! s:prepare_pathlist_for_strip_start(pathlist)
  if type(a:pathlist) == type('string')
    " let strip_re = escape(a:pathlist, '\\.')
    " let strip_re = '^' . substitute(strip_re, ',', '\\|^', 'g')
    let pathlist = split(a:pathlist, ',')
  elseif type(a:pathlist) == type([])
    let pathlist = deepcopy(a:pathlist)
  else
    throw "Unexpected type for a:pathname"
  endif

  " apply a realpath like operation
  let pathlist_abs=filter(copy(pathlist), 'v:val =~ "^\\.\\%(/\\|$\\)"')
  let pathlist += pathlist_abs
  " replace path separators by a regex that can match them
  call map(pathlist, 'substitute(v:val, "[\\\\/]", "[\\\\/]", "g")."[\\/]\\="')
  " echomsg string(pathlist)
  " escape . and ~
  call map(pathlist, '"^".escape(v:val, ".~")')
  " handle "**" as anything
  call map(pathlist, 'substitute(v:val, "\\*\\*", "\\\\%([^\\\\/]*[\\\\/]\\\\)*", "g")')
  " reverse the list to use the real best match, which is "after"
  call reverse(pathlist)

  return pathlist
endfunction

function! s:find_best_match(pathname, pathlist) abort
  let matches = map(copy(a:pathlist), 'substitute(a:pathname, v:val, "", "")')
  let best_match_idx = lh#list#arg_min(matches, function('len'))
  return matches[best_match_idx]
endfunction

function! lh#path#strip_start(pathname, pathlist) abort
  let pathlist = s:prepare_pathlist_for_strip_start(a:pathlist)
  if !empty(pathlist)
    let pathnames = type(a:pathname) == type([]) ? copy(a:pathname) : [a:pathname]
    let res = map(pathnames, 's:find_best_match(v:val, pathlist)')
  else
    let res = a:pathname
  endif
  return type(a:pathname) == type([]) ? res : res[0]
endfunction
function! lh#path#StripStart(pathname, pathlist)
  return lh#path#strip_start(a:pathname, a:pathlist)
endfunction

" Function: lh#path#to_regex({pathname}) {{{3
function! lh#path#to_regex(path) abort
  let regex = substitute(a:path, '[/\\]', '[/\\\\]', 'g')
  return regex
endfunction

" Function: lh#path#find({pathname}, {regex}) {{{3
function! lh#path#find(paths, regex) abort
  let paths = (type(a:paths) == type([]))
        \ ? (a:paths)
        \ : split(a:paths,',')
  call filter(paths, 'match(v:val, a:regex) != -1')
  let shortest = lh#list#arg_min(paths, function('len'))
  return empty(paths) ? '' : paths[shortest]
endfunction

" Function: lh#path#find_upward(what, [from=expand('%:p:h')]) {{{3
function! lh#path#find_upward(what, ...) abort
  call lh#assert#value(a:what).not().empty()
  let path = a:0 == 0 ? expand('%:p:h') : a:1
  call lh#assert#value(path).not().verifies('lh#path#is_distant_or_scratch')
  if a:what[-1 : ] == '/' " directory name
    let r = finddir(a:what, path. ';')
    let mod = ':p:h:h'
    let node_exist = 'isdirectory'
  else
    let r = findfile(a:what, path. ';')
    let mod = ':p:h'
    let node_exist = 'filereadable'
  endif
  if !empty(r)
    let r = fnamemodify(r, mod)
    call lh#assert#value(r.'/'.a:what).verifies(node_exist)
  endif
  return r
endfunction

" Function: lh#path#vimfiles() {{{3
function! lh#path#vimfiles() abort
  let re_HOME = lh#path#to_regex($HOME.'/')
  let re_LUCHOME = exists('$LUCHOME') ? '\|'.lh#path#to_regex($LUCHOME.'/'): ''
  let what = '\%('.re_HOME.re_LUCHOME.'\)'.'\(vimfiles\|\.vim\|\.config[/\\]nvim\)'
  " Comment what
  let z = lh#path#find(&rtp,what)
  return z
endfunction

" Function: lh#path#is_in(file, path) {{{3
function! lh#path#is_in(file, path) abort
  if stridx(a:file, a:path) == 0
    return 1
  else
    " try to check with readlink
    return stridx(lh#path#readlink(a:file), lh#path#readlink(a:path)) == 0
  endif
endfunction

" Function: lh#path#readlink(pathname) {{{3
if executable('greadlink')
  let s:k_readlink = 'greadlink -f '
elseif !has('osx') && executable('readlink')
  " TODO: a better test for the availability of `readlink -f`  shall be
  " implemented.
  let s:k_readlink = 'readlink -f '
elseif executable('realpath')
  let s:k_readlink = 'realpath '
endif
function! lh#path#readlink(pathname) abort
  if exists('s:k_readlink')
    return lh#os#system(s:k_readlink.shellescape(a:pathname))
  else
    return resolve(a:pathname)
  endif
endfunction

" Function: lh#path#add_path_if_exists(listname, path) {{{3
function! lh#path#add_path_if_exists(listname, path) abort
  let path = substitute(a:path, '[/\\]\*\*$', '', '')
  if isdirectory(path)
    if type(a:listname) == type('') && a:listname =~ '^p:'
      let var = lh#project#_get(a:listname[2:])
      let var += [a:path]
    else
      let {a:listname} += [a:path]
    endif
  endif
endfunction

" Function: lh#path#shellslash() {{{3
function! lh#path#shellslash() abort
  return exists('+shellslash') && !&ssl ? '\' : '/'
endfunction

" Function: lh#path#find_in_parents(path, path_patterns, kinds, last_valid_path) {{{3
" @param {last_valid_path} will likelly contain a REGEX pattern aimed at
" identifying things like $HOME
let s:indent = 1
function! lh#path#find_in_parents(path, path_patterns, kinds, last_valid_path) abort
  let indent_str = repeat('  ', s:indent)
  call s:Verbose('%5#path#find_in_parents(%1, %2, %3, %4)', a:path, a:path_patterns, a:kinds, a:last_valid_path, indent_str)
  try
    let s:indent += 1
    if a:path =~ '^\(//\|\\\\\)$'
      " The root path (/) is not a place where to store files like _vimrc_local
      call s:Verbose('%1Stop recursion in UNC invalid root path: '.a:path, indent_str)
      return []
    elseif a:path =~ '^\v(|\a:[/\\]*|[/\\])$'
      " The root path (/) is not a place where to store files like _vimrc_local
      call s:Verbose('%1Wont recurse anymore in root path: '.a:path, indent_str)
      let can_try_to_recurse = 0
    else
      let can_try_to_recurse = 1
    endif

    let res = []

    let path = fnamemodify(a:path, ':p')

    if can_try_to_recurse
      if path[len(path)-1] =~ '[/\\]'
        let path = path[:-2]
      endif
      let up_path = fnamemodify(path,':h')
      if up_path == '.' " Likely a non existent path
        if ! isdirectory(path)
          call lh#common#warning_msg("The current file '".expand('%:p:')."' seems to be in a non-existent directory: '".path."'")
        endif
        let up_path = getcwd()
      endif
      " call confirm('crt='.path."\nup=".up_path."\n$HOME=".s:home, '&Ok', 1)
      " echomsg ('crt='.path."\nup=".up_path."\n$HOME=".s:home)

      " Recursive call:
      " - first check the parent directory
      if path !~ a:last_valid_path && path != up_path
        " Terminal condition
        let res += lh#path#find_in_parents(up_path, a:path_patterns, a:kinds, a:last_valid_path)
      else
        call s:Verbose('%1Terminal condition reached: path '.path.' matches '.string(a:last_valid_path). ' or parent dir is the same', indent_str)

      endif
    endif

    " - then check the current path
    "   Unless it's not a directory
    if ! isdirectory(path)
      return res
    endif
    " Restore the trailling '/'
    if empty(path) || path[len(path)-1] !~ '[/\\]'
      let path .= lh#path#shellslash()
    endif
    let path_patterns = type(a:path_patterns) == type([]) ? a:path_patterns : [a:path_patterns]
    let smthg_found = 0
    for pattern in path_patterns
      let tested_path = path.pattern
      if a:kinds =~ '.*dir.*' && isdirectory(tested_path)
        let res += [tested_path]
        let smthg_found = 1
        call s:Verbose('%1Check '.path.' ... '.pattern.' directory found!', indent_str)
      elseif a:kinds =~ '.*file.*' && filereadable(tested_path)
        let res += [tested_path]
        let smthg_found = 1
        call s:Verbose('%1Check '.path.' ... '.pattern.' file found!', indent_str)
      endif
    endfor
    if smthg_found == 0
      call s:Verbose('%1Check '.path.' for '.string(path_patterns).' ... none found!', indent_str)
    endif
  finally
    let s:indent -= 1
  endtry

  return res
endfunction

" Function: lh#path#munge(pathlist, path [, sep]) {{{3
function! lh#path#munge(pathlist, path, ...) abort
  let path = resolve(a:path)
  if type(a:pathlist) == type('str')
    let sep = get(a:, 1, ',')
    let pathlist = split(a:pathlist, sep)
    return join(lh#path#munge(pathlist, path), sep)
  else
    " if filereadable(path) || isdirectory(path)
    if ! empty(glob(path))
      call lh#list#push_if_new(a:pathlist, path)
    endif
    return a:pathlist
  endif
endfunction

" Function: lh#path#exe(pathname) {{{3
" @return the full path of an executable; emulate |exepath()| on old Vim
" versions
" @since Version 4.6.1
if exists('*exepath')
  function! lh#path#exe(exe) abort
    return exepath(a:exe)
  endfunction
else
  function! lh#path#exe(exe) abort
    let PATH = join(split($PATH, has('unix') ? ':' : ';'), ',')
    return join(filter(split(globpath(PATH, a:exe), "\n"), 'executable(v:val)')[:0], '')
  endfunction
endif

" Function: lh#path#exists(pathname) {{{3
" @return whether the file is readable or a buffer with the same name exists
function! lh#path#exists(pathname) abort
  return filereadable(a:pathname) || bufexists(a:pathname)
endfunction

" Function: lh#path#writable(pathname) {{{3
" @return whether the file exists and is writable, or whether it could be
" created in the requested directory
" Unlike |filewritable()|, non existing files aren't rejected.
" @since Version 4.6.0
function! lh#path#writable(pathname) abort
  return isdirectory(a:pathname)
        \ ? filewritable(a:pathname)
        \ : filewritable(a:pathname) || 2 == filewritable(fnamemodify(a:pathname, ':h'))
endfunction

" Function: lh#path#is_up_to_date(file1, file2) {{{3
" @pre file1 exists and can be read
" @return whether date(f1) <= date(f2)
function! lh#path#is_up_to_date(file1, file2) abort
  call lh#assert#true(filereadable(a:file1))
  if filereadable( a:file2 )
    let d1 = getftime( a:file1 )
    let d2 = getftime( a:file2 )
    return d1 <= d2
  endif
  return 0
endfunction

" Function: lh#path#cd_without_sideeffects(path) {{{3
" @since Version 4.0.0
function! lh#path#cd_without_sideeffects(path) abort
  let cd = exists('*haslocaldir') && haslocaldir()
        \ ? 'lcd '
        \ : 'cd '
  exe cd . a:path
endfunction

" # Permission lists {{{2
" @since v4.0.0, code moved from local_vimrc
" Function: lh#path#new_permission_lists(options) {{{3
" @pre a:options shall contain:
"  - "_do_handle(file)", e.g. { file -> execute('source '.escape(file, ' \$')) }
"  - "_action_name", e.g. source
function! lh#path#new_permission_lists(options) abort
  if !has_key(a:options, '_action_name')
    throw "Invalid use of `lh#path#new_filtered_list()`"
  endif
  let res = lh#object#make_top_type(a:options)
  let res.valided_paths    = []
  let res.rejected_paths   = []
  let res.prepare          = function(s:getSNR('lists_prepare'))
  let res.handle_paths     = function(s:getSNR('lists_handle_paths'))
  let res.handle_file      = function(s:getSNR('lists_handle_file'))
  let res.check_paths      = function(s:getSNR('lists_check_paths'))
  let res.is_file_accepted = function(s:getSNR('lists_is_file_accepted'))

  return res
endfunction

" Methods: {{{3
" - prepare() {{{4
function! s:lists_prepare() dict abort
  let whitelist   = s:GetList('whitelist'  , self)
  let blacklist   = s:GetList('blacklist'  , self)
  let asklist     = s:GetList('asklist'    , self)
  let sandboxlist = s:GetList('sandboxlist', self)

  let mergedlists = whitelist + blacklist + asklist + sandboxlist
  call reverse(sort(mergedlists, function(s:getSNR('SortLists'))))
  return mergedlists
endfunction

" - handle_paths() {{{4
function! s:lists_handle_paths(paths) dict abort
  let n = 0
  if !empty(a:paths)
    let indent_str = repeat('  ', s:indent)
    let filtered_pathnames = self.prepare()
    let fp_keys = map(copy(filtered_pathnames), '"^".lh#path#to_regex((v:val)[0])')
    for path in a:paths
      let idx = lh#list#find_if(fp_keys, string(fnamemodify(path, ':h')).'=~ v:1_')
      let permission = (idx != -1)
            \ ? filtered_pathnames[idx][1]
            \ : "default"
      call s:Verbose('%5%1 =~ fp_keys[%2]=%3 -- %4', fnamemodify(path, ':h'), idx, (idx != -1 ? fp_keys[idx] : 'default'), permission, indent_str)
      let n += self.handle_file(path, permission)
    endfor
  endif
  return n
endfunction

" - handle_file() {{{4
function! s:lists_handle_file(file, permission) dict abort
  if !has_key(self, '_do_handle')
    throw "Invalid use of `lh#path#new_filtered_list().handle_file()`"
  endif
  let filepat = escape(a:file, '\.')
  if a:permission == 'blacklist'
    call s:Verbose( '(blacklist) Ignoring ' . a:file)
    return 0
  elseif a:permission == 'sandboxlist'
    call s:Verbose( '(sandbox) '. self._action_name . ' '. a:file)
    sandbox call self._do_handle(a:file)
    return 1
  elseif match(self.rejected_paths, filepat) >= 0
    call s:Verbose('Path %1 has already been rejected for this session.', a:file)
    return 0
    " TODO: add a way to remove pathnames from validated list
  elseif match(self.valided_paths, filepat) >= 0
    call s:Verbose('Path %1 has already been validated for this session.', a:file)
    " TODO: add a way to remove pathnames from validated list
  elseif a:permission == 'asklist'
    let choice = lh#ui#confirm('Do you want to '. self._action_name. ' "'.a:file.'"?', "&Yes\n&No\n&Always\nNe&ver", 1)
    if choice == 3 " Always
      call s:Verbose("Add %1 to current session whitelist", a:file)
      call lh#path#munge(self.valided_paths, a:file)
    elseif choice == 4 " Never
      call s:Verbose("Add %1 to current session blacklist", a:file)
      call lh#path#munge(self.rejected_paths, a:file)
      return 0
    elseif choice != 1 " not Yes
      return 0
    endif
  endif
  call s:Verbose('('.a:permission.') '. self._action_name. ' ' . a:file)
  call self._do_handle(a:file)
  return 1
endfunction

" - check_paths() {{{4
function! s:lists_check_paths(paths) dict abort
  if !empty(a:paths)
    let filtered_pathnames = self.prepare()
    let fp_keys = map(copy(filtered_pathnames), '"^".lh#path#to_regex((v:val)[0])')
    for path in a:paths
      let idx = lh#list#find_if(fp_keys, string(fnamemodify(path, ':h')).'=~ v:1_')
      let permission = (idx != -1)
            \ ? filtered_pathnames[idx][1]
            \ : "default"
      call s:Verbose('%1 =~ fp_keys[%2]=%3 -- %4', fnamemodify(path, ':h'), idx, fp_keys[idx], permission)
      return self.is_file_accepted(path, permission)
    endfor
  endif
endfunction

" - is_file_accepted() {{{4
function! s:lists_is_file_accepted(file, permission) dict abort
  let filepat = escape(resolve(a:file), '\.')
  if a:permission == 'blacklist'
    call s:Verbose( '(blacklist) Ignoring ' . a:file)
    return 0
  elseif a:permission == 'sandboxlist'
    call s:Verbose( '(sandbox) '. self._action_name . ' '. a:file)
    return 'sandbox'
  elseif match(self.rejected_paths, filepat) >= 0
    call s:Verbose('Path %1 has already been rejected.', a:file)
    return 0
    " TODO: add a way to remove pathnames from validated list
  elseif match(self.valided_paths, filepat) >= 0
    call s:Verbose('Path %1 has already been validated.', a:file)
    " TODO: add a way to remove pathnames from validated list
  elseif a:permission == 'asklist'
    let choice = lh#ui#confirm('Do you want to '. self._action_name. ' "'.a:file.'"?', "&Always\n&Yes\n&No\nNe&ver", 1)
    if     choice == 1 " Always
      call lh#path#munge(self.valided_paths, a:file)
    " elseif choice == 2 " Yes
    " elseif choice == 3 " No
    elseif choice == 4 " Never
      call lh#path#munge(self.rejected_paths, a:file)
    endif
    return choice <= 2
  endif
  call s:Verbose('('.a:permission.') '. self._action_name. ' ' . a:file)
  return 1
endfunction

"=============================================================================
" ## Internal functions {{{1
" # Prepare Permission lists {{{2
" Function: s:SortLists(lhs, rhs) {{{3
function! s:SortLists(lhs, rhs)
  return    (a:lhs)[0] <  (a:rhs)[0] ? -1
        \ : (a:lhs)[0] == (a:rhs)[0] ? 0
        \ :                            1
endfunction

" Function: s:GetList(listname, options) {{{3
function! s:GetList(listname, options)
  let list = copy(get(a:options, a:listname, []))
  call map(list, '[substitute(v:val, "[/\\\\]", lh#path#shellslash(), "g"), a:listname]')
  return list
endfunction

" # Misc {{{2
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
