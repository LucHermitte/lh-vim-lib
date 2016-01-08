"=============================================================================
" File:         autoload/lh/tsort.vim                        {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      3.6.1
let s:k_version = 361
" Created:      21st Apr 2008
" Last Update:  08th Jan 2016
"------------------------------------------------------------------------
" Description:  Library functions for Topological Sort
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim

"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#graph#tsort#version()
  return s:k_version
endfunction

" # Debug {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#graph#tsort#verbose(...)
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

function! lh#graph#tsort#debug(expr) abort
  return eval(a:expr)
endfunction


"=============================================================================

"------------------------------------------------------------------------
"## Helper functions                         {{{1
"# s:Successors_fully_defined(node)          {{{2
function! s:Successors_fully_defined(node) dict
  if has_key(self.table, a:node)
    return self.table[a:node]
  else
    return []
  endif
endfunction

"# s:Successors_lazy(node)                   {{{2
function! s:Successors_lazy(node) dict
  if !has_key(self.table, a:node)
    let nodes = self.fetch(a:node)
    let self.table[a:node] = nodes
    " if len(nodes) > 0
      " let self.nb += 1
    " endif
    return nodes
  else
    return self.table[a:node]
  endif
endfunction

"# s:PrepareDAG(dag)                         {{{2
function! s:PrepareDAG(dag)
  if type(a:dag) == type(function('has_key'))
    let dag = {
          \ 'successors': function('s:Successors_lazy'),
          \ 'fetch'     : a:dag,
          \ 'table'     : {}
          \}
  else
    let dag = {
          \ 'successors': function('s:Successors_fully_defined'),
          \ 'table'     : deepcopy(a:dag)
          \}
  endif
  return dag
endfunction

"## Depth-first search (recursive)           {{{1
" Do not detect cyclic graphs

"# lh#graph#tsort#depth(dag, start_nodes)    {{{2
function! lh#graph#tsort#depth(dag, start_nodes)
  let dag = s:PrepareDAG(a:dag)
  let results = []
  let visited_nodes = { 'Visited':function('s:Visited')}
  call s:RecursiveDTSort(dag, a:start_nodes, results, visited_nodes)
  call reverse(results)
  return results
endfunction

"# The real, recursive, T-Sort               {{{2
"see boost.graph for a non recursive implementation
function! s:RecursiveDTSort(dag, start_nodes, results, visited_nodes)
  for node in a:start_nodes
    let visited = a:visited_nodes.Visited(node)
    if     visited == 1 | continue " done
    elseif visited == 2 | throw "Tsort: cyclic graph detected: ".node
    endif
    let a:visited_nodes[node] = 2 " visiting
    let succs = a:dag.successors(node)
    try
      call s:RecursiveDTSort(a:dag, succs, a:results, a:visited_nodes)
    catch /Tsort:/
      throw v:exception.'>'.node
    endtry
    let a:visited_nodes[node] = 1 " visited
    call add(a:results, node)
  endfor
endfunction

function! s:Visited(node) dict
  return has_key(self, a:node) ? self[a:node] : 0
endfunction

"## Breadth-first search (non recursive)     {{{1
"# lh#graph#tsort#breadth(dag, start_nodes)  {{{2
" warning: This implementation does not work with lazy dag, but only with fully
" defined ones
function! lh#graph#tsort#breadth(dag, start_nodes)
  let result = []
  let dag = s:PrepareDAG(a:dag)
  let queue = deepcopy(a:start_nodes)

  while len(queue) > 0
    let node = remove(queue, 0)
    " echomsg "result <- ".node
    call add(result, node)
    let successors = dag.successors(node)
    while len(successors) > 0
      let m = s:RemoveEdgeFrom(dag, node)
      " echomsg "graph loose ".node."->".m
      if !s:HasIncomingEgde(dag, m)
        " echomsg "queue <- ".m
        call add(queue, m)
      endif
    endwhile
  endwhile
  if !s:Empty(dag)
    throw "Tsort: cyclic graph detected: "
  endif
  return result
endfunction

function! s:HasIncomingEgde(dag, node)
  for node in keys(a:dag.table)
    if type(a:dag.table[node]) != type([])
      continue
    endif
    if index(a:dag.table[node], a:node) != -1
      return 1
    endif
  endfor
  return 0
endfunction
function! s:RemoveEdgeFrom(dag, node)
  let successors = a:dag.successors(a:node)
  if len(successors) > 0
    let successor = remove(successors, 0)
    if len(successors) == 0
      " echomsg "finished with ->".a:node
      call remove(a:dag.table, a:node)
    endif
    return successor
  endif
  throw "No more edges from ".a:node
endfunction
function! s:Empty(dag)
  " echomsg "len="len(a:dag.table)
  return len(a:dag.table) == 0
endfunction
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker
