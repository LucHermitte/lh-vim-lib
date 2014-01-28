"=============================================================================
" $Id$
" File:		mkVba/mk-lh-lib.vim
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" License:      GPLv3 with exceptions
"               <URL:http://code.google.com/p/lh-vim/wiki/License>
" Version:	3.1.16
let s:version = '3.1.16'
" Created:	06th Nov 2007
" Last Update:	$Date$
"------------------------------------------------------------------------
cd <sfile>:p:h
try 
  let save_rtp = &rtp
  let &rtp = expand('<sfile>:p:h:h').','.&rtp
  exe '24,$MkVimball! lh-vim-lib-'.s:version
  set modifiable
  set buftype=
finally
  let &rtp = save_rtp
endtry
finish
autoload/lh/askvim.vim
autoload/lh/buffer.vim
autoload/lh/buffer/dialog.vim
autoload/lh/command.vim
autoload/lh/common.vim
autoload/lh/encoding.vim
autoload/lh/env.vim
autoload/lh/event.vim
autoload/lh/float.vim
autoload/lh/function.vim
autoload/lh/graph/tsort.vim
autoload/lh/icomplete.vim
autoload/lh/let.vim
autoload/lh/list.vim
autoload/lh/map.vim
autoload/lh/menu.vim
autoload/lh/option.vim
autoload/lh/path.vim
autoload/lh/position.vim
autoload/lh/syntax.vim
autoload/lh/visual.vim
doc/lh-vim-lib.txt
lh-vim-lib-addon-info.txt
lh-vim-lib.README
macros/menu-map.vim
mkVba/mk-lh-vim-lib.vim
plugin/let.vim
plugin/lhvl.vim
plugin/ui-functions.vim
plugin/words_tools.vim
tests/lh/function.vim
tests/lh/list.vim
tests/lh/path.vim
tests/lh/test-Fargs2String.vim
tests/lh/test-askmenu.vim
tests/lh/test-command.vim
tests/lh/test-menu-map.vim
tests/lh/test-toggle-menu.vim
tests/lh/topological-sort.vim
