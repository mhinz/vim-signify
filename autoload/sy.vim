scriptencoding utf-8

if exists('b:autoloaded_sy')
    finish
endif
let b:autoloaded_sy = 1

" Init: values {{{1
let g:signify_sign_overwrite = get(g:, 'signify_sign_overwrite', 1)
let g:id_top = 0x100

sign define SignifyPlaceholder text=. texthl=SignifySignChange linehl=

" Function: #start {{{1
function! sy#start(path) abort
  if &diff
        \ || !filereadable(a:path)
        \ || (exists('g:signify_skip_filetype') && has_key(g:signify_skip_filetype, &ft))
        \ || (exists('g:signify_skip_filename') && has_key(g:signify_skip_filename, a:path))
    return
  endif

  " new buffer.. add to list of registered files
  if !has_key(g:sy, a:path)
    if get(g:, 'signify_disable_by_default')
      let g:sy[a:path] = { 'active': 0, 'type': 'unknown', 'hunks': [], 'id_top': g:id_top, 'stats': [-1, -1, -1] }
      return
    endif

    let [ diff, type ] = sy#repo#detect(a:path)
    if empty(diff)
      " register file as active with either no changes or no found VCS
      let g:sy[a:path] = { 'active': 1, 'type': 'unknown', 'hunks': [], 'id_top': g:id_top, 'stats': [0, 0, 0] }
      return
    endif

    " register file as active and containing changes
    let g:sy[a:path] = { 'active': 1, 'type': type, 'hunks': [], 'id_top': g:id_top, 'stats': [0, 0, 0] }

  " inactive buffer.. bail out
  elseif !g:sy[a:path].active
    return

  " retry detecting changes or VCS
  elseif g:sy[a:path].type == 'unknown'
    let [ diff, type ] = sy#repo#detect(a:path)
    if empty(diff)
      " no changes or VCS found
      return
    endif
    let g:sy[a:path].type = type

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
      let g:sy[g:sy_path].stats = [-1, -1, -1]
    else
      let g:sy[g:sy_path].active = 1
      call sy#start(g:sy_path)
    endif
  else
    call sy#start(g:sy_path)
  endif
endfunction

" vim: et sw=2 sts=2
