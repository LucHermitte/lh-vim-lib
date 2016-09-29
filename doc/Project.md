# Introduction
Define new kind of variables: `p:` variables.

The objective is to avoid duplicating a lot of `b:variables` in many buffers.
Instead, all buffers will point to a same global variable associated to the
current project.

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

There are a few use-cases depending you're an end user who want to configure
the plugins you use, or whether you're a plugin maintainer who want to have
project-aware plugins.

## You're a end-user
who want to define the options of your current project.

### New project

First things first, you'll have to tell files when they are opened they belong
to a project.

#### From anywhere (power user)
You can do it from anywhere manually with

```vim
:let prg = lh#project#new({dict-options})
```

#### From your `.lvimrc` or `_vimrc_local.vim`
But I recommend you do it from the project configuration file from a
[local_vimrc](https://github.com/LucHermitte/local_vimrc/) plugin.
This file will be named `.lvimrc` or `_vimrc_local.vim` depending on the plugin
used.

```vim
let s:k_version = 1

" Global definitions executed everytime we enter a file belonging to the project
" This is where we set g:lobal_variables and options for project-unaware plugins.
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
:call lh#project#define(s:, {'some': 'default values'})
```

In the case different independent project configurations may co-exist in a
`_vimrc_local.vim` file, you may need to have several branches, and call
`lh#project#define()` with a third parameter to distinguish the projects. See
[my project configuration for my vim
scripts](http://github.com/LucHermitte/lh-misc/tree/master/_vimrc_local.vim)


Note that `lh#project#define()` will take care of creating a project variable
named `s:project` (default value) (if there was none until now), and it'll make
sure that the current buffer is registered to this project variable.

Another way to process is:
```vim
:Project --define ProjectName
```
which won't set a `s:project` variable. This is most likely the easier way to
define new projects and register buffers to them.

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
" TODO: Show how to fetch prj, or provide :SetInProject
:call prj.set('&isk', '+=µ')
```

We could also simply use `setlocal isk+=µ`. The difference is that with this
new _project_ feature, we register that `&isk` shall contain `'µ'` for all
buffers belonging to the project. This way, when we enter a buffer that belongs
to a project where `&isk` is modified, we'll be sure it'll get modified
dynamically -- TODO: reformuler!


#### Environment variables
 * Set an environment variable for all files in a project
     ```vim
     :call prj.set('$FOOBAR', 42)

     " And use it from plugins
     :echo lh#os#system('echo $FOOBAR')
     " The environment variable won't be changed globally, but its value will
     " be injected on-the-fly with lh#os#system(), not w/ system()/make/...
     ```

### Display various informations

#### List of active projects
(well for now, we cannot deactivate a project)

```vim
Project --list
```

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
   * Register a buffer to the project
     ```vim
     " Meant to be used from _vimrc_local file
     :call s:project.register_buffer([bufid])
     ```

   * Get the current project variable (b:crt_project) or lh#option#undef()
     ```vim
     :let prj = lh#project#crt()
     ```
   * Get a variable under the project
     ```vim
     :let val = lh#project#_get('foo.bar.team')
     ```
   * Get "b:crt_project", or lh#option#undef()
     ```vim
     :let var = lh#project#crt_bufvar_name()
     ```

## You're a plugin maintainer
   * Get a project variable value:
     ```vim
     " Meant to be used by project-aware plugins
     :let val = lh#option#get('b:foo.bar.team')
     ```

   * Define toggable project options
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

   * Execute an external command while some `p:$ENV` variable are defined:
     ```vim
     :echo lh#os#system('echo $FOOBAR')
     ```


# Design choices
# Compatible plugins

Most of my plugins that use `lh#option#get()` are already compatible with this
new feature. However some final tweakings will be required to fully take
advantage of option toggling, `p:$ENV` variables (lh-tags, and
BuildToolsWrappers are the first I've in mind).

