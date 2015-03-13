# Introduction

`lh#buffer#dialog` was initially designed to display (in a scratch buffer) a list of things, select (/tag) one or several items, and validate the choice.

The items can be of any kind (function signatures, email addresses, suggested spellings, ...), as well as the validating action.  The help/header can be customized as well as colours, other mappings, ...

However the list displaying + selection aspect is almost hard coded.


# How it Works

Scripts have to call the function
```
lh#buffer#dialog#new(bname, title, where, support_tagging, action, choices)
```
with:
  * `{bname}` being the name the scratch buffer will receive.
  * `{title}` the title that appear at the first line of the scratch buffer. I use it to display the name of the [client scripts](#client-Scripts), its version, and its purpose/what to do
  * `{where}` are `:split` options (like "`bot below`") used to open the scratch buffer
  * `{support_tagging}` is a boolean (0/1) option that permit to select multiple items
  * `{action}` is the name of the callback function (I may support more advanced calling mechanisms latter)
  * `{choices}` is the |List| of exact string to display

The `#new` function builds and returns a dictionary, it also opens and fills the scratch buffer, and put us within its context.

If we want to add other mappings, and set a syntax highlighting for the new buffer, it is done at this point (see the `s:PostInit()` function in my [client scripts](#client-Scripts)).

At this point, I also add all the high level information to the dictionary (for instance, the list of function signatures is nice, but it does not provides enough information (the corresponding file, the command to jump to the definition/declaration, the scope, ...)

The dictionary is filled with different useful information:
  * buffer ids
  * where we was at the time of its creation
  * name of the callback function


The callback function:
  * can't be a script local function.
  * When called, we are still within the scratch buffer context
  * It must accept a |List| of numbers as parameter: the index (+1) of the items selected
  * The number 0, when in the list, means "aborted". In that case, the callback function is expected to call `lh#buffer#dialog#Quit()` that will terminate the scratch buffer (with `:quit`), and jump back to where we were when `#new` was called, and display a little "Abort"  message.
  * We can terminate the dialog with just :quit if we don't need to jump back anywhere. For instance, [lh-tags](http://github.com/LucHermitte/lh-tags) callback function first terminates the dialog, then jumps to the file where the selected tag comes from.
  * It's completely asynchronous: the callback function does not return anything to anyone, but instead applies transformations in other places.
> This aspect is very important. I don't see how this kind of feature can work if not asynchronously in vim.


## Limitations
This script is a little bit experimental (even if it the result of almost 10 years of evolution), and it is a little bit cumbersome.
  * it is defined to support only one callback -- see the hacks in [lh-tags](http://github.com/LucHermitte/lh-tags) to workaround this limitation.
  * it is defined to display list of items, and to select one or several items in the end.
  * and of course, it requires [lh-vim-lib](http://github.com/LucHermitte/lh-vim-lib), but nothing else.

# Client Scripts
  * [lh-tags](http://github.com/LucHermitte/lh-tags)
  * [lh-cpp / :Override](http://github.com/LucHermitte/lh-cpp)
  * [lh-cpp / :UnmatchedFunctions](http://github.com/LucHermitte/lh-cpp)
  * [lh-cpp / :Constructor](http://github.com/LucHermitte/lh-cpp)

### Origins
  * lhVimSpell
  * lh-mail / mutt aliases
