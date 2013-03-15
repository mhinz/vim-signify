" Copyright (c) 2013 Marco Hinz
" All rights reserved.
"
" Redistribution and use in source and binary forms, with or without
" modification, are permitted provided that the following conditions are met:
"
" - Redistributions of source code must retain the above copyright notice, this
"   list of conditions and the following disclaimer.
" - Redistributions in binary form must reproduce the above copyright notice,
"   this list of conditions and the following disclaimer in the documentation
"   and/or other materials provided with the distribution.
" - Neither the name of the author nor the names of its contributors may be
"   used to endorse or promote products derived from this software without
"   specific prior written permission.
"
" THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
" IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
" ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
" LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
" CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
" SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
" INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
" CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
" ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
" POSSIBILITY OF SUCH DAMAGE.

if exists('g:loaded_signify') || !has('signs') || &cp
  finish
endif
let g:loaded_signify = 1

"  Default values  {{{1
let s:line_highlight = 0   " disable line highlighting
let b:colors_set     = 0   " do colors have to be reset?
let s:sy             = {}  " the main data structure

" overwrite non-signify signs by default
let s:sign_overwrite = exists('g:signify_sign_overwrite') ? g:signify_sign_overwrite : 1

let s:id_start = 0x100
let s:id_top   = s:id_start

"  Default mappings  {{{1
if exists('g:signify_mapping_next_hunk')
  exe 'nnoremap '. g:signify_mapping_next_hunk .' :<c-u>exe v:count ."SignifyJumpToNextHunk"<cr>'
else
  nnoremap <leader>gj :<c-u>exe v:count .'SignifyJumpToNextHunk'<cr>
endif

if exists('g:signify_mapping_prev_hunk')
  exe 'nnoremap '. g:signify_mapping_prev_hunk .' :<c-u>exe v:count ."SignifyJumpToPrevHunk"<cr>'
else
  nnoremap <leader>gk :<c-u>exe v:count .'SignifyJumpToPrevHunk'<cr>
endif

if exists('g:signify_mapping_toggle_highlight')
  exe 'nnoremap '. g:signify_mapping_toggle_highlight .' :SignifyToggleHighlight<cr>'
else
  nnoremap <leader>gh :SignifyToggleHighlight<cr>
endif

if exists('g:signify_mapping_toggle')
  exe 'nnoremap '. g:signify_mapping_toggle .' :SignifyToggle<cr>'
else
  nnoremap <leader>gt :SignifyToggle<cr>
endif

"  Default signs  {{{1
if exists('g:signify_sign_add')
  exe 'sign define SignifyAdd text='. g:signify_sign_add .' texthl=SignifyAdd linehl=none'
else
  sign define SignifyAdd text=+ texthl=SignifyAdd linehl=none
endif

if exists('g:signify_sign_delete')
  exe 'sign define SignifyDelete text='. g:signify_sign_delete .' texthl=SignifyDelete linehl=none'
else
  sign define SignifyDelete text=_ texthl=SignifyDelete linehl=none
endif

if exists('g:signify_sign_delete_first_line')
  exe 'sign define SignifyDeleteFirstLine text='. g:signify_sign_delete_first_line .' texthl=SignifyDeleteFirstLine linehl=none'
else
  sign define SignifyDeleteFirstLine text=‾ texthl=SignifyDelete linehl=none
endif

if exists('g:signify_sign_change')
  exe 'sign define SignifyChange text='. g:signify_sign_change .' texthl=SignifyChange linehl=none'
else
  sign define SignifyChange text=! texthl=SignifyChange linehl=none
endif

if exists('g:signify_sign_change_delete')
  exe 'sign define SignifyChangeDelete text='. g:signify_sign_change_delete .' texthl=SignifyChange linehl=none'
else
  sign define SignifyChangeDelete text=!_ texthl=SignifyChange linehl=none
endif

sign define SignifyPlaceholder text=~ texthl=SignifyChange linehl=none

