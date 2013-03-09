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
let s:line_highlight           = 0   " disable line highlighting
let s:colors_set               = 0   " do colors have to be reset?
let s:last_jump_was_next       = -1  " last movement was next or prev?

let s:other_signs_line_numbers = {}  " holds IDs of other signs
let s:sy                       = {}  " the main data structure

" overwrite non-signify signs by default
let s:sign_overwrite = exists('g:signify_sign_overwrite') ? g:signify_sign_overwrite : 1

let s:id_start = 0x100
let s:id_top   = s:id_start

"  Default mappings  {{{1
if exists('g:signify_mapping_next_hunk')
    exe 'nnoremap '. g:signify_mapping_next_hunk .' :SignifyJumpToNextHunk<cr>'
else
    nnoremap <leader>gn :SignifyJumpToNextHunk<cr>
endif

if exists('g:signify_mapping_prev_hunk')
    exe 'nnoremap '. g:signify_mapping_prev_hunk .' :SignifyJumpToPrevHunk<cr>'
else
    nnoremap <leader>gp :SignifyJumpToPrevHunk<cr>
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

if exists('g:signify_sign_change')
    exe 'sign define SignifyChange text='. g:signify_sign_change .' texthl=SignifyChange linehl=none'
else
    sign define SignifyChange text=! texthl=SignifyChange linehl=none
endif

"  Initial stuff  {{{1
aug signify
    au!
    au ColorScheme              * call s:colors_set()
    au BufWritePost,FocusGained * call s:start(resolve(expand('<afile>:p')))
    au BufEnter                 * let s:colors_set = 0 | call s:start(resolve(expand('<afile>:p')))
aug END

com! -nargs=0 -bar SignifyToggle          call s:toggle_signify()
com! -nargs=0 -bar SignifyToggleHighlight call s:toggle_line_highlighting()
com! -nargs=0 -bar SignifyJumpToNextHunk  call s:jump_to_next_hunk()
com! -nargs=0 -bar SignifyJumpToPrevHunk  call s:jump_to_prev_hunk()

"  Internal functions  {{{1
"  Functions -> s:start()  {{{2
function! s:start(path) abort
    if empty(a:path) || &ft == 'help'
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

    " Is a diff available?
    let diff = s:diff_get(a:path)
    if empty(diff)
        if has_key(s:sy, a:path)
            call s:sign_remove_all(a:path)
        endif
        return
    endif

    " New buffer.. add to list.
    if !has_key(s:sy, a:path)
        let s:sy[a:path] = { 'active': 1, 'ids': [], 'id_jump': s:id_top, 'id_top': s:id_top, 'last_jump_was_next': -1 }
    " Inactive buffer.. bail out.
    elseif s:sy[a:path].active == 0
        return
    " Update active buffer.. reset default values
    else
        call s:sign_remove_all(a:path)
        let s:sy[a:path].id_top  = s:id_top
        let s:sy[a:path].id_jump = s:id_top
        let s:sy[a:path].last_jump_was_next = -1
    endif

    if s:sign_overwrite == 0
        call s:sign_get_others(a:path)
    endif

    " Set colors only for the first time or when a new colorscheme is set.
    if !s:colors_set
        call s:colors_set()
        let s:colors_set = 1
    endif

    " Use git's diff cmd to set our signs.
    call s:process_diff(a:path, diff)

    let s:sy[a:path].id_top = (s:id_top - 1)
endfunction

"  Functions -> s:stop()  {{{2
function! s:stop(path) abort
    if !has_key(s:sy, a:path)
        return
    endif

    call s:sign_remove_all(a:path)

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
        if line =~ '^\s\+line'
            let [ lnum, id ] = matchlist(line, '\vline\=(\d+)\s+id\=(\d+)')[1:2]
            let s:other_signs_line_numbers[lnum] = id
        endif
    endfor
endfunction

