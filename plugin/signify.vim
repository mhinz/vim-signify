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

  autocmd QuickFixCmdPre  *vimgrep* let g:signify_locked = 1
  autocmd QuickFixCmdPost *vimgrep* let g:signify_locked = 0

  autocmd CmdwinEnter * let g:signify_cmdwin_active = 1
  autocmd CmdwinLeave * let g:signify_cmdwin_active = 0

  autocmd BufWritePost * call sy#start()

  if get(g:, 'signify_realtime') && has('patch-7.4.1967')
    autocmd WinEnter * call sy#start()
    if get(g:, 'signify_update_on_bufenter')
      autocmd BufEnter * nested call s:save()
    else
      autocmd BufEnter * call sy#start()
    endif
    if get(g:, 'signify_cursorhold_normal', 1)
      autocmd CursorHold * nested call s:save()
    endif
    if get(g:, 'signify_cursorhold_insert', 1)
      autocmd CursorHoldI * nested call s:save()
    endif
    if get(g:, 'signify_update_on_focusgained', 1)
      autocmd FocusGained * SignifyRefresh
    endif
  else
    autocmd BufRead * call sy#start()
    if get(g:, 'signify_update_on_bufenter')
      autocmd BufEnter * nested call s:save()
    endif
    if get(g:, 'signify_cursorhold_normal')
      autocmd CursorHold * nested call s:save()
    endif
    if get(g:, 'signify_cursorhold_insert')
      autocmd CursorHoldI * nested call s:save()
    endif
    if get(g:, 'signify_update_on_focusgained')
      autocmd FocusGained * SignifyRefresh
    endif
  endif

  if has('gui_running') && has('win32') && argc()
    " Fix 'no signs at start' race.
    autocmd GUIEnter * redraw
  endif
augroup END

" Init: commands {{{1

command! -nargs=0 -bar       SignifyList            call sy#debug#list_active_buffers()
command! -nargs=0 -bar       SignifyDebug           call sy#repo#debug_detection()
command! -nargs=0 -bar -bang SignifyFold            call sy#fold#dispatch(<bang>1)
command! -nargs=0 -bar -bang SignifyDiff            call sy#repo#diffmode(<bang>1)
command! -nargs=0 -bar       SignifyDiffPreview     call sy#repo#preview_hunk()
command! -nargs=0 -bar       SignifyRefresh         call sy#util#refresh_windows()
command! -nargs=0 -bar       SignifyEnable          call sy#enable()
command! -nargs=0 -bar       SignifyDisable         call sy#disable()
command! -nargs=0 -bar       SignifyToggle          call sy#toggle()
command! -nargs=0 -bar       SignifyToggleHighlight call sy#highlight#line_toggle()

" Init: mappings {{{1
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

" Function: save {{{1

function! s:save()
  if exists('b:sy') && b:sy.active && &modified && &modifiable && ! &readonly
    write
  endif
endfunction

if exists('#User#SignifySetup')
  doautocmd <nomodeline> User SignifySetup
endif
