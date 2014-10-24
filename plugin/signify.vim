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
  autocmd BufDelete            * call sy#stop()

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
    autocmd FocusGained * call s:refresh_windows()
  endif
augroup END

" Init: commands {{{1
com! -nargs=0 -bar  SignifyToggle          call sy#toggle()
com! -nargs=0 -bar  SignifyToggleHighlight call sy#highlight#line_toggle()
com! -nargs=0 -bar  SyDebug                call sy#debug#list_active_buffers()

" Init: mappings {{{1
nnoremap <silent> <plug>(signify-toggle)           :<c-u>call sy#toggle()<cr>
nnoremap <silent> <plug>(signify-toggle-highlight) :<c-u>call sy#highlight#line_toggle()<cr>

if exists('g:signify_mapping_toggle')
  execute 'nmap '. g:signify_mapping_toggle .' <plug>(signify-toggle)'
elseif !hasmapto('<plug>(signify-toggle)') && empty(maparg('<leader>gt', 'n'))
  nmap <leader>gt <plug>(signify-toggle)
endif
if exists('g:signify_mapping_toggle_highlight')
  execute 'nmap '. g:signify_mapping_toggle_highlight .' <plug>(signify-toggle-highlight)'
elseif !hasmapto('<plug>(signify-toggle-highlight)') && empty(maparg('<leader>gh', 'n'))
  nmap <leader>gh <plug>(signify-toggle-highlight)
endif

" hunk jumping
nnoremap <silent> <expr> <plug>(signify-next-hunk) &diff ? ']c' : ":\<c-u>call sy#jump#next_hunk(v:count1)\<cr>"
nnoremap <silent> <expr> <plug>(signify-prev-hunk) &diff ? '[c' : ":\<c-u>call sy#jump#prev_hunk(v:count1)\<cr>"

if empty(maparg(']c', 'n'))
  nmap ]c <plug>(signify-next-hunk)
endif
if empty(maparg('[c', 'n'))
  nmap [c <plug>(signify-prev-hunk)
endif
if exists('g:signify_mapping_next_hunk')
  execute 'nmap '. g:signify_mapping_next_hunk .' <plug>(signify-next-hunk)'
elseif !hasmapto('<plug>(signify-next-hunk)') && empty(maparg('<leader>gj', 'n'))
  nmap <leader>gj <plug>(signify-next-hunk)
endif
if exists('g:signify_mapping_prev_hunk')
  execute 'nmap '. g:signify_mapping_prev_hunk .' <plug>(signify-prev-hunk)'
elseif !hasmapto('<plug>(signify-prev-hunk)') && empty(maparg('<leader>gk', 'n'))
  nmap <leader>gk <plug>(signify-prev-hunk)
endif

" hunk text object
onoremap <silent> <plug>(signify-motion-inner-pending) :<c-u>call <sid>hunk_text_object(0)<cr>
xnoremap <silent> <plug>(signify-motion-inner-visual)  :<c-u>call <sid>hunk_text_object(0)<cr>
onoremap <silent> <plug>(signify-motion-outer-pending) :<c-u>call <sid>hunk_text_object(1)<cr>
xnoremap <silent> <plug>(signify-motion-outer-visual)  :<c-u>call <sid>hunk_text_object(1)<cr>

if !hasmapto('<plug>(signify-motion-inner-pending)') && empty(maparg('ic', 'o'))
  omap ic <plug>(signify-motion-inner-pending)
endif
if !hasmapto('<plug>(signify-motion-inner-visual)') && empty(maparg('ic', 'v'))
  xmap ic <plug>(signify-motion-inner-visual)
endif
if !hasmapto('<plug>(signify-motion-outer-pending)') && empty(maparg('ac', 'o'))
  omap ac <plug>(signify-motion-outer-pending)
endif
if !hasmapto('<plug>(signify-motion-outer-visual)') && empty(maparg('ac', 'v'))
  xmap ac <plug>(signify-motion-outer-visual)
endif

" Function: save {{{1
function! s:save()
  if exists('b:sy') && b:sy.active && &modified
    write
  endif
endfunction

" Function: refresh_windows {{{1
function! s:refresh_windows() abort
  let winnr = winnr()
  windo if exists('b:sy') | call sy#start() | endif
  execute winnr .'wincmd w'
endfunction

" Function: hunk_text_object {{{1
function! s:hunk_text_object(emptylines) abort
  if !exists('b:sy')
    return
  endif

  let lnum  = line('.')
  let hunks = filter(copy(b:sy.hunks), 'v:val.start <= lnum && v:val.end >= lnum')

  if empty(hunks)
    return
  endif

  execute hunks[0].start
  normal! V

  if a:emptylines
    let lnum = hunks[0].end
    while getline(lnum+1) =~ '^$'
      let lnum += 1
    endwhile
    execute lnum
  else
    execute hunks[0].end
  endif
endfunction
