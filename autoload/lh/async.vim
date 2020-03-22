"=============================================================================
" File:         autoload/lh/async.vim                             {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      5.0.0
let s:k_version = '050000'
" Created:      01st Sep 2016
" Last Update:  22nd Mar 2020
"------------------------------------------------------------------------
" Description:
"       Various functions to run async jobs
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:
" - Merge identical jobs, or ask to cancel previous and add again
" - Reorganize jobs in `:Job`  dialog
" - Attach continuations à la _and then_
"   e.g. `:Make install` may depend on another make job
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version          {{{2
function! lh#async#version()
  return s:k_version
endfunction

" # Debug            {{{2
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

" # Requirements     {{{2
let s:has_jobs = lh#has#jobs()
if ! s:has_jobs
  finish
endif

" # Helper functions {{{2
function! s:getSID() abort
  return eval(matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_getSID$'))
endfunction
let s:k_script_name      = s:getSID()

"------------------------------------------------------------------------
" ## Constants          {{{1
let s:k_job_methods = [
      \ 'close_cb', 'in_cb', 'out_cb', 'err_cb', 'exit_cb', 'callback',
      \ 'timeout', 'out_timeout', 'err_timeout', 'stoponexit',
      \ 'in_mode', 'out_mode', 'err_mode',
      \ 'term', 'channel',
      \ 'in_io', 'in_top', 'in_bot', 'in_name', 'in_buf',
      \ 'out_io', 'out_top', 'out_bot', 'out_name', 'out_buf', 'out_modifiable',
      \ 'err_io', 'err_top', 'err_bot', 'err_name', 'err_buf', 'err_modifiable',
      \ 'block_write'
      \ ]

"------------------------------------------------------------------------
" ## Exported functions {{{1
" # Job queue {{{2
" TODO: use different named queues ("qf", "tags") and unnamed (loclist for
" current window...) that can have different properties:
" stack-by-default, remplace-by-default, always-ask...

" Function: lh#async#_new_queue(name, default_behaviour) {{{3
function! lh#async#_new_queue(name, default_behaviour) abort
  let queue = lh#object#make_top_type({ 'list': [], 'state': 'active', 'name': a:name, 'default_behaviour': a:default_behaviour })
  call lh#object#inject_methods(queue, s:k_script_name,
        \ 'is_running', 'is_empty', 'is_paused',
        \ 'push_or_start', 'start_next',
        \ '_unsafe_stop_job', '_check_start_next', '_unpause_jobs',
        \ '_build_ui_lines', '_update_ui', '_cancel_jobs_ui', '_do_clear_queue')
  call lh#object#inject(queue, 'stop', 'stop_job', s:k_script_name)
  return queue
endfunction

" Function: lh#async#get_queue(name, default_behaviour) {{{3
let s:queues = get(s:, 'queues', {})
function! lh#async#get_queue(name, default_behaviour) abort
  if ! has_key(s:queues, a:name)
    let s:queues[a:name] = lh#async#_new_queue(a:name, a:default_behaviour)
  endif
  return s:queues[a:name]
endfunction

" Function: lh#async#queue(queue_name, job) {{{3
function! lh#async#queue(queue_name, job) abort
  call lh#notify#deprecated('lh#async#queue(name,job)', 'lh#async#get_queue(name,policy).push_or_start(job)')
  let queue = lh#async#get_queue(a:queue_name, '')
  call queue.push_or_start(a:job)
endfunction

" Function: lh#async#stop(queue_name, id) {{{3
function! lh#async#stop(queue_name, id) abort
  let queue = lh#async#get_queue(a:queue_name, '')
  call s:Verbose('Try to stop %1 in %2 queue', a:id, a:queue_name)
  call queue.stop(a:id)
endfunction

" Function: lh#async#_unpause_jobs(queue_name) {{{3
function! lh#async#_unpause_jobs(queue_name) abort
  let queue = lh#async#get_queue(a:queue_name, '')
  call queue._unpause_jobs()
endfunction

" Function: lh#async#_do_clear_queue() {{{3
" Debugging purpose, avoid using this function!!!
" If a job is really running, errors are to be expected
function! lh#async#_do_clear_queue(queue_name) abort
  let queue = lh#async#get_queue(a:queue_name, '')
  call queue._do_clear_queue()
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
" # accessors {{{2

function! s:_get_existing_queue(name) abort " {{{3
  if !has_key(s:queues, a:name)
    throw 'No job queue named <'.a:name.'> exists'
  endif
  return s:queues[a:name]
endfunction

" Function: lh#async#_get_jobs() {{{3
" NB: used from airline extension
function! lh#async#_get_jobs() abort
  let list = []
  call map(copy(s:queues), {k,v -> extend(l:list, v.list)})
  let nb_paused = eval(join(map(copy(values(s:queues)), {k,v -> v.is_paused()}), '+'))
  return [list, nb_paused]
endfunction

"------------------------------------------------------------------------
" # command completion {{{2
" Function: lh#async#_complete_job_names(ArgLead, CmdLine, CursorPos) {{{3
function! lh#async#_complete_job_names(ArgLead, CmdLine, CursorPos) abort
  let ids = lh#list#get(s:job_queue.list, 'txt', 'v:val.cmd')
  let res = filter(ids, 'v:val =~ a:ArgLead')
  return res
endfunction

" Function: lh#async#_job_queue_names(ArgLead, CmdLine, CursorPos) {{{3
function! lh#async#_job_queue_names(ArgLead, CmdLine, CursorPos) abort
  call s:Verbose('lh#async#_job_queue_names({1.ArgLead}, {1.CmdLine}, {1.CursorPos})', a:)
  let names = keys(s:queues)
  let res = filter(names, 'v:val =~ a:ArgLead')
  return res
endfunction

" Function: lh#async#_paused_job_queue_names(ArgLead, CmdLine, CursorPos) {{{3
function! lh#async#_paused_job_queue_names(ArgLead, CmdLine, CursorPos) abort
  call s:Verbose('lh#async#_paused_job_queue_names({1.ArgLead}, {1.CmdLine}, {1.CursorPos})', a:)
  let queues = filter(copy(s:queues), 'v:val.is_paused()')
  let names = keys(queues)
  let res = filter(names, 'v:val =~ a:ArgLead')
  return res
endfunction

" # Jobs console {{{2
" Features:
" - display job queue
" - cancel selected job
" - automatically updated when jobs are cancelled, added, finished
" - Tie executions: -> .andThen
function! s:_build_ui_lines() dict abort
  let list = copy(self.list)
  let names = lh#list#get(list, 'txt', '(unnamed)')
  let lmax = max(map(copy(names), 'strwidth(v:val)')) + 3
  let lines = []
  if !empty(list)
    let lines += [ printf('>0< - %s %s!(%s)', names[0], repeat(' ', lmax-strwidth(names[0])), list[0].cmd)]
  endif
  let lines += map(list[1:],
        \ {idx, val -> printf('%2d  - %s %s!(%s)', idx+1, names[idx+1], repeat(' ', lmax-strwidth(names[idx+1])), val.cmd)})
  return lines
endfunction

" Function: lh#async#_jobs_console(name) {{{3
function! lh#async#_jobs_console(name) abort
  let job_queue = s:_get_existing_queue(a:name)

  if has_key(job_queue, 'job_ui')
    " make the window visible, and jump to it
    let b = lh#buffer#jump(job_queue.job_ui.id, 'sp')
    if b > 0
      if line('$') == 1
        bw
      else
        call job_queue._update_ui()
        return
      endif
    endif
    " Otherwise, create a new dialog buffer
  endif

  let title = 'Job queue'
  if job_queue.is_paused()
    let title .= '    --> PAUSED <--'
  endif
  silent let job_queue.job_ui = lh#buffer#dialog#new('jobs://list{'.(job_queue.name).'}', title, '', 1, '', job_queue._build_ui_lines())
  let job_queue.job_ui._job_queue = job_queue
  " Cancellation mappings
  nnoremap <silent> <buffer> x     :call b:dialog._job_queue._cancel_jobs_ui()<cr>
  nnoremap <silent> <buffer> <del> :call b:dialog._job_queue._cancel_jobs_ui()<cr>
  nnoremap <silent> <buffer> d     :call b:dialog._job_queue._cancel_jobs_ui()<cr>
  nnoremap <silent> <buffer> p     :call b:dialog._job_queue._unpause_jobs()<cr>
  " Tag then remove
  vmap     <silent> <buffer> x     tx
  vmap     <silent> <buffer> <del> t<del>
  vmap     <silent> <buffer> d     td

  " Help
  call lh#buffer#dialog#add_help(b:dialog, '@| x, <del>, d             : Cancel tagged/selected job(s)', 'long')
  call lh#buffer#dialog#add_help(b:dialog, '@| p                       : Un(p)ause the job queue', 'long')
  " Highliting job names
  if has("syntax")
    syn clear

    " syntax match JobHeader  /^\s*\zs  #.*/
    syntax region JobLine  start='\d' end='$' contains=JobNumber,JobName,JobCmd
    syntax region JobNbOcc  start='^--' end='$' contains=JobNumber,JobName
    syntax match JobNumber /\d\+/ contained
    syntax match JobName /<.\{-}+>/ contained
    syntax match JobCmd /!(.*)$/ contained

    syntax region JobExplain start='@' end='$' contains=JobStart,JobPAUSED
    syntax keyword JobPAUSED PAUSED contained
    syntax match JobStart /@/ contained
    syntax match Statement /--abort--/

    highlight link JobExplain Comment
    " highlight link JobHeader Underlined
    highlight link JobStart Ignore
    highlight link JobLine Normal
    highlight link JobName Identifier
    highlight link JobCmd Directory
    highlight link JobNumber Number
    highlight link JobPAUSED Error
  endif
endfunction

function! s:_update_ui() dict abort " {{{3
  if has_key(self, 'job_ui')
    let w = lh#window#getid()
    try
      let b = lh#buffer#find(self.job_ui.id)
      if b >= 0
        " TODO: try to feed updated tags as well!
        " For now tags are reset
        call self.job_ui.reset_choices(self._build_ui_lines())
        let state = self.is_paused() ? '> PAUSED <' : '> ACTIVE <'
        let self.job_ui.help_ruler[0] = substitute(self.job_ui.help_ruler[0], '\v.{12}\zs.{10}', state, '')
        call lh#buffer#dialog#update_all(self.job_ui)
        " Otherwise, it means there is nothing to update
        " (-> window hidden, or destroyed)
      endif
    finally
      call lh#window#gotoid(w)
    endtry
  endif
endfunction

function! s:_cancel_jobs_ui() dict abort " {{{3
  let self.interrupted = 0
  let l = len(self.list)

  try
    let selected = self.job_ui.selection()
    if (len(selected) == 1 && selected[0] >= 0) || (len(selected) >= 2)
      " call lh#common#echomsg_multilines(map(copy(selected), 'self.job_ui.choices[v:val]'))
      " call s:Verbose("Cancelling: %1", map(copy(selected), 'get(self.list[v:val], "txt", self.job_ui.list[v:val].cmd'))
      let shall_update_ui = 0
      for j in reverse(selected)
        let shall_update_ui += self._unsafe_stop_job(j, l)
        let l -= 1
      endfor
      if shall_update_ui
        call self._update_ui()
      endif
    endif
  finally
    if self.interrupted
      " We could be interrupted just after the test. In that case, the old job
      " won't be removed and it's get executed twice...
      call remove(self.list, 0)
      call self._check_start_next() " cannot be interrupted anymore
    endif
    unlet self.interrupted
  endtry
endfunction

" # Job queue {{{2
" @invariant Running element has index 0
" @invariant If self.interrupted is defined, this means a function like, push,
" stop/cancel or pause has been called. If it gets incremented, this means the
" `close_cb` has been called before the variable was relaxed.
function! s:is_running() dict abort                " {{{3
  return !empty(self.list)
endfunction

function! s:is_empty() dict abort                  " {{{3
  return empty(self.list)
endfunction

function! s:push_or_start(job) dict abort          " {{{3
  let s:k_policies = {'stack': 1, 'replace': 2, 'dump': 3}
  let job_args = lh#dict#subset(a:job, s:k_job_methods)
  try
    let self.interrupted = 0
    " let g:list = deepcopy(self.list)
    " let g:job = deepcopy(a:job)

    let idx = lh#list#find_if_fast(self.list, string(a:job.cmd) . ' == v:val.cmd')
    call s:Verbose('Found another task in job queue at index %1', idx)
    if idx >= 0
      let txt = get(a:job, 'txt', a:job.cmd)
      let choice = get(s:k_policies, self.default_behaviour, -1)
      if choice < 0
        let choice = lh#ui#confirm("A another `".txt."` background task is under way. Do you want to\n-> ",
              \ ["&Queue the new (redundant task)",
              \  "&Cancel the previous job and queue this one instead?",
              \  "&Keep the previous job and dump the new one?"])
        redraw
      endif
      if choice == 3
        call s:Verbose('Ignore the new job')
        return
      elseif choice == 2
        call s:Verbose('Remplate old job by the new job')
        let shall_update_ui = self._unsafe_stop_job(idx, len(self.list))
      else
        call s:Verbose('Queue the new redundant job')
      endif
    endif
    let self.list += [ extend(copy(a:job), {'args': job_args}) ]
    call s:Verbose('Push or start job: %1 at %2-th position', self.list[-1], len(self.list))
  finally
    if self.interrupted
      " We could be interrupted just after the test. In that case, the old job
      " won't be removed and it's get executed twice...
      call remove(self.list, 0)
      let interrupted = self.interrupted
    endif
    unlet self.interrupted
  endtry
  call self._update_ui()
  call self._check_start_next(exists('interrupted')) " cannot be interrupted anymore?
endfunction

function! s:_check_start_next(...) dict abort      " {{{3
  let has_been_interrupted = get(a:, 1, 0)
  if self.state == 'paused'
    call lh#common#warning_msg('The jobs are currently paused. Please unpause them to launch the one you have just queued')
  elseif len(self.list) == 1 || has_been_interrupted
    " Can't start and remove simultaneously => don't wait here
    " There was nothing, the new job is to be started
    call self.start_next()
  endif
endfunction

function! s:start_next() dict abort                " {{{3
  " This function should never be interrupted as:
  " - it's either run by push_or_start if there was no previous job
  " - or it's run by close_cb, which is the only possible interruption
  call lh#assert#value(self).not().has_key('interrupted')
  call lh#assert#true(!self.is_empty())
  " call lh#assert#value(self.state).differ('paused')

  let self.state = 'active'
  let job = self.list[0]
  try
    let success = 0
    let args = job.args
    if has_key(job, 'before_start_cb')
      call s:Verbose('Job has a before_start_cb: %1', job)
      let res = job.before_start_cb()
      call s:Verbose('before_start_cb result: %1 <-- %2', res, string(job.before_start_cb))
    endif
    call s:Verbose('Starting next job: %1', job)
    let Close_cb = get(args, 'close_cb', function('s:default_close_cb'))
    let args.close_cb = function('s:close_cb', [Close_cb, self.name])

    " inject env on-the-fly
    let env = lh#project#_environment()
    if !empty(env)
      let scr = lh#os#new_runner_script(job.cmd, env)
      let job.runner_script = scr
      let cmd0 = &shell . ' ' . scr._script_name
    else
      let cmd0 = job.cmd
    endif

    if lh#os#OnDOSWindows() && &shell =~ 'cmd'
      let cmd = join([&shell, &shellcmdflag, cmd0], ' ')
    else
      let cmd = [&shell, &shellcmdflag, cmd0]
    endif
    let job.job = job_start(cmd, args)
    call s:Verbose('job_start(%2) status: %1', job_info(job.job), cmd)
    if job_info(job.job).status == 'fail'
      call s:Verbose('AGAIN job_start(%2) status: %1', job_info(job.job), cmd)
      if has_key(job, 'start_failed_cb')
        call job.start_failed_cb()
      endif
      throw "Starting `".(job.cmd)."` failed!"
    endif
    let success = 1
  finally
    " Using a guard+finally instead of catch will leave the v:exception
    " unaltered
    if !success
      call remove(self.list, 0)
      if exists('scr')
        call scr.finalize()
      endif
      call self._update_ui()
    endif
  endtry
endfunction

function! s:default_close_cb(channel, ...)         " {{{3
  call s:Verbose('Job finished (default handler)')
endfunction

function! s:close_cb(user_close_cb, queue_name, channel) abort " {{{3
  " Unlike usual MT applications, we cannot yield until we'are ready to handle
  " the close callback.
  " So we need to know whether there is interleaving...
  " What's possible is that close_sb interrupts anything:
  " - job_registration (that can become job starting)
  " - job cancelling
  "
  let job_queue = s:_get_existing_queue(a:queue_name)
  " Wait till adding/removing a job has finished (poor man's mutex)
  if has_key(job_queue, 'interrupted')
    " Notifies we have have interrupted the current action, and remove the
    " first entry in the list
    let job_queue.interrupted += 1
    let job = job_queue.list[0]
    " The removal will be done in interrupted functions
  else
    call lh#assert#value(job_queue.list).not().empty("Expects job queue to contain elements")
    let job = remove(job_queue.list, 0)
  endif

  let last_job_status = copy(job_info(job.job))
  call s:Verbose('Job finished in queue %1: %2 -- %3', a:queue_name, job.job, job_info(job.job))
  try
    if has_key(job, 'runner_script')
      call job.runner_script.finalize()
    endif
  catch /.*/
  endtry
  call call(a:user_close_cb, [a:channel, job_info(job.job)])
  call job_queue._update_ui()

  " Be sure, we always launch the next job
  if !job_queue.is_empty()
    if last_job_status.exitval != 0
      let go_on = lh#ui#confirm("Last `".job.txt."` job failed.\n Shall we -> ", ["&Go on with the ".len(job_queue.list)." remaining jobs?", "&Pause?", "&Clear the job queue?"], 2)
      if     go_on == 3
        let sure = lh#ui#confirm("Do you confirm you want to clear the following pending jobs ()", ["&Yes", "No"], 2)
        if sure == 2
          call job_queue._do_clear_queue()
        endif
      elseif go_on != 1
        let job_queue.state = 'paused'
        call lh#common#warning_msg('To unpause the pending jobs, please execute `:JobUnpause` or use the `:Jobs`  console')
        call job_queue._update_ui()
        redrawstatus
        return
      endif
    endif
    if has_key(job_queue, 'interrupted')
      call s:Verbose("Don't start next job automatically, as we have finished one while doing something else")
    else
      call job_queue.start_next() " will automatically wait if we were doing something else
    endif
  endif
  " And get sure airline is refreshed
  redrawstatus
endfunction

function! s:_unsafe_stop_job(idx, nb_jobs) dict abort                " {{{3
  " Return whether we must update ui
  call assert_true(has_key(self,'interrupted'))
  call assert_inrange(0, len(self.list), a:idx)

  let job = self.list[a:idx]
  call s:Verbose('Found job #%1: %2', a:idx, job)
  " a:nb_jobs is a security in case the list size changes while the function is
  " executed
  if a:idx == 0 && a:nb_jobs == len(self.list) && has_key(job, 'job')
    if get(self, 'interrupted', 0) == 0
      let st = job_stop(job.job)
      if st == 0
        throw "Cannot stop the background execution of ".job.txt
      else
        call lh#common#warning_msg("Background execution of ".(job.txt)." stopped.")
      endif
    else
      call s:Verbose("Job finished in the mean time... => do nothing more")
      " TODO: shall we pause ?
    endif
    return 0 " don't update
  elseif a:nb_jobs == len(self.list)
    call remove(self.list, a:idx)
    call lh#common#warning_msg("Background execution of ".(job.txt)." aborted.")
    return 1
  else
    throw "Unexpected error while trying abort background execution of job #".a:idx
  endif
endfunction

function! s:stop_job(id) dict abort                " {{{3
  " Wait till adding/finishing a job has finished (poor man's mutex)
  try
    let self.interrupted = 0
    let l = len(self.list)
    if l == 0
      throw "No pending job to cancel"
      return
    endif
    let idx = lh#list#find_if_fast(self.list, 'get(v:val, "txt", v:val.cmd) =~ a:id')
    if idx == -1
      throw "No pending job matching ".a:id
    endif
    let shall_update_ui = self._unsafe_stop_job(idx, l)
    if shall_update_ui
      call self._update_ui()
    endif
  finally
    if self.interrupted
      " We could be interrupted just after the test. In that case, the old job
      " won't be removed and it's get executed twice...
      call remove(self.list, 0)
      call self._check_start_next() " cannot be interrupted anymore
    endif
    unlet self.interrupted
  endtry
endfunction

function! s:is_paused() dict abort " {{{3
  return self.state == 'paused'
endfunction

function! s:_unpause_jobs() dict abort " {{{3
  " TODO: check whether a lock is required
  if self.is_paused()
    let self.state = 'active'
    call self._update_ui()
    if !self.is_empty()
      call self.start_next()
    endif
  else
    call s:Verbose("The queue isn't paused => ignore unpause event")
  endif
endfunction

function! s:_do_clear_queue() dict abort " {{{3
" Debugging purpose, avoid using this function!!!
" If a job is really running, errors are to be expected
  call s:Verbose('Clearing job queue. It had %1 element%2 (%3)'
        \ , len(self.list)
        \ , len(self.list) > 1 ? '' : 's'
        \ , self.list
        \)
  let self.list = []
  call self._update_ui()
endfunction


" Example of Use                                     {{{3
" function! TestCb(...)
"   call s:Verbose('TestCb(%1)', a:000)
" endfunction
" let queue = lh#async#get_queue('myplugin', 'stack')
" call queue.push_or_start('sleep 1', {'close_cb':function('TestCb')})

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
