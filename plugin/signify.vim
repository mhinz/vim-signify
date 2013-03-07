if exists('g:loaded_signify') || &cp
  finish
endif
let g:loaded_signify = 1

"  Default values  {{{1
let s:line_highlight_b   = 0
let s:colors_set_b       = 0
let s:last_jump_was_next = -1
let s:active_buffers     = {}

let s:id_start = 0x100
let s:id_top   = s:id_start
let s:id_jump  = s:id_start

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
    sign define SignifyAdd text=>> texthl=SignifyAdd linehl=none
endif

if exists('g:signify_sign_delete')
    exe 'sign define SignifyDelete text='. g:signify_sign_delete .' texthl=SignifyDelete linehl=none'
else
    sign define SignifyDelete text=<< texthl=SignifyDelete linehl=none
endif

if exists('g:signify_sign_change')
    exe 'sign define SignifyChange text='. g:signify_sign_change .' texthl=SignifyChange linehl=none'
else
    sign define SignifyChange text=!! texthl=SignifyChange linehl=none
endif

"  Initial stuff  {{{1
aug signify
    au!
    au ColorScheme  * call s:set_colors()
    au BufWritePost * call s:start()
    au BufEnter     * let s:colors_set_b = 0 | call s:start()
    au BufDelete    * call s:stop() | call s:remove_from_buffer_list(expand('%:p'))
aug END

com! -nargs=0 -bar SignifyToggle          call s:toggle_signify()
com! -nargs=0 -bar SignifyToggleHighlight call s:toggle_line_highlighting()
com! -nargs=0 -bar SignifyJumpToNextHunk  call s:jump_to_next_hunk()
com! -nargs=0 -bar SignifyJumpToPrevHunk  call s:jump_to_prev_hunk()

"  Internal functions  {{{1
"  Functions -> s:start()  {{{2
function! s:start() abort
    let l:path = expand('%:p')

    if empty(l:path) || &ft == 'help'
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
            if i == expand('%')
                return
            endif
        endfor
    endif

    " New buffer.. add to list.
    if !has_key(s:active_buffers, l:path)
        let s:active_buffers[l:path] = 1
    " Inactive buffer.. bail out.
    elseif get(s:active_buffers, l:path) == 0
        return
    endif

    " Is a diff available?
    let diff = s:get_diff(l:path)
    if empty(diff)
        sign unplace *
        return
    endif

    " Set colors only for the first time or when a new colorscheme is set.
    if !s:colors_set_b
        call s:set_colors()
        let s:colors_set_b = 1
    endif

    " Use git's diff cmd to set our signs.
    call s:process_diff(diff)
endfunction

"  Functions -> s:stop()  {{{2
function! s:stop() abort
    sign unplace *
    aug signify
        au! * <buffer>
    aug END
endfunction

"  Functions -> s:get_diff()  {{{2
function! s:get_diff(path) abort
    if !executable('grep')
        echoerr "signify: I cannot work without grep!"
        finish
    endif

    if executable('git')
        let diff = system('git diff --no-ext-diff -U0 '. fnameescape(a:path) .'| grep "^@@ "')
        if !v:shell_error
            return diff
        endif
    endif

    if executable('hg')
        let diff = system('hg diff --nodates -U0 '. fnameescape(a:path) .'| grep "^@@ "')
        if !v:shell_error
            return diff
        endif
    endif

    if executable('diff')
        if executable('svn')
            let diff = system('svn diff --diff-cmd diff -x -U0 '. fnameescape(a:path) .'| grep "^@@ "')
            if !v:shell_error
                return diff
            endif
        endif

        if executable('bzr')
            let diff = system('bzr diff --using diff --diff-options=-U0 '. fnameescape(a:path) .'| grep "^@@ "')
            if !v:shell_error
                return diff
            endif
        endif
    endif

    return []
endfunction

"  Functions -> s:toggle_signify()  {{{2
function! s:toggle_signify() abort
    let l:path = expand('%:p')
    if has_key(s:active_buffers, l:path) && get(s:active_buffers, l:path) == 1
        call s:stop()
        let s:active_buffers[l:path] = 0
    else
        let s:active_buffers[l:path] = 1
        call s:start()
    endif
endfunction

"  Functions -> s:set_colors()  {{{2
func! s:set_colors() abort
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

"  Functions -> s:process_diff()  {{{2
function! s:process_diff(diff) abort
    let s:id_top = s:id_start
    let l:path = expand('%:p')

    sign unplace *

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
                exe 'sign place '. s:id_top .' line='. (new_line + offset) .' name=SignifyAdd file='. l:path
                let [ offset, s:id_top ] += [ 1, 1 ]
            endwhile
        " An old line was removed.
        elseif (old_count >= 1) && (new_count == 0)
            exe 'sign place '. s:id_top .' line='. new_line .' name=SignifyDelete file='. l:path
            let s:id_top += 1
        " A line was changed.
        else
            let offset = 0
            while offset < new_count
                exe 'sign place '. s:id_top .' line='. (new_line + offset) .' name=SignifyChange file='. l:path
                let [ offset, s:id_top ] += [ 1, 1 ]
            endwhile
        endif
    endfor
endfunction

"  Functions -> s:toggle_line_highlighting()  {{{2
function! s:toggle_line_highlighting() abort
    if s:line_highlight_b
        sign define SignifyAdd    text=>> texthl=SignifyAdd    linehl=none
        sign define SignifyChange text=!! texthl=SignifyChange linehl=none
        sign define SignifyDelete text=<< texthl=SignifyDelete linehl=none
        let s:line_highlight_b = 0
    else
        sign define SignifyAdd    text=>> texthl=SignifyAdd    linehl=DiffAdd
        sign define SignifyDelete text=<< texthl=SignifyRemove linehl=DiffDelete
        sign define SignifyChange text=!! texthl=SignifyChange linehl=DiffChange
        let s:line_highlight_b = 1
    endif
    call s:start()
endfunction

"  Functions -> s:jump_to_next_hunk()  {{{2
function! s:jump_to_next_hunk()
    if s:last_jump_was_next == 0
        let s:id_jump += 2
    endif
    exe 'sign jump '. s:id_jump .' file='. expand('%:p')
    let s:id_jump = (s:id_jump == (s:id_top - 1)) ? (s:id_start) : (s:id_jump + 1)
    let s:last_jump_was_next = 1
endfunction

"  Functions -> s:jump_to_prev_hunk()  {{{2
function! s:jump_to_prev_hunk()
    if s:last_jump_was_next == 1
        let s:id_jump -= 2
    endif
    exe 'sign jump '. s:id_jump .' file='. expand('%:p')
    let s:id_jump = (s:id_jump == s:id_start) ? (s:id_top - 1) : (s:id_jump - 1)
    let s:last_jump_was_next = 0
endfunction

"  Functions -> s:remove_from_buffer_list()  {{{2
function! s:remove_from_buffer_list(path) abort
    if has_key(s:active_buffers, a:path)
        call remove(s:active_buffers, a:path)
    endif
endfunction

"  Functions -> SignifyListActiveBuffers()  {{{2
function! SignifyListActiveBuffers() abort
    if len(s:active_buffers) == 0
        echo 'No active buffers!'
        return
    endif

    for i in items(s:active_buffers)
        echo i
    endfor
endfunction
