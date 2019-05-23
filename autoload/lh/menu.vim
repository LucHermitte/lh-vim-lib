"=============================================================================
" File:         autoload/lh/menu.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/lh-vim-lib>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/tree/master/License.md>
" Version:      4.6.4
let s:k_version = 40604
" Created:      13th Oct 2006
" Last Update:  23rd May 2019
"------------------------------------------------------------------------
" Description:
"       Defines the global function lh#menu#def_menu
"       Aimed at (ft)plugin writers.
"
"------------------------------------------------------------------------
" History: {{{2
"       v2.0.0: Moving to vim7
"       v2.0.1: :Toggle echoes the new value
"       v2.2.0: Support environment variables
"               Only one :Toggle command is defined.
"       v2.2.3: :Toggle can directly set the final value
"              (prefer this way of proceeding to update the menu to the new
"              value)
"              :Toggle suports auto-completion on possible values
"       v2.2.6: Toggle menus are silent, but not the actions executed
"       v3.0.0: GPLv3
"       v3.1.2: Enhancements for string options, required by BTW 0.2.0
"       v3.1.3: BugFix for CMake options, required by BTW 0.2.1
"       v3.6.1  ENH: Use new logging framework
"       v4.0.0  ENH: Extend to work with project p:variables
"               ENH: Add `lh#menu#remove()`
"               ENH: toggle-menu on `p:var` always refers to the exact same
"               variable from the current project at the moment the menu is
"               defined.
"               ENH: Accept multiple words value in `:Toggle`
"       v4.5.0  BUG: Make :Toggle reject bar ; may need more intelligence
" TODO: {{{2
"       * Should the argument to :Toggle be simplified to use the variable name
"       instead ? May be a banged :Toggle! could work on the real variable
"       name, and on the real value.
"       * show all possible values in a sub menu (on demand)
"
" Notes:
" .hook cannot be used to execute a toggle action. Use .actions instead.
" }}}1
"=============================================================================


