" Plugin:      https://github.com/mhinz/vim-signify
" Description: show a diff from a version control system via the signcolumn
" Maintainer:  Marco Hinz <http://github.com/mhinz>
" Version:     1.9

if exists('g:loaded_signify') || !has('signs') || &cp
  finish
endif
let g:loaded_signify = 1

" Init: values {{{1
let g:sy = {}

" Init: autocmds {{{1
augroup signify
  autocmd!

  autocmd VimEnter             * call sy#highlight#setup()
  autocmd BufRead,BufEnter     * let g:sy_path = resolve(expand('<afile>:p'))
  autocmd BufRead,BufWritePost * call sy#start(g:sy_path)

  autocmd BufDelete *
        \ let path = resolve(expand('<afile>:p')) |
        \ call sy#stop(path) |
        \ if has_key(g:sy, path) |
        \   call remove(g:sy, path) |
        \ endif

  if get(g:, 'signify_update_on_bufenter')
    autocmd BufEnter * nested
          \ if has_key(g:sy, g:sy_path) && g:sy[g:sy_path].active && &modified |
          \   write |
          \ endif
  endif

  if get(g:, 'signify_cursorhold_normal')
    autocmd CursorHold * nested
          \ if has_key(g:sy, g:sy_path) && g:sy[g:sy_path].active && &modified |
          \   write |
          \ endif
  endif

  if get(g:, 'signify_cursorhold_insert')
    autocmd CursorHoldI * nested
          \ if has_key(g:sy, g:sy_path) && g:sy[g:sy_path].active && &modified |
          \   write |
          \ endif
  endif

  if !has('gui_win32')
    autocmd FocusGained * call sy#start(g:sy_path)
  endif
augroup END

" Init: commands {{{1
com! -nargs=0 -bar        SignifyToggle          call sy#toggle()
com! -nargs=0 -bar        SignifyToggleHighlight call sy#highlight#line_toggle()
com! -nargs=0 -bar -count SignifyJumpToNextHunk  call sy#jump#next_hunk(<count>)
com! -nargs=0 -bar -count SignifyJumpToPrevHunk  call sy#jump#prev_hunk(<count>)
com! -nargs=0 -bar        SyDebug                call sy#debug#list_active_buffers()

" Init: mappings {{{1
if exists('g:signify_mapping_next_hunk')
  execute 'nnoremap <silent> '. g:signify_mapping_next_hunk .' :<c-u>execute v:count1 ."SignifyJumpToNextHunk"<cr>'
else
  nnoremap <silent> <leader>gj :<c-u>execute v:count1 .'SignifyJumpToNextHunk'<cr>
endif

if exists('g:signify_mapping_prev_hunk')
  execute 'nnoremap <silent> '. g:signify_mapping_prev_hunk .' :<c-u>execute v:count1 ."SignifyJumpToPrevHunk"<cr>'
else
  nnoremap <silent> <leader>gk :<c-u>execute v:count1 .'SignifyJumpToPrevHunk'<cr>
endif

if exists('g:signify_mapping_toggle_highlight')
  execute 'nnoremap <silent> '. g:signify_mapping_toggle_highlight .' :SignifyToggleHighlight<cr>'
else
  nnoremap <silent> <leader>gh :SignifyToggleHighlight<cr>
endif

if exists('g:signify_mapping_toggle')
  execute 'nnoremap <silent> '. g:signify_mapping_toggle .' :SignifyToggle<cr>'
else
  nnoremap <silent> <leader>gt :SignifyToggle<cr>
endif

" vim: et sw=2 sts=2
