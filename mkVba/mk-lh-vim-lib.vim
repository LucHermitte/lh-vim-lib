"=============================================================================
" File:		mkVba/mk-lh-lib.vim
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/blob/master/License.md>
" Version:	3.10.3
let s:version = '3.10.3'
" Created:	06th Nov 2007
" Last Update:  25th May 2016
"------------------------------------------------------------------------
cd <sfile>:p:h
try
  let save_rtp = &rtp
  let &rtp = expand('<sfile>:p:h:h').','.&rtp
  exe '23,$MkVimball! lh-vim-lib-'.s:version
  set modifiable
  set buftype=
finally
  let &rtp = save_rtp
endtry
finish
README.md
License.md
addon-info.json
autoload/lh/askvim.vim
autoload/lh/buffer.vim
autoload/lh/buffer/dialog.vim
autoload/lh/command.vim
autoload/lh/common.vim
autoload/lh/dict.vim
autoload/lh/encoding.vim
autoload/lh/env.vim
autoload/lh/event.vim
autoload/lh/float.vim
autoload/lh/fmt.vim
autoload/lh/function.vim
autoload/lh/graph/tsort.vim
autoload/lh/icomplete.vim
autoload/lh/leader.vim
autoload/lh/let.vim
autoload/lh/list.vim
autoload/lh/log.vim
autoload/lh/mapping.vim
autoload/lh/math.vim
autoload/lh/menu.vim
autoload/lh/on.vim
autoload/lh/option.vim
autoload/lh/path.vim
autoload/lh/position.vim
autoload/lh/stack.vim
autoload/lh/string.vim
autoload/lh/syntax.vim
autoload/lh/vcs.vim
autoload/lh/visual.vim
autoload/lh/window.vim
doc/lh-vim-lib.txt
mkVba/mk-lh-vim-lib.vim
plugin/let.vim
plugin/lhvl.vim
plugin/ui-functions.vim
plugin/words_tools.vim
tests/lh/UT-fixpath.vim
tests/lh/encoding.vim
tests/lh/function.vim
tests/lh/list.vim
tests/lh/math.vim
tests/lh/path.vim
tests/lh/test-Fargs2String.vim
tests/lh/test-askmenu.vim
tests/lh/test-command.vim
tests/lh/test-format.vim
tests/lh/test-menu-map.vim
tests/lh/test-toggle-menu.vim
tests/lh/topological-sort.vim
