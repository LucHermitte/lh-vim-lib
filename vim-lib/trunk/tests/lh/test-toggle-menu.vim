" $Id$
" Tests for lh-vim-lib . lh#menu#DefToggleItem()

let Data = {
      \ "variable": "bar",
      \ "idx_crt_value": 1,
      \ "values": [ 'a', 'b', 'c', 'd' ],
      \ "menu": { "priority": '42.50.10', "name": '&LH-Tests.&TogMenu.&bar'}
      \}

call lh#menu#DefToggleItem(Data)

let Data2 = {
      \ "variable": "foo",
      \ "idx_crt_value": 3,
      \ "texts": [ 'un', 'deux', 'trois', 'quatre' ],
      \ "values": [ 1, 2, 3, 4 ],
      \ "menu": { "priority": '42.50.11', "name": '&LH-Tests.&TogMenu.&foo'}
      \}

call lh#menu#DefToggleItem(Data2)

" No default
let Data3 = {
      \ "variable": "nodef",
      \ "texts": [ 'one', 'two', 'three', 'four' ],
      \ "values": [ 1, 2, 3, 4 ],
      \ "menu": { "priority": '42.50.12', "name": '&LH-Tests.&TogMenu.&nodef'}
      \}
call lh#menu#DefToggleItem(Data3)

" No default
let g:def = 2
let Data4 = {
      \ "variable": "def",
      \ "values": [ 1, 2, 3, 4 ],
      \ "menu": { "priority": '42.50.13', "name": '&LH-Tests.&TogMenu.&def'}
      \}
call lh#menu#DefToggleItem(Data4)

function! s:Yes()
  echo "Yes"
endfunction


" What follows does not work because we can build an exportable FuncRef on top
" of a script local function
finish
function! s:No()
  echo "No"
endfunction
let Data4 = {
      \ "variable": "yesno",
      \ "values": [ 1, 2 ],
      \ "text": [ "No", "Yes" ],
      \ "actions": [ function("s:No"), function("s:Yes") ],
      \ "menu": { "priority": '42.50.20', "name": '&LH-Tests.&TogMenu.&yesno'}
      \}
call lh#menu#DefToggleItem(Data4)
