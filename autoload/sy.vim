if exists('b:autoloaded_sy')
    finish
endif
let b:autoloaded_sy = 1

" Init: values {{{1
let g:signify_sign_overwrite = get(g:, 'signify_sign_overwrite', 1)
let g:id_top = 0x100

sign define SignifyPlaceholder text=. texthl=SignifySignChange linehl=NONE

" Function: #start {{{1
function! sy#start(path) abort
  if &diff
        \ || !filereadable(a:path)
        \ || (exists('g:signify_skip_filetype') && has_key(g:signify_skip_filetype, &ft))
        \ || (exists('g:signify_skip_filename') && has_key(g:signify_skip_filename, a:path))
    return
  endif

  " new buffer.. add to list
  if !has_key(g:sy, a:path)
    let [ diff, type ] = sy#repo#detect(a:path)
    if empty(diff)
      return
    endif
    if get(g:, 'signify_disable_by_default')
      let g:sy[a:path] = { 'active': 0, 'type': type, 'hunks': [], 'id_top': g:id_top }
      return
    endif
    let g:sy[a:path] = { 'active': 1, 'type': type, 'hunks': [], 'id_top': g:id_top }
  " inactive buffer.. bail out
  elseif !g:sy[a:path].active
    return
  " update signs
  else
    let diff = sy#repo#get_diff_{g:sy[a:path].type}(a:path)
    if empty(diff)
      call sy#sign#remove_all(a:path)
      return
    endif
    let g:sy[a:path].id_top = g:id_top
  endif

  if get(g:, 'signify_line_highlight')
      call sy#highlight#line_enable()
  else
      call sy#highlight#line_disable()
  endif

  if !g:signify_sign_overwrite
    call sy#sign#get_others(a:path)
  endif

  execute 'sign place 99999 line=1 name=SignifyPlaceholder file='. a:path
  call sy#sign#remove_all(a:path)
  call sy#repo#process_diff(a:path, diff)
  sign unplace 99999

  if !maparg('[c', 'n')
    nnoremap <buffer><silent> ]c :<c-u>execute v:count1 .'SignifyJumpToNextHunk'<cr>
    nnoremap <buffer><silent> [c :<c-u>execute v:count1 .'SignifyJumpToPrevHunk'<cr>
  endif

  let g:sy[a:path].id_top = (g:id_top - 1)
endfunction

" vim: et sw=2 sts=2
" Function: #stop {{{1
function! sy#stop(path) abort
  if !has_key(g:sy, a:path)
    return
  endif

  call sy#sign#remove_all(a:path)

  silent! nunmap <buffer> ]c
  silent! nunmap <buffer> [c

  augroup signify
    autocmd! * <buffer>
  augroup END
endfunction

" Function: #toggle {{{1
function! sy#toggle() abort
  if empty(g:sy_path)
    echomsg 'signify: I cannot sy empty buffers!'
    return
  endif

  if has_key(g:sy, g:sy_path)
    if g:sy[g:sy_path].active
      call sy#stop(g:sy_path)
      let g:sy[g:sy_path].active = 0
    else
      let g:sy[g:sy_path].active = 1
      call sy#start(g:sy_path)
    endif
  else
    call sy#start(g:sy_path)
  endif
endfunction

" vim: et sw=2 sts=2
