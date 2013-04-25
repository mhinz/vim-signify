" Plugin:      https://github.com/mhinz/vim-signify
" Description: show a diff from a version control system via the signcolumn
" Maintainer:  Marco Hinz <http://github.com/mhinz>
" Version:     1.7

if exists('g:loaded_signify') || !has('signs') || &cp
  finish
endif
let g:loaded_signify = 1

" Init: values {{{1
let s:sy = {}  " the main data structure
let s:other_signs_line_numbers = {}

" overwrite non-signify signs by default
let s:sign_overwrite = get(g:, 'signify_sign_overwrite', 1)
let s:vcs_list       = get(g:, 'signify_vcs_list', [ 'git', 'hg', 'svn', 'darcs', 'bzr', 'fossil', 'cvs', 'rcs' ])

let s:id_start = 0x100
let s:id_top   = s:id_start

let s:line_color_add           = get(g:, 'signify_line_color_add',           'DiffAdd')
let s:line_color_delete        = get(g:, 'signify_line_color_delete',        'DiffDelete')
let s:line_color_change        = get(g:, 'signify_line_color_change',        'DiffChange')
let s:line_color_change_delete = get(g:, 'signify_line_color_change_delete', 'DiffChange')

let s:sign_add               = get(g:, 'signify_sign_add',               '+')
let s:sign_delete            = get(g:, 'signify_sign_delete',            '_')
let s:sign_delete_first_line = get(g:, 'signify_sign_delete_first_line', '‾')
let s:sign_change            = get(g:, 'signify_sign_change',            '!')
let s:sign_change_delete     = get(g:, 'signify_sign_change_delete',     '!_')

if has('win32')
  if $VIMRUNTIME =~ ' '
    let s:difftool = (&sh =~ '\<cmd') ? ('"'. $VIMRUNTIME .'\diff"') : (substitute($VIMRUNTIME, ' ', '" ', '') .'\diff"')
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

sign define SignifyPlaceholder text=. texthl=SignifyChange linehl=NONE

" Init: autocmds {{{1
augroup signify
  autocmd!

  autocmd BufEnter             * let s:path = resolve(expand('<afile>:p'))
  autocmd BufWritePost         * call s:start(s:path)
  autocmd VimEnter,ColorScheme * call s:colors_set()

  if get(g:, 'signify_update_on_bufenter', 1)
    autocmd BufEnter * call s:start(s:path)
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

  autocmd BufDelete *
        \ call s:stop(s:path) |
        \ if has_key(s:sy, s:path) |
        \   call remove(s:sy, s:path) |
        \ endif
augroup END

" Init: commands {{{1
com! -nargs=0 -bar        SignifyToggle          call s:toggle_signify()
com! -nargs=0 -bar        SignifyToggleHighlight call s:line_highlighting_toggle()
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

" Function: s:toggle_signify {{{1
function! s:toggle_signify() abort
  if empty(s:path)
    echo 'signify: I cannot sy empty buffers!'
    return
  endif

  if has_key(s:sy, s:path)
    if s:sy[s:path].active
      call s:stop(s:path)
    else
      let s:sy[s:path].active = 1
      call s:start(s:path)
    endif
  else
    call s:start(s:path)
  endif
endfunction

