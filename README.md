# lh-vim-lib [![Last release](https://img.shields.io/github/tag/LucHermitte/lh-vim-lib.svg)](https://github.com/LucHermitte/lh-vim-lib/releases) [![Build Status](https://secure.travis-ci.org/LucHermitte/lh-vim-lib.png?branch=master)](http://travis-ci.org/LucHermitte/lh-vim-lib) [![Project Stats](https://www.openhub.net/p/21020/widgets/project_thin_badge.gif)](https://www.openhub.net/p/21020)

## Introduction

_lh-vim-lib_ is a library that defines some common vim functions I use in my various plugins and ftplugins.

This library has been conceived as a suite of [|autoload|](http://vimhelp.appspot.com/eval.txt.html#autoload) plugins. As such, it requires Vim 7+. A few commands are defined.

As I only have access to a version 7.4-052 on travis-ci, let's say this is the minimum vim version I'll try to be compatible with. Until 2017 (v3.x) I was trying to be compatible with 7.3-429.

The [complete documentation](http://github.com/LucHermitte/lh-vim-lib/blob/master/doc/lh-vim-lib.txt) can be browsed.

**Important:**

- Since Version 2.2.0, the naming policy of these autoload functions have been harmonized. Now, most names are in lower cases, with words separated by underscores.
- Since version 3.2.7, it's no longer hosted on google-code but on github.
- Version 4.0.0 breaks `lh#let#if_undef()` interface, deprecates `CONFIRM()`, requires vim 7.4-52.

## Table of Content

  * [Functions](#functions)
  * [Installation](#installation)
  * [Credits](#credits)
  * [Some other Vim Scripting libraries](#some-other-vim-scripting-libraries)
  * [Design Notes](doc/design_notes.md)

## Functions

  * [Option management](doc/Options.md) -- other web page
  * [Object Oriented Programming in vim scripts](doc/OO.md) -- other web page
  * [Miscellaneous functions](#miscellaneous-functions)
  * [System related functions](#system-related-functions)
  * [Lists and dictionaries related functions](#lists-and-dictionaries-related-functions)
  * [Stacks related functions](#stacks-related-functions)
  * [Graphs related functions](#graphs-related-functions)
  * [Paths related functions](#paths-related-functions)
  * [Commands related functions](#commands-related-functions)
  * [Menus related functions](#menus-related-functions)
  * [Buffers and Windows related functions](#buffers-and-windows-related-functions)
  * [Quickfix related functions](#quickfix-related-functions)
  * [Syntax related functions](#syntax-related-functions)
  * [UI functions](#ui-functions)
  * [Project feature](doc/Project.md) -- other web page
  * [Logging framework](doc/Log.md) -- other web page
  * [Design by Contract functions](doc/DbC.md) -- other web page
  * [Call stack decoding](doc/Callstack.md) -- other web page
  * [Commands](#commands)
  * [Python related functions](#python-related-functions)

### Miscellaneous functions

| Function                                       | Purpose                                                                                                                                                                  |
|------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `lh#askvim#exe()`                              | Returns what a Vim command echoes                                                                                                                                        |
| `lh#askvim#scriptid(name)`                     | Returns the id of the script associated to {name}                                                                                                                        |
| `lh#askvim#scriptname(id)`                     | Returns the name of the script associated to {id}                                                                                                                        |
| `lh#askvim#scriptnames()`                      | Returns `:scriptnames` result as a list of [scriptid, name] arrays                                                                                                       |
| `lh#async#get_queue(name,policy).push_or_start(cmd, options)` | Push a `cmd` to execute in a named queue of jobs. Requires Vim 7.4-1980                                                                                   |
| `lh#common#check_deps()`                       | Checks a Vim symbol is loaded                                                                                                                                            |
| `lh#common#echomsg_multilines()`               | Applies `:echomsg` on a multi-lines text                                                                                                                                 |
| `lh#common#error_msg()`                        | Displays an error message                                                                                                                                                |
| `lh#common#rand()`                             | Returns a random number                                                                                                                                                  |
| `lh#common#warning_msg()`                      | Displays a warning                                                                                                                                                       |
| `lh#encoding#at(mb_string, i)`                 | Returns the i-th character in a multibytes string                                                                                                                        |
| `lh#encoding#previous_character()`             | Returns the character before the cursor -- works with multi-byte characters                                                                                              |
| `lh#encoding#current_character()`              | Returns the character under the cursor -- works with multi-byte characters                                                                                               |
| `lh#encoding#does_support()`                   | Tries to detect automatically whether a codepoint has an associated glyph in the current font used                                                                       |
| `lh#encoding#find_best_glyph()`                | Returns the first codepoint of each list that has a glyph in the current font used                                                                                       |
| `lh#encoding#iconv()`                          | Unlike `iconv()`, this wrapper returns {expr} when we know no conversion can be achieved                                                                                 |
| `lh#encoding#iconv(expr, from, to)`            | Converts an expression from an encoding to another                                                                                                                       |
| `lh#encoding#strlen(mb_string)`                | Executes `strlen()` on a multibytes string                                                                                                                               |
| `lh#encoding#strpart(mb_string, p, l)`         | Executes `strpart()` on a multibytes string                                                                                                                              |
| `lh#event#register_for_one_execution_at()`     | Registers a command to be executed once (and only once) when an event is triggered on the current file                                                                   |
| `lh#file#new_cache().get()`                    | Caches and returns data associated to a file                                                                                                                             |
| `lh#float#arg_max(list)`                       | Returns the index of the maximum element of a list of floats                                                                                                             |
| `lh#float#arg_min(list)`                       | Returns the index of the minimum element of a list of floats                                                                                                             |
| `lh#float#max(list)`                           | Returns the maximum of a list of floats                                                                                                                                  |
| `lh#float#min(list)`                           | Returns the minimum of a list of floats                                                                                                                                  |
| `lh#fmt#printf({format}, {args...})`           | `printf` overload that takes positional arguments                                                                                                                        |
| `lh#ft#is_text()`                              | Tells whether the filetype is a text filetype                                                                                                                            |
| `lh#has#jobs()`                                | Tells whether +job are correctly implemented                                                                                                                             |
| `lh#has#partials()`                            | Tells whether partials are correctly implemented                                                                                                                         |
| `lh#has#patch()`                               | Portable layer over `|has-patch|` feature                                                                                                                                |
| `lh#has#plugin()`                              | Tells whether a file is present in `'runtimepath'`                                                                                                                       |
| `lh#has#default_in_getbufvar()`                | Tells whether `getbufvar()` has its 3 parameters                                                                                                                         |
| `lh#icomplete#new(startcol, matches, Hook)`    | Prepares a smart insert mode omni-completion menu that'll trigger actions instead of inserting text. _smart_ means characters may be typed to reduce choices.            |
| `lh#icomplete#new_on(pat, matches, Hook)`      | Same as previous, but this time the startcol is automatically deduced from the word pattern.                                                                             |
| `lh#icomplete#run(startcol, matches, Hook)`    | Prepares an insert mode completion menu that'll trigger actions instead of inserting text as `complete()` does. **deprecated** prefer `lh#icomplete#new()`               |
| `lh#lang#set_message_temporarily()`            | Changes `$LANG` to the value passed, and returns a `lh#on#exit()` object to restore the variable value                                                                 |
| `lh#leader#get()`                              | Returns the current value of `g:mapleader`, or `'\\'` if unset                                                                                                           |
| `lh#leader#get_local()`                        | Returns the current value of `g:maplocalleader`, or `'\\'` if unset                                                                                                      |
| `lh#leader#set_local_if_unset()`               | Sets a new value to `g:maplocalleader`, if and only if this variable wasn't already set                                                                                  |
| `lh#let#if_undef()`                            | Defines an extended vim variable (with ` :let`) on the condition the variable does not exist yet                                                                         |
| `lh#let#to()`                                  | Defines an extended vim variable (with ` :let`) -- its previous value will be overridden                                                                                 |
| `lh#let#unlet()`                               | Undefines an extended vim variable (with ` :unlet`)                                                                                                                      |
| `lh#mark#is_unused(markname)`                  | Tells whether a mark is already used                                                                                                                                     |
| `lh#mark#find_first_unused()`                  | Returns the name of the first unused mark found in A..Z and a..z                                                                                                         |
| `lh#math#abs()`                                | Portable `abs()` function                                                                                                                                                |
| `lh#mapping#define()`                          | Defines a mapping from its description                                                                                                                                   |
| `lh#mapping#plug()`                            | Defines a series of default mappings associated to a plug mapping                                                                                                        |
| `lh#mapping#reinterpret_escaped_char()`        | Transforms sequences into interpreted sequences for mappings                                                                                                             |
| `lh#mapping#who_map(rhs, mode)`                | Returns a list of mappings that are bound to {rhs} in the specified {mode}                                                                                               |
| `lh#notify#once()`                             | Notifies something once                                                                                                                                                  |
| `lh#notify#deprecated()`                       | Notifies somthing is deprecated once                                                                                                                                     |
| `lh#notify#clear_notifications()`              | Clear previous notification so that could be notified again                                                                                                              |
| `lh#on#exit()`                                 | Prepares a finalizer object to be executed in a `:finally` clause in order to restore variables and execute functions                                                    |
| `lh#ref#bind(varname)`                         | Returns a reference to another variable. To be evaluated with [`lh#option#get()`](doc/Options.md#lhoptiongetname-default--scope)                                         |
| `lh#ref#is_bound(var)`                         | Tells whether a variable is bound to another                                                                                                                             |
| `lh#po#context().translate(msgId)`             | Translates message Id from Portable Object files                                                                                                                         |
| `lh#position#char_at_mark()`                   | Obtains the character under a mark                                                                                                                                       |
| `lh#position#char_at_pos()`                    | Obtains the character at a given position                                                                                                                                |
| `lh#position#char_at()`                        | Obtains the character at a given pair of coordinates                                                                                                                     |
| `lh#position#compare()`                        | Tells if a position in a buffer is before another one -- result compatible with `sort()`                                                                                                                   |
| `lh#position#extract(pos1,pos2)`               | Obtains the text between two positions                                                                                                                                   |
| `lh#position#getcur()`                         | Return [`getcurpos()`](http://vimhelp.appspot.com/eval.txt.html#getcurpos%28%29) when it exists, [`getpos('.')`](http://vimhelp.appspot.com/eval.txt.html#getpos%28%29)  otherwise |
| `lh#position#is_before()`                      | Tells if a position in a buffer is before another one -- boolean result                                                                                                  |
| `lh#position#move(dir)`                        | Returns a the string to use to move the cursor in the given direction -- this can be redoable w/ vim > 7.4.849                                                           |
| `lh#position#move_n(dir, count)`               | Returns a the string to use to move the cursor count times in the given direction -- this can be redoable w/ vim > 7.4.849                                               |
| `lh#string#count_char()`                       | Counts how many times a character is present in a string                                                                                                                 |
| `lh#string#join()`                             | Work as [`join()`](http://vimhelp.appspot.com/eval.txt.html#join%28%29) but on strings directly                                                                          |
| `lh#string#matches()`                          | Extracts a list of all matches in a string                                                                                                                               |
| `lh#string#matchstrpos()`                      | Backports `matchstrpos()` to old vim versions                                                                                                                            |
| `lh#string#or()`                               | Returns the first non empty string                                                                                                                                       |
| `lh#string#trim()`                             | Trims a string                                                                                                                                                           |
| `lh#switch#new()`                              | Creates a new switch object that proposes the `.add_case()` and `.evaluate()` method.                                                                                    |
| `lh#tags#stack#jump()`                         | Forges a new tag entry in the tag stack, and jump to it                                                                                                                  |
| `lh#tags#stack#push()`                         | Forges a new tag entry in the tag stack                                                                                                                                  |
| `lh#time#bench(F,...)`                         | Times the execution of `F(...)`                                                                                                                                          |
| `lh#time#bench_n(n, F,...)`                    | Times n executions of `F(...)`                                                                                                                                           |
| `lh#time#date()`                               | return the equivalent of `strftime('%D-th %b %Y)`                                                                                                                        |
| `lh#vcs#get_type(...)`                         | Returns the type of the versioning system the file is under                                                                                                              |
| `lh#vcs#as_http(...)`                          | Returns the url of the repository the parameter is under, or `g:url` if none is found. Enforce the result in the form http://, if possible                               |
| `lh#vcs#decode_github_url(url)`                | Extract user name and repository name from a github url                                                                                                                  |
| `lh#vcs#get_url(...)`                          | Returns the url of the repository the parameter is under, or `g:url` if none is found                                                                                    |
| `lh#vcs#is_git(...)`                           | Tells whether the file is under a git repository                                                                                                                         |
| `lh#vcs#is_svn(...)`                           | Tells whether the file is under a svn repository                                                                                                                         |
| `lh#visual#cut()`                              | Cut and returns the visually selected text                                                                                                                               |
| `lh#visual#selection()`                        | Returns the visually selected text                                                                                                                                       |

### System related functions

See also [system-tools](http://github.com/LucHermitte/vim-system-tools)

| Function                           | Purpose                                                                                     |
|------------------------------------|---------------------------------------------------------------------------------------------|
| `lh#env#expand_all()`              | Expands environment variables found in strings                                              |
| `lh#os#has_unix_layer_installed()` | Tells whether the enduser has declared a unix layer installed (on a Windows box)            |
| `lh#os#OnDOSWindows()`             | Tells whether the current vim is a native windows flavour of gvim                           |
| `lh#os#sys_cd()`                   | Build a portable string to use to change directory when executing external commands         |
| `lh#os#chomp(text)`                | Like Perl `chomp`, remove the trailing character produced by `system()` calls               |
| `lh#os#make(cmd, bang)`            | Executes `export p:$ENV &amp;&amp; :make{bang} {cmd}`                                       |
| `lh#os#new_script_runner(cmd,env)` | Returns a finalizable temporary script that sets `p:$ENV` variables and execute the command |
| `lh#os#system(cmd)`                | Returns `lh#os#chomp(system(export p:$ENV &amp;&amp; command))`                             |
| `lh#os#cpu_number()`               | Returns the number of processors on the machine                                             |
| `lh#os#cpu_cores_number()`         | Returns the number of cores on the machine                                                  |
| `lh#os#lcd()`                      | Executes `:lcd fnameescape({path})`                                                         |

### Lists and dictionaries related functions
| Function                         | Purpose                                                                                                           |
|:---------------------------------|:------------------------------------------------------------------------------------------------------------------|
| `lh#dict#add_new()`              | Adds elements from the second dictionary if they are not set yet in the first                                     |
| `lh#dict#get_composed()`         | Function symetric to `lh#let#*()` functions                                                                       |
| `lh#dict#key()`                  | Expects the dictionary to have only one element (throw otherwise) and returns it                                  |
| `lh#dict#let()`                  | Emulates `:let dict.key.key.key = value`                                                                          |
| `lh#dict#print_as_tree()`        | Pretty printer for dictionaries: present them as tree                                                             |
| `lh#dict#need_ref_on()`          | Makes sure `:let dict.key.key.key` exists and returns a reference to that element                                 |
| `lh#dict#subset()`               | Builds a subset dictionary of a dict                                                                              |
| `lh#list#accumulate()`           | Accumulates the elements from a list                                                                              |
| `lh#list#accumulate()`           | Accumulates the elements from a list                                                                              |
| `lh#list#accumulate2()`          | Accumulates the elements from a list -- version closer to C++ std::accumulate()                                   |
| `lh#list#arg_min()` & `max`      | Returns the index of the lesser/greater elements                                                                  |
| `lh#list#chain_transform()`      | Applies a series of transformation on each element from a list ; unlike `map()`, the input list is left unchanged |
| `lh#list#concurrent_for()`       | Concurrently searches for symettric differences and intersection of two sorted sets                               |
| `lh#list#contain_entity()`       | Tells whether a Dict or List entity is present within a list                                                      |
| `lh#list#copy_if()`              | Copies the elements from a list that match a predicate                                                            |
| `lh#list#cross()`                | Cross elements from two lists and produce a new list                                                              |
| `lh#list#equal_range()`          | See C++ [`std::equal_range`](http://en.cppreference.com/w/cpp/algorithm/equal_range)                              |
| `lh#list#find_entity()`          | Return the index where an entity is within a list, -1 if not found                                                |
| `lh#list#find_if()`              | Searches the first element in a list that verifies a predicate                                                    |
| `lh#list#find_if_fast()`         | Searches the first element in a list that verifies a simple predicate only relying on `v:val` or `v:key`          |
| `lh#list#flat_extend()`          | Extends a list with another, or add elements into a list depending on the _right-hand-side_ parameter             |
| `lh#list#flatten()`              | Flattens a list                                                                                                   |
| `lh#list#for_each_call()`        | Calls a function of all elements from a list                                                                      |
| `lh#list#get()`                  | Returns a list with the elements of index/key in a list of lists/dictionaries (<=> map get(key/idx) list)         |
| `lh#list#intersect()`            | Intersection of two lists                                                                                         |
| `lh#list#is_contained_in()`      | Returns whether all elements from the sublist are present in the second list                                      |
| `lh#list#lower_bound()`          | See C++ [`std::lower_bound`](http://en.cppreference.com/w/cpp/algorithm/lower_bound)                              |
| `lh#list#map_on()`               | Transforms a list of lists/dictionaries at key/index with specified action.                                       |
| `lh#list#mask()`                 | Builds a subset of the input list ; elements are kept according to a mask list.                                   |
| `lh#list#match()`                | Searches the first element in a list that matches a pattern                                                       |
| `lh#list#match_re()`             | Searches the first pattern in a list that  is matched by a text                                                   |
| `lh#list#matches()`              | Returns the list of indices of elements that match the pattern                                                    |
| `lh#list#not_contain_entity()`   | Tells whether a Dict or List entity is not present within a list                                                  |
| `lh#list#not_found()`            | Returns whether the range returned from `equal_range` is empty (i.e. element not found)                           |
| `lh#list#possible_values()`      | Returns a sorted list of the values that are stored: in a flat list, or at a given {index} in the lists from the input {list}, or at a given {key} in the dictionaries from the input {list} |
| `lh#list#push_if_new()`          | Adds a value if not already present in the list                                                                   |
| `lh#list#push_if_new_elements()` | Adds elements if not already present in the list                                                                  |
| `lh#list#push_if_new_entity()`   | Adds an entity if not already present in the list                                                                 |
| `lh#list#remove()`               | Remove elements from list according to a list of indices                                                          |
| `lh#list#rotate()`               | Rotate elements from list                                                                                         |
| `lh#list#separate()`             | Returns the list that matches the predicate and the list that doesn't match it                                    |
| `lh#list#sort()`                 | Workaround `sort()` bug which has been fixed in Vim v7.4.411                                                      |
| `lh#list#subset()`               | Builds a subset slice of a list                                                                                   |
| `lh#list#transform()`            | Applies a transformation on each element from a list ; unlike `map()`, the input list is left unchanged           |
| `lh#list#transform_if()`         | Applies a transformation on each element from a list that match the predicate                                     |
| `lh#list#uniq()`                 | Emulates `uniq()` when not defined, calls it otherwise                                                            |
| `lh#list#unique_sort()`          | Sorts the elements of a list, and makes sure they are all unique                                                  |
| `lh#list#unique_sort2()`         | Another implementation of `unique_sort`                                                                           |
| `lh#list#upper_bound()`          | See C++ [`std::upper_bound`](http://en.cppreference.com/w/cpp/algorithm/upper_bound)                              |
| `lh#list#zip()`                  | Zip two lists into one list.                                                                                      |
| `lh#list#zip_as_dict()`          | Zip two lists into a dictionary                                                                                   |


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
| Function                                     | Purpose                                                                                                                                  |
|:---------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------|
| `lh#path#add_path_if_exists(listname, path)` | Adds a path is a list iff the path points to an existing node                                                                            |
| `lh#path#cd_without_sideeffects()`           | Change the current directory without altering the behaviour regarding window local directories                                           |
| `lh#path#common()`                           | Returns the biggest common part between several paths                                                                                    |
| `lh#path#depth()`                            | Returns the depth of a path                                                                                                              |
| `lh#path#exe()`                              | Returns the fullpath of an executable (emulate [`exepath()`](http://vimhelp.appspot.com/eval.txt.html#exepath%28%29) on old vim versions |
| `lh#path#exists()`                           | Returns whether a pathname can be read, or if it's open in a buffer                                                                      |
| `lh#path#find(pathlist, regex)`              | Returns the first path in a list that matches a regex                                                                                    |
| `lh#path#find_in_parents()`                  | Support function at the root of [local_vimrc](http://github.com/LucHermitte/local_vimrc)                                                 |
| `lh#path#find_upward()`                      | Uniform interface to `finddir()` and `filefile()`                                                                                        |
| `lh#path#fix()`                              | Fixes a pathname in order for it to be compatible with external commands or vim options                                                  |
| `lh#path#glob_as_list()`                     | Returns `globpath()`result as a list                                                                                                     |
| `lh#path#is_absolute_path()`                 | Tells whether the parameter is an absolute pathname                                                                                      |
| `lh#path#is_distant_or_scratch()`            | Tells whether the parameter is a distant path or a scratch buffer name                                                                   |
| `lh#path#is_in(node, path)`                  | Tells whether a node is already present in a path -- `readlink()` is applied on both parameters                                          |
| `lh#path#is_url()`                           | Tells whether the parameter is an URL                                                                                                    |
| `lh#path#join(pathparts, ...)`               | Joins path parts into a string                                                                                                           |
| `lh#path#munge(pathlist, path)`              | Adds a path to a list on the condition the path isn't already present, and that it points to a valid node                                |
| `lh#path#new_permission_lists()`             | Prepares a permission lists object to be used to accept/reject pathnames based upon white/black/... lists                                |
| `lh#path#readlink(pathname)`                 | Returns `readlink` result on the pathname -- when the command is available on the system                                                 |
| `lh#path#relative_to()`                      | Returns the relative offset to reference files in another directory                                                                      |
| `lh#path#remove_dir_mark()`                  | Removes the trailing `/` or `\` in the path if any                                                                                       |
| `lh#path#select_one()`                       | Asks the end-user to select one pathname                                                                                                 |
| `lh#path#shellslash()`                       | Returns the shellslash character                                                                                                         |
| `lh#path#simplify()`                         | Like `simplify()`, but also strips the leading `./`                                                                                      |
| `lh#path#split(pathname)`                    | Splits a string into path parts                                                                                                          |
| `lh#path#strip_common()`                     | In a set of pathnames, strips the leading part they all have in common                                                                   |
| `lh#path#strip_start()`                      | Strips the leading part of a pathname if found in the given list of pathnames                                                            |
| `lh#path#to_dirname()`                       | Complete the current path with '/' if missing                                                                                            |
| `lh#path#to_regex()`                         | Builds a regex that can be used to match pathnames                                                                                       |
| `lh#path#to_relative()`                      | Transforms a pathname to a pathname relative to the current directory                                                                    |
| `lh#path#vimfiles()`                         | Returns where the current user vimfiles are (`$HOME/.vim` `~/vimfiles`, ...)                                                             |
| `lh#path#writable()`                         | Returns whether we could write into the pathname, even if nothing by that name already exists                                            |


### Commands related functions
| Function                                | Purpose                                                                                     |
|:----------------------------------------|:--------------------------------------------------------------------------------------------|
| `lh#command#new()`                      | Experimental way to define commands that support auto-completion                            |
| `lh#command#Fargs2String()`             | Merges a set strings into a set of parameters (experimental)                                |
| `lh#command#analyse_args()`             | Parse `:command-completion-custom` function parameters                                      |
| `lh#command#matching_variables()`       | Returns a list of Vim variable names matching the lead                                      |
| `lh#command#matching_for_commands()`    | Returns a list of Ex command names matching the lead                                        |
| `lh#command#matching_askvim()`          | Returns a list of what Vim what have returned for cmdline completion given a type of things |
| `lh#command#matching_bash_completion()` | Asks Bash what it'll complete the lead following the command with                           |
| `lh#command#matching_make_completion()` | Asks Bash what it'll complete the lead following `make` with                                |


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
| `lh#menu#emove()`             | Helper function to remove a menus from as many modes as required                                                                                         |
| `lh#menu#text()`              | Transforms a regular text into a text that can be directly used with [|`:menu`|](http://vimhelp.appspot.com/gui.txt.html#:menu) commands.                |

See also the documentation of the old functions at http://hermitte.free.fr/vim/general.php#expl_menu_map


### Buffers and Windows related functions
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
| `lh#window#split()`              | Forces to open a new split, ignoring E36                                                                                         |
| `lh#window#new()`                | Forces to open a new window, ignoring E36                                                                                        |
| `lh#window#create_window_with()` | Forces to create a new split, with any split related command, ignoring E36                                                       |
| `lh#window#getid()`              | Emulates recent `win_getid()` function                                                                                           |
| `lh#window#gotoid()`             | Emulates recent `win_gotoid()` function                                                                                          |
| `lh#window#text_width()`         | Return the actual width available to display text in the current window.                                                         |


### Quickfix related functions
| Function                   | Purpose                                                                                                                      |
|:---------------------------|:-----------------------------------------------------------------------------------------------------------------------------|
| `lh#qf#get_merics()`       | Returns the numbers of errors and warnings in the quickfix list                                                              |
| `lh#qf#get_title()`        | Returns title of the qf window                                                                                               |
| `lh#qf#get_winnr()`        | Returns window number of the qf window -- ignore location list windows                                                       |
| `lh#qf#is_displayed()`     | Tells whether the qf window is visible -- ignore location list windows                                                       |
| `lh#qf#make_context_map()` | Returns a non intrusive alternative to [`quickfix-context`](http://vimhelp.appspot.com/quickfix.txt.html#quickfix%2dcontext) |
| `lh#qf#set_title()`        | Sets the title of the qf window                                                                                              |

### Syntax related functions
| Function                                                         | Purpose                                                                                                                                |
|:-----------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------|
| `lh#syntax#getline_matching()`                                   | Extracts a line with the characters matching a given syntax ID pattern                                                                 |
| `lh#syntax#getline_not_matching()`                               | Extracts a line without the characters matching a given syntax ID pattern                                                              |
| `lh#syntax#is_a_comment()`                                       | Tells the syntax kind of the character at the given mark is a comment                                                                  |
| `lh#syntax#is_a_comment_at()`                                    | Tells the syntax kind of the character at the given position is a comment                                                              |
| `lh#syntax#line_filter()`                                        | Defines an object that extracts the characters matching a given syntax ID pattern text lines                                           |
| `lh#syntax#list()`                                               | Like `lh#syntax#list_raw()`, but reinterprets the results (experimental)                                                               |
| `lh#syntax#list_raw()`                                           | Returns the result of "`syn list {group-name}`" as a string                                                                            |
| `lh#syntax#match_at()`                                           | Tells whether the syntax kind of the character at the given position matches a pattern                                                 |
| `lh#syntax#name_at()`                                            | Tells the syntax kind of the character at the given position                                                                           |
| `lh#syntax#name_at_mark()`                                       | Tells the syntax kind of the character at the given mark                                                                               |
| `lh#syntax#name_at_mark()`                                       | Tells the syntax kind of the character at the given mark                                                                               |
| `lh#syntax#skip()` `lh#syntax#SkipAt()` `lh#syntax#SkipAtMark()` | Helper functions to be used with `searchpair()` in order to ignore comments, Doxygen comments, strings, and characters while searching |


### Functors
| Function                  | Purpose                                                     |
| :------------------------ | :-----------------------------------------------------------|
| `lh#function#bind()`      | Builds a functor object.                                    |
| `lh#function#execute()`   | Executes a functor object.                                  |
| `lh#function#prepare()`   | Prepares a functor object to be `eval`uated.                |
| `lh#partial#make()`       | Prepares a partial (or an emulated partial) to be executed. |
| `lh#partial#execute()`    | Executes a partial (or an emulated partial) .               |


### UI functions
All the functions defined in ui-functions.vim are wrappers around Vim
interactive functions. Depending on a configuration variable
(`(bpg):ui_type`), they will delegate the interaction to a gvim UI
function, or a plain text UI function (defined by vim, or emulated)

Possible values for `(bpg):ui_type` are: `gui` (default) or `text`.

In `lh#ui#confirm()` case, the option `(bpg):ui_confirm_type` can be set to
`'std'` to explicitly use
[`confirm()`](http://vimhelp.appspot.com/eval.txt.html#confirm%28%29) instead
of the old emulated version. The default is to use the emulated version of
`confirm()`, which unlike the standard one permits to navigate between
propositions with the cursor or `tab`  keys to choose one.

| Function                         | Purpose                                                                                                                                                 |
|:---------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------|
| `lh#ui#ask()`                    | Ask a question under the status line                                                                                                                    |
| `lh#ui#check()`                  | Emulates a checbox UI function                                                                                                                          |
| `lh#ui#combo()`                  | Emulates a combobox UI function                                                                                                                         |
| `lh#ui#confirm()`                | Similar to `confirm()`                                                                                                                                  |
| `lh#ui#global_confirm_command()` | Extends `:substitute` `confirm`  flag to `:global`. Wrapped in `:ConfirnGlobal`                                                                         |
| `lh#ui#if()`                     | Acts as the ternary operator                                                                                                                            |
| `lh#ui#input()`                  | Calls `inputdialog()` or `input()`                                                                                                                      |
| `lh#ui#make_confirm_command()`   | Prepare an object to use when executing a command multiple times                                                                                        |
| `lh#ui#switch()`                 | Emulates `switch()` in vim-script language                                                                                                              |
| `lh#ui#which()`                  | Wrapper around functions like `lh#ui#confirm()` or `lh#ui#combo()` that returns the text of the selected item instead of the index of the selected item |

In the same thematics, see also [VFT - Vim Form Toolkit](http://www.vim.org/scripts/script.php?script_id=2160)

### Logging Framework
See separate page: [doc/Log.md](doc/Log.md).

### Design by Contract functions
See separate page: [doc/DbC.md](doc/DbC.md).

### Word Tools
See http://hermitte.free.fr/vim/general.php#expl_words_tools

### Commands

| Command                                   | Purpose                                                                                                                                                                    |
|:------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [`:Toggle`](#menus-related-functions)     | Toggles the state of a cyclic option/variable                                                                                                                              |
| `:LoadedBufDo`                            | Like [`:h :bufdo`](http://vimhelp.appspot.com/windows.txt.html#%3abufdo), on loaded buffers                                                                                |
| `:CleanEmptyBuffers`                      | [Wipeout](http://vimhelp.appspot.com/windows.txt.html#%3abw) empty buffers                                                                                                 |
| [`:LHLog`](doc/Log.md)                    | Helper command to choose where logs shall be dumped to                                                                                                                     |
| `Jobs`, `:JobUnpause`, `:StopBGExecution` | Helper commands to keep track of async jobs registered with lh-vim-lib API                                                                                                 |
| `:ConfirmGlobal`                          | Like the [`:g`](http://vimhelp.appspot.com/repeat.txt.html#%3aglobal) command, but with a _confirm_ option as in [`:s`](http://vimhelp.appspot.com/change.txt.html#%3as_c) |
| `:LetIfUndef`                             | Sets the value of an option, only if not set already -- supports `g.foo.bar = 42`                                                                                          |
| `:LetTo`                                  | Sets the value of an option, even if it's already set -- unlike [`:h :let`](http://vimhelp.appspot.com/eval.txt.html#%3alet), supports `g:foo.bar = 42`                    |
| `:Unlet`                                  | [`:unlet`](http://vimhelp.appspot.com/eval.txt.html#%3aunlet) a variable if it doesn't exists -- no side effect unlike `:silent! unlet`                                    |
| `:PushOptions`, `:PopOptions`             | Pushs/pops values into list variables                                                                                                                                      |
| [`:Project`](doc/Project.md)              | Central command for the project feature                                                                                                                                    |

## Python related functions

| Command                           | Purpose                                                                                       |
| :---------------------------------| :---------------------------------------------------------------------------------------------|
| `lh#python#best_still_avail()`    | Returns the best python flavour we can use without imposing a version, unlike `has('python')` |
| `lh#python#has()`                 | Returns `has('python_compiled') || has('python3_compiled')`                                   |
| `lh#python#can_import()`          | Returns whether `:{bestpy} import {modname}` succeeds                                         |
| `lh#python#external_can_import()` | Returns whether `system('python -c "import {modname}")` succeeds                              |

## Installation
  * Requirements: Vim 7.4, Vim 8 for `lh#async` feature.
  * Clone from the git repository

    ```sh
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
    flavor 'LucHermitte/lh-vim-lib'
    ```

  * Vundle/NeoBundle:

    ```vim
    Bundle 'LucHermitte/lh-vim-lib'
    ```

## Credits
  * Luc Hermitte, maintainer
  * Troy Curtis Jr, for portability functions, and many tests/issues he raised
  * Many other I've forgotten :(

## Some other Vim Scripting libraries

### The ones that seem to be still activelly maintained
  * [ingo-library](http://www.vim.org/scripts/script.php?script_id=4433), by
    Ingo Karkat
  * [maktaba](https://github.com/google/vim-maktaba), by google
  * [tlib](http://www.vim.org/scripts/script.php?script_id=1863), by Tom Link
  * [vim-misc](https://github.com/xolox/vim-misc), by Peter Odding
  * [vital](https://github.com/vim-jp/vital.vim), by the Japanese Vim User
    Group

### The other ones
  * [anwolib](http://www.vim.org/scripts/script.php?script_id=3800), by Andy Wokula
  * [cecutil](http://www.vim.org/scripts/script.php?script_id=1066), by Charles
    "DrChip" Campbell
  * [genutils](http://www.vim.org/scripts/script.php?script_id=197), by Hari
    Krishna Dara
  * [l9](http://www.vim.org/scripts/script.php?script_id=3252), by Takeshi NISHIDA
  * [theonevimlib](http://www.vim.org/scripts/script.php?script_id=1963), initiated by Marc Weber
  * [underscore](http://www.vim.org/scripts/script.php?script_id=5149), by
    haya14busa
