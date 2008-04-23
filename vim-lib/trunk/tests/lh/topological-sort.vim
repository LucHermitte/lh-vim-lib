"=============================================================================
" $Id$
" File:                topological-sort.vim                                           {{{1
" Author:        Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"                <URL:http://hermitte.free.fr/vim/>
" Version:        2.1.0
" Created:        17th Apr 2008
" Last Update:        $Date$
"------------------------------------------------------------------------
" Description:        «description»
"
"------------------------------------------------------------------------
" Installation:        «install details»
" History:        «history»
" TODO:                «missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------

" Fully defineds DAGs {{{1

" A Direct Acyclic Graph {{{2
let dag1 = {}
let dag1[7] = [11, 8]
let dag1[5] = [11]
let dag1[3] = [8, 10]
let dag1[11] = [2, 9, 10]
let dag1[8] = [9]

" A Direct Cyclic Graph {{{2
let dcg1 = deepcopy(dag1)
let dcg1[9] = [11]

" Test DAG1 {{{2
echo "D(dag1)=".string(lh#graph#tsort#depth(dag1, [3, 5,7]))
echo "B(dag1)=".string(lh#graph#tsort#breadth(dag1, [3, 5,7]))

" Test DCG1 {{{2
" echo "D(dcg1)=".string(lh#graph#tsort#depth(dcg1, [3, 5, 7]))
" echo "B(dcg1)=".string(lh#graph#tsort#breadth(dcg1, [3, 5, 7]))

" Lazzy Evaluated DAGs {{{1

" Emulated lazzyness {{{2
" The time-consumings evaluation function
let s:called = 0
function! Fetch(node)
  let s:called += 1
  return has_key(g:dag1, a:node) ? (g:dag1[a:node]) : []
endfunction

" Test Fetch on a DAG {{{2
echo "D(fetch)=".string(lh#graph#tsort#depth(function('Fetch'), [3,5,7]))
echo "Fetch has been evaluated ".s:called." times"



" }}}1
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

