" vim: et sw=2 sts=2

scriptencoding utf-8

" Init: values {{{1
let g:signify_sign_overwrite = get(g:, 'signify_sign_overwrite')
if g:signify_sign_overwrite && (v:version < 703 || (v:version == 703 && !has('patch596')))
  echohl WarningMsg
  echomsg 'signify: Sign overwriting was disabled. See :help signify-option-sign_overwrite'
  echohl NONE
  let g:signify_sign_overwrite = 0
endif

let g:id_top = 0x100
let g:sy_cache = {}

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
      " register file as inactive
      let g:sy[a:path] = { 'active': 0, 'type': 'unknown', 'hunks': [], 'id_top': g:id_top, 'stats': [-1, -1, -1] }
      return
    endif

    let [ diff, type ] = sy#repo#detect(a:path)
    if type == 'unknown'
      " register file as active with no found VCS
      let g:sy[a:path] = { 'active': 1, 'type': 'unknown', 'hunks': [], 'id_top': g:id_top, 'stats': [0, 0, 0] }
      return
    endif

    " register file as active with found VCS
    let g:sy[a:path] = { 'active': 1, 'type': type, 'hunks': [], 'id_top': g:id_top, 'stats': [0, 0, 0] }

    let dir = fnamemodify(a:path, ':h')
    if !has_key(g:sy_cache, dir)
      let g:sy_cache[dir] = type
    endif

    if empty(diff)
      " no changes found
      return
    endif

  " inactive buffer.. bail out
  elseif !g:sy[a:path].active
    return

  " retry detecting VCS
  elseif g:sy[a:path].type == 'unknown'
    let [ diff, type ] = sy#repo#detect(a:path)
    if type == 'unknown'
      " no VCS found
      return
    endif
    let g:sy[a:path].type = type

  " update signs
  else
    let diff = sy#repo#get_diff_{g:sy[a:path].type}(a:path)[1]
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

  execute 'sign place 99999 line=1 name=SignifyPlaceholder file='. a:path
  call sy#sign#remove_all(a:path)

  if !g:signify_sign_overwrite
    call sy#sign#get_others(a:path)
  endif

  call sy#repo#process_diff(a:path, diff)
  sign unplace 99999

  let g:sy[a:path].id_top = (g:id_top - 1)
endfunction

" Function: #stop {{{1
function! sy#stop(path) abort
  if !has_key(g:sy, a:path)
    return
  endif

  call sy#sign#remove_all(a:path)

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
