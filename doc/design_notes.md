# Design Notes

----
## Regarding debugging and maintenance
- loops (speed, debug)
- Dbc
- UT
- `:WTF`
- Logs

----
## Regarding OO
I delved into the subject in another document: [Object Oriented Programming in vim scripts](OO.md).


----
## Regarding dependencies

This is an edited copy of an answer I wrote on [vi.SE](https://vi.stackexchange.com/questions/12666/including-utility-libraries-in-a-vim-plugin).

As you likely have noted my plugins have dependencies and lh-vim-lib is the
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