"=============================================================================
let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Internal Variables {{{1
let s:k_Toggle_cmd = 'Toggle'
let s:k_Set_cmd    = 'Set'
if !exists('s:toggle_commands')
  let s:toggle_commands = {}
endif
if !exists('s:set_string_commands')
  let s:set_string_commands = {}
endif

"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#menu#version()
  return s:k_version
endfunction

" # Debug {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#menu#verbose(...)
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

function! lh#menu#debug(expr) abort
  return eval(a:expr)
endfunction


"=============================================================================
" ## Functions {{{1
"------------------------------------------------------------------------
" # Common stuff       {{{2
" s:getSNR([func_name]) {{{3
function! s:getSNR(...)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

" Function: lh#menu#text({text})                             {{{3
" @return a text to be used in menus where "\" and spaces have been escaped.
function! lh#menu#text(text)
  return escape(a:text, '\ ')
endfunction

" Function: lh#menu#_var_name(variable_name) {{{3
" Menu variable names are either global (without g: said), or from the
" environment.
function! lh#menu#_var_name(varname)
  return (a:varname=~'\v^(\$|[gp]:)' ? '' : 'g:') . a:varname
endfunction

" # Toggling menu item {{{2
" Function: s:Fetch({Data},{key})                          {{{3
" @param[in] Data Menu-item definition
" @param[in] key  Table from which the result will be fetched
" @return the current value, or text, whose index is Data.idx_crt_value.
function! s:Fetch(Data, key) abort
  let len = len(a:Data[a:key])
  if a:Data.idx_crt_value >= len | let a:Data.idx_crt_value = 0 | endif
  let value = a:Data[a:key][a:Data.idx_crt_value]
  return value
endfunction

" Function: s:Search({Data},{value})                       {{{3
" Searches for the index of {value} in {Data.values} list. Return 0 if not
" found.
function! s:Search(Data, value) abort
  let idx = index(a:Data.values, a:value)
  " echo a:Data.variable . "[".idx."] == " . a:value
  return idx > 0 ? idx : 0 " default is first element
endfunction

" Function: s:SearchText({Data},{value})                   {{{3
" Searches for the index of {value} in {Data.values/text} list.
" Returns -1 if not found.
function! s:SearchText(Data, value) abort
  let labels_key = s:MenuKey(a:Data)
  let list = a:Data[labels_key]
  let idx = index(list, a:value)
  return idx
endfunction

" Function: s:Set({Data})                                  {{{3
" @param[in,out] Data Menu item definition
"
" Sets the global variable associated to the menu item according to the item's
" current value.
function! s:Set(Data) abort
  try
    let value = a:Data.values[a:Data.idx_crt_value]
    let variable = a:Data.variable
    if     lh#ref#is_bound(variable)
      call variable.assign(value)
    elseif variable[0] == '$' " environment variables
      exe "let ".variable." = ".string(value)
    elseif variable[0:1] == 'p:' " project variables
      call lh#let#to(variable, value)
    else
      " the following syntax doesn't work with dictionaries => use :exe
      " let g:{variable} = value
      exe 'let g:'.variable.' = '.string(value)
    endif
    if has_key(a:Data, "actions")
      let l:Action = a:Data.actions[a:Data.idx_crt_value]
      if type(l:Action) == type(function('tr'))
        call l:Action()
      else
        exe l:Action
      endif
    endif
    if has_key(a:Data, "hook")
      let l:Action = a:Data.hook
      if type(l:Action) == type(function('tr'))
        call a:Data.hook()
      else
        exe l:Action
      endif
    endif
    return value
  catch /.*/
    throw lh#fmt#printf('Cannot set: %1=%2: %3 in %4', variable, value, v:exception, v:throwpoint)
    " throw "Cannot set: ".variable."=".value.": ".v:exception." in ".v:throwpoint
  finally
  endtry
endfunction

" Function: s:MenuKey({Data})                              {{{3
" @return the table name from which the current value name (to display in the
" menu) must be fetched.
" Priority is given to the optional "texts" table over the madatory "values" table.
function! s:MenuKey(Data) abort
  if has_key(a:Data, "texts")
    let menu_id = "texts"
  else
    let menu_id = "values"
  endif
  return menu_id
endfunction

" Function: s:SetTextValue({Data},{TextValue})             {{{3
" Force the value of the variable to the one associated to the {TextValue}
" The menu, and the variable are updated in consequence.
function! s:SetTextValue(Data, text) abort
  " Where the texts for values must be fetched
  let labels_key = s:MenuKey(a:Data)
  " Fetch the old current value
  let old = s:Fetch(a:Data, labels_key)
  let new_idx = s:SearchText(a:Data, a:text)
  if -1 == new_idx
    throw "toggle-menu: unsupported value (".a:text.") for {".lh#object#to_string(a:Data.variable)."}"
  endif
  if a:Data.idx_crt_value == new_idx
    " value unchanged => abort
    return
  endif

  " Remove the entry from the menu
  call s:ClearMenu(a:Data.menu, old)

  " Cycle/increment the current value
  let a:Data.idx_crt_value = new_idx
  " Fetch it
  let new = s:Fetch(a:Data,labels_key)
  " Add the updated entry in the menu
  call s:UpdateMenu(a:Data.menu, new, a:Data.command)
  " Update the binded global variable
  let value = s:Set(a:Data)
  echo lh#object#to_string(a:Data.variable).'='.lh#object#to_string(value)
endfunction

" Function: s:NextValue({Data})                            {{{3
" Change the value of the variable to the next in the list of value.
" The menu, and the variable are updated in consequence.
function! s:NextValue(Data) abort
  " Where the texts for values must be fetched
  let labels_key = s:MenuKey(a:Data)
  " Fetch the old current value
  let old = s:Fetch(a:Data, labels_key)

  " Remove the entry from the menu
  call s:ClearMenu(a:Data.menu, old)

  " Cycle/increment the current value
  let a:Data.idx_crt_value += 1
  " Fetch it
  let new = s:Fetch(a:Data,labels_key)
  " Add the updated entry in the menu
  call s:UpdateMenu(a:Data.menu, new, a:Data.command)
  " Update the binded global variable
  let value = s:Set(a:Data)
  echo lh#object#to_string(a:Data.variable).'='.lh#object#to_string(value)
endfunction

" Function: s:ClearMenu({Menu}, {text})                    {{{3
" Removes a menu item
"
" @param[in] Menu.priority Priority of the new menu-item
" @param[in] Menu.name     Name of the new menu-item
" @param[in] text          Text of the previous value of the variable binded
function! s:ClearMenu(Menu, text) abort
  if has('gui_running')
    let name = substitute(a:Menu.name, '&', '', 'g')
    let cmd = 'unmenu '.lh#menu#text(name.'<tab>('.a:text.')')
    silent! exe cmd
  endif
endfunction

" Function: s:UpdateMenu({Menu}, {text}, {command})        {{{3
" Adds a new menu item, with the text associated to the current value in
" braces.
"
" @param[in] Menu.priority Priority of the new menu-item
" @param[in] Menu.name     Name of the new menu-item
" @param[in] text          Text of the current value of the variable binded to
"                          the menu-item
" @param[in] command       Toggle command to execute when the menu-item is selected
function! s:UpdateMenu(Menu, text, command) abort
  if has('gui_running')
    call s:Verbose('nnoremenu <silent> %1 %2<tab>(%3) :%4 %5<cr>', a:Menu.priority, a:Menu.name, a:text, s:k_Toggle_cmd, a:command)
    let cmd = 'nnoremenu <silent> '.a:Menu.priority.' '.
          \ lh#menu#text(a:Menu.name.'<tab>('.a:text.')').
          \ ' :'.s:k_Toggle_cmd.' '.a:command."\<cr>"
    silent! exe cmd
  endif
endfunction

" Function: s:SaveData({Data})                             {{{3
" @param Data Menu-item definition
" Saves {Data} as s:Data{s:data_id++}. The definition will be used by
" automatically generated commands.
" @return s:data_id
let s:data_id = 0
function! s:SaveData(Data) abort
  let s:Data{s:data_id} = a:Data
  let id = s:data_id
  let s:data_id += 1
  return id
endfunction

" Function: lh#menu#def_toggle_item({Data})                {{{3
" @param Data.idx_crt_value
" @param Data.definitions == [ {value:, menutext: } ]
" @param Data.menu        == { name:, position: }
"
" Sets a toggle-able menu-item defined by {Data}.
function! s:eval() dict abort
  let key = s:MenuKey(self)
  return s:Fetch(self, key)
endfunction
function! s:val_id() dict abort
  return self.idx_crt_value
endfunction

function! lh#menu#def_toggle_item(Data) abort
  call s:Verbose('Def toggle menu: %1', a:Data)
  let a:Data.eval   = function(s:getSNR('eval'))
  let a:Data.val_id = function(s:getSNR('val_id'))
  " Save the menu data as an internal script variable
  let id = s:SaveData(a:Data)

  " If the variable is a p:variable, then we need to bound it to the exact
  " internal variable in order to alway point to the right variable, even from
  " a buffer that doesn't belong to the project
  if type(a:Data.variable) == type('') && a:Data.variable =~ '^p:'
    let variable = lh#project#crt()
    let key      = a:Data.variable[2:]
    let a:Data.variable = lh#ref#bind(variable, key)
    " let's also override the stringify method to something simplier
    call a:Data.variable.print_with_fmt('p:{%{1.to.name}}.%{1.key}')
  endif

  " If the index of the current value hasn't been set, fetch it from the
  " associated variable
  " @post `has_key(a:Data, "idx_crt_value")` is true
  if !has_key(a:Data, "idx_crt_value")
    " Fetch the value of the associated variable
    if lh#ref#is_bound(a:Data.variable)
      let value = a:Data.variable.resolve()
    else
      let value = lh#option#get(a:Data.variable, 0, 'g')
    endif
    " echo a:Data.variable . " <- " . value
    " Update the index of the current value
    let a:Data.idx_crt_value  = s:Search(a:Data, value)
  endif

  " Name of the auto-matically generated toggle command
  let cmdName = substitute(a:Data.menu.name, '[^a-zA-Z_]', '', 'g')
  " Lazy definition of the command
  if 2 != exists(':'.s:k_Toggle_cmd)
    exe 'command! -nargs=+ -complete=custom,lh#menu#_toggle_complete -bar '
          \ . s:k_Toggle_cmd . ' :call s:Toggle(<f-args>)'
  endif
  " silent exe 'command! -nargs=0 '.cmdName.' :call s:NextValue(s:Data'.id.')'
  let s:toggle_commands[cmdName] = eval('s:Data'.id)
  let a:Data.command = cmdName

  " Add the menu entry according to the current value
  call s:UpdateMenu(a:Data.menu, s:Fetch(a:Data, s:MenuKey(a:Data)), cmdName)
  " Update the associated global variable
  call s:Set(a:Data)
endfunction


"------------------------------------------------------------------------
" :Toggle support functions                                {{{3
function! s:Toggle(cmdName, ...) abort
  if !has_key(s:toggle_commands, a:cmdName)
    throw "toggle-menu: unknown toggable variable ".a:cmdName
  endif
  let data = s:toggle_commands[a:cmdName]
  if a:0 > 0
    call s:SetTextValue(data, join(a:000, ' '))
  else
    call s:NextValue(data)
  endif
endfunction

function! lh#menu#_toggle_complete(ArgLead, CmdLine, CursorPos) abort
  let cmdline = split(a:CmdLine)
  call s:Verbose('cmd line: %1 # %2',cmdline, a:CmdLine =~' $')
  let nb_args = len(cmdline)
  if (a:CmdLine !~ ' $')
    let nb_args -= 1
  endif
  " echomsg "nb args: ". nb_args
  if nb_args < 2
    return join(keys(s:toggle_commands),"\n")
  elseif nb_args == 2
    let variable = cmdline[1]
    if !has_key(s:toggle_commands, variable)
      throw "toggle-menu: unknown toggable variable ".variable
    endif
    let data = s:toggle_commands[variable]
    let labels_key = s:MenuKey(data)
    " echomsg "keys: ".string(data[labels_key])
    return join(data[labels_key], "\n")
  else
    return ''
  endif
endfunction

" # String variable menu item {{{2
" Function: s:VarFetch({Data},{key})                       {{{3
" @param[in] Data Menu-item definition
" @param[in] key  Table table from which the result will be fetched
" @return the current value
function! s:VarFetch(Data, key) abort
  call s:Verbose('Fetching variable <%1> for menu', a:Data.variable)
  if lh#ref#is_bound(a:Data.variable)
    return a:Data.variable.resolve()
  endif
  let variable = lh#menu#_var_name(a:Data.variable)
  if variable =~ '^p:'
    return lh#project#_get(variable[2:])
  else
    let value = eval(variable)
  endif
  return value
endfunction

" Function: s:VarSet({Data})                               {{{3
" @param[in,out] Data Menu item definition
"
" Sets the global variable associated to the menu item according to the item's
" current value.
function! s:VarSet(Data, value) abort
  let variable = a:Data.variable
  let value = a:value
  if lh#ref#is_bound(variable)
    call variable.assign(value)
  elseif variable[0] == '$' " environment variables
    exe "let ".variable." = ".string(value)
  elseif variable[0:1] == 'p:'
    call lh#let#to(variable, value)
  else
    " the following syntax doesn't work with dictionaries => use :exe
    " let g:{variable} = value
    exe 'let g:'.variable.' = '.string(value)
    " tODO/FIXME: what about lh#let#to('g:'.variable, value) ?
  endif
  if has_key(a:Data, "hook")
    let l:Action = a:Data.hook
    if type(l:Action) == type(function('tr'))
      call a:Data.hook()
    else
      exe l:Action
    endif
  endif
  return value
endfunction

" Function: s:VarSetTextValue({Data},{TextValue})          {{{3
" Force the value of the variable to the one associated to the {TextValue}
" The menu, and the variable are updated in consequence.
function! s:VarSetTextValue(Data, text) abort
  " Where the texts for values must be fetched
  let labels_key = s:MenuKey(a:Data)
  " Fetch the old current value
  let old = s:VarFetch(a:Data, labels_key)
  if old == a:text
    " value unchanged => abort
    return
  endif

  " Remove the entry from the menu
  call s:ClearMenu(a:Data.menu, old)

  " Add the updated entry in the menu
  call s:VarUpdateMenu(a:Data.menu, a:text, a:Data.command)
  " Update the binded global variable
  let value = s:VarSet(a:Data, a:text)
  echo lh#objet#to_string(a:Data.variable).'='.lh#object#to_string(value)
endfunction

" Function: s:VarUpdateMenu({Menu}, {text}, {command})     {{{3
" Adds a new menu item, with the text associated to the current value in
" braces.
"
" @param[in] Menu.priority Priority of the new menu-item
" @param[in] Menu.name     Name of the new menu-item
" @param[in] text          Text of the current value of the variable binded to
"                          the menu-item
" @param[in] command       Toggle command to execute when the menu-item is selected
function! s:VarUpdateMenu(Menu, text, command) abort
  if has('gui_running')
    let cmd = 'nnoremenu '.a:Menu.priority.' '.
          \ lh#menu#text(a:Menu.name.'<tab>('.a:text.')').
          \ ' :'.s:k_Set_cmd.' '.a:command
    silent! exe cmd
  endif
endfunction

" Function: lh#menu#def_string_item({Data})                  {{{3
" @param Data.idx_crt_value
" @param Data.definitions == [ {value:, menutext: } ]
" @param Data.menu        == { name:, position: }
"
" Sets a string-variable defined by {Data}.
function! lh#menu#def_string_item(Data) abort
  " Add evaluation function
  function! a:Data.eval() dict
    let key = s:MenuKey(self)
    return s:VarFetch(self, key)
  endfunction
  function! a:Data.val_id() dict
    return self.eval()
  endfunction

  " Save the menu data as an internal script variable
  let id = s:SaveData(a:Data)

  " Name of the auto-matically generated command
  let cmdName = substitute(a:Data.menu.name, '[^a-zA-Z_]', '', 'g')
  " Lazy definition of the command
  if 2 != exists(':'.s:k_Set_cmd)
    exe 'command! -nargs=1 -complete=custom,lh#menu#_string_complete -bar '
          \ . s:k_Set_cmd . ' :call s:SetVariableFromCommand(<f-args>)'
  endif
  " silent exe 'command! -nargs=0 '.cmdName.' :call s:NextValue(s:Data'.id.')'
  let s:set_string_commands[cmdName] = eval('s:Data'.id)
  let a:Data["command"] = cmdName

  " Add the menu entry according to the current value
  let key = s:MenuKey(a:Data)
  let crt_value = s:VarFetch(a:Data, key)
  if lh#option#is_unset(crt_value)
    let crt_value = '{(undefined)}'
    call lh#common#warning_msg('Warning: '.(a:Data.menu.name).' is currently undefined')
  endif
  call s:VarUpdateMenu(a:Data.menu, crt_value, cmdName)
  " Update the associated global variable to the default value
  call s:VarSet(a:Data, crt_value)
endfunction


"------------------------------------------------------------------------
" Function: s:SetVariableFromCommand(all_in_string)          {{{3
function! s:SetVariableFromCommand(all_in_string) abort
  let [dummy, cmdName, value ; dummy2] = matchlist(a:all_in_string, '\(\S\+\)\s\+\(.*\)')
  if !has_key(s:set_string_commands, cmdName)
    throw "set_string-menu: unknown variable ".cmdName
  endif
  let data = s:set_string_commands[cmdName]
  call s:VarSetTextValue(data, value)
endfunction

" Function: lh#menu#_string_complete(ArgLead, CmdLine, CursorPos) {{{3
function! lh#menu#_string_complete(ArgLead, CmdLine, CursorPos) abort
  let cmdline = split(a:CmdLine)
  call s:Verbose('cmd line: %1 # %2',cmdline, a:CmdLine =~' $')
  let nb_args = len(cmdline)
  if (a:CmdLine !~ ' $')
    let nb_args -= 1
  endif
  " echomsg "nb args: ". nb_args
  if nb_args < 2
    return join(keys(s:set_string_commands),"\n")
  else
    return ''
  endif
endfunction


"------------------------------------------------------------------------
" # IVN Menus          {{{2
" Function: s:CTRL_O({cmd})                                {{{3
" Build the command (sequence of ':ex commands') to be executed from
" INSERT-mode.
function! s:CTRL_O(cmd) abort
  return substitute(a:cmd, '\(^\|<CR>\):', '\1\<C-O>:', 'g')
endfunction

" Function: lh#menu#is_in_visual_mode()                    {{{3
function! lh#menu#is_in_visual_mode()
  return get(s:, 'is_in_visual_mode', 0)
endfunction

" Function: lh#menu#_CMD_and_clear_v({cmd})                 {{{3
" Internal function that executes the command and then clears the @v buffer
" todo: save and restore @v,
function! lh#menu#_CMD_and_clear_v(cmd) abort
  try
    let s:is_in_visual_mode = 1
    exe a:cmd
  finally
    let @v=''
    silent! unlet s:is_in_visual_mode
  endtry
endfunction

" Function: s:Build_CMD({prefix},{cmd})                    {{{3
" build the exact command to execute regarding the mode it is dedicated
function! s:Build_CMD(prefix, cmd) abort
  if a:cmd[0] != ':' | return ' ' . a:cmd
  endif
  if     a:prefix[0] == "i"  | return ' ' . <SID>CTRL_O(a:cmd)
  elseif a:prefix[0] == "n"  | return ' ' . a:cmd
  elseif a:prefix[0] == "v"
    if match(a:cmd, ":VCall") == 0
      return substitute(a:cmd, ':VCall', ' :call', ''). "\<cr>gV"
      " gV exit select-mode if we where in it!
    else
      return
            \ " \"vy\<C-C>:call lh#menu#_CMD_and_clear_v('" .
            \ substitute(a:cmd, "<CR>$", '', '') ."')\<cr>"
    endif
  elseif a:prefix[0] == "c"  | return " \<C-C>" . a:cmd
  else                       | return ' ' . a:cmd
  endif
endfunction

" Function: lh#menu#map_all({map_type}, [{map args}...)   {{{3
" map the command to all the modes required
function! lh#menu#map_all(map_type,...) abort
  let nore   = (match(a:map_type, '[aincv]*noremap') != -1) ? "nore" : ""
  let prefix = matchstr(substitute(a:map_type, nore, '', ''), '[aincv]*')
  if a:1 == "<buffer>" | let i = 3 | let binding = a:1 . ' ' . a:2
  else                 | let i = 2 | let binding = a:1
  endif
  let build_cmd = nore . 'map <silent> ' . binding
  let cmd = a:{i}
  let i +=  1
  while i <= a:0
    let cmd .=  ' ' . a:{i}
    let i +=  1
  endwhile
  while strlen(prefix)
    if prefix[0] == "a" | let prefix = "incv"
    else
      let map_cmd = prefix[0] . build_cmd . s:Build_CMD(prefix[0],cmd)
      if hasmapto(binding, prefix)
        call lh#common#warning_msg("Warning: There is already a ".prefix. "-mode mapping starting with ".binding. " when mapping\n  -> ".map_cmd)
        exe 'verbose '.prefix.'map '.binding
      endif
      call s:Verbose("%1", map_cmd)
      execute map_cmd
      let prefix = strpart(prefix, 1)
    endif
  endwhile
endfunction

" Function: lh#menu#make({prefix},{code},{text},{binding},...) {{{3
" Build the menu and map its associated binding to all the modes required
function! lh#menu#make(prefix, code, text, binding, ...) abort
  let nore    = (match(a:prefix, '[aincvsx]*nore') != -1) ? "nore" : ""
  let prefix  = matchstr(substitute(a:prefix, nore, '', ''), '[aincvsx]*')
  let b       = (a:1 == '<buffer>') ? 1 : 0
  let cmd = join(a:000[b : ], ' ')
  if type(a:binding) == type({})
    let binding = get(a:binding, 'binding', '')
    " TODO: Support action
    " let no_mapping = has_key(a:binding, 'action')
  else
    let binding = a:binding
    " let no_mapping = empty(binding)
  endif
  if !empty(binding)
    if prefix == 'i' && exists('*IMAP')
      if b != 0
        call IMAP(binding, cmd, &ft)
      else
        call IMAP(binding, cmd)
      endif
    else
      let sBuffer = b ? ' <buffer> ' : ''
      call lh#menu#map_all(prefix.nore.'map', sBuffer.binding, cmd)
    endif
  endif
  if has("gui_running") && has ('menu')
    let build_cmd = nore . 'menu <silent> ' . a:code . ' ' . lh#menu#text(a:text)
    if !empty(binding)
      let build_cmd .=  '<tab>' .
            \ substitute(lh#menu#text(binding), '&', '\0\0', 'g')
    endif
    while strlen(prefix)
      call s:Verbose(s:BMenu(b) . prefix[0] . build_cmd . s:Build_CMD(prefix[0],cmd))
      execute s:BMenu(b) . prefix[0] . build_cmd . s:Build_CMD(prefix[0],cmd)
      let prefix = strpart(prefix, 1)
    endwhile
  endif
endfunction

" Function: lh#menu#remove(modes, name) {{{3
function! lh#menu#remove(modes, name) abort
  let name = lh#menu#text(a:name)
  for mode in split(a:modes, '\zs')
    call s:Verbose(mode.'unmenu '.name)
    exe mode.'unmenu '.name
  endfor
endfunction

" Function: s:BMenu({b})                                   {{{3
" If <buffermenu.vim> is installed and the menu should be local, then the
" apropriate string is returned.
function! s:BMenu(b) abort
  let res = (a:b && exists(':Bmenu')
        \     && (1 == lh#option#get("want_buffermenu_or_global_disable", 1, "bg"))
        \) ? 'B' : ''
  " call confirm("BMenu(".a:b.")=".res, '&Ok', 1)
  return res
endfunction

" Function: lh#menu#IVN_make(...)                          {{{3
function! lh#menu#IVN_make(code, text, binding, i_cmd, v_cmd, n_cmd, ...) abort
  " nore options
  let nore_i = (a:0 > 0) ? ((a:1 != 0) ? 'nore' : '') : ''
  let nore_v = (a:0 > 1) ? ((a:2 != 0) ? 'nore' : '') : ''
  let nore_n = (a:0 > 2) ? ((a:3 != 0) ? 'nore' : '') : ''
  "
  call lh#menu#make('i'.nore_i,a:code,a:text, a:binding, '<buffer>', a:i_cmd)
  call lh#menu#make('v'.nore_v,a:code,a:text, a:binding, '<buffer>', a:v_cmd)
  if strlen(a:n_cmd) != 0
    call lh#menu#make('n'.nore_n,a:code,a:text, a:binding, '<buffer>', a:n_cmd)
  endif
endfunction

"
" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
