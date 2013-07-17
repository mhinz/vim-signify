" Plugin:      https://github.com/mhinz/vim-signify
" Description: show a diff from a version control system via the signcolumn
" Maintainer:  Marco Hinz <http://github.com/mhinz>
" Version:     1.9

if exists('g:loaded_signify') || !has('signs') || &cp
  finish
endif
let g:loaded_signify = 1

" Init: values {{{1
let s:sy = {}  " the main data structure
let s:other_signs_line_numbers = {}

" overwrite non-signify signs by default
let s:sign_overwrite = get(g:, 'signify_sign_overwrite', 1)

let s:id_start = 0x100
let s:id_top   = s:id_start

let s:sign_add               = get(g:, 'signify_sign_add',               '+')
let s:sign_delete            = get(g:, 'signify_sign_delete',            '_')
let s:sign_delete_first_line = get(g:, 'signify_sign_delete_first_line', '‾')
let s:sign_change            = get(g:, 'signify_sign_change',            '!')

if !empty(get(g:, 'signify_difftool'))
  let s:difftool = g:signify_difftool
else
  if has('win32')
    if $VIMRUNTIME =~ ' '
      let s:difftool = (&sh =~ '\<cmd')
            \ ? ('"'. $VIMRUNTIME .'\diff"')
            \ : (substitute($VIMRUNTIME, ' ', '" ', '') .'\diff"')
    else
      let s:difftool = $VIMRUNTIME .'\diff'
    endif
  else
    if !executable('diff')
      echomsg 'signify: No diff tool found!'
      finish
    endif
    let s:difftool = 'diff'
  endif
endif

sign define SignifyPlaceholder text=. texthl=SignifySignChange linehl=NONE

" Init: autocmds {{{1
augroup signify
  autocmd!

  autocmd VimEnter             * call s:highlight_setup()
  autocmd BufRead,BufEnter     * let s:path = resolve(expand('<afile>:p'))
  autocmd BufRead,BufWritePost * call s:start(s:path)

  autocmd BufDelete *
        \ let path = resolve(expand('<afile>:p')) |
        \ call s:stop(path) |
        \ if has_key(s:sy, path) |
        \   call remove(s:sy, path) |
        \ endif

  if get(g:, 'signify_update_on_bufenter')
    autocmd BufEnter * nested
          \ if has_key(s:sy, s:path) && s:sy[s:path].active && &modified |
          \   write |
          \ endif
  endif

  if get(g:, 'signify_cursorhold_normal')
    autocmd CursorHold * nested
          \ if has_key(s:sy, s:path) && s:sy[s:path].active && &modified |
          \   write |
          \ endif
  endif

  if get(g:, 'signify_cursorhold_insert')
    autocmd CursorHoldI * nested
          \ if has_key(s:sy, s:path) && s:sy[s:path].active && &modified |
          \   write |
          \ endif
  endif

  if !has('gui_win32')
    autocmd FocusGained * call s:start(s:path)
  endif
augroup END

" Init: commands {{{1
com! -nargs=0 -bar        SignifyToggle          call s:toggle()
com! -nargs=0 -bar        SignifyToggleHighlight call s:highlight_line_toggle()
com! -nargs=0 -bar -count SignifyJumpToNextHunk  call s:jump_to_next_hunk(<count>)
com! -nargs=0 -bar -count SignifyJumpToPrevHunk  call s:jump_to_prev_hunk(<count>)

" Init: mappings {{{1
if exists('g:signify_mapping_next_hunk')
  execute 'nnoremap <silent> '. g:signify_mapping_next_hunk .' :<c-u>execute v:count ."SignifyJumpToNextHunk"<cr>'
else
  nnoremap <silent> <leader>gj :<c-u>execute v:count .'SignifyJumpToNextHunk'<cr>
endif

if exists('g:signify_mapping_prev_hunk')
  execute 'nnoremap <silent> '. g:signify_mapping_prev_hunk .' :<c-u>execute v:count ."SignifyJumpToPrevHunk"<cr>'
