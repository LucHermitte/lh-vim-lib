# Option management



## Rationale

Vim supports various means to define options.
 * First there are vim options that are used to tune how Vim behaves in various
   situations. They are set with
   [`:set`](http://vimhelp.appspot.com/options.txt.html#%3aset). Some are
   global, other are
   [local to buffers](http://vimhelp.appspot.com/options.txt.html#local%2doptions).
   In this later case we usually choose their value either on a filetype basis,
   or a project basis.
 * Then there are plugin options. Again, they can be `g:`lobal,
   `b:`uffer-local, or even `w:`indow or `t:`ab local. Sometimes, they can even
   be specialized for buffers/projects and/or filetypes.

Most plugins only care for global options. In that case they are plenty happy
with:

```vim
" At the start of the plugin script
let g:my_option = get(g:, 'my_option', somedefaultvalue)
...
" and everywhere else
call s:use(g:my_option)
```

Alas sometimes, we need to use an option that can be speficic to the current
project (and/or even to the current filetype). Typical examples are which
naming convention should be applied, where the compilation shall happen for the
current project, where project specific snippets are stored, and so on.

In those cases, we have no choice but to fetch the option at the last moment.
First we check if there is a window local option, then a buffer local option,
then a tab local option... and eventually a global option.

## Option API

lh-vim-lib provides several helper functions to handle options.

### Design concepts
#### _unset_ state
In order to represent the state _unset_, a special option value can be obtained
(`lh#option#unset()`), and checked (with `lh#option#is_set()` and
`lh#option#is_unset()`).

#### Variable scopes
TBC
#### Filetype polymorphism
TBC

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

This function becomes interresting to use variables and avoid stuff like

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

Note: [filetype inheritance](#filetype-polymorphism) is supported.

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
Fetches the merged values of a dictionnary that can be specialized on a filetype basis.

Unlike `lh#ft#option#get()`, this time, we gather every possible value, but
keeping the most specialized value.
This only works to gather dictionaries scatered in many specialized variables.

Considering that the following variables will be
[dictionaries](http://vimhelp.appspot.com/eval.txt.html#Dictionaries) --
expecting they exists --, this function will merge all their values into one,
keeping the most specialized value when there are.
Possible variable names: `b:{ft}_{name}`, or `p:{ft}_{name}`, or `g:{ft}_{name}`, or
`b:{name}`, or `p:{name}`, or `g:{name}`.

Note: [filetype inheritance](#filetype-polymorphism) is supported.

See also:
- `lh#ft#option#get()`

#### `lh#option#get({name} [,{default} [, {scope}]])`
Fetches the value of a user defined option, that may be _empty_.

Parameters:
- `{default}` is returned if the option does not exists. Default value for `{default}` is `g:lh#option#unset`
- `{scope}` specifies which scopes shall be tested. By default, `{scope}`
  values "bpg", with `p` that stands for the [`p:`roject scope](Project.md)

#### `lh#option#get_non_empty()`
Fetches the value of a user defined option, that is not _empty_

IOW, returns of `b:{name}`, `g:{name}`, or `{default}` the first which exists and is not empty

The order of the variables checked can be specified through the optional
argument `{scope}`

#### `lh#option#get_from_buf({bufid}, {name} [...])`
Same as `lh#option#get()` except that it works from {bufid} context

#### `lh#option#getbufvar({buf}, {varname} [,{default}])`
Encapsulates `getbufvar(buf, varname, g:lh#option#unset)` when `{default}` is not passed

#### `lh#option#getbufglobvar({buf}, {varname} [,{default}])`
Encapsulates `getbufvar(buf, varname, get(g:, varname, g:lh#option#unset))`

#### `lh#option#is_set({expr})`
Tells whether the expression is set (i.e. different from `g:lh#option#unset`)

#### `lh#option#is_unset({expr})`
Tells whether the expression is not set (i.e. identical to `g:lh#option#unset`)
