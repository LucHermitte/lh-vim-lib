# Introduction
Define new kind of variables: `p:` variables.

The objective is to avoid duplicating a lot of `b:variables` in many buffers.
Instead, all buffers will point to a same global variable associated to the
current project.

# Rationale

Vim support various means to define options.
 * First there are vim options that are use to tune how Vim behaves in various
   situations. They are set with `:set`. Some are global, other are local to
   buffers. In this later case we usually choose their value either on a
   filetype basis, or a project basis.
 * Then there are plugin options. Again, they can be `g:`lobal,
   `b:`uffer-local, or even `w:`indow or `t:`ab local. In lh-vim-lib I've been
   providing `lh#option#get()` to obtain in a simple call the most refined
   value of an option. In lh-dev, I've went a little bit further in order to
   support specialization for buffer and/or filetypes.

Given the objective to have options that are project specific, that works
thanks to plugins like
[local_vimrc](https://github.com/LucHermitte/local_vimrc/) (or similar
techniques). With these plugins, we say a file belongs to a project when it's
located in a directory under the one where a `_vimrc_local` file resides.

In that `_vimrc_local` file, we define project-speficic options as local
options with `:setlocal`, and `b:uffer_local_options`.

That works well I've said. Up to a point: a same options could be duplicated
hundred times: once in each buffer that belongs to a project. As long as we
don't want to change an option this is fine. But as soon as we want to change a
setting we have to change it in every opened buffer belonging to the project.
How often does this need arise? Much to often IMO. In
[BuildToolsWrappers](https://github.com/LucHermitte/BuildToolsWrappers/) , I've
experimented the issue when I wanted to change the current compilation
directory (from _Debug_ to _Release_ for instance). This is just one option,
but it impacts CMake configuration directory, included directory list (for
`.h.in` files), build directory, etc.

Being able to toggle an option between several values, when this is a buffer
local option, quickly becomes a nightmare. This is because we don't have
`p:roject_options`.

So? Let's have them!

# Usage:
 * New project:
   * From anywhere:
     ```vim
     :let prg = lh#project#new({dict-options})
     ```
   * From `local_vimrc`
     ```vim
     :call lh#project#define(s:, {dict-options})
     ```

 * Register a buffer to the project
     ```vim
     " Meant to be used from _vimrc_local file
     :call s:project.register_buffer([bufid])
     ```

 * Propose a value to a project option:
     ```vim
     :LetIfUndef p:foo.bar.team 12
     ```
 * Override the value of a project option (define it if new):
     ```vim
     :Let p:foo.bar.team 42
     ```

 * Set a vim option for all files in a project
     ```vim
     :call prj.set('&isk', '+=µ')
     ```

 * Set an environment variable for all files in a project
     ```vim
     :call prj.set('$FOOBAR', 42)

     " And use it from plugins
     :echo lh#os#system('echo $FOOBAR')
     " The environment variable won't be changed globally, but its value will
     " be injected on-the-fly with lh#os#system(), not w/ system()/make/...
     ```

 * Power user
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

 * Plugins
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

