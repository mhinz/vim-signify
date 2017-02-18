![vim-signify](https://raw.githubusercontent.com/mhinz/vim-signify/master/pictures/signify-logo.png)

---

_Signify (or just Sy) uses the sign column to indicate added, modified and
removed lines in a file that is managed by a version control system._

---

- Supports **git**, **mercurial**, **darcs**, **bazaar**, **subversion**,
  **cvs**, **rcs**, **fossil**, **accurev**, **perforce**, **tfs**.
- VCS tools are executed **asynchronously** for Vim 7.4.1967+ or Neovim.
- Mappings for **navigation of hunks** ("blocks of changed lines").
- An **operator that acts on hunks**, e.g. for editing or deleting.
- Optional **line highlighting** for lines with signs.
- **Preserve signs** from other plugins.
- Define lists for **skipping certain filetypes or filenames**.
- Depending on your workflow you can also **disable the plugin by default** and
  **toggle it per buffer** later.
- Great documentation and handsome maintainers!

---

_If git is the only version control system you use, I suggest having a look at
[vim-gitgutter](https://github.com/airblade/vim-gitgutter)._

## Installation

Use your favorite [plugin
manager](https://github.com/mhinz/vim-galore#managing-plugins), e.g. using
[vim-plug](https://github.com/junegunn/vim-plug):

    Plug 'mhinz/vim-signify'

## Documentation

1. Understand how the plugin works by reading this short intro:
   [`:h signify-modus-operandi`](https://github.com/mhinz/vim-signify/blob/master/doc/signify.txt#L52)
1. The single most important option by far: `:h g:signify_vcs_list`

## Demo

![Example:signify in action](https://raw.githubusercontent.com/mhinz/vim-signify/master/pictures/signify-demo.gif)

## Author and Feedback

If you like this plugin, star it! It's a great way of getting feedback. The same
goes for reporting issues or feature requests.

Contact: [Twitter](https://twitter.com/_mhinz_)

Co-maintainer: [@jamessan](https://github.com/jamessan)
