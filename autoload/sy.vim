" vim: et sw=2 sts=2 fdm=marker

scriptencoding utf-8

" #start {{{1
" Optional argument: {'bufnr': X }
function! sy#start(...) abort
  if g:signify_locked
    call sy#verbose('Locked.')
    return
  endif

  let bufnr = a:0 && has_key(a:1, 'bufnr') ? a:1.bufnr : bufnr('')

  let sy_path = resolve(fnamemodify(bufname(bufnr), ':p'))
  if has('win32')
    let sy_path = substitute(sy_path, '\v^(\w):\\\\', '\1:\\', '')
  endif

  if s:skip(bufnr, sy_path)
    call sy#verbose('Skip file: '. sy_path)
    if !empty(getbufvar(bufnr, 'sy'))
      call sy#sign#remove_all_signs(bufnr)
    endif
    return
  endif

  let sy = getbufvar(bufnr, 'sy')

  if empty(sy) || sy.path != sy_path
    call sy#verbose('Register new file: '. sy_path)
    let sy = {
          \ 'path':       sy_path,
          \ 'buffer':     bufnr,
          \ 'active':     0,
          \ 'detecting':  0,
          \ 'vcs':        [],
          \ 'hunks':      [],
          \ 'signid':     0x100,
          \ 'updated_by': '',
          \ 'stats':      [-1, -1, -1],
          \ 'info':       {
          \    'dir':  fnamemodify(sy_path, ':p:h'),
          \    'path': sy#util#escape(sy_path),
          \    'file': sy#util#escape(fnamemodify(sy_path, ':t'))
          \ }}
    call setbufvar(bufnr, 'sy', sy)
    if get(g:, 'signify_disable_by_default')
      call sy#verbose('Disabled by default.')
      return
    endif
    let sy.active = 1
    call setbufvar(bufnr, 'sy', sy)
    call sy#repo#detect(bufnr)
  elseif has('vim_starting')
    call sy#verbose("Don't r   un Sy more than once during startup.")
    return
  elseif !sy.active
    call sy#verbose('Inactive buffer.')
    return
  elseif empty(sy.vcs)
    if get(sy, 'retry')
      let sy.retry = 0
      call sy#verbose('Redetecting VCS.')
      call sy#repo#detect()
    else
      if get(sy, 'detecting')
        call sy#verbose('Detection is already in progress.')
      else
        call sy#verbose('No VCS found. Disabling.')
        call sy#disable(bufnr)
      endif
    endif
  else
    for vcs in sy.vcs
      let job_id = getbufvar(bufnr, 'sy_job_id_'. vcs, 0)
      if type(job_id) != type(0) || job_id > 0
        call sy#verbose('Update is already in progress.', vcs)
      else
        call sy#verbose('Updating signs.', vcs)
        call sy#repo#get_diff(bufnr, vcs, function('sy#sign#set_signs'))
      endif
    endfor
  endif
endfunction

" #stop {{{1
function! sy#stop(bufnr) abort
  let sy = getbufvar(a:bufnr, 'sy')
  if empty(sy)
    return
  endif

  call sy#sign#remove_all_signs(a:bufnr)
endfunction

" #enable {{{1
function! sy#enable() abort
  if !exists('b:sy')
    call sy#start()
    return
  endif

  if !b:sy.active
    let b:sy.active = 1
    let b:sy.retry  = 1
    call sy#start()
  endif
endfunction

" #disable {{{1
function! sy#disable(...) abort
  let sy = getbufvar(a:0 ? a:1 : bufnr(''), 'sy')

  if !empty(sy) && sy.active
    call sy#stop(sy.buffer)
    let b:sy.active = 0
    let b:sy.stats = [-1, -1, -1]
  endif
endfunction

" #toggle {{{1
function! sy#toggle() abort
  if !exists('b:sy') || !b:sy.active
    call sy#enable()
  else
    call sy#disable()
  endif
endfunction

" #buffer_is_active {{{1
function! sy#buffer_is_active()
  return exists('b:sy') && b:sy.active
endfunction

" #verbose {{{1
function! sy#verbose(msg, ...) abort
  if &verbose
    if type(a:msg) == type([])
      for msg in a:msg
        echomsg printf('[sy%s] %s', (a:0 ? ':'.a:1 : ''), msg)
      endfor
    else
      echomsg printf('[sy%s] %s', (a:0 ? ':'.a:1 : ''), a:msg)
    endif
  endif
endfunction

" s:skip {{{1
function! s:skip(bufnr, path)
  if getbufvar(a:bufnr, '&diff') || !filereadable(a:path)
    return 1
  endif

  if exists('g:signify_skip_filetype')
    if has_key(g:signify_skip_filetype, &filetype)
      return 1
    elseif has_key(g:signify_skip_filetype, 'help')
          \ && getbufvar(a:bufnr, '&buftype') == 'help')
      return 1
    endif
  endif

  if exists('g:signify_skip_filename') && has_key(g:signify_skip_filename, a:path)
    return 1
  endif

  if exists('g:signify_skip_filename_pattern')
    for pattern in g:signify_skip_filename_pattern
      if a:path =~ pattern
        return 1
      endif
    endfor
  endif

  return 0
endfunction
