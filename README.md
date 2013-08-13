vim-signify
-----------

Or just: __Sy__.

Sy shows all added, deleted and modified lines since the last commit via Vim its
sign column. It __supports several version control systems__.

It's __fast__, __highly configurable__ and __well documented__.

Features:

- supports git, mercurial, darcs, bazaar, subversion, cvs, rcs, fossil, accurev,
  perforce
- quick jumping between blocks of changed lines
- apart from signs there is also optional line highlighting
- fully configurable through global variables (options and mappings)
- optional preserving of signs from other plugins
- you can toggle the plugin per buffer
- skip certain filetypes and filenames
- good documentation

- quick developer response! :-)

![Example:signify in action](https://github.com/mhinz/vim-signify/raw/master/signify.gif)

Limits exist only in your mind!

Feedback, please!
-----------------

If you use any of my plugins, star it on github. This is a great way of getting
feedback! Same for issues or feature requests.

Thank you for flying mhi airlines. Get the Vim on!

You can also follow me on Twitter: [@_mhinz_](https://twitter.com/_mhinz_)

What about vim-gitgutter?
-------------------------

To be honest, I don't understand why people always compare plugins like Sy to
vim-gitgutter. I understand that it is by far the most known one, but primarily
because it was featured on the Hacker News frontpage.

Don't get me wrong, I don't intend to badmouth gitgutter, I even contributed to
it once. (Granted, it was only a small fix.) And I'm glad about everyone
contributing to the Vim community, but there are two important facts one should
consider:

1. There were other plugins providing the same functionality as gitgutter years
   before its creation.

1. Sy provides a superset of gitgutter.

So here is the short answer: The main difference is Sy its support for version
control systems other than git. Moreover, two of its design goals are speed and
high configurability.

Sign explanation
----------------

`+`

This indicates a new line.

`_1`

This indicates the number of deleted lines. If the number is larger than 9, a
`>` will be shown instead.

`!`

This indicates a changed line.

`!1`

This indicates a changed line and a number of lines below that were deleted.  It
is a combination of `!` and `_`. If the number is larger than 9, a `>` will be
shown instead.

`‾`

This is used instead of `_` in the special case of the first line being removed.

Longer introduction
-------------------

#### supports several version control systems

This plugin is based on the diffing features of the supported version control
systems. Since not all VCS support the same options, sometimes we have to fall
back to the 'diff' executable.

Currently the following VCS are supported:

- git
- mercurial (hg)
- bazaar (bzr)
- darcs
- subversion (svn)
- cvs
- rcs
- fossil
- accurev
- perforce

#### quick jumping between changed lines

There are mappings for jumping forth and back between blocks of changes
(so-called hunks). The following example shows the default mappings and how to
change them:

```vim
let g:signify_mapping_next_hunk = '<leader>gj'
let g:signify_mapping_prev_hunk = '<leader>gk'
```

Note: In case you don't know about the mapleader, have a look at `:h mapleader`.
The default is the '\' button.

Following Vim conventions you can also use __]c__ and __[c__.

#### apart from signs there is also optional line highlighting

Sy shows you signs for changed lines. Moveover, you can enable highlighting of
the concerned lines:

```vim
let g:signify_mapping_toggle_highlight = '<leader>gh'
```

#### you can toggle the plugin per buffer

In case you want to disable the plugin for the current buffer, you can toggle
it:

```vim
let g:signify_mapping_toggle = '<leader>gt'
```

#### skip certain filetypes and filenames

If you want to disable Sy for certain kinds of filename or file types,
you explicitely have to create "skip dicts":

Example:

```vim
let g:signify_skip_filetype = { 'vim': 1, 'c': 1 }
let g:signify_skip_filename = { '/home/user/.vimrc': 1 }
```

__NOTE__: Filenames have to be absolute paths!

#### good documentation

You should know by now!

Installation
------------

If you have no preferred installation method, I suggest using tpope's pathogen:

1. git clone https://github.com/tpope/vim-pathogen ~/.vim/bundle/vim-pathogen
1. mkdir -p ~/.vim/autoload && cd ~/.vim/autoload
1. ln -s ../bundle/vim-pathogen/autoload/pathogen.vim

Afterwards installing Sy is as easy as pie:

2. git clone https://github.com/mhinz/vim-signify ~/.vim/bundle/vim-signify
2. start Vim
2. :Helptags
2. :h signify

Documentation
-------------

`:h signify`

Configuration
-------------

__NOTE__: The shown assignments are only examples. You can find the default
values in the help.

For more info: `:h signify-options`


```vim
let g:signify_vcs_list = [ 'git', 'hg' ]

let g:signify_difftool = 'gnudiff'

let g:signify_mapping_next_hunk = '<leader>gj'
let g:signify_mapping_prev_hunk = '<leader>gk'

let g:signify_mapping_toggle_highlight = '<leader>gh'
let g:signify_mapping_toggle           = '<leader>gt'

let g:signify_skip_filetype = { 'vim': 1, 'c': 1 }
let g:signify_skip_filename = { '/home/user/.vimrc': 1 }

let g:signify_sign_overwrite = 1

let g:signify_update_on_bufenter = 1
let g:signify_update_on_focusgained = 0

let g:signify_line_highlight = 1

let g:signify_sign_add               = '+'
let g:signify_sign_change            = '!'
let g:signify_sign_delete            = '_'
let g:signify_sign_delete_first_line = '‾'

let g:signify_cursorhold_normal = 1
let g:signify_cursorhold_insert = 1
```

Author
------

Marco Hinz `<mh.codebro@gmail.com>`

License
-------

MIT license. Copyright (c) 2013 Marco Hinz.
