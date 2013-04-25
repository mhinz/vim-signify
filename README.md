

NEWS: Sy is pretty stable at the moment, so there will be no commits (apart from
bugfixes/feature requests) in the next ~month. I'm mainly working at Sy 2.0 at the
moment. Stay tuned! :-)


vim-signify
-----------

Or just: __sy__

Sy shows all added, deleted and modified lines since the last commit via Vim its
sign column. It __supports several version control systems__.

It's __fast__, __highly configurable__ and __well documented__.

Features:

- supports git, mercurial, darcs, bazaar, subversion, cvs, rcs, fossil
- quick jumping between changed lines
- apart from signs there is also optional line highlighting
- fully configurable through global variables (options and mappings)
- optional preserving of signs from other plugins
- you can toggle the plugin per buffer
- skip certain filetypes and filenames
- good documentation

- quick developer response! :-)

![Example:signify in action](https://github.com/mhinz/vim-signify/raw/master/signify.png)

Limits exist only in your mind!

Feedback, please!
-----------------

If you use any of my plugins, star it on github. This is a great way of getting
feedback! Same for issues or feature requests.

Thank you for flying mhi airlines. Get the Vim on!

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

A new line was added. The sign is shown on the same line as the new line.

`_`

A line was deleted. The sign is shown on the line above the deleted line. Special case: The first line was deleted. In this case the sign is shown on the same line.

`!`

A line was changed. Something was changed, but the amount of lines stayed the same. The sign is shown on the same line.

`!_`

A line was changed and one or more of the lines below were deleted. A combination of **!** and **_**. The sign is shown on the same line.


`‾`

The first line was deleted. This special case is indicated by **‾** rather than
**_**.

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

#### quick jumping between changed lines

There are mappings for jumping forth and back between changed lines (so-called
hunks). The following example shows the default mappings and how to change them:

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

You can also change the highlighting classes for these lines. The defaults are:

```vim
let g:signify_line_color_add           = 'DiffAdd'
let g:signify_line_color_delete        = 'DiffDelete'
let g:signify_line_color_change        = 'DiffChange'
let g:signify_line_color_change_delete = 'DiffChange'
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

For more info: `:h signify-options`

__NOTE__: The shown assignments are only examples, not defaults.

```vim
let g:signify_vcs_list = [ 'git', 'hg' ]

let g:signify_mapping_next_hunk = '<leader>gj'
let g:signify_mapping_prev_hunk = '<leader>gk'

let g:signify_mapping_toggle_highlight = '<leader>gh'
let g:signify_mapping_toggle           = '<leader>gt'

let g:signify_skip_filetype = { 'vim': 1, 'c': 1 }
let g:signify_skip_filename = { '/home/user/.vimrc': 1 }

let g:signify_sign_overwrite = 1

let g:signify_update_on_bufenter = 1

let g:signify_line_highlight = 1

let g:signify_sign_weight = 'bold'

let g:signify_sign_add               = '+'
let g:signify_sign_delete            = '-'
let g:signify_sign_change            = '*'
let g:signify_sign_change_delete     = '*_'
let g:signify_sign_delete_first_line = '‾'

let g:signify_sign_color_guifg_add      = '#00ff00'
let g:signify_sign_color_guifg_delete   = '#ff0000'
let g:signify_sign_color_guifg_change   = '#ffff00'
let g:signify_sign_color_guibg          = '#111111'

let g:signify_sign_color_ctermfg_add    = 2
let g:signify_sign_color_ctermfg_delete = 1
let g:signify_sign_color_ctermfg_change = 3
let g:signify_sign_color_ctermbg        = 0

let g:signify_sign_color_group_add    = 'MyAdd'
let g:signify_sign_color_group_delete = 'MyDelete'
let g:signify_sign_color_group_change = 'MyChange'

let g:signify_line_color_add    = 'DiffAdd'
let g:signify_line_color_delete = 'DiffDelete'
let g:signify_line_color_change = 'DiffChange'

let g:signify_cursorhold_normal = 1
let g:signify_cursorhold_insert = 1
```

Author
------

Marco Hinz `<mh.codebro@gmail.com>`

License
-------

Copyright © Marco Hinz. Distributed under the same terms as Vim itself. See
`:help license`.
