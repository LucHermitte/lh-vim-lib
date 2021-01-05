"=============================================================================
" File:		mkVba/mk-lh-lib.vim
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/blob/master/License.md>
" Version:	5.3.0
let s:version = '5.3.0'
" Created:	06th Nov 2007
" Last Update:  04th Jan 2021
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
after/plugin/lh-project-delayed-events.vim
autoload/airline/extensions/async.vim
autoload/lh/askvim.vim
autoload/lh/assert.vim
autoload/lh/async.vim
autoload/lh/buffer.vim
autoload/lh/buffer/dialog.vim
autoload/lh/coc.vim
autoload/lh/command.vim
autoload/lh/common.vim
autoload/lh/dict.vim
autoload/lh/encoding.vim
autoload/lh/env.vim
autoload/lh/event.vim
autoload/lh/file.vim
autoload/lh/float.vim
autoload/lh/fmt.vim
autoload/lh/ft.vim
autoload/lh/ft/option.vim
autoload/lh/function.vim
autoload/lh/graph/tsort.vim
autoload/lh/has.vim
autoload/lh/icomplete.vim
autoload/lh/leader.vim
autoload/lh/let.vim
autoload/lh/list.vim
autoload/lh/log.vim
autoload/lh/mapping.vim
autoload/lh/mark.vim
autoload/lh/math.vim
autoload/lh/menu.vim
autoload/lh/notify.vim
autoload/lh/on.vim
autoload/lh/option.vim
autoload/lh/partial.vim
autoload/lh/path.vim
autoload/lh/po.vim
autoload/lh/position.vim
autoload/lh/project.vim
autoload/lh/project/cmd.vim
autoload/lh/project/list.vim
autoload/lh/project/menu.vim
autoload/lh/qf.vim
autoload/lh/ref.vim
autoload/lh/stack.vim
autoload/lh/string.vim
autoload/lh/syntax.vim
autoload/lh/type.vim
autoload/lh/ui.vim
autoload/lh/vcs.vim
autoload/lh/visual.vim
autoload/lh/window.vim
doc/DbC.md
doc/Dialog.md
doc/Log.md
doc/Project.md
doc/lh-vim-lib.txt
mkVba/mk-lh-vim-lib.vim
plugin/let.vim
plugin/lh-project.vim
plugin/lhvl.vim
plugin/ui-functions.vim
plugin/words_tools.vim
tests/lh/UT-fixpath.vim
tests/lh/encoding.vim
tests/lh/function.vim
tests/lh/list.vim
tests/lh/math.vim
tests/lh/path.vim
tests/lh/ref.vim
tests/lh/reinterpret_escaped_chars.vim
tests/lh/test-Fargs2String.vim
tests/lh/test-askmenu.vim
tests/lh/test-command.vim
tests/lh/test-format.vim
tests/lh/test-menu-map.vim
tests/lh/test-options.vim
tests/lh/test-toggle-menu.vim
tests/lh/topological-sort.vim
