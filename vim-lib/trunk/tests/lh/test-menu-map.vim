"=============================================================================
" $Id$
" File:		test-menu-map.vim                                           {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" Version:	2.0.0
" Created:	05th Dec 2006
" Last Update:	$Date$
"------------------------------------------------------------------------
" Description:	Tests for lh-vim-lib . lh#menu#
" 
"------------------------------------------------------------------------
" Installation:	«install details»
" History:	«history»
" TODO:		«missing features»
" }}}1
"=============================================================================


" let g:want_buffermenu_or_global_disable = 1
" let b:want_buffermenu_or_global_disable = 1
" echo lh#option#Get("want_buffermenu_or_global_disable", 1, "bg")

" Call a command (':Command')
call lh#menu#Make("nic", '42.50.340',
      \ '&LH-Tests.&Menu-Make.Build Ta&gs', "<C-L>g",
      \ '<buffer>',
      \ ":echo 'TeXtags'<CR>")

" With '{' expanding to '{}××', or '{}' regarding the mode
call lh#menu#IVN_Make('42.50.360.200',
      \ '&LH-Tests.&Menu-Make.&Insert.\toto{}', ']toto',
      \ '\\toto{',
      \ '{%i\\toto<ESC>%l',
      \ "viw]toto")

" Noremap for the visual maps
call lh#menu#IVN_Make('42.50.360.200',
      \ '&LH-Tests.&Menu-Make.&Insert.\titi{}', ']titi',
      \ '\\titi{',
      \ '<ESC>`>a}<ESC>`<i\\titi{<ESC>%l',
      \ "viw]titi",
      \ 0, 1, 0)

" Noremap for the insert and visual maps
call lh#menu#IVN_Make('42.50.360.200',
      \ '&LH-Tests.&Menu-Make.&Insert.<tata></tata>', ']tata',
      \ '<tata></tata><esc>?<<CR>i', 
      \ '<ESC>`>a</tata><ESC>`<i<tata><ESC>/<\\/tata>/e1<CR>',
      \ "viw]tata", 
      \ 1, 1, 0)

"=============================================================================
" vim600: set fdm=marker:
