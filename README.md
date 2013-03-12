# vim-signify

Or just: sy

Sy shows all added, deleted and modified lines since the last commit via Vim its
sign column. It supports several version control systems.

It's fast, highly configurable and well documented.

Features:

- supports git, mercurial, darcs, bazaar, subversion, cvs
- quick jumping between changed lines
- apart from signs there is also optional line highlighting
- fully configurable through global variables (options and mappings)
- optional preserving of signs from other plugins
- you can toggle the plugin per buffer
- exception lists for filetypes and filenames
- good documentation

- quick developer response! :-)

![Example:signify in action](https://github.com/mhinz/vim-signify/raw/master/signify.png)

Limits exist only in your mind! Vim on!

## Longer introduction

`supports git, mercurial, darcs, bazaar, subversion, cvs`

This plugin is based on the diffing features of the supported version control
systems. Since not all VCS support the same options, sometimes we have to fall
back to the 'diff' executable.

Current the following VCS are supported:

- git
- mercurial (hg)
- bazaar (bzr)
- darcs
- subversion (svn)
- cvs

Note: CVS detection is disabled by default, because it can lead to considerable
delay if the current repo is not a CVS one and the environment variable $CVSROOT
is set nevertheless because a remote connection could be made.

`quick jumping between changed lines`

There are mappings for jumping forth and back between changed lines (so-called
hunks). The following example shows the default mappings and how to change them:

    let g:signify_mapping_next_hunk = '<leader>gn'
    let g:signify_mapping_prev_hunk = '<leader>gp'

Note: In case you don't know about the mapleader, have a look at `:h mapleader`.
The default is the '\' button.

`apart from signs there is also optional line highlighting`

Sy shows you signs for changed lines. Moveover, you can enable highlighting of
the concerned lines:

    let g:signify_mapping_toggle_highlight = '<leader>gh'

You can also change the highlighting classes for these lines. The defaults are:

    let g:signify_line_color_add    = 'DiffAdd'
    let g:signify_line_color_delete = 'DiffDelete'
    let g:signify_line_color_change = 'DiffChange'

`you can toggle the plugin per buffer`

In case you want to disable the plugin for the current buffer, you can toggle
it:

    let g:signify_mapping_toggle = '<leader>gt'

`exception lists for filetypes and filenames`

If you want to disable Sy for certain kinds of filename or file types,
you explicitely have to create exception lists:

Example:

    let g:signify_exceptions_filetype = [ 'vim', 'c' ]
    let g:signify_exceptions_filename = [ '.vimrc' ]

`good documentation`

You should know by now!

## Installation

I suggest using tpope's plain and awesome pathogen:

- https://github.com/tpope/vim-pathogen

Afterwards, just clone vim-signify into ~/.vim/bundle/.

## Usage

`:h signify`

## Configuration

For more info: `:h signify-options`

    let g:signify_mapping_next_hunk = '<leader>gn'
    let g:signify_mapping_prev_hunk = '<leader>gp'

    let g:signify_mapping_toggle_highlight = '<leader>gh'
    let g:signify_mapping_toggle           = '<leader>gt'

    let g:signify_exceptions_filetype = [ 'vim', 'c' ]
    let g:signify_exceptions_filename = [ '.vimrc' ]

    let g:signify_sign_overwrite = 1

    let g:signify_sign_add               = '+'
    let g:signify_sign_delete            = '-'
    let g:signify_sign_change            = '*'
    let g:signify_sign_delete            = '-'
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

    let g:signify_enable_cvs = 1

    let g:signify_cursorhold_normal = 1
    let g:signify_cursorhold_insert = 1

## Author

Marco Hinz `<mh.codebro@gmail.com>`

## License

Copyright © 2013 Marco Hinz. Revised BSD license.