"  Functions -> s:sign_set()  {{{2
function! s:sign_set(lnum, type, path)
    " Preserve non-signify signs
    if get(s:other_signs_line_numbers, a:lnum) == 1
        return
    endif

    call add(s:sy[a:path].ids, s:id_top)
    exe 'sign place '. s:id_top .' line='. a:lnum .' name='. a:type .' file='. a:path

    let s:id_top += 1
endfunction

"  Functions -> s:sign_remove_all()  {{{2
function! s:sign_remove_all(path) abort
    for id in s:sy[a:path].ids
        exe 'sign unplace '. id
    endfor

    let s:other_signs_line_numbers = {}
    let s:sy[a:path].ids = []
endfunction

"  Functions -> s:diff_get()  {{{2
function! s:diff_get(path) abort
    if !executable('grep')
        echoerr 'signify: I cannot work without grep!'
        return
    endif

    if executable('git')
        let orig_dir = getcwd()
        let wt = fnamemodify(a:path, ':h')
        exe 'cd '. wt
        let gd = system('git rev-parse --git-dir')[:-2]  " remove newline
        if v:shell_error
            echom 'signify: I cannot find the .git dir!'
            return []
        endif
        let wt = fnamemodify(gd, ':h')
        let diff = system('git --work-tree '. wt .' --git-dir '. gd .' diff --no-ext-diff -U0 -- '. a:path .' | grep "^@@ "')
        if !v:shell_error
            exe 'cd '. orig_dir
            return diff
        endif
        exe 'cd '. orig_dir
    endif

    if executable('hg')
        let diff = system('hg diff --nodates -U0 '. a:path .' | grep "^@@ "')
        if !v:shell_error
            return diff
        endif
    endif

    if executable('diff')
        if executable('svn')
            let diff = system('svn diff --diff-cmd diff -x -U0 '. a:path .' | grep "^@@ "')
            if !v:shell_error
                return diff
            endif
        endif

        if executable('bzr')
            let diff = system('bzr diff --using diff --diff-options=-U0 '. a:path .' | grep "^@@ "')
            if !v:shell_error
                return diff
            endif
        endif
    endif

    if executable('cvs')
        let diff = system('cvs diff -U0 '. a:path .' 2>&1 | grep "^@@ "')
        if !empty(diff)
            return diff
        endif
    endif

    return []
endfunction

"  Functions -> s:process_diff()  {{{2
function! s:process_diff(path, diff) abort
    " Determine where we have to put our signs.
    for line in split(a:diff, '\n')
        " Parse diff output.
        let tokens = matchlist(line, '\v^\@\@ -(\d+),?(\d*) \+(\d+),?(\d*)')
        if empty(tokens)
            echoerr 'signify: I cannot parse this line "'. line .'"'
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
            call s:sign_set(new_line, 'SignifyDelete', a:path)
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
                call s:sign_set(new_line + offset - 1, 'SignifyDelete', a:path)
            " (old_count < new_count): Lines were added && changed.
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
func! s:colors_set() abort
    if has('gui_running')
        let guifg_add    = exists('g:signify_color_sign_guifg_add')    ? g:signify_color_sign_guifg_add    : '#11ee11'
        let guifg_delete = exists('g:signify_color_sign_guifg_delete') ? g:signify_color_sign_guifg_delete : '#ee1111'
        let guifg_change = exists('g:signify_color_sign_guifg_change') ? g:signify_color_sign_guifg_change : '#eeee11'

        if exists('g:signify_color_sign_guibg')
            let guibg = g:signify_color_sign_guibg
        endif

        if !exists('guibg')
            let guibg = synIDattr(hlID('LineNr'), 'bg', 'gui')
        endif

        if empty(guibg) || guibg < 0
            exe 'hi SignifyAdd    gui=bold guifg='. guifg_add
            exe 'hi SignifyDelete gui=bold guifg='. guifg_delete
            exe 'hi SignifyChange gui=bold guifg='. guifg_change
        else
            exe 'hi SignifyAdd    gui=bold guifg='. guifg_add    .' guibg='. guibg
            exe 'hi SignifyDelete gui=bold guifg='. guifg_delete .' guibg='. guibg
            exe 'hi SignifyChange gui=bold guifg='. guifg_change .' guibg='. guibg
        endif
    else
        let ctermfg_add    = exists('g:signify_color_sign_ctermfg_add')    ? g:signify_color_sign_ctermfg_add    : 2
        let ctermfg_delete = exists('g:signify_color_sign_ctermfg_delete') ? g:signify_color_sign_ctermfg_delete : 1
        let ctermfg_change = exists('g:signify_color_sign_ctermfg_change') ? g:signify_color_sign_ctermfg_change : 3

        if exists('g:signify_color_sign_ctermbg')
            let ctermbg = g:signify_color_sign_ctermbg
        endif

        if !exists('ctermbg')
            let ctermbg = synIDattr(hlID('LineNr'), 'bg', 'cterm')
        endif

        if empty(ctermbg) || ctermbg < 0
            exe 'hi SignifyAdd    cterm=bold ctermfg='. ctermfg_add
            exe 'hi SignifyDelete cterm=bold ctermfg='. ctermfg_delete
            exe 'hi SignifyChange cterm=bold ctermfg='. ctermfg_change
        else
            exe 'hi SignifyAdd    cterm=bold ctermfg='. ctermfg_add    .' ctermbg='. ctermbg
            exe 'hi SignifyDelete cterm=bold ctermfg='. ctermfg_delete .' ctermbg='. ctermbg
            exe 'hi SignifyChange cterm=bold ctermfg='. ctermfg_change .' ctermbg='. ctermbg
        endif
    endif
