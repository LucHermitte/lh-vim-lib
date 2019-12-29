  * [1. Introduction](#1-introduction)
    * [1.1. What is a project?](#11-what-is-a-project)
    * [1.2. What's a project aware-plugin?](#12-whats-a-project-aware-plugin)
  * [2. Rationale](#2-rationale)
  * [3. Usage:](#3-usage)
    * [3.1. You're an end-user](#31-youre-an-end-user)
      * [3.1.1 and you want to define a new project](#311-and-you-want-to-define-a-new-project)
        * [3.1.1.1 Automagically](#3111-automagically)
        * [3.1.1.2. From your `.lvimrc` or `_vimrc_local.vim`](#3112-from-your-lvimrc-or-_vimrc_localvim)
        * [3.1.1.3. From your `.editorconfig` file.](#3113-from-your-editorconfig-file)
      * [3.1.2. Auto-detect the project root path](#312-auto-detect-the-project-root-path)
      * [3.1.3. Default value for project options](#313-default-value-for-project-options)
      * [3.1.4. Set a project option](#314-set-a-project-option)
        * [Variables](#variables)
        * [vim options](#vim-options)
        * [Environment variables](#environment-variables)
      * [3.1.5. A more complete configuration example will be:](#315-a-more-complete-configuration-example-will-be)
      * [3.1.6. Display various information](#316-display-various-information)
        * [List of active projects](#list-of-active-projects)
        * [List project(s) associated to a buffer](#list-projects-associated-to-a-buffer)
        * [List buffers associated to a project](#list-buffers-associated-to-a-project)
        * [Echo a variable associated to a project](#echo-a-variable-associated-to-a-project)
        * [Execute a command in any window associated to a project](#execute-a-command-in-any-window-associated-to-a-project)
        * [Execute a command in all opened windows associated a project](#execute-a-command-in-all-opened-windows-associated-a-project)
        * [Execute a command in all buffers associated a project](#execute-a-command-in-all-buffers-associated-a-project)
        * [Remove a project from the list of known project](#remove-a-project-from-the-list-of-known-project)
    * [3.2. Power User](#32-power-user)
      * [3.2.1. Create a project from `_vimrc_local.vim`, and keep a reference to the project variable](#321-create-a-project-from-_vimrc_localvim-and-keep-a-reference-to-the-project-variable)
      * [3.2.2. Create a new project, from anywhere](#322-create-a-new-project-from-anywhere)
      * [3.2.3. Fetch the current project](#323-fetch-the-current-project)
      * [3.2.4. Fetch the name of the current project variable](#324-fetch-the-name-of-the-current-project-variable)
      * [3.2.5. Fetch the name under which an option is stored](#325-fetch-the-name-under-which-an-option-is-stored)
      * [3.2.6. Register a buffer to the project](#326-register-a-buffer-to-the-project)
      * [3.2.7. Get a variable under the project](#327-get-a-variable-under-the-project)
      * [3.2.8. Set a variable in a precise project...](#328-set-a-variable-in-a-precise-project)
        * [...through project references](#through-project-references)
        * [...through `:Project :let`](#through-project-let)
        * [...through `:LetTo`](#through-letto)
    * [3.3. You're a plugin maintainer](#33-youre-a-plugin-maintainer)
      * [3.3.1. Get a project variable value:](#331-get-a-project-variable-value)
      * [3.3.2. Define toggable project options](#332-define-toggable-project-options)
      * [3.3.3. Execute an external command while some `p:$ENV` variable are defined:](#333-execute-an-external-command-while-some-penv-variable-are-defined)
      * [3.3.4 Define menu entries in `&Project` top-menu](#334-define-menu-entries-in-project-top-menu)
  * [4. Design choices](#4-design-choices)
    * [Regarding project file inventory](#regarding-project-file-inventory)
    * [Regarding tabs](#regarding-tabs)
    * [Regarding environment variables](#regarding-environment-variables)
    * [Miscellaneous stuff](#miscellaneous-stuff)
  * [5. Compatible plugins](#5-compatible-plugins)
  * [6. TO DO list](#6-to-do-list)

# 1. Introduction
This extension defines new kind of variables: `p:` variables.

The objective is to avoid duplicating a lot of `b:variables` in many buffers.
Instead, all those buffers will point to a same global variable associated to
the current project.

This variable will hold a single instance for each pair _variable_:_value_.

This means that modifying a `p:variable` in a buffer will also modify its state
in all the buffers belonging to the same project.

## 1.1. What is a project?

Given a set of files in a same directory, each file can be the unique file of a
project -- I always have a `tests/` directory where I host pet projects, or
where I test the behaviour of the compiler. I call those: _monofile projects_.
On the opposite, the files from a directory hierarchy can be part of a same and
very big project. We may even imagine subprojects within a hierarchy.

In the end, what really defines a programming project is a (root) "makefile" --
and BTW, why restrict ourselves to makefiles, what about scons, autotools, ant,
(b)jam, Rakefile? Also, Sun-Makefiles or GNU-Makefiles?
Other projects will be recognized by the `.git/` directory at their root, and
they won't have anything to do with programming.

It's important to notice that what distinguishes two projects is not the type
of their files. Having a configuration for C++ projects and another for Java
projects is not enough. For instance, I'm often working simultaneously on
several C++ projects with very different sets of options, starting with the
compilation options. And more and more I have multi-languages projects (like
C++ and Python).

## 1.2. What's a project aware-plugin?
So, what' the point? What can we do with those _projects_?

We can do many things actually. For instance, each project can have:

 - specific compilation instructions (build directory, build mode) ;
 - different indentation setting ;
 - different naming policies ;
 - different root directory for sources ;
 - different JSON compilation database ;
 - specialized snippets and templates ;
 - a singular way to distribute C header and sources files ;
 - specific ctags build options, starting with the output tag files.

To take advantage of this, when a plugin fetches an option that tunes its
behaviour, it needs to fetch options with a finer granularity than global
options, when available.

The finest possible option for a given buffer would be first a `b:`uffer local
variable, then a `p:`roject local variable, a `t:`ab local variable, to finish
with default settings in `g:`lobal variables. That's where
[`lh#option#get()`](Options.md#lhoptiongetname-default--scope) comes into play.

# 2. Rationale

Vim supports various means to define options.
 * First there are vim options that are used to tune how Vim behaves in various
   situations. They are set with
   [`:set`](http://vimhelp.appspot.com/options.txt.html#%3aset). Some are
   global, other are
   [local to buffers](http://vimhelp.appspot.com/options.txt.html#local%2doptions).
   In this later case we usually choose their value either on a filetype basis,
   or a project basis.
 * Then there are plugin options. Again, they can be `g:`lobal,
   `b:`uffer-local, or even `w:`indow or `t:`ab local. In lh-vim-lib I provide
   [`lh#option#get()`](Options.md#lhoptiongetname-default--scope) to obtain in
   a simple call the most specialized value of an option.
   I even went a little bit further in order to support
   [specialization for buffer and/or filetypes](Options.md#filetype-independent-option-api).

Given the objective to have options that are project specific, it's quite easy
to achieve it thanks to plugins like
[local_vimrc](https://github.com/LucHermitte/local_vimrc/), or similar
techniques. With these plugins, we say a file belongs to a project when it's
located in a directory under the one where a `_vimrc_local` file resides.

In that `_vimrc_local` file, we define project-specific options as local
options with `:setlocal`, and `b:uffer_local_options`.

That works well I've said. Up to a point: a same option could be duplicated
hundred times: once in each buffer that belongs to a project. As long as we
don't want to change an option this is fine. But as soon as we want to change a
setting we have to change it in every opened buffer belonging to the project.
This is tedious to do correctly: we must have a way to find all buffers that
share the same variable. Should we maintain a list of buffers, or jump in every
buffer (and trigger too many unrequired autocommands if done incorrectly), or
should we check buffer pathnames against a pattern...?

How often does this need arise? Much to often IMO. In
[BuildToolsWrapper](https://github.com/LucHermitte/vim-build-tools-wrapper/),
I've experimented the issue when I wanted to change the current compilation
directory (from _Debug_ to _Release_ for instance). This is just one option,
but it impacts CMake configuration directory, included directory list (for
`.h.in` files), build directory, compilation database, etc.

Being able to toggle an option between several values, when this is a buffer
local option, quickly becomes a nightmare. This is because we don't have
`p:roject_options`.

So? Let's have them then!

# 3. Usage:

There are a few use-cases depending on whether you're an end-user who wants to
configure the plugins you use, or whether you're a plugin maintainer who wants
to have project-aware plugins.

## 3.1. You're an end-user
...who wants to define the options of your current project.

Discl.: Of course, if the plugins you use don't take advantage of this library, it
won't help you much. At best, it'll you help organize buffers into projects and
provide an automated way to change the current directory to point to project
root directory.

### 3.1.1 and you want to define a new project

First things first, when files are opened, you'll have to tell them that they
belong to a project.

#### 3.1.1.1 Automagically
Most project detections may be done implicitly. The conditions to detect all
the files from a directory hierarchy as part of a same project are:

 * At the root, there is a directory typical of a versioning system, i.e. a
   `.svn/`, `.git/`, `.hg/`, `_darcs/`, or `.bzr/` directory (See `:h
   g:lh#project.root_patterns`);
 * You have to set in your `.vimrc`:

     ```vim
     LetTo g:lh#project.auto_detect = 1
     " or
     let g:lh#project = { 'auto_detect' : 1 }
     ```

From there, the project name will be built automatically.

This approach is perfect for projects under source control, when we don't need
to force the project root directory, nor to factorize some settings between
several subprojects (one per program sub-component for instance).

If you need more control, or if you don't want to activate this automagic
feature, use one of the approaches described next.

Note: You'll want to read the documentation about blacklists and so on:
`:h g:lh#project.permissions`.

#### 3.1.1.2. From your `.lvimrc` or `_vimrc_local.vim`
If you don't want to automagically detect projects, or if you need more control
to do so, I recommend you to define new projects from the project configuration
file of a [local_vimrc](https://github.com/LucHermitte/local_vimrc/) plugin.
This file will be named `.lvimrc` or `_vimrc_local.vim` depending on the actual
plugin used.

```vim
:Project --define ProjectName
```

Note that this also could be done by hand -- see power-user approaches below.

#### 3.1.1.3. From your `.editorconfig` file.
[EditorConfig project](http://editorconfig.org/) aims a rationalizing and
factorizing project configuration among multiple IDEs.

While all the _project_ settings provided by this lh-vim-lib feature cannot be
used from other IDEs, you may still be interested at maintaining only one
file, instead of one file for a local vimrc plugin, and one file for
EditorConfig.

In that `.editorconfig` file, you'll have options shared among several IDEs,
and _project_ options.

In order to use EditorConfig, I expect you have properly installed
[EditorConfig-vim](https://github.com/editorconfig/editorconfig-vim), and
registered it in your plugin manager.

Then, you'll be able to maintain an `.editorconfig` file at the root of a
project.  From there, you'll be able to define a _lh-vim-lib project_, and to
set options through `:LetTo` and `:LetIfUndef`, but with another (!) dedicated
syntax.

```dosini
[*]
# Define a new project, as with "Project --define Name"
p#name = My Project Name

# Set p:foo.bar to 42, as with ":LetTo"
p!foo.bar = 42

# Idem, as with "LetTo --overwrite" for nested projects, see below
p!overwrite!foo.bar2 = 12

# Idem, as with "LetTo --hide" for nested projects, see below
p!hide!foo.bar3 = 12

# Set p:foo.str to 'some string', if it wasn't defined, as with ":LetIfUndef"
# Don't forget the quotes around the string expression
p?foo.str = 'some string'
```

Note that the global-, buffer-, window- and tab- scopes are also supported.

See also:
- [3.1.1.1 (You're an end-user and you want to define a new project) Automagically](#3111-automagically)
- [3.1.3. (You're an end-user and you want to) Set a default value for project options](#313-default-value-for-project-options)
- [3.1.4. (You're an end-user and you want to) Set a project option](#314-set-a-project-option)
- [3.2.8. (Set a variable in a precise project) through `:LetTo`](#328-set-a-variable-in-a-precise-project)

**Warnings**: Because of editorconfig(-vim?) way of doing things:
- environment variables will be changed to lowercase. This means, that
  `p!$FOO = 42` won't assign 42 to `p:$FOO` but to `p:$foo`. I've used another
  trick to say: this is uppercase stuff: double the dollars as in `p:$$FoO` to
  design the environment variable `p:FOO`. At, there is no way to use `$FoO`.
- this is the same with other variables, there is no way to support mixed
  capitalization like CamelCase.
- we have no control over the evaluation order of the variables. IOW, don't try

    ```dosini
    g!dependency = 42
    g!variable = g:dependency *  2
    ```

    EditorConfig cannot hold computations as complex as the ones we can realize
    in local vimrcs. You may have to use both approaches in your projects.

### 3.1.2. Auto-detect the project root path
On a project definition, we can automatically deduce the current project root
directory. This directory will then be used by other plugins like
[lh-tags](http://github.com/LucHermitte/lh-tags),
[mu-template](http://github.com/LucHermitte/mu-template), and
[BuildToolsWrapper](http://github.com/LucHermitte/vim-build-tools-wrapper).
It'll also be used to automatically change the current local directory
([`:h :lcd`](http://vimhelp.appspot.com/editing.txt.html#%3alcd)) to the
`paths.sources` dirname from the current project (iff `g:lh#project.auto_chdir`
is true).

The detection policy will depend on the value of
`g:lh#project.auto_discover_root`:

 - 1, `'yes'`: We'll always try to automatically find a project root directory.
 - 0, `'no'`: We'll never try to automatically find a project root directory.
 - `'in_doubt_ask'`: Ask the end-user whether the file current path is what
   must be used.
 - `'in_doubt_ignore`: Don't do anything in doubt.
 - `'in_doubt_improvise`: Uses the file current path a project root.

By default, we reuse `p:paths.sources`. Then, we check whether a parent
directory contains a [directory related to a versioning system](#3111-automagically)
(i.e.  `.git/`, `.svn/`...) to use it as root directory. Then we check among
the current list of dirnames used as project root directories to see whether there
is one that matches the pathname of the current file. Then, in doubt, we may
ask the user to fill in this dirname.


This could also be overridden from `lh#project#define()` and `lh#project#new()`
TODO: Example.

The current project path can also be changed dynamically with:
```vim
:Project :cd dirname
:Project ProjectName :cd dirname
" or to restore it back to p:paths.sources:
:Project ProjectName :cd !
```

### 3.1.3. Default value for project options
In order to propose a default value to a project option:
```vim
:LetIfUndef p:foo.bar.team 12
:LetIfUndef p:foo.bar.team = 12
```

### 3.1.4. Set a project option

#### Variables
We can override the value of a project option (or define it if it's a new one):

```vim
:LetTo p:foo.bar.team 42
:LetTo p:foo.bar.team = 42
```

#### vim options
We can set a vim option for all files in a project
```vim
" Both syntaxes are supported
" - the one that works as well with environment variables
:LetTo p:&isk+=µ
" - the one that follows local standard options
:LetTo &p:isk+=µ
```

We could also simply use `setlocal isk+=µ`. The difference is that with `:Let
p:&isk`, we register that `&isk` shall contain `'µ'` for all buffers belonging
to the project.

This way, when we enter a buffer that belongs to a project where `&isk` is
modified, we'll be sure it'll get modified dynamically, without having to
change a project configuration file.

#### Environment variables
We can set an environment variable for all buffers in a project

```vim
:LetTo p:$FOOBAR = 42

" And use it from plugins
:echo lh#os#system('echo $FOOBAR')
```

The environment variable won't be changed globally, but its value will be
injected on-the-fly with `lh#os#system()`, not w/ `system()` nor `:make`...
Yet,
[BuildToolsWrapper](https://github.com/LucHermitte/vim-build-tools-wrapper)
uses it both in background and in foreground compilations.

### 3.1.5. A more complete configuration example will be:
```vim
" File: _vimrc_local.vim
let s:k_version = 1

" Global definitions executed everytime we enter a file belonging to the project
" This is where we set g:lobal_variables and options for project-unaware plugins.
    let g:foobar = whatever
    ....

" Then the anti-reinclusion guards for buffer definitions
if &cp || (exists("b:loaded__my_foobar_project_settings")
      \ && (b:loaded__my_foobar_project_settings > s:k_version)
      \ && !exists('g:force_reload__my_foobar_project_settings'))
  finish
endif
let b:loaded__my_foobar_project_settings = s:k_version
let s:cpo_save=&cpo
set cpo&vim

" HERE, we say the current buffer belongs to a project
    :Project --define ProjectName

" and then, we'll define project options like for instance
    " Be sure tags are automatically updated on the current file
    LetIfUndef p:tags_options.no_auto 0
    " Declare the indexed filetypes
    call lh#tags#add_indexed_ft('vim')
    LetIfUndef p:tags_options.flags ' --exclude="flavors/*" --exclude="bundle/*"'
    ...
```

Here are also a few examples of `_vimrc_local`:

 * [my project configuration for my vim scripts](http://github.com/LucHermitte/lh-misc/tree/master/_vimrc_local.vim)
 * _more to come..._

### 3.1.6. Display various information

#### List of active projects

```vim
Project --list
```

#### List project(s) associated to a buffer
```vim
Project --which
```

This'll display the projects the current buffer belongs to, directly and
indirectly through project inheritance.

#### List buffers associated to a project

```vim
Project ProjectName ls
Project ProjectName :ls
```

It'll display the same information as `:ls`, but restricted to the
project specified.

```vim
Project :ls
```

This time, it'll display the buffers associated to the current project (i.e.
the project the current buffer belongs to).


#### Echo a variable associated to a project
```vim
Project ProjectName :echo varname
Project ProjectName echo varname

" Or for the current project only
Project :echo varname
```

#### Execute a command in any window associated to a project
```vim
Project ProjectName :doonce echo bufname('%')

" Or for the current project only
Project :doonce echo bufname('%')
```

The best way to execute `:make` on a project (different from the current) is
with this subcommand. This way, it makes sure all variables related to the
project are correctly set when compiling.

```vim
Project ProjectName :doonce make %<
```

Note that `:Project :doonce command` is strictly equivalent to `:command` and
doesn't really make any sense.

#### Execute a command in all opened windows associated a project
```vim
Project ProjectName :windo echo bufname('%')

" Or for the current project only
Project :windo echo bufname('%')
```

#### Execute a command in all buffers associated a project
```vim
Project ProjectName :bufdo echo bufname('%')

" Or for the current project only
Project :bufdo echo bufname('%')
```

#### Remove a project from the list of known project
```vim
Project ProjectName :bd
" or
Project ProjectName :bw
```

This will apply [`:bd`](http://vimhelp.appspot.com/windows.txt.html#%3abd), or
[`:bw`](http://vimhelp.appspot.com/windows.txt.html#%3abw) on all buffers
associated to the specified project, and remove the project and its subprojects
from the list of all known projects.

Note: the variant `:Project :bd` is purposely not implemented.

## 3.2. Power User

Here are a few other use cases and alternative ways of doing things in case you
need more control over _project_ options.

### 3.2.1. Create a project from `_vimrc_local.vim`, and keep a reference to the project variable
Instead of using
```vim
:Project --define ProjectName
```

We can use:
```vim
:call lh#project#define(s:, {'some': 'default values', 'name' :'ProjectName'})

" or simply:
:call lh#project#define(s:, {'some': 'default values'})
" and let a default name be generated.
```

`lh#project#define()` will take care of creating a project variable named
`s:project` (default value) (if there was none until now), and it'll make
sure that the current buffer is registered to this project variable.

`:Project --define` won't set a `s:project` variable. This is most likely the
easier way to define new projects and register buffers to them. Moreover, this
command requires the user to specify a name to the project. On the other hand,
the function will provide a default generated name if none has been provided.

In the case different independent project configurations may co-exist in a
`_vimrc_local.vim` file, you may need to have several branches, and call
`lh#project#define()` with a third parameter to distinguish the projects. This
will permit to store project information in a variable with a name which is not
`s:project`. See the
[`_local_vimrc` file](https://github.com/LucHermitte/lh-misc/blob/master/_vimrc_local.vim)
I drop at the root of my `$HOME/.vim/` directory.

### 3.2.2. Create a new project, from anywhere
You can do it from anywhere manually with

```vim
:let prj = lh#project#new({dict-options})
```

Beware, the current buffer will be registered to this project.

### 3.2.3. Fetch the current project
```vim
:let prj = lh#project#crt()
```
In case there is no project associated to the current buffer,
[`lh#option#unset()`](Options.md#lhoptionis_unsetexpr) will be returned.

### 3.2.4. Fetch the name of the current project variable
This name is the name of the buffer-local variable used to store the project
configuration associated the current buffer.

```vim
:let prj_varname = lh#project#crt_bufvar_name()
```
In case there is no project associated to the current buffer,
an exception will be thrown.

This will most likely return `"b:crt_project"`, the exact name depends on
`g:lh#project#varname` global variable which can be overridden in your `.vimrc`
once and for all.

### 3.2.5. Fetch the name under which an option is stored
```
:let varname = lh#project#crt_var_name('&isk')
:let varname = lh#project#crt_var_name('$PATH')
:let varname = lh#project#crt_var_name('foobar')
```
This internal function is used by `lh#let#*` functions.

### 3.2.6. Register a buffer to the project
```vim
:call s:project.register_buffer([bufid])
```

### 3.2.7. Get a variable under the project
```vim
:let val = lh#project#_get('foo.bar.team')
```

### 3.2.8. Set a variable in a precise project...
When a buffer belongs to several projects, we'll want to select which inherited
project get the settings.

Two approaches are possibles:

#### ...through project references

You may obtain a reference to the project you're interested in (hint: use
`lh#project#define()` to obtain references, or `lh#project#crt()`, or
`lh#project#list#_get()`), then set the variables to what you wish with
`set()` method:

```vim
" Vim option, with a project scope
:call prj.set('&isk', '+=µ')

" Environment variable, with a project scope
:call prj.set('$FOOBAR', 42)

" Set p:foo.bar in the current project
let crt_prj  = lh#project#crt()
:call crt_prj.set('foo.bar', 42)
" or in its first parents
:call crt_prj.parents[0].set('foo.bar', 43)

" Or in a named project
let foo_prj  = lh#project#list#_get('FooProject')
:call foo_prj.set('foo.bar', 12)
```

#### ...through `:Project :let`
You could also specify the target project with `:Project` first argument:

```vim
" In the current project
:Project :let foo.bar = 42

" Or in a named project
:Project FooProject :let foo.bar = 12
```

#### ...through `:LetTo`
`:LetTo` (and `lh#let#to()`) has two special options that permits to select the
target project of the current buffer.

```vim
" Set p:foo.bar at current project level
LetTo --hide      p:foo.bar = 42

" Replace any previous definition of `p:foo.bar` in parent projects with the
" new one, if there was one.
" Or define the value in the current project namespace if it didn't exist.
LetTo --overwrite p:foo.bar = 43
```

## 3.3. You're a plugin maintainer
and you want your plugins to be project-aware:

### 3.3.1. Get a project variable value:
```vim
:let val = lh#option#get('foo.bar.team')
```

Note, in order to know whether the option is set, use
[`lh#option#set(val)`](Options.md#lhoptionis_setexpr) or
[`lh#option#unset(val)`](Options.md#lhoptionis_unsetexpr). When not, you'll may
prefer to print its value either with lh-vim-lib logging framework

```vim
:echo lh#fmt#printf("%1", val)
```

or with

```vim
:echo lh#object#to_string(lh#option#get('foo.bar.team'))
```

which will print: `{(unknown option: (bpg):foo.bar.team)}`, instead of the
unreadable `{'_to_string': function('<SNR>43_unset_to_string'), '__lhvl_oo_type': function('<SNR>45_lhvl_oo_type'), '__lhvl_unset_type': function('<SNR>43_unset_type'), '__msg': 'unknown option: (bpg):foo.bar.team'}`.

### 3.3.2. Define toggable project options
```vim
" Define a global variable, g:bar, that can be toggled
let Data = {
      \ "variable": "bar",
      \ "idx_crt_value": 1,
      \ "values": [ 'a', 'b', 'c', 'd' ],
      \ "menu": { "priority": '42.50.10', "name": '&LH-Tests.&TogMenu.&bar'}
      \}
call lh#menu#def_toggle_item(Data)

" Define a project variable, p:bar, that can be toggled,
" and that has a default value coming from the global variable
let p1 = lh#project#new({'name': 'Menu'})
let pData = {
    \ "variable": "p:bar",
    \ "idx_crt_value": 1,
    \ "values": [lh#ref#bind('g:bar')] + g:Data.values,
    \ "texts": ['default'] + g:Data.values,
    \ "menu": { "priority": '42.50.11', "name": '&LH-Tests.&TogMenu.&Project Foo p:bar'}
    \}
Assert! lh#ref#is_bound(pData.values[0])
call lh#menu#def_toggle_item(pData)

" And the end-user will be able to execute
Toggle LHTestsTogMenuProjectFoopbar
" or to toggle the option with the menus
" to toggle the p:bar variable,

" and to execute
Toggle LHTestsTogMenubar
" to toggle the g:bar variable
```

**Beware**, toggling `p:bar` with `:Toggle` can be done anywhere, but it'll
only apply to the option from one specific project!

### 3.3.3. Execute an external command while some `p:$ENV` variable are defined:
```vim
:echo lh#os#system('echo $FOOBAR')
```

### 3.3.4 Define menu entries in `&Project` top-menu
You can use for this:

 * `lh#project#menu#def_toggle_itme()`
 * `lh#project#menu#make()`
 * `lh#project#menu#remove()`

These functions will execute the `lh#menu#...` equivalent functions from
lh-vim-lib, in `g:lh#project#menu` context. This dictionary can be overridden in
a `.vimrc` and it contains by default: `{'name': '&Project.', 'priority': '50.'}`.

# 4. Design choices

## Regarding project file inventory
I don't see any point in explicitly listing every file that belongs to a
project in order to have vim know them. IMO, they are best globed.  The
venerable known project.vim plugin already does the job. Personally I use a
[local_vimrc](http://github.com/LucHermitte/local_vimrc) plugin.

With this plugin, I just have to drop a `_vimrc_local.vim` file in a directory,
and what is defined in it (`:mappings`, `:functions`, variables, `:commands`,
`:settings`, ...) will apply to each file under the directory -- I work on a
big project having a dozen of subcomponents, each component live in its own
directory, has its own makefile (not even named Makefile, nor with a name of
the directory)

## Regarding tabs
We could have said that every thing that is loaded in a tab belongs to a same
project. Alas, this is not always true. Often I open, in the current tab, files
that belong to different projects. My typical use case is when I split-open a
C++ header file (or even sometimes an implementation file) from a third party
library in order to see how it's meant to be used. When I do that, I want the
third-party code side by side with the code I'm working on. With tabs, this
isn't "possible".

## Regarding environment variables

Until Vim 8.0.1832, [we could not unset environment variables](https://github.com/vim/vim/issues/1116).
As a consequence, I've preferred setting them on-the-fly and locally only when
we need to use them.

## Miscellaneous stuff

 * `lh#project#root()` doesn't fill `p:paths.sources,` but returns a value.
   It's up to `lh#project#new()` to fill `p:paths.sources` from
   `lh#project#root()` result.

# 5. Compatible plugins

Most of my plugins, as they use
[`lh#ft#option#get()`](Options.md#lhftoptiongetname-ft--default--scope), are already
compatible with this new _project_ feature. However some final tweaking will be
required to fully take advantage of option toggling, `p:$ENV` variables
([lh-tags](http://github.com/LucHermitte/lh-tags),
[lh-dev](http://github.com/LucHermitte/lh-dev)
, and
[BuildToolsWrapper](http://github.com/LucHermitte/vim-build-tools-wrapper) are
the firsts I've in mind).

# 6. TO DO list

 * Doc
   * `lh#project#_best_varname_match()`
 * Use in plugins:
   * `p:$ENV variables`
      * [X] lh-tags synchronous (via lh#os#system)
      * [X] lh-tags asynchronous (via lh#async)
      * [X] BTW synchronous (via lh#os#make)
      * [X] BTW asynchronous (via lh#async)
      * [ ] BTW -> QFImport b:crt_project
      * [ ] lh-dev
      * [X] µTemplate
      * [ ] Test on windows!
   * [ ] Have let-modeline support `p:var`, `p:&opt`, and `p:$env`
 * Set locally vim options on new files
 * Simplify dictionaries
   * -> no 'parents' when there are none!
   * -> merge 'variables', 'env', 'options' in `variables`
 * Fix `find_holder()` to use `update()` code and refactor the later
 * Add VimL Syntax highlight for `LetTo`, `LetIfUndef`, `p:var`
 * Serialize and deserialize options from a file that'll be maintained
   alongside a `_vimrc_local.vim` file.
   Expected Caveats:
   * How to insert a comment near each variable serialized
   * How to computed value at the last moment (e.g. path relative to current
     directory, and have the variable hold an absolute path)