else
  nnoremap <silent> <leader>gk :<c-u>execute v:count .'SignifyJumpToPrevHunk'<cr>
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

" Function: s:start {{{1
function! s:start(path) abort
  if !filereadable(a:path)
        \ || (exists('g:signify_skip_filetype') && has_key(g:signify_skip_filetype, &ft))
        \ || (exists('g:signify_skip_filename') && has_key(g:signify_skip_filename, a:path))
    return
  endif

  " new buffer.. add to list
  if !has_key(s:sy, a:path)
    let [ diff, type ] = sy#repo#detect(a:path)
    if empty(diff)
      return
    endif
    if get(g:, 'signify_disable_by_default')
      let s:sy[a:path] = { 'active': 0, 'type': type, 'hunks': [], 'id_top': s:id_top }
      return
    endif
    let s:sy[a:path] = { 'active': 1, 'type': type, 'hunks': [], 'id_top': s:id_top }
  " inactive buffer.. bail out
  elseif !s:sy[a:path].active
    return
  " update signs
  else
    let diff = sy#repo#get_diff_{s:sy[a:path].type}(a:path)
    if empty(diff)
      call s:sign_remove_all(a:path)
      return
    endif
    let s:sy[a:path].id_top  = s:id_top
  endif

  if !exists('s:line_highlight')
    if get(g:, 'signify_line_highlight')
      call s:highlight_line_enable()
    else
      call s:highlight_line_disable()
    endif
  endif

  if !s:sign_overwrite
    call s:sign_get_others(a:path)
  endif

  execute 'sign place 99999 line=1 name=SignifyPlaceholder file='. a:path
  call s:sign_remove_all(a:path)
  call sy#repo#process_diff(a:path, diff)
  sign unplace 99999

  if !maparg('[c', 'n')
    nnoremap <buffer><silent> ]c :<c-u>execute v:count1 .'SignifyJumpToNextHunk'<cr>
    nnoremap <buffer><silent> [c :<c-u>execute v:count1 .'SignifyJumpToPrevHunk'<cr>
  endif

  let s:sy[a:path].id_top = (s:id_top - 1)
endfunction

" Function: s:stop {{{1
function! s:stop(path) abort
  if !has_key(s:sy, a:path)
    return
  endif

  call s:sign_remove_all(a:path)

  silent! nunmap <buffer> ]c
  silent! nunmap <buffer> [c

  augroup signify
    autocmd! * <buffer>
  augroup END
endfunction

" Function: s:toggle {{{1
function! s:toggle() abort
  if empty(s:path)
    echomsg 'signify: I cannot sy empty buffers!'
    return
  endif

  if has_key(s:sy, s:path)
    if s:sy[s:path].active
      call s:stop(s:path)
      let s:sy[s:path].active = 0
    else
      let s:sy[s:path].active = 1
      call s:start(s:path)
    endif
  else
    call s:start(s:path)
  endif
endfunction

" Function: s:sign_get_others {{{1
function! s:sign_get_others(path) abort
  redir => signlist
    silent! execute 'sign place file='. a:path
  redir END

  for line in filter(split(signlist, '\n'), 'v:val =~ "^\\s\\+line"')
    let lnum = matchlist(line, '\v^\s+line\=(\d+)')[1]
    let s:other_signs_line_numbers[lnum] = 1
  endfor
endfunction

" Function: s:sign_set {{{1
function! s:sign_set(signs)
  let hunk = { 'ids': [], 'start': a:signs[0].lnum, 'end': a:signs[-1].lnum }
  for sign in a:signs
    " Preserve non-signify signs
    if !s:sign_overwrite && has_key(s:other_signs_line_numbers, sign.lnum)
      next
    endif

    call add(hunk.ids, s:id_top)
    execute 'sign place '. s:id_top .' line='. sign.lnum .' name='. sign.type .' file='. sign.path

    let s:id_top += 1
  endfor
  call add(s:sy[sign.path].hunks, hunk)
endfunction

" Function: s:sign_remove_all {{{1
function! s:sign_remove_all(path) abort
  for hunk in s:sy[a:path].hunks
    for id in hunk.ids
      execute 'sign unplace '. id
    endfor
  endfor

  let s:other_signs_line_numbers = {}
  let s:sy[a:path].hunks = []
endfunction

" Function: s:highlight_setup {{{1
function! s:highlight_setup() abort
  highlight link SignifyLineAdd    DiffAdd
  highlight link SignifyLineChange DiffChange
  highlight link SignifyLineDelete DiffDelete
  highlight link SignifySignAdd    DiffAdd
  highlight link SignifySignChange DiffChange
  highlight link SignifySignDelete DiffDelete
endfunction

" Function: s:highlight_line_enable {{{1
function! s:highlight_line_enable() abort
  execute 'sign define SignifyAdd text='. s:sign_add ' texthl=SignifySignAdd linehl=SignifyLineAdd'

  execute 'sign define SignifyChange text='. s:sign_change ' texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyChangeDelete1 text='. s:sign_change .'1 texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyChangeDelete2 text='. s:sign_change .'2 texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyChangeDelete3 text='. s:sign_change .'3 texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyChangeDelete4 text='. s:sign_change .'4 texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyChangeDelete5 text='. s:sign_change .'5 texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyChangeDelete6 text='. s:sign_change .'6 texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyChangeDelete7 text='. s:sign_change .'7 texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyChangeDelete8 text='. s:sign_change .'8 texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyChangeDelete9 text='. s:sign_change .'9 texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyChangeDeleteMore text='. s:sign_change .'> texthl=SignifySignChange linehl=SignifyLineChange'

  execute 'sign define SignifyDelete1 text='. s:sign_delete .'1 texthl=SignifySignDelete linehl=SignifyLineDelete'
  execute 'sign define SignifyDelete2 text='. s:sign_delete .'2 texthl=SignifySignDelete linehl=SignifyLineDelete'
  execute 'sign define SignifyDelete3 text='. s:sign_delete .'3 texthl=SignifySignDelete linehl=SignifyLineDelete'
  execute 'sign define SignifyDelete4 text='. s:sign_delete .'4 texthl=SignifySignDelete linehl=SignifyLineDelete'
  execute 'sign define SignifyDelete5 text='. s:sign_delete .'5 texthl=SignifySignDelete linehl=SignifyLineDelete'
  execute 'sign define SignifyDelete6 text='. s:sign_delete .'6 texthl=SignifySignDelete linehl=SignifyLineDelete'
  execute 'sign define SignifyDelete7 text='. s:sign_delete .'7 texthl=SignifySignDelete linehl=SignifyLineDelete'
  execute 'sign define SignifyDelete8 text='. s:sign_delete .'8 texthl=SignifySignDelete linehl=SignifyLineDelete'
  execute 'sign define SignifyDelete9 text='. s:sign_delete .'9 texthl=SignifySignDelete linehl=SignifyLineDelete'
  execute 'sign define SignifyDeleteMore text='. s:sign_delete .'> texthl=SignifySignDelete linehl=SignifyLineDelete'

  execute 'sign define SignifyDeleteFirstLine text='. s:sign_delete_first_line ' texthl=SignifySignDelete linehl=SignifyLineDelete'

  let s:line_highlight = 1
endfunction

" Function: s:highlight_line_disable {{{1
function! s:highlight_line_disable() abort
  execute 'sign define SignifyAdd text='. s:sign_add ' texthl=SignifySignAdd linehl=none'

  execute 'sign define SignifyChange text='. s:sign_change ' texthl=SignifySignChange linehl=none'
  execute 'sign define SignifyChangeDelete1 text='. s:sign_change .'1 texthl=SignifySignChange linehl=none'
  execute 'sign define SignifyChangeDelete2 text='. s:sign_change .'2 texthl=SignifySignChange linehl=none'
  execute 'sign define SignifyChangeDelete3 text='. s:sign_change .'3 texthl=SignifySignChange linehl=none'
  execute 'sign define SignifyChangeDelete4 text='. s:sign_change .'4 texthl=SignifySignChange linehl=none'
  execute 'sign define SignifyChangeDelete5 text='. s:sign_change .'5 texthl=SignifySignChange linehl=none'
  execute 'sign define SignifyChangeDelete6 text='. s:sign_change .'6 texthl=SignifySignChange linehl=none'
  execute 'sign define SignifyChangeDelete7 text='. s:sign_change .'7 texthl=SignifySignChange linehl=none'
  execute 'sign define SignifyChangeDelete8 text='. s:sign_change .'8 texthl=SignifySignChange linehl=none'
  execute 'sign define SignifyChangeDelete9 text='. s:sign_change .'9 texthl=SignifySignChange linehl=none'
  execute 'sign define SignifyChangeDeleteMore text='. s:sign_change .'> texthl=SignifySignChange linehl=none'

  execute 'sign define SignifyDelete1 text='. s:sign_delete .'1 texthl=SignifySignDelete linehl=none'
  execute 'sign define SignifyDelete2 text='. s:sign_delete .'2 texthl=SignifySignDelete linehl=none'
  execute 'sign define SignifyDelete3 text='. s:sign_delete .'3 texthl=SignifySignDelete linehl=none'
  execute 'sign define SignifyDelete4 text='. s:sign_delete .'4 texthl=SignifySignDelete linehl=none'
  execute 'sign define SignifyDelete5 text='. s:sign_delete .'5 texthl=SignifySignDelete linehl=none'
  execute 'sign define SignifyDelete6 text='. s:sign_delete .'6 texthl=SignifySignDelete linehl=none'
  execute 'sign define SignifyDelete7 text='. s:sign_delete .'7 texthl=SignifySignDelete linehl=none'
  execute 'sign define SignifyDelete8 text='. s:sign_delete .'8 texthl=SignifySignDelete linehl=none'
  execute 'sign define SignifyDelete9 text='. s:sign_delete .'9 texthl=SignifySignDelete linehl=none'
  execute 'sign define SignifyDeleteMore text='. s:sign_delete .'> texthl=SignifySignDelete linehl=none'

  execute 'sign define SignifyDeleteFirstLine text='. s:sign_delete_first_line ' texthl=SignifySignDelete linehl=none'

  let s:line_highlight = 0
endfunction

" Function: s:highlight_line_toggle {{{1
function! s:highlight_line_toggle() abort
  if !has_key(s:sy, s:path)
    echomsg 'signify: I cannot detect any changes!'
    return
  endif

  if s:line_highlight
    call s:highlight_line_disable()
  else
    call s:highlight_line_enable()
  endif

  call s:start(s:path)
endfunction

" Function: s:jump_to_next_hunk {{{1
function! s:jump_to_next_hunk(count)
  if !has_key(s:sy, s:path)
    echomsg 'signify: I cannot detect any changes!'
    return
  endif

  let lnum = line('.')
  let hunks = filter(copy(s:sy[s:path].hunks), 'v:val.start > lnum')
  let hunk = get(hunks, a:count - 1, {})

  if !empty(hunk)
    execute 'sign jump '. hunk.ids[0] .' file='. s:path
  endif
endfunction

" Function: s:jump_to_prev_hunk {{{1
function! s:jump_to_prev_hunk(count)
  if !has_key(s:sy, s:path)
    echomsg 'signify: I cannot detect any changes!'
    return
  endif

  let lnum = line('.')
  let hunks = filter(copy(s:sy[s:path].hunks), 'v:val.start < lnum')
  let hunk = get(hunks, 0 - a:count, {})

  if !empty(hunk)
    execute 'sign jump '. hunk.ids[0] .' file='. s:path
  endif
endfunction

" Function: SignifyDebugListActiveBuffers {{{1
function! SignifyDebugListActiveBuffers() abort
  if empty(s:sy)
    echomsg 'No active buffers!'
    return
  endif

  for [path, stats] in items(s:sy)
    echo "\n". path ."\n". repeat('=', strlen(path))
    for stat in sort(keys(stats))
      echo printf("%20s  =  %s\n", stat, string(stats[stat]))
    endfor
  endfor
endfunction

" vim: et sw=2 sts=2
