vim-signify
-----------

![Example:signify in action](https://github.com/mhinz/vim-signify/raw/master/signify.gif)

by Marco Hinz

Twitter: https://twitter.com/_mhinz_  
IRC: __mhi^__ (Freenode)

If you use any of my plugins, please star them on github. It's a great way of
getting feedback and gives me the kick to put more time into their development.
If you encounter any bugs or have feature requests, just open an issue report on
Github.

Intro
-----

Signify (or just Sy) is a quite unobtrusive plugin. It uses signs to indicate
added, modified and removed lines based on data of an underlying version
control system.

It's __fast__, __easy to use__ and __well documented__.

_NOTE:_ If git is the only version control system you use, I suggest having a
look at [vim-gitgutter](https://github.com/airblade/vim-gitgutter). It provides
more git-specific features that would be unfeasible for Sy, since it only
implements features that work for _all_ supported VCS.

---

Features:

- supports git, mercurial, darcs, bazaar, subversion, cvs, rcs, fossil, accurev,
  perforce
- quick jumping between blocks of changed lines ("hunks")
- apart from signs there is also optional line highlighting
- preserves signs from other plugins
- you can toggle the plugin per buffer
- good documentation
- skip certain filetypes and filenames
- depending on your usual workflow you can disable it per default and enable on
  demand later
- fully configurable through global variables (options and mappings)

Installation & Documentation
----------------------------

If you have no preferred installation method, I suggest using tpope's
[pathogen](https://github.com/tpope/vim-pathogen). Afterwards installing
vim-signify is as easy as pie:

    $ git clone https://github.com/mhinz/vim-signify ~/.vim/bundle/vim-signify

It works without any configuration, but you might want to look into the
documentation for further customization:

    :Helptags  " rebuilding tags files
    :h signify

_NOTE_: The single most important option by far is `g:signify_vcs_list`. Please
read `:h g:signify_vcs_list`.

License
-------

MIT license. Copyright (c) 2015 Marco Hinz.
