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
  if g:signify_locked
    return
  endif

  if &diff
        \ || !filereadable(a:path)
        \ || (exists('g:signify_skip_filetype') && has_key(g:signify_skip_filetype, &ft))
        \ || (exists('g:signify_skip_filename') && has_key(g:signify_skip_filename, a:path))
    return
  endif

  " new buffer.. add to list of registered files
  if !exists('b:sy') || b:sy.path != a:path
    let b:sy = { 'path': a:path, 'buffer': bufnr(''), 'active': 0, 'type': 'unknown', 'hunks': [], 'id_top': g:id_top, 'stats': [-1, -1, -1] }
    if get(g:, 'signify_disable_by_default')
      return
    endif

    " register buffer as active
    let b:sy.active = 1

    let [ diff, b:sy.type ] = sy#repo#detect()
    if b:sy.type == 'unknown'
      return
    endif

    " register file as active with found VCS
    let b:sy.stats = [0, 0, 0]

    let dir = fnamemodify(b:sy.path, ':h')
    if !has_key(g:sy_cache, dir)
      let g:sy_cache[dir] = b:sy.type
    endif

    if empty(diff)
      " no changes found
      return
    endif

  " inactive buffer.. bail out
  elseif !b:sy.active
    return

  " retry detecting VCS
  elseif b:sy.type == 'unknown'
    let [ diff, b:sy.type ] = sy#repo#detect()
    if b:sy.type == 'unknown'
      " no VCS found
      return
    endif

  " update signs
  else
    let diff = sy#repo#get_diff_{b:sy.type}()[1]
    if empty(diff)
      call sy#sign#remove_all(b:sy.buffer)
      return
    endif
    let b:sy.id_top = g:id_top
  endif

  if get(g:, 'signify_line_highlight')
      call sy#highlight#line_enable()
  else
      call sy#highlight#line_disable()
  endif

  execute 'sign place 99999 line=1 name=SignifyPlaceholder buffer='. b:sy.buffer
  call sy#sign#remove_all(b:sy.buffer)

  if !g:signify_sign_overwrite
    call sy#sign#get_others()
  endif

  call sy#repo#process_diff(diff)
  sign unplace 99999

  let b:sy.id_top = (g:id_top - 1)
endfunction

" Function: #stop {{{1
function! sy#stop(bnum) abort
  let bvars = getbufvar(a:bnum, '')
  if empty(bvars) || !has_key(bvars, 'sy')
    return
  endif

  call sy#sign#remove_all(a:bnum)

  augroup signify
    execute 'autocmd! * <buffer='. a:bnum .'>'
  augroup END
endfunction

" Function: #toggle {{{1
function! sy#toggle() abort
  if !exists('b:sy') || empty(b:sy.path)
    echomsg 'signify: I cannot sy empty buffers!'
    return
  endif

  if b:sy.active
    call sy#stop(b:sy.buffer)
    let b:sy.active = 0
    let b:sy.stats = [-1, -1, -1]
  else
    let b:sy.active = 1
    call sy#start(b:sy.path)
  endif
endfunction
