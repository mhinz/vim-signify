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
  let diff = s:run(g:signify_vcs_cmds.git, b:sy_info.file, 1)
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_hg {{{1
function! sy#repo#get_diff_hg() abort
  let diff = s:run(g:signify_vcs_cmds.hg, b:sy_info.path, 1)
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_svn {{{1
function! sy#repo#get_diff_svn() abort
  let diff = s:run(g:signify_vcs_cmds.svn, b:sy_info.path, 0)
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_bzr {{{1
function! sy#repo#get_diff_bzr() abort
  let diff = s:run(g:signify_vcs_cmds.bzr, b:sy_info.path, 0)
  return (v:shell_error =~ '[012]') ? [1, diff] : [0, '']
endfunction

" Function: #get_diff_darcs {{{1
function! sy#repo#get_diff_darcs() abort
  let diff = s:run(g:signify_vcs_cmds.darcs, b:sy_info.path, 1)
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_fossil {{{1
function! sy#repo#get_diff_fossil() abort
  let diff = s:run(g:signify_vcs_cmds.fossil, b:sy_info.path, 1)
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_cvs {{{1
function! sy#repo#get_diff_cvs() abort
  let diff = s:run(g:signify_vcs_cmds.cvs, b:sy_info.file, 1)
  return ((v:shell_error == 1) && (diff =~ '+++')) ? [1, diff] : [0, '']
endfunction

" Function: #get_diff_rcs {{{1
function! sy#repo#get_diff_rcs() abort
  let diff = s:run(g:signify_vcs_cmds.rcs, b:sy_info.path, 0)
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_accurev {{{1
function! sy#repo#get_diff_accurev() abort
  let diff = s:run(g:signify_vcs_cmds.accurev, b:sy_info.file, 1)
  return (v:shell_error == 2) ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_perforce {{{1
function! sy#repo#get_diff_perforce() abort
  let diff = s:run(g:signify_vcs_cmds.perforce, b:sy_info.path, 0)
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_tfs {{{1
function! sy#repo#get_diff_tfs() abort
  let diff = s:run(g:signify_vcs_cmds.tfs, b:sy_info.file, 0)
  return v:shell_error ? [0, ''] : [1, s:strip_context(diff)]
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
        \ 'git':      [g:signify_vcs_cmds.git,      b:sy_info.file, 1],
        \ 'hg':       [g:signify_vcs_cmds.hg,       b:sy_info.path, 1],
        \ 'svn':      [g:signify_vcs_cmds.svn,      b:sy_info.path, 0],
        \ 'darcs':    [g:signify_vcs_cmds.darcs,    b:sy_info.path, 1],
        \ 'bzr':      [g:signify_vcs_cmds.bzr,      b:sy_info.path, 0],
        \ 'fossil':   [g:signify_vcs_cmds.fossil,   b:sy_info.path, 1],
        \ 'cvs':      [g:signify_vcs_cmds.cvs,      b:sy_info.file, 1],
        \ 'rcs':      [g:signify_vcs_cmds.rcs,      b:sy_info.path, 0],
        \ 'accurev':  [g:signify_vcs_cmds.accurev,  b:sy_info.file, 1],
        \ 'perforce': [g:signify_vcs_cmds.perforce, b:sy_info.path, 0],
        \ 'tfs':      [g:signify_vcs_cmds.tfs,      b:sy_info.file, 0],
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
  execute b:sy_info.chdir fnameescape(b:sy_info.dir)
  try
    let ret = system(s:expand_cmd(a:cmd, a:path))
  catch
    " This exception message can be seen via :SignifyDebugUnknown.
    " E.g. unquoted VCS programs in vcd_cmds can lead to E484.
    let ret = v:exception .' at '. v:throwpoint
  finally
    execute b:sy_info.chdir b:sy_info.cwd
    return ret
  endtry
endfunction

" Function: s:replace {{{1
function! s:replace(cmd, pat, sub)
  let parts = split(a:cmd, a:pat, 1)
  return join(parts, a:sub)
endfunction

" Function: s:strip_context {{{1
function! s:strip_context(context)
  let diff = []
  let hunk = []
  let state = 0
  let lines = split(a:context,"\n",1)
  let linenr = 0

  while linenr < len(lines)
    let line = lines[linenr]

    if state == 0
      if line =~ "^@@ "
        let tokens = matchlist(line, '^@@ -\v(\d+),?(\d*) \+(\d+),?(\d*)')
        let old_line = str2nr(tokens[1])
        let new_line = str2nr(tokens[3])
        let old_count = empty(tokens[2]) ? 1 : str2nr(tokens[2])
        let new_count = empty(tokens[4]) ? 1 : str2nr(tokens[4])
        let state = 1
      else
        call add(diff,line)
      endif
      let linenr = linenr + 1
    elseif state == 1
      if line[0] == ' '
        let old_line = old_line + 1
        let new_line = new_line + 1
        let old_count = old_count - 1
        let new_count = new_count - 1
        let linenr = linenr + 1
      else
        let hunk = []
        let old_count_part = 0
        let new_count_part = 0
        let state = 2
      endif
    elseif state == 2
      if line[0] == '-'
        call add(hunk,line)
        let old_count_part = old_count_part + 1
        let linenr = linenr + 1
      else
        let state = 3
      endif
    elseif state == 3
      if line[0] == '+'
        call add(hunk,line)
        let new_count_part = new_count_part + 1
        let linenr = linenr + 1
      else
        call add(diff, printf("@@ -%d,%d +%d,%d @@",old_line, old_count_part, (new_count_part == 0 && new_line > 0) ? new_line - 1 : new_line, new_count_part))
        let diff = diff + hunk
        let hunk = []
        let old_count = old_count - old_count_part
        let new_count = new_count - new_count_part
        let old_line = old_line + old_count_part
        let new_line = new_line + new_count_part
        let state = 1
      endif
    endif

    if state > 0 && new_count <= 0 && old_count <= 0
      if len(hunk) > 0
        call add(diff, printf("@@ -%d,%d +%d,%d @@",old_line, old_count_part, (new_count_part == 0 && new_line > 0) ? new_line - 1 : new_line, new_count_part))
        let diff = diff + hunk
        let hunk = []
      endif
      let state = 0
    endif
  endwhile

  return join(diff,"\n")."\n"
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
        \ 'perforce': 'p4',
        \ 'tfs':      'tf'
        \ }
else
  echomsg 'signify: No diff tool found -> no support for svn, darcs, bzr, fossil.'
  let s:vcs_dict = {
        \ 'git':      'git',
        \ 'hg':       'hg',
        \ 'cvs':      'cvs',
        \ 'rcs':      'rcsdiff',
        \ 'accurev':  'accurev',
        \ 'perforce': 'p4',
        \ 'tfs':      'tf'
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
      \ 'perforce': 'p4 info '. sy#util#shell_redirect('%n') .' && env P4DIFF=%d p4 diff -dU0 %f',
      \ 'tfs':      'tf diff -version:W -noprompt -format:Unified %f'
      \ }

if exists('g:signify_vcs_cmds')
  call extend(g:signify_vcs_cmds, s:vcs_cmds, 'keep')
else
    let g:signify_vcs_cmds = s:vcs_cmds
endif

let s:difftool = sy#util#escape(s:difftool)
let s:devnull  = has('win32') || has ('win64') ? 'NUL' : '/dev/null'
