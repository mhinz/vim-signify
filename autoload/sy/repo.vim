" vim: et sw=2 sts=2

scriptencoding utf-8

" Function: #detect {{{1
function! sy#repo#detect(do_register) abort
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
    call sy#repo#get_diff_start(type, a:do_register)
  endfor
endfunction

" Function: s:callback_stdout_nvim {{{1
function! s:callback_stdout_nvim(_job_id, data, _event) dict abort
  if empty(self.stdoutbuf) || empty(self.stdoutbuf[-1])
    let self.stdoutbuf += a:data
  else
    let self.stdoutbuf = self.stdoutbuf[:2]
          \ + [self.stdoutbuf[-1] . get(a:data, 0, '')
          \ + a:data[1:]
  endif
endfunction

" Function: s:callback_exit {{{1
function! s:callback_exit(_job_id, exitcode, _event) dict abort
  call sy#verbose('Running callback_exit().')
  if !a:exitcode
    call sy#repo#get_diff_{self.vcs}(a:exitcode, join(self.stdoutbuf, "\n"),
          \ self.do_register)
  endif
  silent! unlet b:job_id_{self.vcs}
endfunction

" Function: sy#get_diff_start {{{1
function! sy#repo#get_diff_start(vcs, do_register) abort
  call sy#verbose('Running s:get_diff_start().')
  if has('nvim')
    if exists('b:job_id_'.a:vcs)
      silent! call jobstop(b:job_id_{a:vcs})
    endif
    let cmd = s:expand_cmd(g:signify_vcs_cmds[a:vcs], b:sy_info.file)
    let cmd = (has('win32') && &shell =~ 'cmd')  ? cmd : ['sh', '-c', cmd]
    execute b:sy_info.chdir fnameescape(b:sy_info.dir)
    try
      let b:job_id_{a:vcs} = jobstart(cmd, {
            \ 'stdoutbuf':   [],
            \ 'vcs':         a:vcs,
            \ 'do_register': a:do_register,
            \ 'on_stdout':   function('s:callback_stdout_nvim'),
            \ 'on_exit':     function('s:callback_exit'),
            \ })
      call sy#verbose('Running jobstart(). Job ID: '. b:job_id_{a:vcs})
    finally
      execute b:sy_info.chdir b:sy_info.cwd
    endtry
  else
    let diff = s:run(g:signify_vcs_cmds[a:vcs], b:sy_info.path)
    call s:get_diff_{a:vcs}(v:shell_error, diff, a:do_register)
  endif
endfunction

" Function: s:get_diff_end {{{1
function! s:get_diff_end(found_diff, type, diff, do_register) abort
  call sy#verbose('Running s:get_diff_end().')
  if a:found_diff
    let b:sy.type = a:type
  endif
  if !a:do_register
    let b:sy.id_top = g:id_top
  endif
  call sy#set_signs(a:diff, a:do_register)
endfunction

" Function: #get_diff_git {{{1
function! sy#repo#get_diff_git(exitcode, diff, do_register) abort
  call sy#verbose('Running get_diff_git().')
  let [found_diff, diff] = a:exitcode ? [0, ''] : [1, a:diff]
  call s:get_diff_end(found_diff, 'git', diff, a:do_register)
endfunction

" Function: #get_diff_hg {{{1
function! sy#repo#get_diff_hg(exitcode, diff, do_register) abort
  call sy#verbose('Running get_diff_hg().')
  let [found_diff, diff] = v:shell_error ? [0, ''] : [1, a:diff]
  call s:get_diff_end(found_diff, 'hg', diff, a:do_register)
endfunction

" Function: #get_diff_svn {{{1
function! sy#repo#get_diff_svn(exitcode, diff, do_register) abort
  call sy#verbose('Running get_diff_svn().')
  let [found_diff, diff] = v:shell_error ? [0, ''] : [1, a:diff]
  call s:get_diff_end(found_diff, 'svn', diff, a:do_register)
endfunction

" Function: #get_diff_bzr {{{1
function! sy#repo#get_diff_bzr(exitcode, diff, do_register) abort
  call sy#verbose('Running get_diff_bzr().')
  let [found_diff, diff] = (v:shell_error =~ '[012]') ? [1, a:diff] : [0, '']
  call s:get_diff_end(found_diff, 'bzr', diff, a:do_register)
endfunction

" Function: #get_diff_darcs {{{1
function! sy#repo#get_diff_darcs(exitcode, diff, do_register) abort
  call sy#verbose('Running get_diff_darcs().')
  let [found_diff, diff] = v:shell_error ? [0, ''] : [1, a:diff]
  call s:get_diff_end(found_diff, 'darcs', diff, a:do_register)
endfunction

" Function: #get_diff_fossil {{{1
function! sy#repo#get_diff_fossil(exitcode, diff, do_register) abort
  call sy#verbose('Running get_diff_fossil().')
  let [found_diff, diff] = v:shell_error ? [0, ''] : [1, a:diff]
  call s:get_diff_end(found_diff, 'fossil', diff, a:do_register)
endfunction

