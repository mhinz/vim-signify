" vim: et sw=2 sts=2

scriptencoding utf-8

" Function: #detect {{{1
function! sy#repo#detect() abort
  let vcs_list = s:vcs_list
  " Simple cache. If there is a registered VCS-controlled file in this
  " directory already, assume that this file is probably controlled by
  " the same VCS. Thus we shuffle that VCS to the top of our copy of
  " s:vcs_list, so we don't affect the preference order of s:vcs_list.
  if has_key(g:sy_cache, b:sy_info.dir)
    let vcs_list = [g:sy_cache[b:sy_info.dir]] +
          \ filter(copy(s:vcs_list), 'v:val != "'.
          \        g:sy_cache[b:sy_info.dir] .'"')
  endif

  for type in vcs_list
    let [istype, diff] = sy#repo#get_diff_{type}()
    if istype
      return [diff, type]
    endif
  endfor

  return ['', 'unknown']
endfunction

" Function: #get_diff_git {{{1
function! sy#repo#get_diff_git() abort
  let diff = s:run(s:vcs_cmds.git, b:sy_info.file, 1)
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_hg {{{1
function! sy#repo#get_diff_hg() abort
  let diff = s:run(s:vcs_cmds.hg, b:sy_info.path, 1)
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_svn {{{1
function! sy#repo#get_diff_svn() abort
  let diff = s:run(s:vcs_cmds.svn, b:sy_info.path, 0)
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_bzr {{{1
function! sy#repo#get_diff_bzr() abort
  let diff = s:run(s:vcs_cmds.bzr, b:sy_info.path, 0)
  return (v:shell_error =~ '[012]') ? [1, diff] : [0, '']
endfunction

" Function: #get_diff_darcs {{{1
function! sy#repo#get_diff_darcs() abort
  let diff = s:run(s:vcs_cmds.darcs, b:sy_info.path, 1)
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_fossil {{{1
function! sy#repo#get_diff_fossil() abort
  let diff = s:run(s:vcs_cmds.fossil, b:sy_info.path, 1)
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_cvs {{{1
function! sy#repo#get_diff_cvs() abort
  let diff = s:run(s:vcs_cmds.cvs, b:sy_info.file, 1)
  return ((v:shell_error == 1) && (diff =~ '+++')) ? [1, diff] : [0, '']
endfunction

" Function: #get_diff_rcs {{{1
function! sy#repo#get_diff_rcs() abort
  let diff = s:run(s:vcs_cmds.rcs, b:sy_info.path, 0)
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_accurev {{{1
function! sy#repo#get_diff_accurev() abort
  let diff = s:run(s:vcs_cmds.accurev, b:sy_info.file, 1)
  return (v:shell_error != 1) ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_perforce {{{1
function! sy#repo#get_diff_perforce() abort
  let diff = s:run(s:vcs_cmds.perforce, b:sy_info.path, 0)
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_stats {{{1
function! sy#repo#get_stats() abort
  if !exists('b:sy') || !has_key(b:sy, 'stats')
    return [-1, -1, -1]
  endif

  return b:sy.stats
endfunction

" Function: #debug_detection {{{1
function! sy#repo#debug_detection()
  if !exists('b:sy')
    echomsg 'signify: I cannot detect any changes!'
    return
  endif

  let vcs_args = {
        \ 'git':      [s:vcs_cmds.git,      b:sy_info.file, 1],
        \ 'hg':       [s:vcs_cmds.hg,       b:sy_info.path, 1],
        \ 'svn':      [s:vcs_cmds.svn,      b:sy_info.path, 0],
        \ 'darcs':    [s:vcs_cmds.darcs,    b:sy_info.path, 1],
        \ 'bzr':      [s:vcs_cmds.bzr,      b:sy_info.path, 0],
        \ 'fossil':   [s:vcs_cmds.fossil,   b:sy_info.path, 1],
        \ 'cvs':      [s:vcs_cmds.cvs,      b:sy_info.file, 1],
        \ 'rcs':      [s:vcs_cmds.rcs,      b:sy_info.path, 0],
        \ 'accurev':  [s:vcs_cmds.accurev,  b:sy_info.file, 1],
        \ 'perforce': [s:vcs_cmds.perforce, b:sy_info.path, 0],
        \ }

  for vcs in s:vcs_list
    let cmd = s:expand_cmd(vcs_args[vcs][0], vcs_args[vcs][1])
    echohl Statement
    echo cmd
    echo repeat('=', len(cmd))
    echohl NONE

    let diff = call('s:run', vcs_args[vcs])
    if v:shell_error
      echohl ErrorMsg
      echo diff
      echohl NONE
    else
      echo empty(diff) ? "<none>" : diff
    endif
    echo "\n"
  endfor
endfunction

" Function: s:expand_cmd {{{1
function! s:expand_cmd(cmd, path) abort
  let cmd = s:replace(a:cmd, '%f', a:path)
  let cmd = s:replace(cmd,   '%d', s:difftool)
  let cmd = s:replace(cmd,   '%n', s:devnull)
  let b:sy_info.cmd = cmd
  return cmd
endfunction

" Function: s:run {{{1
function! s:run(cmd, path, do_switch_dir)
  let cmd = s:expand_cmd(a:cmd, a:path)

  if a:do_switch_dir
    try
      execute b:sy_info.chdir fnameescape(b:sy_info.dir)
      let ret = system(cmd)
    finally
      execute b:sy_info.chdir b:sy_info.cwd
    endtry
    return ret
  endif

  return system(cmd)
endfunction

" Function: s:replace {{{1
function! s:replace(cmd, pat, sub)
  let tmp = split(a:cmd, a:pat, 1)
  if len(tmp) > 1
    return  tmp[0] . a:sub . tmp[1]
  else
    return a:cmd
  endif
endfunction

" Variables {{{1
let s:difftool = get(g:, 'signify_difftool', 'diff')
if executable(s:difftool)
  let s:vcs_dict = {
        \ 'git':      'git',
        \ 'hg':       'hg',
        \ 'svn':      'svn',
        \ 'darcs':    'darcs',
        \ 'bzr':      'bzr',
        \ 'fossil':   'fossil',
        \ 'cvs':      'cvs',
        \ 'rcs':      'rcsdiff',
        \ 'accurev':  'accurev',
        \ 'perforce': 'p4'
        \ }
else
  echomsg 'signify: No diff tool found -> no support for svn, darcs, bzr, fossil.'
  let s:vcs_dict = {
        \ 'git':      'git',
        \ 'hg':       'hg',
        \ 'cvs':      'cvs',
        \ 'rcs':      'rcsdiff',
        \ 'accurev':  'accurev',
        \ 'perforce': 'p4'
        \ }
endif

let s:vcs_list = get(g:, 'signify_vcs_list', [])
if empty(s:vcs_list)
  let s:vcs_list = keys(filter(s:vcs_dict, 'executable(v:val)'))
endif

let s:vcs_cmds = {
      \ 'git':      'git diff --no-color --no-ext-diff -U0 -- %f',
      \ 'hg':       'hg diff --config extensions.color=! --config defaults.diff= --nodates -U0 -- %f',
      \ 'svn':      'svn diff --diff-cmd %d -x -U0 -- %f',
      \ 'bzr':      'bzr diff --using %d --diff-options=-U0 -- %f',
      \ 'darcs':    'darcs diff --no-pause-for-gui --diff-command="%d -U0 %1 %2" -- %f',
      \ 'fossil':   'fossil set diff-command "%d -U 0" && fossil diff --unified -c 0 -- %f',
      \ 'cvs':      'cvs diff -U0 -- %f',
      \ 'rcs':      'rcsdiff -U0 %f 2>%n',
      \ 'accurev':  'accurev diff %f -- -U0',
      \ 'perforce': 'p4 info >%n 2>&1 && env P4DIFF=%d p4 diff -dU0 %f',
      \ }

if exists('g:signify_vcs_cmds')
  call extend(s:vcs_cmds, g:signify_vcs_cmds)
endif

let s:difftool = sy#util#escape(s:difftool)
let s:devnull  = has('win32') || has ('win64') ? 'NUL' : '/dev/null'