"  Initial stuff  {{{1
augroup signify
  autocmd!

  if exists('g:signify_cursorhold_normal') && (g:signify_cursorhold_normal == 1)
    autocmd CursorHold * write | call s:start(resolve(expand('<afile>:p')))
  endif

  if exists('g:signify_cursorhold_insert') && (g:signify_cursorhold_insert == 1)
    autocmd CursorHoldI * write | call s:start(resolve(expand('<afile>:p')))
  endif

  if !has('gui_win32')
    autocmd FocusGained * call s:start(resolve(expand('<afile>:p')))
  endif

  autocmd ColorScheme  * call s:colors_set()
  autocmd BufWritePost * call s:start(resolve(expand('<afile>:p')))
  autocmd BufEnter     * call s:colors_set() | call s:start(resolve(expand('<afile>:p')))
augroup END

com! -nargs=0 -bar        SignifyToggle          call s:toggle_signify()
com! -nargs=0 -bar        SignifyToggleHighlight call s:toggle_line_highlighting()
com! -nargs=0 -bar -count SignifyJumpToNextHunk  call s:jump_to_next_hunk(<count>)
com! -nargs=0 -bar -count SignifyJumpToPrevHunk  call s:jump_to_prev_hunk(<count>)

"  Internal functions  {{{1
"  Functions -> s:start()  {{{2
function! s:start(path) abort
  if empty(a:path) || !filereadable(a:path) || &ft == 'help'
    return
  endif

  " Check for exceptions.
  if exists('g:signify_exceptions_filetype')
    for i in g:signify_exceptions_filetype
      if i == &ft
        return
      endif
    endfor
  endif
  if exists('g:signify_exceptions_filename')
    for i in g:signify_exceptions_filename
      if i == a:path
        return
      endif
    endfor
  endif


  " New buffer.. add to list.
  if !has_key(s:sy, a:path)
    let [ diff, type ] = s:repo_detect(a:path)
    if empty(diff)
      return
    endif
    let s:sy[a:path] = { 'active': 1, 'type': type, 'ids': [], 'id_jump': s:id_top, 'id_top': s:id_top, 'last_jump_was_next': -1 }
  " Inactive buffer.. bail out.
  elseif s:sy[a:path].active == 0
    return
  else
    call s:sign_remove_all(a:path)
    let diff = s:repo_get_diff_{s:sy[a:path].type}(a:path)
    if empty(diff)
      sign unplace 99999
      return
    endif
    let s:sy[a:path].id_top  = s:id_top
    let s:sy[a:path].id_jump = s:id_top
    let s:sy[a:path].last_jump_was_next = -1
  endif

  if !s:sign_overwrite
    call s:sign_get_others(a:path)
  endif

  call s:repo_process_diff(a:path, diff)

  let s:sy[a:path].id_top = (s:id_top - 1)
  sign unplace 99999
endfunction

"  Functions -> s:stop()  {{{2
function! s:stop(path) abort
  if !has_key(s:sy, a:path)
    return
  endif

  call s:sign_remove_all(a:path)
  sign unplace 99999

  if (s:sy[a:path].active == 0)
    return
  else
    call remove(s:sy, a:path)
  endif

  aug signify
    au! * <buffer>
  aug END
endfunction

"  Functions -> s:sign_get_others()  {{{2
function! s:sign_get_others(path) abort
  redir => signlist
    sil! exe 'sign place file='. a:path
  redir END

  for line in split(signlist, '\n')
    if line =~ '\v^\s+\w+'
      let lnum = matchlist(line, '\v^\w+\=(\d+)')[1]
      let s:other_signs_line_numbers[lnum] = 1
    endif
  endfor
endfunction

"  Functions -> s:sign_set()  {{{2
function! s:sign_set(lnum, type, path)
  " Preserve non-signify signs
  if !s:sign_overwrite && has_key(s:other_signs_line_numbers, a:lnum)
    return
  endif

  call add(s:sy[a:path].ids, s:id_top)
  exe 'sign place '. s:id_top .' line='. a:lnum .' name='. a:type .' file='. a:path

  let s:id_top += 1
