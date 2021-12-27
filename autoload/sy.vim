" vim: et sw=2 sts=2 fdm=marker

scriptencoding utf-8

" #start {{{1
" Optional argument: {'bufnr': X }
function! sy#start(...) abort
  if g:signify_locked
    call sy#verbose('Locked.')
    return
  endif

  if g:signify_detecting > 50
    call sy#verbose('Too many detection jobs running, deferring detection')
    return
  endif

  let bufnr = a:0 && has_key(a:1, 'bufnr') ? a:1.bufnr : bufnr('')
  let sy = getbufvar(bufnr, 'sy')

  if empty(sy)
    let path = s:get_path(bufnr)
    if s:skip(bufnr, path)
      call sy#verbose('Skip file: '. path)
      return
    endif
    call sy#verbose('Register new file: '. path)
    let new_sy = {
          \ 'path':       path,
          \ 'buffer':     bufnr,
          \ 'detecting':  0,
          \ 'vcs':        [],
          \ 'hunks':      [],
          \ 'signid':     0x100,
          \ 'updated_by': '',
          \ 'stats':      [-1, -1, -1],
          \ 'info':       {
          \    'dir':  fnamemodify(path, ':p:h'),
          \    'path': sy#util#escape(path),
          \    'file': sy#util#escape(fnamemodify(path, ':t'))
          \ }}
    call setbufvar(bufnr, 'sy', new_sy)
    call sy#set_buflocal_autocmds(bufnr)
    call sy#repo#detect(bufnr)
  elseif has('vim_starting')
    call sy#verbose("Don't run Sy more than once during startup.")
    return
  else
    let path = s:get_path(bufnr)
    if !filereadable(path)
      call sy#stop()
      return
    elseif empty(sy.vcs)
      if get(sy, 'retry')
        let sy.retry = 0
        call sy#verbose('Redetecting VCS.')
        call sy#repo#detect(sy.buffer)
      else
        if get(sy, 'detecting')
          call sy#verbose('Detection is already in progress.')
        else
          call sy#verbose('No VCS found. Disabling.')
          call sy#stop(sy.buffer)
        endif
      endif
    else
      for vcs in sy.vcs
        let job_id = getbufvar(sy.buffer, 'sy_job_id_'. vcs, 0)
        if type(job_id) != type(0) || job_id > 0
          call sy#verbose('Update is already in progress.', vcs)
        else
          call sy#verbose('Updating signs.', vcs)
          call sy#repo#get_diff(sy.buffer, vcs, function('sy#sign#set_signs'))
        endif
      endfor
    endif
  endif
endfunction

" #stop {{{1
function! sy#stop(...) abort
  let bufnr = bufnr('')
  if empty(getbufvar(a:0 ? a:1 : bufnr, 'sy')) | return | endif
  call sy#sign#remove_all_signs(bufnr)
  execute printf('autocmd! signify * <buffer=%d>', bufnr)
  call setbufvar(bufnr, 'sy', {})
endfunction

" #toggle {{{1
function! sy#toggle() abort
  call call(empty(getbufvar(bufnr(''), 'sy')) ? 'sy#start' : 'sy#stop', [])
endfunction

" #start_all {{{1
function! sy#start_all() abort
  for bufnr in range(1, bufnr("$"))
    call sy#start({'bufnr': bufnr})
  endfor
  let g:signify_disable_by_default = 0
endfunction

" #stop_all {{{1
function! sy#stop_all() abort
  for bufnr in range(1, bufnr(''))
    if !empty(getbufvar(bufnr, 'sy'))
      call sy#stop(bufnr)
    endif
  endfor
  let g:signify_disable_by_default = 1
endfunction

" #buffer_is_active {{{1
function! sy#buffer_is_active(...)
  let bufnr = a:0 ? a:1 : bufnr('')
  return !empty(getbufvar(bufnr, 'sy'))
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

" #set_buflocal_autocmds {{{1
function! sy#set_buflocal_autocmds(bufnr) abort
  augroup signify
    execute printf('autocmd! * <buffer=%d>', a:bufnr)

    execute printf('autocmd BufEnter     <buffer=%d> call sy#start()', a:bufnr)
    execute printf('autocmd WinEnter     <buffer=%d> call sy#start()', a:bufnr)
    execute printf('autocmd BufWritePost <buffer=%d> call sy#start()', a:bufnr)

    execute printf('autocmd CursorHold   <buffer=%d> call sy#start()', a:bufnr)
    execute printf('autocmd CursorHoldI  <buffer=%d> call sy#start()', a:bufnr)

    execute printf('autocmd FocusGained  <buffer=%d> SignifyRefresh', a:bufnr)

    execute printf('autocmd CmdwinEnter <buffer=%d> let g:signify_cmdwin_active = 1', a:bufnr)
    execute printf('autocmd CmdwinLeave <buffer=%d> let g:signify_cmdwin_active = 0', a:bufnr)

    execute printf('autocmd ShellCmdPost <buffer=%d> call sy#start()', a:bufnr)

    if exists('##VimResume')
      execute printf('autocmd VimResume <buffer=%d> call sy#start()', a:bufnr)
    endif
  augroup END

  if exists('#User#SignifyAutocmds')
    doautocmd <nomodeline> User SignifyAutocmds
  endif
endfunction

" s:get_path {{{1
function! s:get_path(bufnr)
  let path = resolve(fnamemodify(bufname(a:bufnr), ':p'))
  if has('win32')
    let path = substitute(path, '\v^(\w):\\\\', '\1:\\', '')
  endif
  return path
endfunction

" s:skip {{{1
function! s:skip(bufnr, path)
  if getbufvar(a:bufnr, '&diff') || !filereadable(a:path)
    return 1
  endif

  if exists('g:signify_skip_filetype')
    if has_key(g:signify_skip_filetype, getbufvar(a:bufnr, '&filetype'))
      return 1
    elseif has_key(g:signify_skip_filetype, 'help')
          \ && getbufvar(a:bufnr, '&buftype') == 'help'
      return 1
    endif
  endif

  if exists('g:signify_skip_filename') && has_key(g:signify_skip_filename, a:path)
    return 1
  endif

  " DEPRECATED: Use g:signify_skip.pattern instead.
  if exists('g:signify_skip_filename_pattern')
    for pattern in g:signify_skip_filename_pattern
      if a:path =~ pattern
        return 1
      endif
    endfor
  endif

  if exists('g:signify_skip')
    if has_key(g:signify_skip, 'pattern')
      for pattern in g:signify_skip.pattern
        if a:path =~ pattern
          return 1
        endif
      endfor
    endif
  endif

  return 0
endfunction