endfunc

"  Functions -> s:toggle_signify()  {{{2
function! s:toggle_signify() abort
    let path = resolve(expand('%:p'))

    if empty(path)
        echoerr "signify: I don't sy empty buffers!"
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
        sign define SignifyAdd    text=+ texthl=SignifyAdd    linehl=none
        sign define SignifyDelete text=_ texthl=SignifyDelete linehl=none
        sign define SignifyChange text=! texthl=SignifyChange linehl=none
        let s:line_highlight = 0
    else
        let add    = exists('g:signify_color_line_highlight_add')    ? g:signify_color_line_highlight_add    : 'DiffAdd'
        let delete = exists('g:signify_color_line_highlight_delete') ? g:signify_color_line_highlight_delete : 'DiffDelete'
        let change = exists('g:signify_color_line_highlight_change') ? g:signify_color_line_highlight_change : 'DiffChange'

        exe 'sign define SignifyAdd    text=+ texthl=SignifyAdd    linehl='. add
        exe 'sign define SignifyDelete text=_ texthl=SignifyDelete linehl='. delete
        exe 'sign define SignifyChange text=! texthl=SignifyChange linehl='. change
        let s:line_highlight = 1
    endif
    call s:start(resolve(expand('%:p')))
endfunction

"  Functions -> s:jump_to_next_hunk()  {{{2
function! s:jump_to_next_hunk()
    let path = resolve(expand('%:p'))

    if s:sy[path].last_jump_was_next == 0
        let s:sy[path].id_jump += 2
    endif

    if s:sy[path].id_jump > s:sy[path].id_top
        let s:sy[path].id_jump = s:sy[path].ids[0]
    endif

    exe 'sign jump '. s:sy[path].id_jump .' file='. path

    let s:sy[path].id_jump += 1
    let s:sy[path].last_jump_was_next = 1
endfunction

"  Functions -> s:jump_to_prev_hunk()  {{{2
function! s:jump_to_prev_hunk()
    let path = resolve(expand('%:p'))

    if s:sy[path].last_jump_was_next == 1
        let s:sy[path].id_jump -= 2
    endif

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

"  Functions -> SignifyDebugID()  {{{2
function! SignifyDebugID() abort
    echo [ s:id_start, s:id_top ]
endfunction