endfunction

"  Functions -> s:sign_remove_all()  {{{2
function! s:sign_remove_all(path) abort
  exe 'sign place 99999 line=1 name=SignifyPlaceholder  file='. a:path

  for id in s:sy[a:path].ids
    exe 'sign unplace '. id
  endfor

  let s:other_signs_line_numbers = {}
  let s:sy[a:path].ids = []
  let s:sy[a:path].id_jump = -1
endfunction

"  Functions -> s:repo_detect()  {{{2
function! s:repo_detect(path) abort
  if !executable('grep') || !executable('diff')
    echo 'signify: I cannot work without grep and diff!'
  endif

  for type in [ 'git', 'hg', 'svn', 'darcs', 'bzr', 'cvs' ]
    let diff = s:repo_get_diff_{type}(a:path)
    if !empty(diff)
      return [ diff, type ]
    endif
  endfor

  return [ '', '' ]
endfunction

"  Functions -> s:repo_get_diff_git  {{{2
function! s:repo_get_diff_git(path) abort
  if executable('git')
    let orig_dir = getcwd()
    exe 'cd '. fnamemodify(a:path, ':h')
    let diff = system('git diff --no-ext-diff -U0 -- '. a:path .' | grep "^@@ "')
    if !v:shell_error
      exe 'cd '. orig_dir
      return diff
    endif
    exe 'cd '. orig_dir
  endif
  return ''
endfunction

"  Functions -> s:repo_get_diff_hg  {{{2
function! s:repo_get_diff_hg(path) abort
  if executable('hg')
    let diff = system('hg diff --nodates -U0 -- '. a:path .' | grep "^@@ "')
    return v:shell_error ? '' : diff
  endif
endfunction

"  Functions -> s:repo_get_diff_svn  {{{2
function! s:repo_get_diff_svn(path) abort
  if executable('svn')
    let diff = system('svn diff --diff-cmd diff -x -U0 -- '. a:path .' | grep "^@@ "')
    return v:shell_error ? '' : diff
  endif
endfunction

"  Functions -> s:repo_get_diff_bzr  {{{2
function! s:repo_get_diff_bzr(path) abort
  if executable('bzr')
    let diff = system('bzr diff --using diff --diff-options=-U0 -- '. a:path .' | grep "^@@ "')
    return v:shell_error ? '' : diff
  endif
endfunction

"  Functions -> s:repo_get_diff_darcs  {{{2
function! s:repo_get_diff_darcs(path) abort
  if executable('darcs')
    let orig_dir = getcwd()
    exe 'cd '. fnamemodify(a:path, ':h')
    let diff = system('darcs diff --no-pause-for-gui --diff-command="diff -U0 %1 %2" -- '. a:path .' | grep "^@@ "')
    if !v:shell_error
      exe 'cd '. orig_dir
      return diff
    endif
    exe 'cd '. orig_dir
  endif
  return ''
endfunction

"  Functions -> s:repo_get_diff_cvs  {{{2
function! s:repo_get_diff_cvs(path) abort
  if executable('cvs') && exists('g:signify_enable_cvs') && (g:signify_enable_cvs == 1)
    let diff = system('cvs diff -U0 -- '. a:path .' 2>&1 | grep "^@@ "')
    return v:shell_error ? '' : diff
  endif
endfunction

"  Functions -> s:repo_process_diff()  {{{2
function! s:repo_process_diff(path, diff) abort
  " Determine where we have to put our signs.
  for line in split(a:diff, '\n')
    " Parse diff output.
    let tokens = matchlist(line, '\v^\@\@ -(\d+),?(\d*) \+(\d+),?(\d*)')
    if empty(tokens)
      echo 'signify: I cannot parse this line "'. line .'"'
      return
    endif

    let [ old_line, old_count, new_line, new_count ] = [ str2nr(tokens[1]), (tokens[2] == '') ? 1 : str2nr(tokens[2]), str2nr(tokens[3]), (tokens[4] == '') ? 1 : str2nr(tokens[4]) ]

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

