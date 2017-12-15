# Option management

  * [Introduction](#introduction)
  * [Option API](#option-api)
    * [Design concepts](#design-concepts)
      * [_unset_ state](#_unset_-state)
      * [Variable scopes](#variable-scopes)
      * [Project options](#project-options)
      * [Inherited filetypes](#inherited-filetypes)
      * [Dictionary options](#dictionary-options)
    * [Function list](#function-list)
      * [Vim option API](#vim-option-api)
         * [`lh#option#add({name}, {values...})`](#lhoptionaddname-values)
      * [(filetype independent) option API](#filetype-independent-option-api)
         * [`lh#option#get({name} [,{default} [, {scope}]])`](#lhoptiongetname-default--scope)
         * [`lh#option#get_non_empty({name} [,{default} [, {scope}]])`](#lhoptionget_non_emptyname-default--scope)
         * [`lh#option#get_from_buf({bufid}, {name} [,{default} [, {scope}]])`](#lhoptionget_from_bufbufid-name-default--scope)
         * [`lh#option#getbufvar({buf}, {varname} [,{default}])`](#lhoptiongetbufvarbuf-varname-default)
         * [`lh#option#getbufglobvar({buf}, {varname} [,{default}])`](#lhoptiongetbufglobvarbuf-varname-default)
      * [Filetype-option API](#filetype-option-api)
         * [`lh#ft#option#get({name}, {ft} [, {default} [, {scope}]])`](#lhftoptiongetname-ft--default--scope)
         * [`lh#ft#option#get_postfixed({name}, {ft} [, {default} [, {scope}]])`](#lhftoptionget_postfixedname-ft--default--scope)
         * [`lh#ft#option#get_all({name} [, {ft}])`](#lhftoptionget_allname--ft)
      * [_unset_ state API](#_unset_-state-api)
         * [`lh#option#is_set({expr})`](#lhoptionis_setexpr)
         * [`lh#option#is_unset({expr})`](#lhoptionis_unsetexpr)
         * [`lh#option#unset([{textual context}])`](#lhoptionunsettextual-context)
  * [Note on how options could be set](#notes-on-how-options-could-be-set)
    * [Global options](#global-options)
    * [Local options](#local-options)

## Introduction

There exist two kinds of options in Vim.

#### Vim options
First there are vim options that are used to tune how Vim behaves in various
situations. They are set with
[`:set`](http://vimhelp.appspot.com/options.txt.html#%3aset). Some are global,
other are
[local to buffers](http://vimhelp.appspot.com/options.txt.html#local%2doptions).
In this later case we usually choose their value either on a filetype basis, or
on a project basis.

#### Plugin options
Then there are plugin options.

Most plugins only care for global options. In that case they are plenty happy
with:

```vim
" At the start of the plugin script, to make sure the option exists
let g:my_option = get(g:, 'my_option', somedefaultvalue)
...
" and then everywhere else, when the option is used
call s:use(g:my_option)
```

Alas sometimes, we need to use an option that can be specific to the current
project (and/or to the current filetype). Typical examples are: _"which naming
convention should be applied?"_, _"where the compilation shall happen for the
current project?"_, _"where project specific snippets are stored?"_, and so on.

This means that technically, again, options can be either `g:`lobal, or `b:`uffer-local,
or even `w:`indow-local or `t:`ab-local.

In those later cases, we have no choice but to fetch the option in the last
moment.  Indeed, we cannot store the value of the option when the plugin starts
and expect it to remain valid in a buffer not yet opened.
Instead, first we'd check if there is a window-local option, then a
buffer-local option, then a tab-local option... and eventually a global option.

## Option API

In order to simplify the process of fetching the value of such
not-always-global (plugin) options, lh-vim-lib provides a few helper functions
to plugin authors.

### Design concepts
#### _unset_ state
Sometimes, we need to distinguish when an option is not set, from the case it's
voluntarily set to 0, 42, an empty list, etc.

In order to represent the state _unset_, a special option value can be obtained
(with `lh#option#unset()`), and checked (with `lh#option#is_set()` and
`lh#option#is_unset()`).

Example:

```vim
let opt = lh#option#get('my.option')
if lh#option#is_unset(opt)
    echoerr "Sorry, you need to set the option (bpg):my.option"
endif
```

#### Variable scopes
All the following functions, that permit to fetch an option value, take an
optional parameter: the `{scope}` list that specifies where to search for the
option.

By default, `{scope}` is considered to be `"bpg"`.
This means, that `lh#option#get('my.option')` will search in order for an
option named either `b:my.option`, or `p:my.option`, or at the last resort
`g:my_option`.

This means we can specify the scopes, and the order, in which a variable is
searched.  For instance, If you wish to also check `w:my.option` or
`t:my.option`, then pass for instance `"wbptg"` to the `{scope}` parameter.

**Notes:**
 * In Vim documentation, what I call _scope_ is named
 [_name spaces_](http://vimhelp.appspot.com/eval.txt.html#internal%2dvariables).
 * You need to be aware that lh-vim-lib functions cannot access
 [script-variables](http://vimhelp.appspot.com/eval.txt.html#script%2dvariable).
 * As a personal convention, when I document an option, I prefix its name with
   the list of admissible scopes. IOW, you'll see `(bpg):my.option`, or
   `(wbg):my.other_option`..., in the documentation of my plugins depending of
   the supported scopes.

#### Project options
At this point, you're probably wondering what are those `p:variables` as there
is no such beast in Vim. Indeed. `p:variables` are a personal extension meant
to hold _project-variables_. You'll find a more thorough description of this
feature in the related [help page](Project.md).

#### Inherited filetypes
Some the options available though lh-vim-lib and its _ft-option_ API
(`lh#ft#option#*()`) can be specialized for each filetype. Doing so for every
filetype would quickly become cumbersome when these filetypes have a lot in
common like for instance C and C++. Instead of copying all
`(bpg):c_some.options` into `(bpg):cpp_some.options`, it's more interesting to
say that `(bpg):c_some.options` are valid in C++ contexts.

As a consequence, to simplify options tuning, `lh#ft#option#*()` functions support
filetype inheritance.

By default, C++ option settings inherits C option settings. In future versions,
Java option settings may also inherit C or C++ option settings.

If you want to define new inheritance relations between filetypes, send me an
email so I add it to the default configuration, or do so in your `.vimrc` with

```vim
:let g:{ft3}_inherits = 'ft1,ft2,...'
```

#### Dictionary options
You may have noticed that I use indiscriminately `(bpg):my_option` and
`(bpg):my.options` in my examples. lh-vim-lib option-API makes no difference
between both.

[Dictionary](http://vimhelp.appspot.com/eval.txt.html#Dictionary) options
permit to limit scope pollution. For instance, instead of having
`g:myplugin_option1`, `g:myplugin_option2`..., with `g:myplugin.option1`,
`g:myplugin.option2`... we only see `g:myplugin` in
[`g:`](http://vimhelp.appspot.com/eval.txt.html#g%3a).
That's why a non negligible number of plugins use dictionary options.

Note: lh-vim-lib `:LetIfUndef` and `:LetTo` commands are able to assign
`dict.key.subkey` is one step. (TODO: add link)

### Function list

#### Vim option API
##### `lh#option#add({name}, {values...})`
Adds new values to a vim list-option -- and prevents the values from being listed more than once.

**Example:**

```vim
call lh#option#add('l:tags', '.tags')
" or
call lh#option#add('l:tags', ['.tags'])

" which are equivalent to
setlocal tags+=.tags
```

This function becomes interesting to use variables and avoid more complex code like:

```vim
exe 'setlocal tags+='.fnameescape(some_path.'/tags')
```

#### (filetype independent) option API
##### `lh#option#get({name} [,{default} [, {scope}]])`
Fetches the value of a user defined option, that may be _empty_.

**Parameters:**
 * `{name}` option (root) name
 * `{default}` default value for the option if not found -- default: `lh#option#unset()`
 * [`{scope}`](#variable-scopes) scopes in which the option name shall be searched -- default: `"bpg"`

**See also:**
- `lh#option#get_non_empty()`
- `lh#option#get_from_buf()`
- `lh#ft#option#get()`
- `lh#ft#option#get_postfixed()`
- `lh#ft#option#get_all()`

##### `lh#option#get_non_empty({name} [,{default} [, {scope}]])`
Fetches the value of a user defined option, that is **not** _empty_.

IOW, returns of `b:{name}`, `g:{name}`..., or `{default}` the first which exists and is not empty.

**Parameters:**
 * `{name}` option (root) name
 * `{default}` default value for the option if not found -- default: `lh#option#unset()`
 * [`{scope}`](#variable-scopes) scopes in which the option name shall be searched -- default: `"bpg"`

**See also:**
- `lh#option#get_non_empty()`
- `lh#option#get_from_buf()`

##### `lh#option#get_from_buf({bufid}, {name} [,{default} [, {scope}]])`
Same as `lh#option#get()` except that it works from `{bufid}` context.

**Parameters:**
 * `{bufid}` buffer identifier to use to search for `b:{name}`
 * `{name}` option (root) name
 * `{default}` default value for the option if not found -- default: `lh#option#unset()`
 * [`{scope}`](#variable-scopes) scopes in which the option name shall be searched -- default: `"bpg"`

**See also:**
- `lh#option#get()`
- `lh#option#get_non_empty()`

##### `lh#option#getbufvar({buf}, {varname} [,{default}])`
Encapsulates `getbufvar(buf, varname, lh#option#unset())` when `{default}` is not passed. This provides [`getbufvar()`](http://vimhelp.appspot.com/eval.txt.html#getbufvar%28%29) on older versions of vim.

##### `lh#option#getbufglobvar({buf}, {varname} [,{default}])`
Encapsulates `getbufvar(buf, varname, get(g:, varname, lh#option#unset()))`.

#### Filetype-option API
These functions relate to options that can also be specialised on a filetype
basis.

[Filetype inheritance](#inherited-filetypes) is supported in all these
functions.

##### `lh#ft#option#get({name}, {ft} [, {default} [, {scope}]])`
Fetches the value of a user defined option that can be specialized on a filetype basis

Returns which ever exists first among: `b:{name}_{ft}`, or `p:{name}_{ft}`, or
`g:{name}_{ft}`, or `b:{name}`, or `p:{name}`, or `g:{name}`. `{default}` is
returned if none exists.

**Parameters:**
 * `{name}` option (root) name
 * `{ft}` filetype for which the option name shall be searched -- usual value: `&ft`
 * `{default}` default value for the option if not found -- default: `lh#option#unset()`
 * [`{scope}`](#variable-scopes) scopes in which the option name shall be searched -- default: `"bpg"`

**See also:**
- `lh#option#get()`
- `lh#ft#option#get_postfixed()`
- `lh#ft#option#get_all()`

##### `lh#ft#option#get_postfixed({name}, {ft} [, {default} [, {scope}]])`
Fetches the value of a user defined option that can be specialized on a filetype basis.

This function is similar to `lh#ft#option#get()`. The difference relates to the
option names searched: returns which ever exists first among: `b:{name}_{ft},`
or `g:{name}_{ft}`, or `b:{name}`, or `g:{name}`. `{default}` is returned if
none exists.

**Parameters:**
 * `{name}` option (root) name
 * `{ft}` filetype for which the option name shall be searched -- usual value: `&ft`
 * `{default}` default value for the option if not found -- default: `lh#option#unset()`
 * [`{scope}`](#variable-scopes) scopes in which the option name shall be searched -- default: `"bpg"`

**See also:**
- `lh#ft#option#get()`
- `lh#ft#option#get_all()`

##### `lh#ft#option#get_all({name} [, {ft}])`
Fetches the merged values of a dictionary that can be specialized on a filetype basis.

Unlike `lh#ft#option#get()`, this time, we gather every possible value, but
we keep the most specialized value.
This only works to gather dictionaries scattered in many specialized variables.

Considering that the following variables will be
[dictionaries](http://vimhelp.appspot.com/eval.txt.html#Dictionaries) --
expecting they exists --, this function will merge all their values into one,
keeping the most specialized value when there are.
Possible variable names: `b:{ft}_{name}`, or `p:{ft}_{name}`, or `g:{ft}_{name}`, or
`b:{name}`, or `p:{name}`, or `g:{name}`.

**Parameters:**
 * `{name}` option (root) name
 * `{ft}` filetype for which the option name shall be searched -- default value: `&ft`

**Example:**
```vim
Unlet g:foo
Unlet b:foo
Unlet g:FT_foo
Unlet b:FT_foo
LetTo g:foo.glob        = 'g'
LetTo g:foo.spe_buff    = 'g'
LetTo g:foo.spe_gFT     = 'g'

LetTo g:FT_foo.gFT      = 'gft'
LetTo g:FT_foo.spe_gFT  = 'gft'
LetTo g:FT_foo.spe_bFT  = 'gft'

LetTo b:foo.buff        = 'b'
LetTo b:foo.spe_buff    = 'b'
LetTo b:foo.spe_bFT     = 'b'

LetTo b:FT_foo.bFT      = 'bft'
LetTo b:FT_foo.spe_bFT  = 'bft'

let d = lh#ft#option#get_all('foo', 'FT')
AssertEquals(d.glob,     'g')
AssertEquals(d.buff,     'b')
AssertEquals(d.spe_buff, 'b')
AssertEquals(d.gFT,      'gft')
AssertEquals(d.spe_gFT,  'gft')
AssertEquals(d.bFT,      'bft')
AssertEquals(d.spe_bFT,  'bft')
```

**See also:**
- `lh#ft#option#get()`
- `lh#ft#option#get_all()`

#### _unset_ state API
##### `lh#option#is_set({expr})`
Tells whether the expression is set (i.e. different from `lh#option#unset()`).

##### `lh#option#is_unset({expr})`
Tells whether the expression is not set (i.e. identical to
`lh#option#unset()`).

##### `lh#option#unset([{textual context}])`
Returns an [object](OO.md) that is interpreted as _unset_ by
`lh#option#is_set()` and `lh#option#is_unset()`.

**Parameter:**
* `{textual context}` Optional message that can report more information about the
  nature of the unset option.

**Example:**

```vim
:echo lh#object#to_string(lh#option#unset())
{(unset)}

:echo lh#object#to_string(lh#option#unset('No known extension associated to xxx filetype'))
{(No known extension associated to xxx filetype)}
```

## Notes on how options could be set
So far I haven't addressed the question regarding where options could be set
depending on their scope.

The answer depends on the scope of the option we wish to define.

### Global options
A global option is best initialized in a script that is loaded once. Afterward,
it could be changed globally for every buffer on user actions.

The best place to initialize a variable once is quite certainly the
[`.vimrc`](http://vimhelp.appspot.com/starting.txt.html#%2evimrc).

Sometimes, we use a plugin that uses global variables to tune a behaviour that
should have been project specific. That's for instance the case of
alternate.vim which uses `g:alternateSearchPath` to indicate where to find a
header file given an implementation file and the other way around. That option
should be specific to each project, and yet, it's a global one. In those cases,
we could use the _always loaded_ section of
[local_vimrcs](https://github.com/LucHermitte/local_vimrc) to change the value
of the option every time we enter a different buffer.

That's a classic workaround with plugins which aren't project-aware as they
should have been.

### Local options
When plugins do use options that can be specialized for each buffer (filetype
and/or project specific options), we should not set those options in scripts
which will initialize them in only one single buffer.

Indeed, if you set `b:my.option` in your `.vimrc`, it will be set only for the
buffer opened along with Vim. The option won't be known in buffers
opened/created later. It's the same with
[plugin scripts](http://vimhelp.appspot.com/usr_05.txt.html#plugin).
At best a buffer-related
[autocommand](http://vimhelp.appspot.com/autocmd.txt.html#autocommand) could be
defined in a `.vimrc` or in a plugin script, and that autocommand will
eventually modify/set a buffer-local variable or a buffer-local vim-option.

Local options are thus best initialized from buffer-related autocommands. We
could hard-code these autocommands manually, we could or rely on plugins or on
core features that does this transparently. That is to say:
 * From a [filetype-plugin script](http://vimhelp.appspot.com/usr_43.txt.html#filetype%2dplugin),
 we can initialize local options based on the ... current filetype.
 * From a [local_vimrc](https://github.com/LucHermitte/local_vimrc),
 we can initialize local options based on the ... current directory. The
 semantics we associate to a directory is usually: _"what's within belong to a
 same project"_.
 * From a [`.editorconfig` file given lh-vim-lib hook is used](Project.md#3113-from-your-editorconfig-file),
 we can initialize local options based on the current directory and on the
 current file extension.
 * From an [extended let-modeline](https://github.com/LucHermitte/lh-misc/blob/master/plugin/let-modeline.vim),
 we can define a local variable also -- but as modelines, this doesn't scale
 much.
 * _project_ and _projectionist_ plugins provides other ways to achieve a
   similar result.


And of course, we can change local variables manually. But beware, changing a
buffer-local variable in a buffer won't change its value in other buffers, even
if they are meant to belong to a same project. However, when we change manually
a [`p:`roject variable](Project.md) in a buffer, the change will be replicated
to all other buffers belonging to the same project, whether they are already
opened or they'll be opened later on.

