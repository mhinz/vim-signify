scriptencoding utf-8

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

  if get(g:, 'signify_update_on_focusgained') && !has('gui_win32')
    autocmd FocusGained * call sy#start(g:sy_path)
  endif
augroup END

" Init: commands {{{1
com! -nargs=0 -bar  SignifyToggle          call sy#toggle()
com! -nargs=0 -bar  SignifyToggleHighlight call sy#highlight#line_toggle()
com! -nargs=0 -bar  SyDebug                call sy#debug#list_active_buffers()

" Init: mappings {{{1
nnoremap <silent> <expr> <plug>(signify-next-hunk) &diff ? ']c' : ":\<c-u>call sy#jump#next_hunk(v:count1)\<cr>"
nnoremap <silent> <expr> <plug>(signify-prev-hunk) &diff ? '[c' : ":\<c-u>call sy#jump#prev_hunk(v:count1)\<cr>"
nnoremap <silent> <plug>(signify-toggle-highlight) :<c-u>call sy#highlight#line_toggle()<cr>
nnoremap <silent> <plug>(signify-toggle)           :<c-u>call sy#toggle()<cr>

if exists('g:signify_mapping_next_hunk')
  execute 'nmap '. g:signify_mapping_next_hunk .' <plug>(signify-next-hunk)'
elseif !hasmapto('<plug>(signify-next-hunk)') && !maparg('<leader>gj', 'n')
  nmap <leader>gj <plug>(signify-next-hunk)
endif

if exists('g:signify_mapping_prev_hunk')
  execute 'nmap '. g:signify_mapping_prev_hunk .' <plug>(signify-prev-hunk)'
elseif !hasmapto('<plug>(signify-prev-hunk)') && !maparg('<leader>gk', 'n')
  nmap <leader>gk <plug>(signify-prev-hunk)
endif

if exists('g:signify_mapping_toggle_highlight')
  execute 'nmap '. g:signify_mapping_toggle_highlight .' <plug>(signify-toggle-highlight)'
elseif !hasmapto('<plug>(signify-toggle-highlight)') && !maparg('<leader>gh', 'n')
  nmap <leader>gh <plug>(signify-toggle-highlight)
endif

if exists('g:signify_mapping_toggle')
  execute 'nmap '. g:signify_mapping_toggle .' <plug>(signify-toggle)'
elseif !hasmapto('<plug>(signify-toggle)') && !maparg('<leader>gt', 'n')
  nmap <leader>gt <plug>(signify-toggle)
endif

if !maparg(']c', 'n')
  nmap ]c <plug>(signify-next-hunk)
endif

if !maparg('[c', 'n')
  nmap [c <plug>(signify-prev-hunk)
endif

" vim: et sw=2 sts=2
