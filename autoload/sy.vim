" vim: et sw=2 sts=2

scriptencoding utf-8

" Init: values {{{1
let g:sy_cache = {}

let s:has_doau_modeline = v:version > 703 || v:version == 703 && has('patch442')

" Function: #start {{{1
function! sy#start() abort
  if g:signify_locked
    call sy#verbose('Locked.')
    return
  endif

  let sy_path = resolve(expand('%:p'))

  if s:skip(sy_path)
    call sy#verbose('Skip file.')
    if exists('b:sy')
      call sy#sign#remove_all_signs(bufnr(''))
      unlet! b:sy b:sy_info
    endif
    return
  endif

  " sy_info is used in autoload/sy/repo
  let b:sy_info = {
        \ 'dir':   fnamemodify(sy_path, ':p:h'),
        \ 'path':  sy#util#escape(sy_path),
        \ 'file':  sy#util#escape(fnamemodify(sy_path, ':t')),
        \ }

  if !exists('b:sy') || b:sy.path != sy_path
    call sy#verbose('Register new file.')
    let b:sy = {
          \ 'path'  : sy_path,
          \ 'buffer': bufnr(''),
          \ 'active': 0,
          \ 'vcs'   : 'unknown',
          \ 'hunks' : [],
          \ 'signid': 0x100,
          \ 'stats' : [-1, -1, -1] }
    if get(g:, 'signify_disable_by_default')
      call sy#verbose('Disabled by default.')
      return
    endif
    let b:sy.active = 1
    call sy#repo#detect(1)
  elseif !b:sy.active
    call sy#verbose('Inactive buffer.')
    return
  elseif b:sy.vcs == 'unknown'
    call sy#verbose('No VCS found. Disabling.')
    call sy#disable()
  else
    call sy#verbose('Updating signs.')
    call sy#repo#get_diff_start(b:sy.vcs, 0)
  endif
endfunction

" Function: #set_signs {{{1
function! sy#set_signs(diff, do_register) abort
  call sy#verbose('set_signs()', b:sy.vcs)

  if a:do_register
    let b:sy.stats = [0, 0, 0]
    let dir = fnamemodify(b:sy.path, ':h')
    if !has_key(g:sy_cache, dir)
      let g:sy_cache[dir] = b:sy.vcs
    endif
    if empty(a:diff)
      call sy#verbose('No changes found.', b:sy.vcs)
      return
    endif
  endif

  if get(g:, 'signify_line_highlight')
    call sy#highlight#line_enable()
  else
    call sy#highlight#line_disable()
  endif

  call sy#sign#process_diff(a:diff)

  if exists('#User#Signify')
    execute 'doautocmd' (s:has_doau_modeline ? '<nomodeline>' : '') 'User Signify'
  endif
endfunction

" Function: #stop {{{1
function! sy#stop(bufnr) abort
  let sy = getbufvar(a:bufnr, 'sy')
  if empty(sy)
    return
  endif

  call sy#sign#remove_all_signs(a:bufnr)
endfunction

" Function: #enable {{{1
function! sy#enable() abort
  silent! unlet b:sy b:sy_info
  call sy#start()
endfunction

" Function: #disable {{{1
function! sy#disable() abort
  if exists('b:sy') && b:sy.active
    call sy#stop(b:sy.buffer)
    let b:sy.active = 0
    let b:sy.stats = [-1, -1, -1]
  endif
endfunction

" Function: #toggle {{{1
function! sy#toggle() abort
  if !exists('b:sy') || !b:sy.active
    call sy#enable()
  else
    call sy#disable()
  endif
endfunction

" Function: #buffer_is_active {{{1
function! sy#buffer_is_active()
  return exists('b:sy') && b:sy.active
endfunction

" Function: #verbose {{{1
function! sy#verbose(msg, ...) abort
  if &verbose
    echomsg printf('[sy%s] %s', (a:0 ? ':'.a:1 : ''), a:msg)
  endif
endfunction

" Function: s:skip {{{1
function! s:skip(path)
  if &diff || !filereadable(a:path)
    return 1
  endif

  if exists('g:signify_skip_filetype')
    if has_key(g:signify_skip_filetype, &filetype)
      return 1
    elseif has_key(g:signify_skip_filetype, 'help') && (&buftype == 'help')
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
