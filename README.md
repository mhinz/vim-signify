![vim-signify](https://raw.githubusercontent.com/mhinz/vim-signify/master/pictures/signify-logo.png)

---

_Signify (or just Sy) uses the sign column to indicate added, modified and
removed lines in a file that is managed by a version control system (VCS)._

---

- Supports **git**, **mercurial**, **darcs**, **bazaar**, **subversion**,
  **cvs**, **rcs**, **fossil**, **accurev**, **perforce**, **tfs**, **yadm**.
- **Asynchronous** execution of VCS tools for Vim 8.0.902+ and Neovim.
- **Preserves signs** from other plugins.
- Handles **nested repositories** controlled by different VCS.
- Provides mappings for **navigating hunks** ("blocks of changed lines").
- Provides an **operator** that acts on hunks.
- **Preview** changes in the current line in a popup window.
- Show all changes in **diff mode**.
- Alternative workflow: Disable the plugin by default and **toggle it per
  buffer** on demand.
- Optional **line highlighting**.
- Optional **skipping of filetypes/filenames**.
- Optional **stats in the statusline**.
- **Works out of the box**, but allows fine-grained configuration.
- **Great documentation** and **handsome maintainers**!

---

_Similar plugin for git: [vim-gitgutter](https://github.com/airblade/vim-gitgutter)_

## Installation

The `master` branch is async-only and thus requires at least Vim 8.0.902. Use
the `legacy` branch for older Vim versions.

Using your favorite [plugin
manager](https://github.com/mhinz/vim-galore#managing-plugins), e.g.
[vim-plug](https://github.com/junegunn/vim-plug):

```vim
if has('nvim') || has('patch-8.0.902')
  Plug 'mhinz/vim-signify'
else
  Plug 'mhinz/vim-signify', { 'branch': 'legacy' }
endif
```

## Configuration for async update
```vim
" default updatetime 4000ms is not good for async update
set updatetime=100
```

## Demo

![Example:signify in action](https://raw.githubusercontent.com/mhinz/vim-signify/master/pictures/signify-demo.gif)

## Author and Feedback

If you like this plugin, star it! It's a great way of getting feedback. The same
goes for reporting issues or feature requests.

Contact: [Twitter](https://twitter.com/_mhinz_)

Co-maintainer: [@jamessan](https://github.com/jamessan)
