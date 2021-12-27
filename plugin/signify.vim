" vim: et sw=2 sts=2 fdm=marker

scriptencoding utf-8

if exists('g:loaded_signify') || !has('signs') || &compatible
  finish
endif

let g:loaded_signify = 1
let g:signify_locked = 0
let g:signify_detecting = 0

" Commands {{{1
command! -nargs=0 -bar       SignifyList            call sy#debug#list_active_buffers()
command! -nargs=0 -bar       SignifyDebug           call sy#repo#debug_detection()
command! -nargs=0 -bar -bang SignifyFold            call sy#fold#dispatch(<bang>1)
command! -nargs=0 -bar -bang SignifyDiff            call sy#repo#diffmode(<bang>1)
command! -nargs=0 -bar       SignifyHunkDiff        call sy#repo#diff_hunk()
command! -nargs=0 -bar       SignifyHunkUndo        call sy#repo#undo_hunk()
command! -nargs=0 -bar       SignifyRefresh         call sy#util#refresh_windows()

command! -nargs=0 -bar       SignifyEnable          call sy#start()
command! -nargs=0 -bar       SignifyDisable         call sy#stop()
command! -nargs=0 -bar       SignifyToggle          call sy#toggle()
command! -nargs=0 -bar       SignifyToggleHighlight call sy#highlight#line_toggle()
command! -nargs=0 -bar       SignifyEnableAll       call sy#start_all()
command! -nargs=0 -bar       SignifyDisableAll      call sy#stop_all()

" Mappings {{{1
let s:cpoptions = &cpoptions
set cpoptions+=B

" hunk jumping
nnoremap <silent> <expr> <plug>(signify-next-hunk) &diff
      \ ? ']c'
      \ : ":\<c-u>call sy#jump#next_hunk(v:count1)\<cr>"
nnoremap <silent> <expr> <plug>(signify-prev-hunk) &diff
      \ ? '[c'
      \ : ":\<c-u>call sy#jump#prev_hunk(v:count1)\<cr>"

if empty(maparg(']c', 'n')) && !hasmapto('<plug>(signify-next-hunk)', 'n')
  nmap ]c <plug>(signify-next-hunk)
  if empty(maparg(']C', 'n')) && !hasmapto('9999]c', 'n')
    nmap ]C 9999]c
  endif
endif
if empty(maparg('[c', 'n')) && !hasmapto('<plug>(signify-prev-hunk)', 'n')
  nmap [c <plug>(signify-prev-hunk)
  if empty(maparg('[C', 'n')) && !hasmapto('9999[c', 'n')
    nmap [C 9999[c
  end
endif

" hunk text object
onoremap <silent> <plug>(signify-motion-inner-pending) :<c-u>call sy#util#hunk_text_object(0)<cr>
xnoremap <silent> <plug>(signify-motion-inner-visual)  :<c-u>call sy#util#hunk_text_object(0)<cr>
onoremap <silent> <plug>(signify-motion-outer-pending) :<c-u>call sy#util#hunk_text_object(1)<cr>
xnoremap <silent> <plug>(signify-motion-outer-visual)  :<c-u>call sy#util#hunk_text_object(1)<cr>

let &cpoptions = s:cpoptions
unlet s:cpoptions

" Autocmds {{{1
if has('gui_running') && has('win32') && argc()
  " Fix 'no signs at start' race.
  autocmd GUIEnter * redraw
endif

autocmd QuickFixCmdPre  *vimgrep* let g:signify_locked = 1
autocmd QuickFixCmdPost *vimgrep* let g:signify_locked = 0

autocmd BufNewFile,BufRead * nested
      \ if !get(g:, 'signify_disable_by_default') |
      \   call sy#start({'bufnr': bufnr('')}) |
      \ endif
" 1}}}

if exists('#User#SignifySetup')
  doautocmd <nomodeline> User SignifySetup
endif