"  Functions -> s:colors_set()  {{{2
function! s:colors_set() abort
  if has('gui_running')
    if exists('g:signify_sign_color_guibg')
      let guibg = g:signify_sign_color_guibg
    endif

    if !exists('guibg')
      let guibg = synIDattr(hlID('SignColumn'), 'bg', 'gui')
    endif

    if exists('g:signify_sign_color_group_add')
      exe 'hi! link SignifyAdd '. g:signify_sign_color_group_add
    else
      let guifg_add = exists('g:signify_sign_color_guifg_add') ? g:signify_sign_color_guifg_add : '#11ee11'
      if empty(guibg) || guibg < 0
        exe 'hi SignifyAdd gui=bold guifg='. guifg_add
      else
        exe 'hi SignifyAdd gui=bold guifg='. guifg_add    .' guibg='. guibg
      endif
    endif

    if exists('g:signify_sign_color_group_delete')
      exe 'hi! link SignifyDelete '. g:signify_sign_color_group_delete
    else
      let guifg_delete = exists('g:signify_sign_color_guifg_delete') ? g:signify_sign_color_guifg_delete : '#ee1111'
      if empty(guibg) || guibg < 0
        exe 'hi SignifyDelete gui=bold guifg='. guifg_delete
      else
        exe 'hi SignifyDelete gui=bold guifg='. guifg_delete .' guibg='. guibg
      endif
    endif

    if exists('g:signify_sign_color_group_change')
      exe 'hi! link SignifyChange '. g:signify_sign_color_group_change
    else
      let guifg_change = exists('g:signify_sign_color_guifg_change') ? g:signify_sign_color_guifg_change : '#eeee11'
      if empty(guibg) || guibg < 0
        exe 'hi SignifyChange gui=bold guifg='. guifg_change
      else
        exe 'hi SignifyChange gui=bold guifg='. guifg_change .' guibg='. guibg
      endif
    endif
  else
    if exists('g:signify_sign_color_ctermbg')
      let ctermbg = g:signify_sign_color_ctermbg
    endif

    if !exists('ctermbg')
      let ctermbg = synIDattr(hlID('SignColumn'), 'bg', 'cterm')
    endif

    if exists('g:signify_sign_color_group_add')
      exe 'hi! link SignifyAdd '. g:signify_sign_color_group_add
    else
      let ctermfg_add = exists('g:signify_sign_color_ctermfg_add') ? g:signify_sign_color_ctermfg_add : 2
      if empty(ctermbg) || ctermbg < 0
        exe 'hi SignifyAdd cterm=bold ctermfg='. ctermfg_add
      else
        exe 'hi SignifyAdd cterm=bold ctermfg='. ctermfg_add    .' ctermbg='. ctermbg
      endif
    endif

    if exists('g:signify_sign_color_group_delete')
      exe 'hi! link SignifyDelete '. g:signify_sign_color_group_delete
    else
      let ctermfg_delete = exists('g:signify_sign_color_ctermfg_delete') ? g:signify_sign_color_ctermfg_delete : 1
      if empty(ctermbg) || ctermbg < 0
        exe 'hi SignifyDelete cterm=bold ctermfg='. ctermfg_delete
      else
        exe 'hi SignifyDelete cterm=bold ctermfg='. ctermfg_delete .' ctermbg='. ctermbg
      endif
    endif

    if exists('g:signify_sign_color_group_change')
      exe 'hi! link SignifyChange '. g:signify_sign_color_group_change
    else
      let ctermfg_change = exists('g:signify_sign_color_ctermfg_change') ? g:signify_sign_color_ctermfg_change : 3
      if empty(ctermbg) || ctermbg < 0
        exe 'hi SignifyChange cterm=bold ctermfg='. ctermfg_change
      else
        exe 'hi SignifyChange cterm=bold ctermfg='. ctermfg_change .' ctermbg='. ctermbg
      endif
    endif
  endif
