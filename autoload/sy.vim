" vim: et sw=2 sts=2

scriptencoding utf-8

" Init: values {{{1
let g:id_top = 0x100
let g:sy_cache = {}

" Function: #start {{{1
function! sy#start() abort
  if g:signify_locked
    return
  endif

  let b:sy_path = resolve(expand('%:p'))

  if &diff
        \ || !filereadable(b:sy_path)
        \ || (exists('g:signify_skip_filetype') && (has_key(g:signify_skip_filetype, &ft)
        \                                       || (has_key(g:signify_skip_filetype, 'help')
        \                                       && &bt == 'help')))
        \ || (exists('g:signify_skip_filename') && has_key(g:signify_skip_filename, b:sy_path))
    return
  endif

  " sy_info is used in autoload/sy/repo
  if !exists('b:sy_info')
    let b:sy_info = {
          \ 'chdir': haslocaldir() ? 'lcd' : 'cd',
          \ 'cwd':   getcwd(),
          \ 'dir':   fnamemodify(b:sy_path, ':p:h'),
          \ 'path':  sy#util#escape(b:sy_path),
          \ 'file':  sy#util#escape(fnamemodify(b:sy_path, ':t')),
          \ }
  endif

  " new buffer.. add to list of registered files
  if !exists('b:sy') || b:sy.path != b:sy_path
    let b:sy = {
          \ 'path'  : b:sy_path,
          \ 'buffer': bufnr(''),
          \ 'active': 0,
          \ 'type'  : 'unknown',
          \ 'hunks' : [],
          \ 'id_top': g:id_top,
          \ 'stats' : [-1, -1, -1] }
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
    let b:sy.id_top = g:id_top
  endif

  if get(g:, 'signify_line_highlight')
    call sy#highlight#line_enable()
  else
    call sy#highlight#line_disable()
  endif

  call sy#sign#process_diff(diff)

  let b:sy.id_top = (g:id_top - 1)
endfunction

" Function: #stop {{{1
function! sy#stop(bufnr) abort
  let sy = getbufvar(a:bufnr, 'sy')
  if empty(sy)
    return
  endif

  call sy#sign#remove_all_signs(a:bufnr)

  augroup signify
    execute printf('autocmd! * <buffer=%d>', sy.buffer)
  augroup END
endfunction

" Function: #toggle {{{1
function! sy#toggle() abort
  if !exists('b:sy')
    call sy#start()
    return
  endif

  if b:sy.active
    call sy#stop(b:sy.buffer)
    let b:sy.active = 0
    let b:sy.stats = [-1, -1, -1]
  else
    let b:sy.active = 1
    call sy#start()
  endif
endfunction
