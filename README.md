# lh-vim-lib [![Build Status](https://secure.travis-ci.org/LucHermitte/lh-vim-lib.png?branch=master)](http://travis-ci.org/LucHermitte/lh-vim-lib) [![Project Stats](https://www.openhub.net/p/21020/widgets/project_thin_badge.gif)](https://www.openhub.net/p/21020)

## Introduction

_lh-vim-lib_ is a library that defines some common VimL functions I use in my various plugins and ftplugins.

This library has been conceived as a suite of [|autoload|](http://vimhelp.appspot.com/eval.txt.html#autoload) plugins. As such, it requires Vim 7+.

The [complete documentation](http://github.com/LucHermitte/lh-vim-lib/blob/master/doc/lh-vim-lib.txt) can be browsed.

**Important:

- Since Version 2.2.0, the naming policy of these autoload functions have been harmonized. Now, most names are in lower cases, with words separated by underscores.
- Since version 3.2.7, it's no longer hosted on google-code but on github**

## Functions

  * [Miscellaneous functions](#miscellaneous-functions)
  * [System related functions](#system-related-functions)
  * [Lists related functions](#lists-related-functions)
  * [Stacks related functions](#stacks-related-functions)
  * [Graphs related functions](#graphs-related-functions)
  * [Paths related functions](#paths-related-functions)
  * [Commands related functions](#commands-related-functions)
  * [Menus related functions](#menus-related-functions)
  * [Buffers related functions](#buffers-related-functions)
  * [Syntax related functions](#syntax-related-functions)
  * [UI functions](#ui-functions)

### Miscellaneous functions

| Function                                    | Purpose                                                                                                                                                                  |
|---------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `lh#askvim#exe()`                           | Returns what a VimL command echoes                                                                                                                                       |
| `lh#common#check_deps()`                    | Checks a VimL symbol is loaded                                                                                                                                           |
| `lh#common#echomsg_multilines()`            | Applies `:echomsg` on a multi-lines text                                                                                                                                 |
| `lh#common#error_msg()`                     | Displays an error message                                                                                                                                                |
| `lh#common#rand()`                          | Returns a random number                                                                                                                                                  |
| `lh#common#warning_msg()`                   | Displays a warning                                                                                                                                                       |
| `lh#encoding#at(mb_string, i)`              | Returns the i-th character in a multibytes string                                                                                                                        |
| `lh#encoding#iconv()`                       | Unlike `iconv()`, this wrapper returns {expr} when we know no conversion can be achieved.                                                                                |
| `lh#encoding#iconv(expr, from, to)`         | Converts an expression from an encoding to another                                                                                                                       |
| `lh#encoding#strlen(mb_string)`             | Executes `strlen()` on a multibytes string                                                                                                                               |
| `lh#encoding#strpart(mb_string, p, l)`      | Executes `strpart()` on a multibytes string                                                                                                                              |
| `lh#event#register_for_one_execution_at()`  | Registers a command to be executed once (and only once) when an event is triggered on the current file                                                                   |
| `lh#exception#callstack()`                  | Parses `v:throwpoint` to extract the functions called                                                                                                                    |
| `lh#fmt#printf({format}, {args...})`        | `printf` overload that takes positional arguments                                                                                                                        |
| `lh#float#arg_max(list)`                    | Returns the index of the maximum element of a list of floats                                                                                                             |
| `lh#float#arg_min(list)`                    | Returns the index of the minimum element of a list of floats                                                                                                             |
| `lh#float#max(list)`                        | Returns the maximum of a list of floats                                                                                                                                  |
| `lh#float#min(list)`                        | Returns the minimum of a list of floats                                                                                                                                  |
| `lh#ft#is_text()`                           | Tells whether the filetype is a text filetype                                                                                                                            |
| `lh#icomplete#run(startcol, matches, Hook)` | Prepares an insert mode completion menu that'll trigger actions instead of inserting text as `complete()` does                                                           |
| `lh#leader#get()`                           | Returns the current value of `g:mapleader`, or `'\\'` if unset                                                                                                           |
| `lh#leader#get_local()`                     | Returns the current value of `g:maplocalleader`, or `'\\'` if unset                                                                                                      |
| `lh#leader#set_local_if_unset()`            | Sets a new value to `g:maplocalleader`, if and only if this variable wasn't already set                                                                                  |
| `lh#let#let_if_undef()`                     | Defines a vim variable (with ` :let`) on the condition the variable does not exist yet                                                                                   |
| `lh#on#exit()`                              | Prepares a finalizer object to be executed in a `:finally` clause in order to restore variables and execute functions                                                    |
| `lh#option#add()`                           | Adds new values to a vim option -- and avoid the values being listed more than once                                                                                      |
| `lh#option#get(name [,default [, scope]])`  | Fetches the value of a user defined option, that may be _empty_. `default` is returned if the option does not exists. Default value for `default` is `g:lh#option#unset` |
| `lh#option#get_non_empty()`                 | Fetches the value of a user defined option, that is not _empty_                                                                                                          |
| `lh#option#getbufvar(buf, varname [,def])`  | Encapsulates `getbufvar(buf, varname, g:lh#option#unset)` when `def` is not passed                                                                                       |
| `lh#option#is_set(expr)`                    | Tells whether the expression is set (i.e. different from `g:lh#option#unset`)                                                                                            |
| `lh#option#is_unset(expr)`                  | Tells whether the expression is not set (i.e. identical to `g:lh#option#unset`)                                                                                          |
| `lh#position#char_at_mark()`                | Obtains the character under a mark                                                                                                                                       |
| `lh#position#char_at_pos()`                 | Obtains the character at a given position                                                                                                                                |
| `lh#position#char_at()`                     | Obtains the character at a given pair of coordinates                                                                                                                     |
| `lh#position#extract(pos1,pos2)`            | Obtains the text between two positions                                                                                                                                   |
| `lh#position#is_before()`                   | Tells if a position in a buffer is before another one                                                                                                                    |
| `lh#vcs#get_type(...)`                      | Returns the type of the versioning system the file is under                                                                                                              |
| `lh#vcs#as_http(...)`                       | Returns the url of the repo the parameter is under, or `g:url` if none is found. Enforce the rsult in the form http://, if possible                                      |
| `lh#vcs#decode_github_url(url)`             | Extract user name and repo name from a github url                                                                                                                        |
| `lh#vcs#get_url(...)`                       | Returns the url of the repo the parameter is under, or `g:url` if none is found                                                                                          |
| `lh#vcs#is_git(...)`                        | Tells whether the file is under a git repository                                                                                                                         |
| `lh#vcs#is_svn(...)`                        | Tells whether the file is under a svn repository                                                                                                                         |
| `lh#visual#cut()`                           | Cut and returns the visually selected text                                                                                                                               |
| `lh#visual#selection()`                     | Returns the visually selected text                                                                                                                                       |

### System related functions

See also [system-tools](http://github.com/LucHermitte/vim-system-tools)

| Function                           | Purpose                                                                            |
|------------------------------------|------------------------------------------------------------------------------------|
| `lh#env#expand_all()`              | Expands environment variables found in strings                                     |
| `lh#os#has_unix_layer_installed()` | Tells whether the enduser has declared a unix layer installed (on a Windows box)   |
| `lh#os#OnDOSWindows()`             | Tells whether the current vim is a native windows flavour of gvim                  |
| `lh#os#sys_cd()`                   | Build a portable string to use to change directoy when executing external commands |
| `lh#os#chomp(text)`                | Like Perl `chomp`, remove the trailing character produced by `system()` calls      |
| `lh#os#system(cmd)`                | Returns `lh#os#chomp(system(command))`                                             |
| `lh#os#cpu_number()`               | Returns the number of processors on the machine                                    |
| `lh#os#cpu_cores_number()`         | Returns the number of cores on the machine                                         |

### Lists and dictionary related functions
| Function                    | Purpose                                                                                                           |
|:----------------------------|:------------------------------------------------------------------------------------------------------------------|
| `lh#dict#add_new()`         | Adds elements from the second dictionary if they are not set yet in the first                                     |
| `lh#list#accumulate()`      | Accumulates the elements from a list                                                                              |
| `lh#list#accumulate()`      | Accumulates the elements from a list                                                                              |
| `lh#list#accumulate2()`     | Accumulates the elements from a list -- version closer to C++ std::accumulate()                                   |
| `lh#list#chain_transform()` | Applies a series of transformation on each element from a list ; unlike `map()`, the input list is left unchanged |
| `lh#list#copy_if()`         | Copies the elements from a list that match a predicate                                                            |
| `lh#list#equal_range()`     | See C++ [`std::equal_range`](http://en.cppreference.com/w/cpp/algorithm/equal_range)                              |
| `lh#list#find_if()`         | Searches the first element in a list that verifies a predicate                                                    |
| `lh#list#flat_extend()`     | Extends a list with another, or add elements into a list depending on the _right-hand-side_ parameter             |
| `lh#list#flatten()`         | Flattens a list                                                                                                   |
| `lh#list#for_each_call()`   | Calls a function of all elements from a list                                                                      |
| `lh#list#get()`             | Returns a list with the elements of index/key in a list of lists/dictionaries (<=> map get(key/idx) list)         |
| `lh#list#intersect()`       | Intersection of two lists                                                                                         |
| `lh#list#lower_bound()`     | See C++ [`std::lower_bound`](http://en.cppreference.com/w/cpp/algorithm/lower_bound)                              |
| `lh#list#map_on()`          | Transforms a list of lists/dictionaries at key/index with specified action.                                       |
| `lh#list#mask()`            | Builds a subset of the input list ; elements are kept according to a mask list.                                   |
| `lh#list#match()`           | Searches the first element in a list that matches a pattern                                                       |
| `lh#list#match_re()`        | Searches the first pattern in a list that  is matched by a text                                                   |
| `lh#list#matches()`         | Returns the list of indices of elements that match the pattern                                                    |
| `lh#list#not_found()`       | Returns whether the range returned from `equal_range` is empty (i.e. element not found)                           |
| `lh#list#possible_values()` | Returns a sorted list of the values that are stored: in a flat list, or at a given {index} in the lists from the input {list}, or at a given {key} in the dictionaries from the input {list} |
| `lh#list#push_if_new()`     | Adds a elements is not already present in the list                                                                |
| `lh#list#remove()`          | Remove elements from list according to a list of indices                                                          |
| `lh#list#rotate()`          | Rotate elements from list                                                                                         |
| `lh#list#sort()`            | Workaround `sort()` bug which has been fixed in Vim v7.4.411                                                      |
| `lh#list#subset()`          | Builds a subset slice of a list                                                                                   |
| `lh#list#transform()`       | Applies a transformation on each element from a list ; unlike `map()`, the input list is left unchanged           |
| `lh#list#transform_if()`    | Applies a transformation on each element from a list that match the predicate                                     |
| `lh#list#unique_sort()`     | Sorts the elements of a list, and makes sure they are all unique                                                  |
| `lh#list#unique_sort2()`    | Another implementation of `unique_sort`                                                                           |
| `lh#list#upper_bound()`     | See C++ [`std::upper_bound`](http://en.cppreference.com/w/cpp/algorithm/upper_bound)                              |


### Stacks related functions

#### Procedural way

| Function                      | Purpose                                                                                      |
|:------------------------------|:---------------------------------------------------------------------------------------------|
| `lh#stack#push(stack, value)` | Pushes a variable at the end of a list that will be interpreted as a _stack_                 |
| `lh#stack#top(stack)`         | Fetches the top of the stack                                                                 |
| `lh#stack#pop(stack)`         | Pops the top of the stack                                                                    |

#### OO way

| Function                      | Purpose                                                                                      |
|:------------------------------|:---------------------------------------------------------------------------------------------|
| `lh#stack#new(...)`           | Creates a new _stack_ object that proposes `push`, `top` and `pop` methods.                  |
| `lh#stack#new_list(nb)`       | Builds what `repeat([lh#stack#new()], 42)` cannot build                                      |

### Graphs related functions
| Function                   | Purpose                                                                                      |
|:---------------------------|:---------------------------------------------------------------------------------------------|
| `lh#graph#tsort#breadth()` | Same as `depth()`, but with a non-recursive breadth-first search                             |
| `lh#graph#tsort#depth()`   | Implements a Topological Sort on a Direct Acyclic Graph, with a recursive depth-first search |


### Paths related functions
| Function                                     | Purpose                                                                                                  |
|:---------------------------------------------|:---------------------------------------------------------------------------------------------------------|
| `lh#path#add_path_if_exists(listname, path)` | Adds a path is a list iff the path points to an existing node                                            |
| `lh#path#common()`                           | Returns the biggest common part between several paths                                                    |
| `lh#path#depth()`                            | Returns the depth of a path                                                                              |
| `lh#path#find(pathlist, regex)`              | Returns the first path in a list that matches a regex                                                    |
| `lh#path#find_in_parents()`                  | Support function at the root of [local_vimrc](http://github.com/LucHermitte/local_vimrc)                 |
| `lh#path#fix()`                              | Fixes a pathname in order for it to be compatible with external commands or vim options                  |
| `lh#path#glob_as_list()`                     | Returns `globpath()`result as a list                                                                     |
| `lh#path#is_absolute_path()`                 | Tells whether the parameter is an absolute pathname                                                      |
| `lh#path#is_in(node, path)`                  | Tells whether a node is already present in a path -- `readlink()` is applied on both parameters          |
| `lh#path#is_url()`                           | Tells whether the parameter is an URL                                                                    |
| `lh#path#join(pathparts, ...)`               | Joins path parts into a string                                                                           |
| `lh#path#munge(pathlist, path)`              | Adds a path to a list on the condition the path isn't already present, and that it points to a valid node|
| `lh#path#readlink(pathname)`                 | Returns `readlink` result on the pathname -- when the command is available on the system                 |
| `lh#path#relative_to()`                      | Returns the relative offset to reference files in another directory                                      |
| `lh#path#select_one()`                       | Asks the end-user to select one pathname                                                                 |
| `lh#path#shellslash()`                       | Returns the shellslash character                                                                         |
| `lh#path#simplify()`                         | Like `simplify()`, but also strips the leading `./`                                                      |
| `lh#path#split(pathname)`                    | Splits a string into path parts                                                                          |
| `lh#path#strip_common()`                     | In a set of pathnames, strips the leading part they all have in common                                   |
| `lh#path#strip_start()`                      | Strips the leading part of a pathname if found in the given list of pathnames                            |
| `lh#path#to_dirname()`                       | Complete the current path with '/' if missing                                                            |
| `lh#path#to_regex()`                         | Builds a regex that can be used to match pathnames                                                       |
| `lh#path#to_relative()`                      | Transforms a pathname to a pathname relative to the current directory                                    |
| `lh#path#vimfiles()`                         | Returns where the current user vimfiles are (`$HOME/.vim` `~/vimfiles`, ...)                             |


### Commands related functions
| Function                    | Purpose                                                          |
|:----------------------------|:-----------------------------------------------------------------|
| `lh#command#new()`          | Experimental way to define commands that support auto-completion |
| `lh#command#Fargs2String()` | Merges a set strings into a set of parameters (experimental)     |


### Menus related functions
| Function                      | Purpose                                                                                                                                                  |
|:------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------|
| `lh#askvim#menu()`            | Experimental functions to ask vim which menus are defined                                                                                                |
| `lh#mapping#define()`         | Defines a new mapping given a mapping definition                                                                                                         |
| `lh#menu#IVN_make()`          | Like `lh#menu#make()`, but dedicated to text inserting actions and INSERT, NORMAL, and VISUAL modes.                                                     |
| `lh#menu#def_string_item()`   | This function defines a [|`:menu`|](http://vimhelp.appspot.com/gui.txt.html#:menu) entry that will be associated to a |global-variable| string variable. |
| `lh#menu#def_toggle_item()`   | This function defines a [|`:menu`|](http://vimhelp.appspot.com/gui.txt.html#:menu) entry that will be associated to a |global-variable| whose values can be cycled and explored from the menu. This global variable can be seen as an enumerate whose value can be cyclically updated through a menu. |
| `lh#menu#is_in_visual_mode()` | Tells whether the action triggered by a menu/map was initiated while in visual mode.                                                                     |
| `lh#menu#make()`              | Helper function to associate menus and mappings to actions in different modes.                                                                           |
| `lh#menu#map_all()`           | Helper function to define several mappings at once as `:amenu` would do                                                                                  |
| `lh#menu#text()`              | Transforms a regular text into a text that can be directly used with [|`:menu`|](http://vimhelp.appspot.com/gui.txt.html#:menu) commands.                |

See also the documentation of the old functions at http://hermitte.free.fr/vim/general.php#expl_menu_map


### Buffers related functions
| Function                         | Purpose                                                                                                                          |
|:---------------------------------|:---------------------------------------------------------------------------------------------------------------------------------|
| `lh#buffer#dialog#add_help()`    | see [lh-vim-lib/dialog](doc/Dialog.md)                                                                                           |
| `lh#buffer#dialog#new()`         | see [lh-vim-lib/dialog](doc/Dialog.md)                                                                                           |
| `lh#buffer#dialog#select()`      | see [lh-vim-lib/dialog](doc/Dialog.md)                                                                                           |
| `lh#buffer#dialog#toggle_help()` | see [lh-vim-lib/dialog](doc/Dialog.md)                                                                                           |
| `lh#buffer#find()`               | Finds and jumps to the window that matches the buffer identifier, does nothing if not found.                                     |
| `lh#buffer#get_nr()`             | Returns the buffer number associated to a buffername/filename. If no such file is known to vim, a buffer will be locally created |
| `lh#buffer#jump()`               | Like `lh#buffer#find()`, but opens the buffer in a new window if it no matching window was opened before.                        |
| `lh#buffer#list()`               | Returns the list of `buflisted` buffers.                                                                                         |
| `lh#buffer#scratch()`            | Opens a new scratch buffer.                                                                                                      |
|:---------------------------------|:---------------------------------------------------------------------------------------------------------------------------------|
| `lh#window#split()`              | Forces to open a new split, ignoring E36                                                                                         |
| `lh#window#new()`                | Forces to open a new window, ignoring E36                                                                                        |
| `lh#window#create_window_with()` | Forces to create a new split, with any split related command, ignoring E36                                                       |


### Syntax related functions
| Function                                                         | Purpose                                                                                                                                |
|:-----------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------|
| `lh#syntax#is_a_comment()`                                       | Tells the syntax kind of the character at the given mark is a comment                                                                  |
| `lh#syntax#is_a_comment_at()`                                    | Tells the syntax kind of the character at the given position is a comment                                                              |
| `lh#syntax#list()`                                               | Like `lh#syntax#list_raw()`, but reinterprets the results (experimental)                                                               |
| `lh#syntax#list_raw()`                                           | Returns the result of "`syn list {group-name}`" as a string                                                                            |
| `lh#syntax#name_at()`                                            | Tells the syntax kind of the character at the given position                                                                           |
| `lh#syntax#name_at_mark()`                                       | Tells the syntax kind of the character at the given mark                                                                               |
| `lh#syntax#name_at_mark()`                                       | Tells the syntax kind of the character at the given mark                                                                               |
| `lh#syntax#skip()` `lh#syntax#SkipAt()` `lh#syntax#SkipAtMark()` | Helper functions to be used with `searchpair()` in order to ignore comments, Doxygen comments, strings, and characters while searching |
|:-----------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------|


### Functors
| Function                | Purpose                                      |
|:------------------------|:---------------------------------------------|
| `lh#function#bind()`    | Builds a functor object.                     |
| `lh#function#execute()` | Executes a functor object.                   |
| `lh#function#prepare()` | Prepares a functor object to be `eval`uated. |


### UI functions
All the functions defined in ui-functions.vim are wrappers around Vim
interactive functions. Depending on a configuration variable
(`[bg]:ui_type`), they will delegate the interaction to a gvim UI
function, or a plain text UI function (defined by vim, or emulated)

| Function    | Purpose                                                                                                                                     |
|:------------|:--------------------------------------------------------------------------------------------------------------------------------------------|
| `CHECK()`   | Emulates a checbox UI function                                                                                                              |
| `COMBO()`   | Emulates a combobox UI function                                                                                                             |
| `CONFIRM()` | Similar to `confirm()`                                                                                                                      |
| `IF()`      | Acts as the ternary operator                                                                                                                |
| `INPUT()`   | Calls `inputdialog()` or `input()`                                                                                                          |
| `SWITCH()`  | Â«Â»                                                                                                                                    |
| `WHICH()`   | Wrapper around functions like `CONFIRM()` or `COMBO()` that returns the text of the selected item instead of the index of the selected item |

In the same thematics, see also [VFT - Vim Form Toolkit](http://www.vim.org/scripts/script.php?script_id=2160)

### Word Tools
See http://hermitte.free.fr/vim/general.php#expl_words_tools


## Installation
  * Requirements: Vim 7.4
  * Clone from the git repository
```
git clone git@github.com:LucHermitte/lh-vim-lib.git
```
  * [Vim Addon Manager](http://github.com/MarcWeber/vim-addon-manager): (this
    is the preferred method as VAM handles dependencies).
```vim
ActivateAddons lh-vim-lib
```
  * Note that [vim-flavor](https://github.com/kana/vim-flavor) also handles
    dependencies which will permit to automatically import lh-vim-lib from
    plugins that use it:
```
flavor LucHermitte/lh-vim-lib
```
  * Vundle/NeoBundle:
```vim
Bundle 'LucHermitte/lh-vim-lib'
```

## Some other VimL libraries
  * [genutils](http://www.vim.org/scripts/script.php?script_id=197)
  * [pathogen](http://www.vim.org/scripts/script.php?script_id=2332)
  * [Tom Link's tlib](http://www.vim.org/scripts/script.php?script_id=1863)
  * [theonevimlib](http://github.com/MarcWeber/theonevimlib/tree/master), initiated by Marc Weber
  * [anwolib](http://www.vim.org/scripts/script.php?script_id=3800), by Andy Wokula
  * [l9](http://www.vim.org/scripts/script.php?script_id=3252), by Takeshi NISHIDA
