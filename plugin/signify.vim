" vim: et sw=2 sts=2

scriptencoding utf-8

if exists('g:loaded_signify') || !has('signs') || &compatible
  finish
endif

" Init: values {{{1

let g:loaded_signify = 1
let g:signify_locked = 0

" Init: autocmds {{{1

augroup signify
  autocmd!

  autocmd BufRead,BufWritePost * call sy#start()

  autocmd QuickFixCmdPre  *vimgrep* let g:signify_locked = 1
  autocmd QuickFixCmdPost *vimgrep* let g:signify_locked = 0

  if get(g:, 'signify_update_on_bufenter')
    autocmd BufEnter * nested call s:save()
  endif
  if get(g:, 'signify_cursorhold_normal')
    autocmd CursorHold * nested call s:save()
  endif
  if get(g:, 'signify_cursorhold_insert')
    autocmd CursorHoldI * nested call s:save()
  endif

  if get(g:, 'signify_update_on_focusgained') && !has('gui_win32')
    autocmd FocusGained * SignifyRefresh
  endif
augroup END

" Init: commands {{{1

command! -nargs=0 -bar SignifyDebug           call sy#debug#list_active_buffers()
command! -nargs=0 -bar SignifyDebugDiff       call sy#debug#verbose_diff_cmd()
command! -nargs=0 -bar SignifyDebugUnknown    call sy#repo#debug_detection()
command! -nargs=0 -bar SignifyFold            call sy#fold#do()
command! -nargs=0 -bar SignifyRefresh         call sy#util#refresh_windows()
command! -nargs=0 -bar SignifyToggle          call sy#toggle()
command! -nargs=0 -bar SignifyToggleHighlight call sy#highlight#line_toggle()

" Init: mappings {{{1

" hunk jumping
nnoremap <silent> <expr> <plug>(signify-next-hunk) &diff
      \ ? ']c'
      \ : ":\<c-u>call sy#jump#next_hunk(v:count1)\<cr>"
nnoremap <silent> <expr> <plug>(signify-prev-hunk) &diff
      \ ? '[c'
      \ : ":\<c-u>call sy#jump#prev_hunk(v:count1)\<cr>"

if empty(maparg(']c', 'n'))
  nmap ]c <plug>(signify-next-hunk)
endif
if empty(maparg('[c', 'n'))
  nmap [c <plug>(signify-prev-hunk)
endif

" hunk text object
onoremap <silent> <plug>(signify-motion-inner-pending) :<c-u>call sy#util#hunk_text_object(0)<cr>
xnoremap <silent> <plug>(signify-motion-inner-visual)  :<c-u>call sy#util#hunk_text_object(0)<cr>
onoremap <silent> <plug>(signify-motion-outer-pending) :<c-u>call sy#util#hunk_text_object(1)<cr>
xnoremap <silent> <plug>(signify-motion-outer-visual)  :<c-u>call sy#util#hunk_text_object(1)<cr>

" Function: save {{{1

function! s:save()
  if exists('b:sy') && b:sy.active && &modified
    write
  endif
endfunction