" Function: s:start {{{1
function! s:start(path) abort
  if !filereadable(a:path)
        \ || (exists('g:signify_skip_filetype') && has_key(g:signify_skip_filetype, &ft))
        \ || (exists('g:signify_skip_filename') && has_key(g:signify_skip_filename, a:path))
    return
  endif

  " New buffer.. add to list.
  if !has_key(s:sy, a:path)
    let [ diff, type ] = s:repo_detect(a:path)
    if empty(diff)
      return
    endif
    let s:sy[a:path] = { 'active': 1, 'type': type, 'ids': [], 'id_jump': s:id_top, 'id_top': s:id_top, 'last_jump_was_next': -1 }
  " Inactive buffer.. bail out.
  elseif !s:sy[a:path].active
    return
  " Update signs.
  else
    let diff = s:repo_get_diff_{s:sy[a:path].type}(a:path)
    if empty(diff)
      call s:sign_remove_all(a:path)
      return
    endif
    let s:sy[a:path].id_top  = s:id_top
    let s:sy[a:path].id_jump = s:id_top
    let s:sy[a:path].last_jump_was_next = -1
  endif

  if !exists('s:line_highlight')
    if get(g:, 'signify_line_highlight')
      call s:line_highlighting_enable()
    else
      call s:line_highlighting_disable()
    endif
  endif

  if !s:sign_overwrite
    call s:sign_get_others(a:path)
  endif

  execute 'sign place 99999 line=1 name=SignifyPlaceholder file='. a:path
  call s:sign_remove_all(a:path)
  call s:repo_process_diff(a:path, diff)
  sign unplace 99999

  if !maparg('[c', 'n')
    nnoremap <buffer><silent> ]c :<c-u>execute v:count .'SignifyJumpToNextHunk'<cr>
    nnoremap <buffer><silent> [c :<c-u>execute v:count .'SignifyJumpToPrevHunk'<cr>
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

  let s:sy[s:path].active = 0
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
function! s:sign_set(lnum, type, path)
  " Preserve non-signify signs
  if !s:sign_overwrite && has_key(s:other_signs_line_numbers, a:lnum)
    return
  endif

  call add(s:sy[a:path].ids, s:id_top)
  execute 'sign place '. s:id_top .' line='. a:lnum .' name='. a:type .' file='. a:path

  let s:id_top += 1
endfunction

" Function: s:sign_remove_all {{{1
function! s:sign_remove_all(path) abort
  for id in s:sy[a:path].ids
    execute 'sign unplace '. id
  endfor

  let s:other_signs_line_numbers = {}
  let s:sy[a:path].ids = []
endfunction

" Function: s:repo_detect {{{1
function! s:repo_detect(path) abort
  for type in s:vcs_list
    let diff = s:repo_get_diff_{type}(a:path)
    if !empty(diff)
      return [ diff, type ]
    endif
  endfor

  return [ '', '' ]
endfunction

" Function: s:repo_get_diff_git {{{1
function! s:repo_get_diff_git(path) abort
  if executable('git')
    let diff = system('cd '. s:escape(fnamemodify(a:path, ':h')) .' && git diff --no-ext-diff -U0 -- '. s:escape(a:path))
    return v:shell_error ? '' : diff
  endif
endfunction

" Function: s:repo_get_diff_hg {{{1
function! s:repo_get_diff_hg(path) abort
  if executable('hg')
    let diff = system('hg diff --nodates -U0 -- '. s:escape(a:path))
    return v:shell_error ? '' : diff
  endif
endfunction

" Function: s:repo_get_diff_svn {{{1
function! s:repo_get_diff_svn(path) abort
  if executable('svn')
    let diff = system('svn diff --diff-cmd '. s:difftool .' -x -U0 -- '. s:escape(a:path))
    return v:shell_error ? '' : diff
  endif
endfunction

" Function: s:repo_get_diff_bzr {{{1
function! s:repo_get_diff_bzr(path) abort
  if executable('bzr')
    let diff = system('bzr diff --using '. s:difftool .' --diff-options=-U0 -- '. s:escape(a:path))
    return ((v:shell_error == 0) || (v:shell_error == 1) || (v:shell_error == 2)) ? diff : ''
  endif
endfunction

" Function: s:repo_get_diff_darcs {{{1
function! s:repo_get_diff_darcs(path) abort
  if executable('darcs')
    let diff = system('cd '. s:escape(fnamemodify(a:path, ':h')) .' && darcs diff --no-pause-for-gui --diff-command="'. s:difftool .' -U0 %1 %2" -- '. s:escape(a:path))
    return v:shell_error ? '' : diff
  endif
endfunction

" Function: s:repo_get_diff_fossil {{{1
function! s:repo_get_diff_fossil(path) abort
  if executable('fossil')
    let diff = system('cd '. s:escape(fnamemodify(a:path, ':h')) .' && fossil set diff-command "'. s:difftool .' -U 0" && fossil diff --unified -c 0 -- '. s:escape(a:path))
    return v:shell_error ? '' : diff
  endif
endfunction

" Function: s:repo_get_diff_cvs {{{1
function! s:repo_get_diff_cvs(path) abort
  if executable('cvs')
    let diff = system('cd '. s:escape(fnamemodify(a:path, ':h')) .' && cvs diff -U0 -- '. s:escape(fnamemodify(a:path, ':t')))
    return v:shell_error ? '' : diff
  endif
endfunction

" Function: s:repo_get_diff_rcs {{{1
function! s:repo_get_diff_rcs(path) abort
  if executable('rcs')
    let diff = system('rcsdiff -U0 '. s:escape(a:path) .' 2>/dev/null')
    return v:shell_error ? '' : diff
  endif
endfunction

" Function: s:repo_process_diff {{{1
function! s:repo_process_diff(path, diff) abort
  " Determine where we have to put our signs.
  for line in filter(split(a:diff, '\n'), 'v:val =~ "^@@ "')
    let tokens = matchlist(line, '^@@ -\v(\d+),?(\d*) \+(\d+),?(\d*)')

    let [ old_line, old_count, new_line, new_count ] = [ str2nr(tokens[1]), empty(tokens[2]) ? 1 : str2nr(tokens[2]), str2nr(tokens[3]), empty(tokens[4]) ? 1 : str2nr(tokens[4]) ]

    " A new line was added.
    if (old_count == 0) && (new_count >= 1)
      let offset = 0
      while offset < new_count
        call s:sign_set(new_line + offset, 'SignifyAdd', a:path)
        let offset += 1
      endwhile
      " An old line was removed.
    elseif (old_count >= 1) && (new_count == 0)
      if new_line == 0
        call s:sign_set(1, 'SignifyDeleteFirstLine', a:path)
      else
        call s:sign_set(new_line, 'SignifyDelete', a:path)
      endif
      " A line was changed.
    elseif (old_count == new_count)
      let offset = 0
      while offset < new_count
        call s:sign_set(new_line + offset, 'SignifyChange', a:path)
        let offset += 1
      endwhile
    else
      " Lines were changed && deleted.
      if (old_count > new_count)
        let offset = 0
        while offset < new_count
          call s:sign_set(new_line + offset, 'SignifyChange', a:path)
          let offset += 1
        endwhile
        call s:sign_set(new_line + offset - 1, 'SignifyChangeDelete', a:path)
        " (old_count < new_count): Lines were changed && added.
      else
        let offset = 0
        while offset < old_count
          call s:sign_set(new_line + offset, 'SignifyChange', a:path)
          let offset += 1
        endwhile
        while offset < new_count
          call s:sign_set(new_line + offset, 'SignifyAdd', a:path)
          let offset += 1
        endwhile
      endif
    endif
  endfor
endfunction

" Function: s:colors_set {{{1
function! s:colors_set() abort
  let weight = get(g:, 'signify_sign_weight', 'bold')

  if has('gui_running')
    if exists('g:signify_sign_color_guibg')
      let guibg = g:signify_sign_color_guibg
    elseif get(g:, 'signify_sign_color_inherit_from_linenr')
      let guibg = synIDattr(hlID('LineNr'), 'bg', 'gui')
    else
      let guibg = synIDattr(hlID('SignColumn'), 'bg', 'gui')
    endif

    if exists('g:signify_sign_color_group_add')
      execute 'hi! link SignifyAdd '. g:signify_sign_color_group_add
    else
      let guifg_add = get(g:, 'signify_sign_color_guifg_add', '#11ee11')
      if empty(guibg) || guibg < 0
        execute 'hi SignifyAdd gui='. weight .' guifg='. guifg_add
      else
        execute 'hi SignifyAdd gui='. weight .' guifg='. guifg_add .' guibg='. guibg
      endif
    endif

    if exists('g:signify_sign_color_group_delete')
      execute 'hi! link SignifyDelete '. g:signify_sign_color_group_delete
    else
      let guifg_delete = get(g:, 'signify_sign_color_guifg_delete', '#ee1111')
      if empty(guibg) || guibg < 0
        execute 'hi SignifyDelete gui='. weight .' guifg='. guifg_delete
      else
        execute 'hi SignifyDelete gui='. weight .' guifg='. guifg_delete .' guibg='. guibg
      endif
    endif

    if exists('g:signify_sign_color_group_change')
      execute 'hi! link SignifyChange '. g:signify_sign_color_group_change
    else
      let guifg_change = get(g:, 'signify_sign_color_guifg_change', '#eeee11')
      if empty(guibg) || guibg < 0
        execute 'hi SignifyChange gui='. weight .' guifg='. guifg_change
      else
        execute 'hi SignifyChange gui='. weight .' guifg='. guifg_change .' guibg='. guibg
      endif
    endif
  else
    if exists('g:signify_sign_color_ctermbg')
      let ctermbg = g:signify_sign_color_ctermbg
    elseif get(g:, 'signify_sign_color_inherit_from_linenr')
      let ctermbg = synIDattr(hlID('LineNr'), 'bg', 'cterm')
    else
      let ctermbg = synIDattr(hlID('SignColumn'), 'bg', 'cterm')
    endif

    if exists('g:signify_sign_color_group_add')
      execute 'hi! link SignifyAdd '. g:signify_sign_color_group_add
    else
      let ctermfg_add = get(g:, 'signify_sign_color_ctermfg_add', 2)
      if empty(ctermbg) || ctermbg < 0
        execute 'hi SignifyAdd cterm='. weight .' ctermfg='. ctermfg_add
      else
        execute 'hi SignifyAdd cterm='. weight .' ctermfg='. ctermfg_add .' ctermbg='. ctermbg
      endif
    endif

    if exists('g:signify_sign_color_group_delete')
      execute 'hi! link SignifyDelete '. g:signify_sign_color_group_delete
    else
      let ctermfg_delete = get(g:, 'signify_sign_color_ctermfg_delete', 1)
      if empty(ctermbg) || ctermbg < 0
        execute 'hi SignifyDelete cterm='. weight .' ctermfg='. ctermfg_delete
      else
        execute 'hi SignifyDelete cterm='. weight .' ctermfg='. ctermfg_delete .' ctermbg='. ctermbg
      endif
    endif

    if exists('g:signify_sign_color_group_change')
      execute 'hi! link SignifyChange '. g:signify_sign_color_group_change
    else
      let ctermfg_change = get(g:, 'signify_sign_color_ctermfg_change', 3)
      if empty(ctermbg) || ctermbg < 0
        execute 'hi SignifyChange cterm='. weight .' ctermfg='. ctermfg_change
      else
        execute 'hi SignifyChange cterm='. weight .' ctermfg='. ctermfg_change .' ctermbg='. ctermbg
      endif
    endif
  endif
endfunction

" Function: s:line_highlighting_enable {{{1
function! s:line_highlighting_enable() abort
  execute 'sign define SignifyAdd text='. s:sign_add .' texthl=SignifyAdd linehl='. s:line_color_add
  execute 'sign define SignifyChange text='. s:sign_change .' texthl=SignifyChange linehl='. s:line_color_change
  execute 'sign define SignifyChangeDelete text='. s:sign_change_delete .' texthl=SignifyChange linehl='. s:line_color_change_delete
  execute 'sign define SignifyDelete text='. s:sign_delete .' texthl=SignifyDelete linehl='. s:line_color_delete
  execute 'sign define SignifyDeleteFirstLine text='. s:sign_delete_first_line .' texthl=SignifyDelete linehl='. s:line_color_delete

  let s:line_highlight = 1
endfunction

" Function: s:line_highlighting_disable {{{1
function! s:line_highlighting_disable() abort
  execute 'sign define SignifyAdd text='. s:sign_add .' texthl=SignifyAdd linehl=NONE'
  execute 'sign define SignifyChange text='. s:sign_change .' texthl=SignifyChange linehl=NONE'
  execute 'sign define SignifyChangeDelete text='. s:sign_change_delete .' texthl=SignifyChange linehl=NONE'
  execute 'sign define SignifyDelete text='. s:sign_delete .' texthl=SignifyDelete linehl=NONE'
  execute 'sign define SignifyDeleteFirstLine text='. s:sign_delete_first_line .' texthl=SignifyDelete linehl=NONE'

  let s:line_highlight = 0
endfunction

" Function: s:line_highlighting_toggle {{{1
function! s:line_highlighting_toggle() abort
  if !has_key(s:sy, s:path)
    echo 'signify: I cannot detect any changes!'
    return
  endif

  if s:line_highlight
    call s:line_highlighting_disable()
  else
    call s:line_highlighting_enable()
  endif

  call s:start(s:path)
endfunction

" Function: s:jump_to_next_hunk {{{1
function! s:jump_to_next_hunk(count)
  if !has_key(s:sy, s:path) || s:sy[s:path].id_jump == -1
    echo 'signify: I cannot detect any changes!'
    return
  endif

  if s:sy[s:path].last_jump_was_next == 0
    let s:sy[s:path].id_jump += 2
  endif

  let s:sy[s:path].id_jump += a:count ? (a:count - 1) : 0

  if s:sy[s:path].id_jump > s:sy[s:path].id_top
    let s:sy[s:path].id_jump = s:sy[s:path].ids[0]
  endif

  execute 'sign jump '. s:sy[s:path].id_jump .' file='. s:path

  let s:sy[s:path].id_jump += 1
  let s:sy[s:path].last_jump_was_next = 1
endfunction

" Function: s:jump_to_prev_hunk {{{1
function! s:jump_to_prev_hunk(count)
  if !has_key(s:sy, s:path) || s:sy[s:path].id_jump == -1
    echo 'signify: I cannot detect any changes!'
    return
  endif

  if s:sy[s:path].last_jump_was_next == 1
    let s:sy[s:path].id_jump -= 2
  endif

  let s:sy[s:path].id_jump -= a:count ? (a:count - 1) : 0

  if s:sy[s:path].id_jump < s:sy[s:path].ids[0]
    let s:sy[s:path].id_jump = s:sy[s:path].id_top
  endif

  execute 'sign jump '. s:sy[s:path].id_jump .' file='. s:path

  let s:sy[s:path].id_jump -= 1
  let s:sy[s:path].last_jump_was_next = 0
endfunction

" Function: s:escape {{{1
function s:escape(path) abort
  if exists('+shellslash')
    let old_ssl = &shellslash
    set noshellslash
  endif

  let path = shellescape(a:path)

  if exists('old_ssl')
    let &shellslash = old_ssl
  endif

  return path
endfunction

" Function: SignifyDebugListActiveBuffers {{{1
function! SignifyDebugListActiveBuffers() abort
  if empty(s:sy)
    echo 'No active buffers!'
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
