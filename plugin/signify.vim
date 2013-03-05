if exists('g:loaded_signify') || !executable('git') || &cp
  finish
endif
let g:loaded_signify = 1

"  Default values  {{{1
let s:line_highlight_b = 0
let s:colors_set_b     = 0
let s:active_buffers   = {}

let s:id_start = 0x100
let s:id_top   = s:id_start
let s:id_jump  = s:id_start

"  Default mappings  {{{1
if exists('g:signify_mapping_next_change')
    exe 'nnoremap '. g:signify_mapping_next_change .' :SignifyJumpToNextChange<cr>'
else
    nnoremap <leader>gn :SignifyJumpToNextChange<cr>
endif

if exists('g:signify_mapping_prev_change')
    exe 'nnoremap '. g:signify_mapping_prev_change .' :SignifyJumpToPrevChange<cr>'
else
    nnoremap <leader>gp :SignifyJumpToPrevChange<cr>
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
    au BufDelete    * call s:stop() | call remove(s:active_buffers, expand('%:p'))
aug END

com! -nargs=0 -bar SignifyToggle           call s:toggle_signify()
com! -nargs=0 -bar SignifyToggleHighlight  call s:toggle_line_highlighting()
com! -nargs=0 -bar SignifyJumpToNextChange call s:jump_to_next_change()
com! -nargs=0 -bar SignifyJumpToPrevChange call s:jump_to_prev_change()

"  Internal functions  {{{1
"  Functions -> s:start()  {{{2
function! s:start() abort
    let l:path = expand('%:p')

    if empty(l:path) || &ft == 'help'
        return
    endif

    " New buffer.. add to list.
    if !has_key(s:active_buffers, l:path)
        let s:active_buffers[l:path] = 1
    " Inactive buffer.. bail out.
    elseif get(s:active_buffers, l:path) == 0
        return
    endif

    " Is a diff available?
    let s:diff = system('git diff --no-ext-diff -U0 '. fnameescape(l:path) .'| grep "^@@ "')
    if v:shell_error
        sign unplace *
        return
    endif

    " Set colors only for the first time or when a new colorscheme is set.
    if !s:colors_set_b
        call s:set_colors()
        let s:colors_set_b = 1
    endif

    " Use git's diff cmd to set our signs.
    call s:process_diff(s:diff)
endfunction

"  Functions -> s:stop()  {{{2
function! s:stop() abort
    sign unplace *
    aug signify
        au! * <buffer>
    aug END
    let s:active_buffers[expand('%:p')] = 0
endfunction

"  Functions -> s:toggle_signify()  {{{2
function! s:toggle_signify() abort
    let l:path = expand('%:p')
    if has_key(s:active_buffers, l:path) && get(s:active_buffers, l:path) == 1
        call s:stop()
        let s:active_buffers[l:path] = 0
        echom 'signify: stopped!'
    else
        let s:active_buffers[l:path] = 1
        call s:start()
        echom 'signify: started!'
    endif
endfunction

"  Functions -> s:set_colors()  {{{2
func! s:set_colors() abort
    if has('gui_running')
        let guibg = synIDattr(hlID('LineNr'), 'bg', 'gui')
        if empty(guibg)
            hi SignifyAdd    gui=bold guifg=#11ee11
            hi SignifyDelete gui=bold guifg=#ee1111
            hi SignifyChange gui=bold guifg=#eeee11
        else
            exe 'hi SignifyAdd    gui=bold guifg=#11ee11 guibg='. guibg
            exe 'hi SignifyDelete gui=bold guifg=#ee1111 guibg='. guibg
            exe 'hi SignifyChange gui=bold guifg=#eeee11 guibg='. guibg
        endif
    else
        let ctermbg = synIDattr(hlID('LineNr'), 'bg', 'cterm')
        if empty(ctermbg)
            hi SignifyAdd    cterm=bold ctermfg=2
            hi SignifyDelete cterm=bold ctermfg=1
            hi SignifyChange cterm=bold ctermfg=3
        else
            exe 'hi SignifyAdd    cterm=bold ctermfg=2 ctermbg='. ctermbg
            exe 'hi SignifyDelete cterm=bold ctermfg=1 ctermbg='. ctermbg
            exe 'hi SignifyChange cterm=bold ctermfg=3 ctermbg='. ctermbg
        endif
    endif
endfunc

"  Functions -> s:process_diff()  {{{2
function! s:process_diff(diff) abort
    sign unplace *
    let s:id_top = s:id_start
    " Determine where we have to put our signs.
    for line in split(a:diff, '\n')
        " Parse diff output.
        let tokens = matchlist(line, '\v^\@\@ -(\d+),?(\d*) \+(\d+),?(\d*)')
        if empty(tokens)
            echoerr 'signify: Could not parse this line "'. line .'"'
        endif

        let [ old_line, old_count, new_line, new_count ] = [ str2nr(tokens[1]), (tokens[2] == '') ? 1 : str2nr(tokens[2]), str2nr(tokens[3]), (tokens[4] == '') ? 1 : str2nr(tokens[4]) ]

        " A new line was added.
        if (old_count == 0) && (new_count >= 1)
            let offset = 0
            while offset < new_count
                exe 'sign place '. s:id_top .' line='. (new_line + offset) .' name=SignifyAdd file='. expand('%:p')
                let [ offset, s:id_top ] += [ 1, 1 ]
            endwhile
        " An old line was removed.
        elseif (old_count >= 1) && (new_count == 0)
            exe 'sign place '. s:id_top .' line='. old_line .' name=SignifyDelete file='. expand('%:p')
            let s:id_top += 1
        " A line was changed.
        else
            let offset = 0
            while offset < new_count
                exe 'sign place '. s:id_top .' line='. (new_line + offset) .' name=SignifyChange file='. expand('%:p')
                let [ offset, s:id_top ] += [ 1, 1 ]
            endwhile
        endif
    endfor
endfunction
"  Functions -> s:toggle_line_highlighting()  {{{2
function! s:toggle_line_highlighting() abort
    if s:line_highlight_b
        sign define SignifyAdd    text=+ texthl=SignifyAdd    linehl=none
        sign define SignifyChange text=* texthl=SignifyChange linehl=none
        sign define SignifyDelete text=- texthl=SignifyDelete linehl=none
        let s:line_highlight_b = 0
    else
        sign define SignifyAdd    text=+ texthl=SignifyAdd    linehl=DiffAdd
        sign define SignifyChange text=* texthl=SignifyChange linehl=DiffChange
        sign define SignifyDelete text=- texthl=SignifyRemove linehl=DiffDelete
        let s:line_highlight_b = 1
    endif
    call s:start()
endfunction

"  Functions -> s:jump_to_next_change()  {{{2
function! s:jump_to_next_change()
    exe 'sign jump '. s:id_jump .' file='. expand('%:p')
    let s:id_jump = ((s:id_jump + 1) == s:id_top) ? (s:id_start) : (s:id_jump + 1)
endfunction

"  Functions -> s:jump_to_prev_change()  {{{2
function! s:jump_to_prev_change()
    exe 'sign jump '. s:id_jump .' file='. expand('%:p')
    let s:id_jump = (s:id_jump == s:id_start) ? (s:id_top - 1) : (s:id_jump - 1)
endfunction
