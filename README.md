# vim-signify

Or just: sy

Sy shows all added, deleted and changed lines since the last commit via Vim its
sign column (and much more!)

It's fast, highly configurable and well documented.

Features:

- supports git, mercurial, bazaar, subversion, cvs
- apart from signs there is also optional line highlighting
- fully configurable through global variables
- optional preserving of signs from other plugins
- you can toggle the plugin per buffer
- exception lists for filetypes and filenames
- good documentation

- quick developer response! :-)

![Example:signify in action](https://github.com/mhinz/vim-signify/raw/master/signify.png)

Limits exist only in your mind! Vim on!

## What about vim-gitgutter?

Because people keep asking for it: Yes, I knew about vim-gitgutter before, I
even contributed to it. But in the end I just didn't like the codebase and
started my own plugin. And because I like programming VimL.

The main difference is probably the support for other DVCS. Moreover, execution
speed and high configurability are two of the design goals.

## Installation

I suggest using tpope's plain and awesome pathogen:

- https://github.com/tpope/vim-pathogen

Afterwards, just clone vim-signify into ~/.vim/bundle/.

## Usage

`:h signify`

## Configuration

For more info: `:h signify-options`

    let g:signify_sign_overwrite = 1

    let g:signify_mapping_next_hunk = '<leader>gn'
    let g:signify_mapping_prev_hunk = '<leader>gp'

    let g:signify_mapping_toggle_highlight = '<leader>gh'

    let g:signify_mapping_toggle = '<leader>gt'

    let g:signify_sign_add    = '+'
    let g:signify_sign_delete = '-'
    let g:signify_sign_change = '*'

    let g:signify_exceptions_filetype = [ 'vim', 'c' ]
    let g:signify_exceptions_filename = [ '.vimrc' ]

    let g:signify_color_sign_guifg_add      = '#00ff00'
    let g:signify_color_sign_guifg_delete   = '#ff0000'
    let g:signify_color_sign_guifg_change   = '#ffff00'
    let g:signify_color_guibg               = '#111111'

    let g:signify_color_sign_ctermfg_add    = 2
    let g:signify_color_sign_ctermfg_delete = 1
    let g:signify_color_sign_ctermfg_change = 3
    let g:signify_color_sign_ctermbg        = 0

    let g:signify_color_line_highlight_add    = 'DiffAdd'
    let g:signify_color_line_highlight_delete = 'DiffDelete'
    let g:signify_color_line_highlight_change = 'DiffChange'

## Author

Marco Hinz `<mh.codebro@gmail.com>`

## License

Copyright © 2013 Marco Hinz. Revised BSD license.
