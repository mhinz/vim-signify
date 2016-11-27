![vim-signify](https://raw.githubusercontent.com/mhinz/vim-signify/master/pictures/signify-logo.png)

---

Signify (or just Sy) is a quite unobtrusive plugin. It uses signs to indicate
added, modified and removed lines based on data of an underlying version control
system.

It's __fast__, __easy to use__ and __well documented__.

---

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

---

_If git is the only version control system you use, I suggest having a look at
[vim-gitgutter](https://github.com/airblade/vim-gitgutter). It provides more
git-specific features that would be unfeasible for Sy, since it only implements
features that work for all supported VCS._

## Installation and Documentation

Use your favorite [plugin
manager](https://github.com/mhinz/vim-galore#managing-plugins), e.g. using
[vim-plug](https://github.com/junegunn/vim-plug):

    Plug 'mhinz/vim-signify'

It works without any configuration, but you might want to look into the
documentation for further customization:

    :h signify

_The single most important option by far is `g:signify_vcs_list`. Please read
`:h g:signify_vcs_list`._

## Demo

![Example:signify in action](https://raw.githubusercontent.com/mhinz/vim-signify/master/pictures/signify-demo.gif)

## Author and Feedback

If you like this plugin, star it! It's a great way of getting feedback. The same
goes for reporting issues or feature requests.

Contact: [Twitter](https://twitter.com/_mhinz_)

Co-maintainer: [@jamessan](https://github.com/jamessan)
