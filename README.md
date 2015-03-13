# Introduction

_lh-vim-lib_ is a library that defines some common VimL functions I use in my
various plugins and ftplugins.

This library has been conceived as a suite of |autoload| plugins, and a few
|macros| plugins. As such, it requires Vim 7+.

The [complete documentation](http://github.com/LucHermitte/lh-vim-lib/blob/master/doc/lh-vim-lib.txt) can be browsed.

**Important: Since Version 2.2.0, the naming policy of these autoload functions have been harmonized. Now, most names are in lower cases, with words separated by underscores.**

# Functions

  * [Miscellanous functions](README#Miscellanous_functions.md)
  * [Lists related functions](README#Lists_related_functions.md)
  * [Graphs related functions](README#Graphs_related_functions.md)
  * [Paths related functions](README#Graphs_related_functions.md)
  * [Commands related functions](README#Commands_related_functions.md)
  * [Menus related functions](README#Menus_related_functions.md)
  * [Buffers related functions](README#Buffers_related_functions.md)
  * [Syntax related functions](README#Syntax_related_functions.md)
  * [UI functions](README#UI_functions.md)

## Miscellanous functions
| `lh#askvim#exe()` | Returns what a VimL command echoes |
|:------------------|:-----------------------------------|
| `lh#common#check_deps()` | Checks a VimL symbol is loaded     |
| `lh#common#echomsg_multilines()` | Applies `:echomsg` on a multi-lines text |
| `lh#common#error_msg()` | Displays an error message          |
| `lh#common#warning_msg()` | Displays a warning                 |
| `lh#encoding#iconv()` | Unlike `iconv()`, this wrapper returns {expr} when we know no conversion can be achieved. |
| `lh#env#expand_all()` | Expands environment variables found in strings |
| `lh#event#register_for_one_execution_at()` | Registers a command to be executed once (and only once) when an event is triggered on the current file |
| `lh#option#get()` | Fetches the value of a user defined option, that may be _empty_ |
| `lh#option#get_non_empty()` | Fetches the value of a user defined option, that is not _empty_ |
| `lh#position#char_at_mark()` | Obtains the character under a mark |
| `lh#position#char_at_pos()` | Obtains the character at a given position |
| `lh#position#is_before()` | Tells if a position in a buffer is before another one|
| `lh#visual#selection()` | Returns the visually selected text |


## Lists related functions
| `lh#list#acculate()` | Accumulates the elements from a list |
|:---------------------|:-------------------------------------|
| `lh#list#copy_if()`  | Copies the elements from a list that match a predicate |
| `lh#list#find_if()`  | Searches the first element in a list that verifies a predicate |
| `lh#list#intersect()` | Insersection of two lists            |
| `lh#list#match()`    | Searches the first element in a list that matches a pattern |
| `lh#list#subset()`   | Builds a subset slice of a list      |
| `lh#list#transform()` | Applies a transformation on each element from a list ; unlike `map()`, the input list is left unchanged |
| `lh#list#unique_sort()` | Sorts the elements of a list, and makes sure they are all unique (trunk only for the moment) |


## Graphs related functions
| `lh#graph#tsort#depth()` | Implements a Topological Sort on a Direct Acyclic Graph, with a recursive depth-first search |
|:-------------------------|:---------------------------------------------------------------------------------------------|
| `lh#graph#tsort#breadth()` | Same as `depth()`, but with a non-recursive breadth-first search                             |


## Paths related functions
| `lh#path#common()` | Returns the biggest common part between several paths |
|:-------------------|:------------------------------------------------------|
| `lh#path#depth()`  | Returns the depth of a path                           |
| `lh#path#glob_as_list()` | Returns `globpath()`result as a list                  |
| `lh#path#is_absolute_path()` | Tells whether the parameter is an absolute pathname   |
| `lh#path#is_url()` | Tells whether the parameter is an URL                 |
| `lh#path#select_one()` | Asks the end-user to select one pathname              |
| `lh#path#simplify()` | Like `simplify()`, but also strips the leading `./`   |
| `lh#path#strip_common()` | In a set of pathnames, strips the leading part they all have in common |
| `lh#path#strip_start()` | Strips the leading part of a pathname if found in the given list of pathnames |
| `lh#path#to_dirname()` | Complete the current path with '/' if missing         |
| `lh#path#to_relative()` | Transforms a pathname to a pathname relative to the current directory |
| `lh#path#relative_to()` | Returns the relative offset to reference files in another directory |
| `lh#path#to_regex()` | Builds a regex that can be used to match pathnames    |


## Commands related functions
| `lh#command#New()` | Experimental way to define commands that support auto-completion |
|:-------------------|:-----------------------------------------------------------------|
| `lh#command#Fargs2String()` | Merges a set strings into a set of parameters (experimental)     |


## Menus related functions
| `lh#menu#def_toggleitem()` | This function defines a |menu| entry that will be associated to a |global-variable| whose values can be cycled and explored from the menu. This global variable can be seen as an enumerate whose value can be cyclically updated through a menu. |
|:---------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `lh#menu#text()`           | Transforms a regular text into a text that can be directly used with `:menu` commands.                                                                                                                                                            |
| `lh#menu#make()`           | Helper function to associate menus and mappings to actions in different modes.                                                                                                                                                                    |
| `lh#menu#IVN_make()`       | Like `lh#menu#Make()`, but dedicated to text inserting actions and INSERT, NORMAL, and VISUAL modes.                                                                                                                                              |
| `lh#menu#is_in_visual_mode()` | Tells whether the action triggered by a menu/map was initiated while in visual mode.                                                                                                                                                              |
| `lh#menu#map_all()`        | Helper function to define several mappings at once as `:amenu` would do                                                                                                                                                                           |
| `lh#askvim#menu()`         | Experimental functions to ask vim which menus are defined                                                                                                                                                                                         |

See also the documentation of the old functions at http://hermitte.free.fr/vim/general.php#expl_menu_map


## Buffers related functions
| `lh#buffer#list()` | Returns the list of `buflisted` buffers. |
|:-------------------|:-----------------------------------------|
| `lh#buffer#find()` | Finds and jumps to the window that matches the buffer identifier, does nothing if not found. |
| `lh#buffer#jump()` | Like `lh#buffer#Find()`, but opens the buffer in a new window if it no matching window was opened before. |
| `lh#buffer#scratch()` | Opens a new scratch buffer.              |
| `lh#buffer#dialog#toggle_help()` | see [lh-vim-lib/dialog](Dialog.md)       |
| `lh#buffer#dialog#add_help()` | see [lh-vim-lib/dialog](Dialog.md)       |
| `lh#buffer#dialog#new()` | see [lh-vim-lib/dialog](Dialog.md)       |
| `lh#buffer#dialog#select()` | see [lh-vim-lib/dialog](Dialog.md)       |


## Syntax related functions
| `lh#syntax#name_at()` | Tells the syntax kind of the character at the given position |
|:----------------------|:-------------------------------------------------------------|
| `lh#syntax#name_at_mark()` | Tells the syntax kind of the character at the given mark     |
| `lh#syntax#skip()` `lh#syntax#SkipAt()` `lh#syntax#SkipAtMark()` | Helper functions to be used with `searchpair()` in order to ignore comments, doxygen comments, strings, and characters while searching |
| `lh#syntax#syn_list_raw()` | Returns the result of "`syn list {group-name}`" as a string  |
| `lh#syntax#syn_list()` | Like `lh#syntax#SynListRaw()`, but reinterprets the results (experimental) |


## Functors
| `lh#function#bind()` | Builds a functor object. |
|:---------------------|:-------------------------|
| `lh#function#execute()` | Executes a functor object. |
| `lh#function#prepare()` | Prepares a functor object to be `eval`uated. |


## UI functions
All the functions defined in ui-functions.vim are wrappers around Vim
interactive functions. Depeding on a configuration variable
(`[bg]:ui_type`), they will delegate the interaction to a gvim UI
function, or a plain text UI function (defined by vim, or emulated)

| `IF()`  | Acts as the ternary operator |
|:--------|:-----------------------------|
| `SWITCH()` | Â«Â»                     |
| `CONFIRM()` | Similar to `confirm()`       |
| `INPUT()` | Calls `inputdialog()` or `input()` |
| `COMBO()` | Emulates a combobox UI function |
| `WHICH()` | Wrapper around functions like `CONFIRM()` or `COMBO()` that returns the text of the selected item instead of the index of the selected item |
| `CHECK()` | Emulates a checbox UI function |

In the same thematics, see also [VFT - Vim Form Toolkit](http://www.vim.org/scripts/script.php?script_id=2160)

## Word Tools
See http://hermitte.free.fr/vim/general.php#expl_words_tools


# Installation
  * Requirements: Vim 7.4
  * Clone from the git repository
```vim
git clone git@github.com:LucHermitte/lh-vim-lib.git
```
  * [Vim Addon Manager](http://github.com/MarcWeber/vim-addon-manager): (this
    is the preferred method as VAM handles dependencies).
```vim
ActivateAddons lh-vim-lib
```

  * Vundle/NeoBundle:
```vim
Bundle 'LucHermitte/lh-vim-lib'
```

# Other VimL libraries
  * [genutils](http://www.vim.org/scripts/script.php?script_id=197)
  * [pathogen](http://www.vim.org/scripts/script.php?script_id=2332)
  * [Tom Link's tlib](http://www.vim.org/scripts/script.php?script_id=1863)
  * [theonevimlib](http://github.com/MarcWeber/theonevimlib/tree/master), initiated by Marc Weber
  * [anwolib](http://www.vim.org/scripts/script.php?script_id=3800), by Andy Wokula
  * [l9](http://www.vim.org/scripts/script.php?script_id=3252), by Takeshi NISHIDA
