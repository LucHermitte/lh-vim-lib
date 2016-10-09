# Introduction
Define new kind of variables: `p:` variables.

The objective is to avoid duplicating a lot of `b:variables` in many buffers.
Instead, all those buffers will point to a same global variable associated to
the current project.

This variable will hold a single instance of each pair _variable_:_value_.

## What is a project?

Given a set of files in a same directory, each file can be the unique file of a
project -- I always have a tests/ directory where I host pet projects, or where
I test the behaviour of the compiler. I call those: _monofile projects_.
On the opposite, the files from a directory hierarchy can be part of a same and
very big project. We may even imagine subprojects within a hierarchy.

In the end, what really defines a programming project is a (leaf) "makefile" --
And why restrict ourselves to makefiles, what about scons, autotools, ant,
(b)jam, aap? And BTW, Sun-Makefiles or GNU-Makefiles? Other project will be
recognize by the `.git/` directory at their root.

It's important to notice that what distinguishes two projects is not the type
of their files. Having a configuration for C++ projects and another for Java
projects is not enough. For instance, I'm often working simultaneously on
several C++ projects with very set of options, starting with the compilation
options.

## What's a project aware-plugin?
So what' the point? What can we do with those _projects_?

We can do many things actually. For instance:

 - each project can have specific compilation instructions (build directory,
   build mode) ;
 - ctags build options may also differ, starting with the output tag files ;
 - different projects may have different indentation setting ;
 - but also different naming policies ;
 - different root directory for sources ;
 - different JSON compilation database ;

To take advantage of this, when a plugin fetch an option that tunes its
behaviour, it needs to fetch options with a finer granularity than global
options, when available.

The finest possible option for a given buffer would be a `b:`uffer local
variable, then a `p:`roject local variable, a `t:`ab local variable, to finish
with default settings in `g:`lobal variables. That's where `lh#option#get()`
comes into play.

# Rationale

