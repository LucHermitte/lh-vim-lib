# Option management

## Rationale

There exist two kinds of options in Vim.

#### Vim options
First there are vim options that are used to tune how Vim behaves in various
situations. They are set with
[`:set`](http://vimhelp.appspot.com/options.txt.html#%3aset). Some are global,
other are
[local to buffers](http://vimhelp.appspot.com/options.txt.html#local%2doptions).
In this later case we usually choose their value either on a filetype basis, or
a project basis.

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
project (and/or to the current filetype). Typical examples are which naming
convention should be applied, where the compilation shall happen for the
current project, where project specific snippets are stored, and so on.

This means that technically, again, options can be `g:`lobal, `b:`uffer-local,
or even `w:`indow or `t:`ab local.

In those cases, we have no choice but to fetch the option at the last moment.
First we check if there is a window local option, then a buffer local option,
then a tab local option... and eventually a global option.



TODO: Sometimes, they can even be specialized for buffers/projects and/or
filetypes.


## Option API

In order to simplify to process of fetching the value of such (plugin) options,
lh-vim-lib provides a few helper functions.

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
All the following functions that permit to fetch an option value, take an
optional parameter: the `{scope}` list that specifies where to search for the
option.

By default, `{scope}` is considered to be `"bpg"`.
This means, that `lh#option#get('my.option')` will search for an option named
either `b:my.option`, `p:my.option`, or `g:my_option`.

If you wish to check `w:my.option` or `t:my.option`, then pass for instance
`"wbptg"` to `{scope}` parameter.


At this point, you're probably wondering what are those `p:variables` as there
is no such beast in Vim. Indeed. `p:variables` are a personal extension meant
to hold _project-variables_. You'll find a more thorough description of this
feature in the related [help page](Project.md).

**Note:** As a personal convention, when I document an option, I prefix its
name with the list of admissible scopes. IOW, you'll see `(bpg):my.option`, or
`(wbg):my.other_option`..., in the documentation of my plugins.

#### Inherited filetypes
All the options available though lh-vim-lib and its API (`lh#ft#*()`) can be
specialized for each filetype. Doing so for every filetype will quickly become
cumbersome when these filetypes have a lot in common like C and C++. To
simplify options tuning, `lh#ft#*()` functions support filetype inheritance.

By default, C++ option settings inherits C option settings. In future versions,
Java option settings may also inherit C or C++ option settings.

If you want to define new inheritance relations between filetypes, send me an
email for me to add to it to the default configuration, or do so in your
`.vimrc` with

```vim
:let `g:{ft}_inherits = 'ft1,ft2,...'`
```

#### Project options
TBC

### Function list

#### `lh#option#add({name}, {values...})`
Adds new values to a vim option -- and avoids the values being listed more than once

Example:

```vim
call lh#option#add('l:tags', '.tags')
" or
call lh#option#add('l:tags', ['.tags'])
" which is equivalent to
setlocal tags+=.tags
```

This function becomes interesting to use variables and avoid stuff like

```vim
exe 'setlocal tags+='.fnameescape(some_path.'/tags')
```

#### `lh#ft#option#get({name}, {ft}[, {default} [, {scope}]] )`
Fetches the value of a user defined option that can be specialized on a filetype basis

Returns which ever exists first among: `b:{name}_{ft}`, or `p:{name}_{ft}`, or
`g:{name}_{ft}`, or `b:{name}`, or `p:{name}`, or `g:{name}`. `{default}` is
returned if none exists.

The order of the scopes for the variables checked can be specified through the
optional argument `{scope}`.

Note: [filetype inheritance](#filetype-inheritance) is supported.

See also:
- `lh#ft#option#get_postfixed()`
- `lh#ft#option#get_all()`

#### `lh#ft#option#get_postfixed({name}, {ft} [, {default} [, {scope}]])`
Fetches the value of a user defined option that can be specialized on a filetype basis.

This function is similar to `lh#ft#option#get()`. The difference relates to the
option names searched: returns which ever exists first among: `b:{name}_{ft},`
or `g:{name}_{ft}`, or `b:{name}`, or `g:{name}`. `{default}` is returned if
none exists.

#### `lh#ft#option#get_all({name} [, {ft}...])`
Fetches the merged values of a dictionary that can be specialized on a filetype basis.

Unlike `lh#ft#option#get()`, this time, we gather every possible value, but
keeping the most specialized value.
This only works to gather dictionaries scattered in many specialized variables.

Considering that the following variables will be
[dictionaries](http://vimhelp.appspot.com/eval.txt.html#Dictionaries) --
expecting they exists --, this function will merge all their values into one,
keeping the most specialized value when there are.
Possible variable names: `b:{ft}_{name}`, or `p:{ft}_{name}`, or `g:{ft}_{name}`, or
`b:{name}`, or `p:{name}`, or `g:{name}`.

Note: [filetype inheritance](#filetype-inheritance) is supported.

See also:
- `lh#ft#option#get()`

#### `lh#option#get({name} [,{default} [, {scope}]])`
Fetches the value of a user defined option, that may be _empty_.

Parameters:
- `{default}` is returned if the option does not exists. Default value for `{default}` is `g:lh#option#unset`
- `{scope}` specifies which scopes shall be tested. By default, `{scope}`
  values `"bpg"`, with `p` that stands for the [`p:`roject scope](Project.md)

#### `lh#option#get_non_empty()`
Fetches the value of a user defined option, that is not _empty_

IOW, returns of `b:{name}`, `g:{name}`, or `{default}` the first which exists and is not empty

The order of the variables checked can be specified through the optional
argument `{scope}`

#### `lh#option#get_from_buf({bufid}, {name} [...])`
Same as `lh#option#get()` except that it works from `{bufid}` context

#### `lh#option#getbufvar({buf}, {varname} [,{default}])`
Encapsulates `getbufvar(buf, varname, g:lh#option#unset)` when `{default}` is not passed

#### `lh#option#getbufglobvar({buf}, {varname} [,{default}])`
Encapsulates `getbufvar(buf, varname, get(g:, varname, g:lh#option#unset))`

#### `lh#option#is_set({expr})`
Tells whether the expression is set (i.e. different from `g:lh#option#unset`)

#### `lh#option#is_unset({expr})`
Tells whether the expression is not set (i.e. identical to `g:lh#option#unset`)
