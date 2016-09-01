"=============================================================================
" File:         autoload/lh/async.vim                             {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      3.13.0.
let s:k_version = '3130'
" Created:      01st Sep 2016
" Last Update:  01st Sep 2016
"------------------------------------------------------------------------
" Description:
"       Various functions to run async jobs
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version      {{{2
function! lh#async#version()
  return s:k_version
endfunction

" # Debug        {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#async#verbose(...)
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

function! lh#async#debug(expr) abort
  return eval(a:expr)
endfunction

" # Requirements {{{2
let s:has_jobs = exists('*job_start') && has("patch-7.4.1980")
if ! s:has_jobs 
  finish
endif

"------------------------------------------------------------------------
" ## Exported functions {{{1
" # Job queue {{{2

" Function: lh#async#queue(job) {{{3
function! lh#async#queue(cmd, args) abort
  call s:job_queue.push_or_start(a:cmd, a:args) 
endfunction

" Function: lh#async#do_clear_queue() {{{3
" Debugging purpose, avoid using this function!!!
" If a job is really running, errors are to be expected
function! lh#async#_do_clear_queue() abort
  call s:Verbose('Clearing job queue. It had %1 element%2 (%3)'
        \ , len(s:job_queue.list)
        \ , len(s:job_queue.list) > 1 ? '' : 's'
        \ , s:job_queue.list
        \)
  let s:job_queue.list = []
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
" # Job queue {{{2
" @invariant Running element has index 0
function! s:is_running() dict abort                " {{{3
  return !empty(self.list)
endfunction

function! s:is_empty() dict abort                  " {{{3
  return empty(self.list)
endfunction

function! s:push_or_start(cmd, args) dict abort    " {{{3
  let self.list += [ {'cmd': a:cmd, 'args': a:args} ]
  call s:Verbose('Push or start job: %1 at %2-th position', self.list[-1], len(self.list))
  if len(self.list) == 1
    " There was nothing, the new job is to be started
    call self.start_next()
  endif
endfunction

function! s:start_next() dict abort                " {{{3
  call assert_true(!self.is_empty())
  let job = self.list[0]
  try
    let success = 0
    call s:Verbose('Starting next job: %1', job)
    let args = job.args
    let args.close_cb = get(args, 'close_cb', function('s:default_close_cb'))
    let Close_cb = args.close_cb
    
    if lh#os#OnDOSWindows() && &shell =~ 'cmd'
      let cmd = &shell . ' ' . &shellcmdflag . ' '.job.cmd
    else
      let cmd = [&shell, &shellcmdflag, job.cmd]
    endif
    let job.job = job_start(cmd, {'close_cb': function('s:close_cb', [Close_cb])})
    if job_info(job.job).status == 'fail' 
      throw "Starting `".(job.cmd)."` failed!"
    endif
    let success = 1
  finally
    " Using a guard+finally instead of catch will leave the v:exception
    " unaltered
    if !success
      call remove(self.list, 0)
    endif
  endtry
endfunction

function! s:default_close_cb(channel)              " {{{3
  call s:Verbose('Job finished (default handler)')
endfunction

function! s:close_cb(user_close_cb, channel) abort " {{{3
  " TODO: bind this function to s:job_queue
  let job = remove(s:job_queue.list, 0)
  try
    call s:Verbose('Job finished %1 -- %2', job.job, job_info(job.job))
    " if !empty(a:user_close_cb)
      call call(a:user_close_cb, [a:channel])
    " endif
  finally
    " Be sure, we always launch the next job
    if !s:job_queue.is_empty()
      call s:job_queue.start_next()
    endif
  endtry
endfunction

" Define job_queue global variable                   {{{3
let s:default_queue = { 'list': [] }
let s:job_queue = get(s:, 'job_queue', s:default_queue)
let s:job_queue.is_running    = function('s:is_running')
let s:job_queue.is_empty      = function('s:is_empty')
let s:job_queue.push_or_start = function('s:push_or_start')
let s:job_queue.start_next    = function('s:start_next')

" Example of Use                                     {{{3
" function! TestCb(...)
"   call s:Verbose('TestCb(%1)', a:000)
" endfunction
" call lh#async#queue('sleep 1', {'close_cb':function('TestCb')})

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