Vim support various means to define options.
 * First there are vim options that are used to tune how Vim behaves in various
   situations. They are set with `:set`. Some are global, other are local to
   buffers. In this later case we usually choose their value either on a
   filetype basis, or a project basis.
 * Then there are plugin options. Again, they can be `g:`lobal,
   `b:`uffer-local, or even `w:`indow or `t:`ab local. In lh-vim-lib I've been
   providing `lh#option#get()` to obtain in a simple call the most refined
   value of an option. In
   [lh-dev](http://github.com/LucHermitte/lh-dev#options-1), I've went a little
   bit further in order to support specialization for buffer and/or filetypes.

Given the objective to have options that are project specific, it's quite easy
to achieve it thanks to plugins like
[local_vimrc](https://github.com/LucHermitte/local_vimrc/) (or similar
techniques). With these plugins, we say a file belongs to a project when it's
located in a directory under the one where a `_vimrc_local` file resides.

In that `_vimrc_local` file, we define project-specific options as local
options with `:setlocal`, and `b:uffer_local_options`.

That works well I've said. Up to a point: a same option could be duplicated
hundred times: once in each buffer that belongs to a project. As long as we
don't want to change an option this is fine. But as soon as we want to change a
setting we have to change it in every opened buffer belonging to the project,
which is tedious to do correctly.

How often does this need arise? Much to often IMO. In
[BuildToolsWrappers](https://github.com/LucHermitte/BuildToolsWrappers/), I've
experimented the issue when I wanted to change the current compilation
directory (from _Debug_ to _Release_ for instance). This is just one option,
but it impacts CMake configuration directory, included directory list (for
`.h.in` files), build directory, etc.

Being able to toggle an option between several values, when this is a buffer
local option, quickly becomes a nightmare. This is because we don't have
`p:roject_options`.

So? Let's have them then!

# Usage:

There are a few use-cases depending you're an end-user who want to configure
the plugins you use, or whether you're a plugin maintainer who want to have
project-aware plugins.

## You're a end-user
who want to define the options of your current project.

NB: Of course, if the plugins you use don't take advantage of this library, it
won't help you much. At best, it'll you help organize buffers into projects.

### and you want to define a new project

First things first, you'll have to tell files when they are opened they belong
to a project.

#### From your `.lvimrc` or `_vimrc_local.vim`
I recommend you define new projects from the project configuration file for a
[local_vimrc](https://github.com/LucHermitte/local_vimrc/) plugin.
This file will be named `.lvimrc` or `_vimrc_local.vim` depending on the actual
plugin used.

```vim
:Project --define ProjectName
```

Note that this also could be done by hand.

### Auto-detect the project root path
On a project definition, we can automatically deduce the current project root
directory. This directory will then be used by other plugins like
[lh-tags](http://github.com/LucHermitte/lh-tags),
[mu-template](http://github.com/LucHermitte/mu-template), and
[BuildToolsWrappers](http://github.com/LucHermitte/BuildToolsWrappers).
It'll also be used to automatically change the current local directory (`:h
:lcd`) to the `paths.sources` dirname from the current project (iff
`g:lh#project.autochdir` is true).

The detection policy will depend on the value of
`g:lh#project.auto_discover_root`:

 - 1, `'yes'`: We'll always try to automatically find a project root directory.
 - 0, `'no'`: We'll never try to automatically find a project root directory.
 - `'in_doubt_ask'`: Ask the end-user whether the file current path is what
   must be used.
 - `'in_doubt_ignore`: Don't do anything in doubt.
 - `'in_doubt_improvise`: Uses the file current path a project root.

By default, we reuse `p:paths.sources`. Then, we check whether a parent
directory contains a directory named `.git/` or `.svn/` to use it a root
directory. Then we check among current list of dirnames used as project root
directories to see whether there is one that matches the pathname of the
current file. Then, in doubt, we may ask to user to fill in this dirname.


This could also be overridden from `lh#project#define()` and `lh#project#new()`
TODO: Example.



### Default value for project options
In order to propose a default value to a project option:
```vim
:LetIfUndef p:foo.bar.team 12
```

### Set a project option

#### Variables
We can override the value of a project option (or define it if it's a new one):

```vim
:LetTo p:foo.bar.team 42
```

#### vim options
We can set a vim option for all files in a project
```vim
:LetTo p:&isk+=µ
```

We could also simply use `setlocal isk+=µ`. The difference is that with `:Let
p:&isk`, we register that `&isk` shall contain `'µ'` for all buffers belonging
to the project.

This way, when we enter a buffer that belongs to a project where `&isk` is
modified, we'll be sure it'll get modified dynamically, without having to
change a project configuration file.

#### Environment variables
We can set an environment variable for all files in a project

```vim
:LetTo p:$FOOBAR = 42

" And use it from plugins
:echo lh#os#system('echo $FOOBAR')
```

The environment variable won't be changed globally, but its value will be
injected on-the-fly with `lh#os#system()`, not w/ `system()`/`:make`/...

### A more complete configuration example will be:
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

### Display various informations

#### List of active projects
(well for now, we cannot deactivate a project)

```vim
Project --list
```

#### List project associated to a buffer
```vim
Project --which
```

This'll present the projects the current buffer belongs to directly and
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
the one the current buffer belongs to).


#### Echo a variable associated to a project
```vim
Project ProjectName :echo varname
Project ProjectName echo varname

" Or for the current project only
Project :echo varname
```

## Power User

Here are a few other use cases and alternative ways of doing things in case you
need more control over _project_ options.

### Create a project from `_vimrc_local.vim`, and keep a reference to the project variable
Instead of using
```vim
:Project --define ProjectName
```

We can use:
```vim
:call lh#project#define(s:, {'some': 'default values', 'name' :'ProjectName'})
" simply:
:call lh#project#define(s:, {'some': 'default values')
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
from `s:project`.

### Create a new project, from anywhere
You can do it from anywhere manually with

```vim
:let prj = lh#project#new({dict-options})
```

Beware, the current buffer will be registered to this project.

### Fetch the current project
```vim
:let prj = lh#project#crt()
```
In case there is no project associated to the current buffer,
`lh#option#unset()` will be returned.

### Fetch a name of the current project variable
```vim
:let prj_varname = lh#project#crt_bufvar_name()
```
In case there is no project associated to the current buffer,
an exception will be thrown.

This will most likely return `b:crt_project`, the exact name depends on
`g:lh#project#varname` global which can be overridden in your `.vimrc`.

### Fetch the name under which an option is stored
```
:let varname = lh#project#crt_var_name('&isk')
:let varname = lh#project#crt_var_name('$PATH')
:let varname = lh#project#crt_var_name('foobar')
```
This internal function is use by `lh#let#*` functions.

### Register a buffer to the project
```vim
:call s:project.register_buffer([bufid])
```

### Get a variable under the project
```vim
:let val = lh#project#_get('foo.bar.team')
```

### Set a variable in a precise project
When a buffer belongs to several projects, it's not easily possible (yet) to
select which inherited project get the settings.

For now, you'll need to obtain the project reference you're interested in
(hint: use `lh#project#define()` to obtain references), then set the variables
to what you which:

```vim
" Vim option, with a project scope
:call prj.set('&isk', '+=µ')

" Environment variable, with a project scope
:call prj.set('$FOOBAR', 42)

```

## You're a plugin maintainer
and you want your plugins to be project-aware:

### Get a project variable value:
```vim
:let val = lh#option#get('b:foo.bar.team')
```

### Define toggable project options
```vim
let p1 = lh#project#new({'name': 'Menu'})
let pData = {
    \ "variable": "p:bar",
    \ "idx_crt_value": 1,
    \ "values": [lh#ref#bind('g:bar')] + g:Data.values,
    \ "texts": ['default'] + g:Data.values,
    \ "menu": { "priority": '42.50.11', "name": '&LH-Tests.&TogMenu.&p:bar'}
    \}
Assert! lh#ref#is_bound(pData.values[0])
call lh#menu#def_toggle_item(pData)

" And the end-user will be able to execute
Toggle LHTestsTogMenupbar
```

### Execute an external command while some `p:$ENV` variable are defined:
```vim
:echo lh#os#system('echo $FOOBAR')
```

# Design choices

## Regarding project file inventory
I don't see any point in explicitly listing every files that belongs to project
in order to have vim know them. IMO, they are best globbed.  The venerable
known project.vim plugin already does the job. Personally I use a
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
isn't possible.

## Miscelleanous stuff

 * `lh#project#root()` shall not fill `p:paths.sources,` but return a value.
   It's up to `lh#project#new()` to fill `p:paths.sources` from
   `lh#project#root()` result.


# Compatible plugins

Most of my plugins that use `lh#option#get()` are already compatible with this
new feature. However some final tweaking will be required to fully take
advantage of option toggling, `p:$ENV` variables (lh-tags, and
BuildToolsWrappers are the first I've in mind).

# TO DO list

 * Doc
 * Have root path be official for BTW and lh-tags
 * `:Unlet p:$ENV`
 * Completion on `:Let*` and `:Unlet` for inherited `p:`variables
 * Toggling:
   * at global level: [a, b, c]
   * at project level: [default value from global VS force [a, b, c]]
 * Have menu priority + menu name in all projects in order to simplify
   toggling definitions
 * Setlocally vim options on new files
 * Have lh-tags, lh-dev, BTW, ... use:
   * `p:$ENV variables`
   * `paths.sources`
 * Be able to control which parent is filled with `lh#let#` functions
     * -> :Project <name> :LetTo var = value
 * `:call prj.set(plain_variable, value)`
 * `:Project <name> do <cmd> ...`
 * `:Project <name> :bw` -> with confirmation!
 * `:Project [<name>] :make`
   -> rely on `:Make` if it exists
 * `:Project [<name>] :cd <path>`
 * Simplify dictionaries -> no `'parents'`,` 'variables'`,` 'env'`, `'options'`
   when there are none!
 * auto projectification of every buffer ?
 * Serialize and deserialize options from a file that'll be maintained
   alongside a `_vimrc_local.vim` file.
   Expected Caveats:
   * How to insert a comment near each variable serialized
   * How to computed value at the last moment (e.g. path relative to current
     directory, and have the variable hold an absolute path)
