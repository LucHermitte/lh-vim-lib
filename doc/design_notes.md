# Design Notes

* [Scope](#scope)
* [Regarding debugging and maintenance](#regarding-debugging-and-maintenance)
    * [Debugging](#debugging)
        * [Debugging loops](#debugging-loops)
    * [Code instrumentation (Logs and global variables)](#code-instrumentation-logs-and-global-variables)
        * [Variables](#variables)
        * [Logs](#logs)
    * [Design by Contract](#design-by-contract)
    * [Unit Testing](#unit-testing)
    * [`:WTF`](#wtf)
* [Regarding OO](#regarding-oo)
* [Regarding dependencies](#regarding-dependencies)
    * [1. Standalone plugins](#1-standalone-plugins)
    * [2. Plugins that depend on other plugins](#2-plugins-that-depend-on-other-plugins)
    * [3. Submodules](#3-submodules)
    * [My choice on the subject](#my-choice-on-the-subject)

----
## Scope
TBC
<!---

common stuff used elsewhere but not programming related (lh-dev: analysing
source code), nor tool related (lh-tag, vim-clang, build-tools-wrappers).

I avoid intrusive features (commands, mappings, global functions) (->local_vimrc, lh-brackets, mu-template...), yet there is :Project and a few others

But, given the old: project-specific, `p:` were a natural extension for
`lh#option#get()` - - finding the exact limit is sometimes complex; for instance Copen, Make...

-->

----
## Regarding debugging and maintenance
Softwares have bugs, and neither lh-vim-lib nor my other plugins are exempted.

Various techniques exists, and I'm using them in my plugins. These techniques
have consequences on the code of my plugins, and on features I've ended up
defining in lh-vim-lib.

Let's have a quick tour.

###  Debugging
Vim provides a debugger for its Vim script language. It is started with
[`:h :debug`](http://vimhelp.appspot.com/repeat.txt.html#%3adebug). And from
here we can display expressions with `:echo`,
[`>step`](http://vimhelp.appspot.com/repeat.txt.html#%3estep) into a command,
execute the [`>next`](http://vimhelp.appspot.com/repeat.txt.html#%3enext)
command and do a few more things.

This debugger has the merit to exist, but it's definitively not ergonomic.
Indeed once a debugging session has started we can no longer operate Vim as a
text editor and browse the buffers it would display the rest of the time.
To add a breakpoint, we will have to remember where (or to open the relevant
files in another process).
Vim kernel would need to be rewritten in order to have a non blocking/modal
debug mode.

I'm aware of
[Alberto Fanjul's `vim-breakpts` project](https://github.com/albfan/vim-breakpts)
that tries to work around this limitation (by running two instances of Vim,
IIRC)

#### Debugging loops
Debugging loops is one of the things that annoys me the most when debugging vim
scripts. We have to do `>next` several times, check manually the thing that
changes (_variant_/index/element) at each iteration (as there is no possible
`>watch` because of the design of Vim kernel), and there is no
`>finish-the-loop`, only a `>finish`-the-function.

Of course we could have breakpoints but... I don't want to open the file in
another window to see where it must go. By the way, there are no _conditional
breakpoints_.

As a workaround I avoid loops and instead I try to use
[`map()`](http://vimhelp.appspot.com/eval.txt.html#map%28%29) and
[`filter()`](http://vimhelp.appspot.com/eval.txt.html#filter%28%29) as much as
possible. Even when I'm looking for the first element that matches a predicate
I filter the whole list and... it's not even slower but much faster that
manual loops -- because loops are interpreted while list functions are coded in
C.

BTW, there are also many list-related functions that I miss and thus I emulate
them in lh-vim-lib. Sometimes they are added later in Vim like the recent (as
far as I'm concerned)
[`reduce()`](http://vimhelp.appspot.com/eval.txt.html#reduce%28%29).

### Code instrumentation (Logs and global variables)
One of the oldest alternative approach to debug consist in instrumenting our
source code to observe what happens -- I guess this is even much older than
debuggers.

Two approaches mainly.

#### Variables
We can store
[local-variables](http://vimhelp.appspot.com/eval.txt.html#local%2dvariable)
into [global-variables](http://vimhelp.appspot.com/eval.txt.html#global%2dvariable)

```vim
let g:foobar = foobar
```

This is quite efficient to store complex things like
[lists](http://vimhelp.appspot.com/eval.txt.html#list) or
[dictionaries](http://vimhelp.appspot.com/eval.txt.html#Dictionaries) just
before a crash. It's more complex to follow the code flow with them.

#### Logs
Logs can start with a single
[`:echomsg`](http://vimhelp.appspot.com/eval.txt.html#%3aechomsg). In the past
I was even playing with
[`confirm()`](http://vimhelp.appspot.com/eval.txt.html#confirm%28%29) dialog
box to have the time to read the message.

That does the job. Dr Charles Campbell even defines a `Decho` command to
display logs.

But I needed more.

- I needed first to not spend my time commenting and uncommenting log
  instructions depending on whether I needed them or not. In particular I did
  not want such changes to parasite my commits.
- And I also needed to see where the log was happening, and why not display the
  log in the
  [`quickfix-window`](http://vimhelp.appspot.com/quickfix.txt.html#quickfix%2dwindow)
  it already has everything to navigate between its entries.

Thanks to a (slow) hack I found, I was able to retrieve the current callstack
and thus to display logs in the quickfix window with the exact reference of the
calling line (and even the calling functions!).

The result is my [logging framework](Log.md). Given my needs, the fact that I
don't really need logging levels but just errors that stops, warnings that are
notified, debug logs, and information notification messages, the framework
ended up minimalist. Logs are always logged (in qf-window or loclist-windows,
or as `:messages`), and it's up to each vim files to control whether it logs or
not. As such all my autoload plugin files have the same first lines that help
control their verbosity level. I can activate logs in one file and not the
other. e.g. `:call lh#path#verbose(1)` (or `:Verbose pa<tab>` thanks to a small
miscellaneous plugin I have)

### Design by Contract
There is a lot to say about Designing by Contract, and I've already said a lot,
but [in French, and for C++](https://luchermitte.github.io/blog/2014/05/24/programmation-par-contrat-un-peu-de-theorie/).

To make it short, it's about specifying contracts on functions, classes, points
in the program... And when a contract is not respected this means we have a
design error or a programming error.

Often I write functions and consider they are not meant to be called with
a certain context (parameter state, buffer state...). Because I don't care for
this extra situation, and think it should absolutely never happen. Because it
would be too complex to handle. And so on.

I put a contract on a function, on a line in the program: I assert a given
state and I know that if that state isn't verified, there is, or there will be,
an error. Continuing makes absolutely no sense. At best we can abort. We can
_fail fast_.

My take on the subject is that recovering from errors is hardly possible.
Sometimes this means some internal state is completely corrupted. Sometimes the
only solution we have is to get rid of a buffer (with `:bw`) or even restart
Vim.

So, I prefer to be aggressive with my assertions. I like to fail fast with as
much as context as possible in order to be able to investigate and fix the error.

That's how I ended up defining my [DbC framework](Dbc.md). And thus I use
assertions in my vim scripts in critical places in case I need investigating in
the future.

Or course I could instead throw an exception and investigate its stack with
[`:WTF`](#WTF). But, with exceptions I won't have any access to the full program
state (like local variables). With my assertion framework I have the choice
between ignore-and-continue, abort, and start-the-debugger when an error is
detected.

I reserve exceptions for exceptional but plausible situations. Not for aborting
when a plugin is in a corrupted or unexpected state.


Last thing, DbC assertions are perfect for preconditions but definitively not
the best tools for post-conditions. Unit tests are much better for
post-conditions.

### Unit Testing
I also have my
[own solution for unit-testing](https://github.com/LucHermitte/vim-UT). An old one.

Its primary design goal was to see the assertion failures appear in the
[`quickfix-window`](http://vimhelp.appspot.com/quickfix.txt.html#quickfix%2dwindow),
and also to be able to see the callstack of uncaught exceptions.

A few version back Vim introduced
[assertion functions](http://vimhelp.appspot.com/testing.txt.html#assert%2dfunctions%2ddetails).
Since Vim 8.2.1297 we can also access directly to the callstack.

I'll continue with my framework as it works well, and it answers my first need:
filling the quickfix-window.


### `:WTF`
Thanks to [`:WTF`](Callstack.md#lhexceptionsay_what) I have a nice tool to
analyse error messages and fill the
[`quickfix-window`](http://vimhelp.appspot.com/quickfix.txt.html#quickfix%2dwindow)
with the error call stack.

In fair honesty, this feature is directly inspired from
https://github.com/tweekmonster/exception.vim
I've ported it to lh-vim-lib has I had already the required tools to analyse
the error messages (as they are in the same format as
[`v:throwpoint`](http://vimhelp.appspot.com/eval.txt.html#v%3athrowpoint)).
Beside, I handle i18n issues which the original plugin did not.

Also, as I try to avoid defining too many commands, mappings... in lh-vim-lib,
`:WTF` isn't not defined. It's up to us to bind `lh#exception#say_what()` to
whatever we want in our `.vimrc.`

### Plugin reloading
TBC
<!--
`:Reload`

guards
-->

----
## Regarding OO
I delved into the subject in another document: [Object Oriented Programming in vim scripts](OO.md).


----
## Regarding dependencies

This is an edited copy of an answer I wrote on [vi.SE](https://vi.stackexchange.com/questions/12666/including-utility-libraries-in-a-vim-plugin).

As you likely have noticed my plugins have dependencies, and lh-vim-lib is the
central one they all depend upon.

When we want to reuse a function between unrelated plugins, we have a few
different approaches available.

### 1. Standalone plugins
This is the dominant approach. Code from other plugins is copied.

**pro**:

- The end-user won't have to install several plugins;
- It's the friendliest approach with the plugin managers everybody use;
- We perfectly control the version of the dependency used.

**cons**:

- Maintainability is catastrophic: you won't profit from bug fixes, performance
  improvements, or even added features;
- If you're serious about licences, this could get ugly if we start mixing codes
  with different licences in the same file.

### 2. Plugins that depend on other plugins
Very few plugins follow this approach. End-users have to install the plugins we
depend upon. Dare I say this is the most professional one.

**pro**:

- Maintainability -- it's the exact opposite of the approach 1;
- Copyright: it's easier to depend on plugins with different licences without
  having to use a licence different from the one we would have chosen, or to
  mix licences within a same plugin, or to violate original licences by
  changing it without the initial author knowledge/explicit authorization.

**cons**

- Installing a plugin that depends on others may become very complicated
  without assistance: see [lh-cpp requirements][1] for instance. Without
  [VAM][3] or [vim-flavor][4], this is a nightmare;
- Very few people use plugin managers that understand dependencies => this is a
  nightmare for maintainers to track dependencies (what if a plugin we depend
  upon introduce a new dependency?), and for end-users to know exactly what is
  required by each plugin, and to know when a plugin introduce a new
  dependency...;
- If we depend on a specific version of a plugin, this could get ugly -- see
  the dependencies issues in Ruby or Python world. vim-flavor helps a little
  here.

### 3. Submodules
We could also introduce our dependencies as submodules.

**pro**

- Maintainability and Copyright: as with previous solution, we share something
  that is maintained elsewhere;
- Installation could almost become transparent whatever plugin manager is used
  -- if we ignore the fact the new submodule may not be correctly registered in
  vim
  [`'runtimepath'`](http://vimhelp.appspot.com/options.txt.html#%27runtimepath%27)
  option;
- Specifying the required version would be quite easy.

**cons**

- A same plugin may be installed several times. As Vim provides no way (yet?) to
  isolate plugins we could observe some quirky situations. Just for
  mu-template we would have

      ```
      mu-template/
      +-> lh-vim-lib/
      +-> lh-brackets/
          +-> lh-vim-lib/
      +-> lh-style/
          +-> lh-vim-lib/
          +-> editorconfig-vim/
      ```

    where lh-vim-lib would appear 3 times in `runtimepath`. Hopefully every
    plugin depends on the same version...

### My choice on the subject
I'm maintaining something like almost 20 different plugins. A long time ago
after playing with duplicated functions, I've eventually chosen to define this
plugin library that other plugins depend upon.
This library contains a lot of things. I definitively don't regret to have made
this choice.
Thanks to that I've a efficient solution to debug and log what happens in my
plugins, many list related functions that should have been defined in
Vim, and so on. And I don't maintain it several times, but only once. When I've
added DbC for lh-tags, I've been able to use it immediately in
build-tools-wrappers, where I've introduced new assertions that were available
in lh-tags without having to synchronize any file.

Regarding installation, every time somebody asks about plugin managers, I
explain why I prefer [VAM][3] or [vim-flavor][4]: these tools have understood
the importance of dependencies. Nobody would use a `yum`/`dnf`/`apt-get`/`pip`
that don't handle dependencies, and yet this is what most people do in vim
world. As trendy plugin managers don't understand dependencies, plugins avoid
to have dependencies, as thus plugin managers don't feel the need to support
dependencies, and so on. This is a vicious circle.

For plugin maintainers, the real question is to find the trade-off between the
burden we will impose on our end-users and the burden we are ready to accept to
maintain our plugins.

I've chosen to not repeat myself and to build more complex solutions by
stacking layers of thematic and independent features -- which is far from
being an easy feat.


  [1]: https://github.com/LucHermitte/lh-cpp#installation
  [2]: https://github.com/LucHermitte/lh-vim-lib
  [3]: https://github.com/MarcWeber/vim-addon-manager
  [4]: https://github.com/kana/vim-flavor