" Function: #get_diff_cvs {{{1
function! sy#repo#get_diff_cvs(exitcode, diff, do_register) abort
  call sy#verbose('Running get_diff_cvs().')
  let [found_diff, diff] = ((v:shell_error == 1) && (a:diff =~ '+++'))
        \ ? [1, diff]
        \ : [0, '']
  call s:get_diff_end(found_diff, 'cvs', diff, a:do_register)
endfunction

" Function: #get_diff_rcs {{{1
function! sy#repo#get_diff_rcs() abort
  call sy#verbose('Running get_diff_rcs().')
  let [found_diff, diff] = v:shell_error ? [0, ''] : [1, a:diff]
  call s:get_diff_end(found_diff, 'rcs', diff, a:do_register)
endfunction

" Function: #get_diff_accurev {{{1
function! sy#repo#get_diff_accurev() abort
  call sy#verbose('Running get_diff_accurev().')
  let [found_diff, diff] = (v:shell_error >= 2) ? [0, ''] : [1, a:diff]
  call s:get_diff_end(found_diff, 'accurev', diff, a:do_register)
endfunction

" Function: #get_diff_perforce {{{1
function! sy#repo#get_diff_perforce() abort
  call sy#verbose('Running get_diff_perforce().')
  let [found_diff, diff] = v:shell_error ? [0, ''] : [1, a:diff]
  call s:get_diff_end(found_diff, 'perforce', diff, a:do_register)
endfunction

" Function: #get_diff_tfs {{{1
function! sy#repo#get_diff_tfs() abort
  call sy#verbose('Running get_diff_tfs().')
  let [found_diff, diff] = v:shell_error
        \ ? [0, '']
        \ : [1, s:strip_context(a:diff)]
  call s:get_diff_end(found_diff, 'tfs', diff, a:do_register)
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
        \ 'git':      [g:signify_vcs_cmds.git,      b:sy_info.file],
        \ 'hg':       [g:signify_vcs_cmds.hg,       b:sy_info.path],
        \ 'svn':      [g:signify_vcs_cmds.svn,      b:sy_info.path],
        \ 'darcs':    [g:signify_vcs_cmds.darcs,    b:sy_info.path],
        \ 'bzr':      [g:signify_vcs_cmds.bzr,      b:sy_info.path],
        \ 'fossil':   [g:signify_vcs_cmds.fossil,   b:sy_info.path],
        \ 'cvs':      [g:signify_vcs_cmds.cvs,      b:sy_info.file],
        \ 'rcs':      [g:signify_vcs_cmds.rcs,      b:sy_info.path],
        \ 'accurev':  [g:signify_vcs_cmds.accurev,  b:sy_info.file],
        \ 'perforce': [g:signify_vcs_cmds.perforce, b:sy_info.path],
        \ 'tfs':      [g:signify_vcs_cmds.tfs,      b:sy_info.file],
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
function! s:run(cmd, path)
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
        let hunk = []
        let state = 1
      else
        call add(diff,line)
      endif
      let linenr += 1
    elseif index([1,2,3],state) >= 0 && index(['\','/'],line[0]) >= 0
      let linenr += 1
      call add(hunk,line)
    elseif state == 1
      if line[0] == ' '
        let old_line += 1
        let new_line += 1
        let old_count -= 1
        let new_count -= 1
        let linenr += 1
      else
        let old_count_part = 0
        let new_count_part = 0
        let state = 2
      endif
    elseif state == 2
      if line[0] == '-'
        call add(hunk,line)
        let old_count_part += 1
        let linenr += 1
      else
        let state = 3
      endif
    elseif state == 3
      if line[0] == '+'
        call add(hunk,line)
        let new_count_part += 1
        let linenr += 1
      else
        call add(diff, printf("@@ -%d%s +%d%s @@",(old_count_part == 0 && old_line > 0) ? old_line -1 : old_line, old_count_part == 1 ? "" : printf(",%d", old_count_part), (new_count_part == 0 && new_line > 0) ? new_line - 1 : new_line, new_count_part == 1 ? "" : printf(",%d", new_count_part)))
        let diff += hunk
        let hunk = []
        let old_count -= old_count_part
        let new_count -= new_count_part
        let old_line += old_count_part
        let new_line += new_count_part
        let state = 1
      endif
    endif

    if state > 0 && new_count <= 0 && old_count <= 0
      if len(hunk) > 0
        call add(diff, printf("@@ -%d%s +%d%s @@",(old_count_part == 0 && old_line > 0) ? old_line -1 : old_line, old_count_part == 1 ? "" : printf(",%d", old_count_part), (new_count_part == 0 && new_line > 0) ? new_line - 1 : new_line, new_count_part == 1 ? "" : printf(",%d", new_count_part)))
        let diff = diff + hunk
        let hunk = []
      endif
      let state = 0
    endif
  endwhile
  if len(hunk) > 0
    call add(diff, printf("@@ -%d%s +%d%s @@",(old_count_part == 0 && old_line > 0) ? old_line -1 : old_line, old_count_part == 1 ? "" : printf(",%d", old_count_part), (new_count_part == 0 && new_line > 0) ? new_line - 1 : new_line, new_count_part == 1 ? "" : printf(",%d", new_count_part)))
    let diff = diff + hunk
    let hunk = []
  endif
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