endfunction

"  Functions -> s:toggle_signify()  {{{2
function! s:toggle_signify() abort
  let path = resolve(expand('%:p'))

  if empty(path)
    echo "signify: I don't sy empty buffers!"
    return
  endif

  if has_key(s:sy, path)
    if (s:sy[path].active == 1)
      let s:sy[path].active = 0
      call s:stop(path)
    else
      let s:sy[path].active = 1
      call s:start(path)
    endif
  endif
endfunction

"  Functions -> s:toggle_line_highlighting()  {{{2
function! s:toggle_line_highlighting() abort
  if s:line_highlight
    sign define SignifyAdd             text=+  texthl=SignifyAdd    linehl=none
    sign define SignifyChange          text=!  texthl=SignifyChange linehl=none
    sign define SignifyChangeDelete    text=!_ texthl=SignifyChange linehl=none
    sign define SignifyDelete          text=_  texthl=SignifyDelete linehl=none
    sign define SignifyDeleteFirstLine text=‾  texthl=SignifyDelete linehl=none

    let s:line_highlight = 0
  else
    let add    = exists('g:signify_line_color_add')    ? g:signify_line_color_add    : 'DiffAdd'
    let delete = exists('g:signify_line_color_delete') ? g:signify_line_color_delete : 'DiffDelete'
    let change = exists('g:signify_line_color_change') ? g:signify_line_color_change : 'DiffChange'

    exe 'sign define SignifyAdd             text=+  texthl=SignifyAdd    linehl='. add
    exe 'sign define SignifyChange          text=!  texthl=SignifyChange linehl='. change
    exe 'sign define SignifyChangeDelete    text=!_ texthl=SignifyChange linehl='. change
    exe 'sign define SignifyDelete          text=_  texthl=SignifyDelete linehl='. delete
    exe 'sign define SignifyDeleteFirstLine text=‾  texthl=SignifyDelete linehl='. delete

    let s:line_highlight = 1
  endif
  call s:start(resolve(expand('%:p')))
endfunction

"  Functions -> s:jump_to_next_hunk()  {{{2
function! s:jump_to_next_hunk(count)
  let path = resolve(expand('%:p'))

  if !has_key(s:sy, path) || s:sy[path].id_jump == -1
    echo "signify: I cannot detect any changes!"
    return
  endif

  if s:sy[path].last_jump_was_next == 0
    let s:sy[path].id_jump += 2
  endif

  let s:sy[path].id_jump += a:count ? (a:count - 1) : 0

  if s:sy[path].id_jump > s:sy[path].id_top
    let s:sy[path].id_jump = s:sy[path].ids[0]
  endif

  exe 'sign jump '. s:sy[path].id_jump .' file='. path

  let s:sy[path].id_jump += 1
  let s:sy[path].last_jump_was_next = 1
endfunction

"  Functions -> s:jump_to_prev_hunk()  {{{2
function! s:jump_to_prev_hunk(count)
  let path = resolve(expand('%:p'))

  if !has_key(s:sy, path) || s:sy[path].id_jump == -1
    echo "signify: I cannot detect any changes!"
    return
  endif

  if s:sy[path].last_jump_was_next == 1
    let s:sy[path].id_jump -= 2
  endif

  let s:sy[path].id_jump -= a:count ? (a:count - 1) : 0

  if s:sy[path].id_jump < s:sy[path].ids[0]
    let s:sy[path].id_jump = s:sy[path].id_top
  endif

  exe 'sign jump '. s:sy[path].id_jump .' file='. path

  let s:sy[path].id_jump -= 1
  let s:sy[path].last_jump_was_next = 0
endfunction

"  Functions -> SignifyDebugListActiveBuffers()  {{{2
function! SignifyDebugListActiveBuffers() abort
  if len(s:sy) == 0
    echo 'No active buffers!'
    return
  endif

  for i in items(s:sy)
    echo i
  endfor
endfunction

" vim:set et sw=2 sts=2:
