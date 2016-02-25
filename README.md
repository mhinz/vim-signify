![vim-signify](https://raw.githubusercontent.com/mhinz/vim-signify/master/pictures/signify-logo.png)

---

Signify (or just Sy) is a quite unobtrusive plugin. It uses signs to indicate
added, modified and removed lines based on data of an underlying version
control system.

It's __fast__, __easy to use__ and __well documented__.

_NOTE:_ If git is the only version control system you use, I suggest having a
look at [vim-gitgutter](https://github.com/airblade/vim-gitgutter). It provides
more git-specific features that would be unfeasible for Sy, since it only
implements features that work for _all_ supported VCS.

**Features:**

- supports git, mercurial, darcs, bazaar, subversion, cvs, rcs, fossil, accurev,
  perforce, tfs
- quick jumping between blocks of changed lines ("hunks")
- apart from signs there is also optional line highlighting
- preserves signs from other plugins
- you can toggle the plugin per buffer
- good documentation
- skip certain filetypes and filenames
- depending on your usual workflow you can disable it per default and enable on
  demand later
- fully configurable through global variables (options and mappings)

## Installation and Documentation

Use your favorite plugin manager.

Using [vim-plug](https://github.com/junegunn/vim-plug):

    Plug 'mhinz/vim-signify'

It works without any configuration, but you might want to look into the
documentation for further customization:

    :h signify

_NOTE_: The single most important option by far is `g:signify_vcs_list`. Please
read `:h g:signify_vcs_list`.

## Demo

![Example:signify in action](https://raw.githubusercontent.com/mhinz/vim-signify/master/pictures/signify-demo.gif)

## Author and Feedback

If you like my plugins, please star them on Github. It's a great way of getting
feedback. Same goes for issues reports or feature requests.

Contact:
[Mail](mailto:mh.codebro@gmail.com) |
[Twitter](https://twitter.com/_mhinz_) |
[Gitter](https://gitter.im/mhinz/mhinz)

Co-maintainer: [@jamessan](https://github.com/jamessan)

_Get your Vim on!_
