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

  for vcs in vcs_list
    call sy#repo#get_diff_start(vcs, a:do_register)
  endfor
endfunction

" Function: s:callback_stdout_nvim {{{1
function! s:callback_stdout_nvim(_job_id, data, _event) dict abort
  if empty(self.stdoutbuf) || empty(self.stdoutbuf[-1])
    let self.stdoutbuf += a:data
  else
    let self.stdoutbuf = self.stdoutbuf[:2]
          \ + [self.stdoutbuf[-1] . get(a:data, 0, '')]
          \ + a:data[1:]
  endif
endfunction

" Function: s:callback_stdout_vim {{{1
function! s:callback_stdout_vim(_job_id, data) dict abort
  let self.stdoutbuf += [a:data]
endfunction

" Function: s:callback_exit {{{1
function! s:callback_exit(job_id, exitval, ...) dict abort
  call sy#verbose('callback_exit()', self.vcs)
  call win_gotoid(self.winid)
  if self.bufnr != bufnr('%')
    return
  endif
  call sy#repo#get_diff_{self.vcs}(a:exitval, self.stdoutbuf, self.do_register)
  silent! unlet b:job_id_{self.vcs}
endfunction

" Function: sy#get_diff_start {{{1
function! sy#repo#get_diff_start(vcs, do_register) abort
  call sy#verbose('get_diff_start()', a:vcs)

  " Neovim
  if has('nvim')
    if exists('b:job_id_'.a:vcs)
      silent! call jobstop(b:job_id_{a:vcs})
    endif

    let [cmd, options] = s:initialize_job(a:vcs, a:do_register)
    let [cwd, chdir] = sy#util#chdir()

    try
      execute chdir fnameescape(b:sy_info.dir)
      let b:job_id_{a:vcs} = jobstart(cmd, extend(options, {
            \ 'on_stdout': function('s:callback_stdout_nvim'),
            \ 'on_exit':   function('s:callback_exit'),
            \ }))
    finally
      execute chdir fnameescape(cwd)
    endtry

  " Newer Vim
  elseif v:version > 704 || v:version == 704 && has('patch1967')
    if exists('b:job_id_'.a:vcs)
      silent! call job_stop(b:job_id_{a:vcs})
    endif

    let [cmd, options] = s:initialize_job(a:vcs, a:do_register)
    let [cwd, chdir] = sy#util#chdir()

    try
      execute chdir fnameescape(b:sy_info.dir)
      let b:job_id_{a:vcs} = job_start(cmd, {
            \ 'in_io':   'null',
            \ 'out_cb':  function('s:callback_stdout_vim', options),
            \ 'exit_cb': function('s:callback_exit', options),
            \ })
    finally
      execute chdir fnameescape(cwd)
    endtry

  " Older Vim
  else
    let diff = split(s:run(a:vcs), '\n')
    call sy#repo#get_diff_{a:vcs}(v:shell_error, diff, a:do_register)
  endif
endfunction

" Function: s:get_diff_end {{{1
function! s:get_diff_end(found_diff, vcs, diff, do_register) abort
  call sy#verbose('get_diff_end()', a:vcs)
  if a:found_diff
    let b:sy.vcs = a:vcs
    call sy#set_signs(a:diff, a:do_register)
  endif
endfunction

" Function: #get_diff_git {{{1
function! sy#repo#get_diff_git(exitval, diff, do_register) abort
  call sy#verbose('get_diff_git()', 'git')
  let [found_diff, diff] = a:exitval ? [0, ''] : [1, a:diff]
  call s:get_diff_end(found_diff, 'git', diff, a:do_register)
endfunction

" Function: #get_diff_hg {{{1
function! sy#repo#get_diff_hg(exitval, diff, do_register) abort
  call sy#verbose('get_diff_hg()', 'hg')
  let [found_diff, diff] = a:exitval ? [0, ''] : [1, a:diff]
  call s:get_diff_end(found_diff, 'hg', diff, a:do_register)
endfunction

" Function: #get_diff_svn {{{1
function! sy#repo#get_diff_svn(exitval, diff, do_register) abort
  call sy#verbose('get_diff_svn()', 'svn')
  let [found_diff, diff] = a:exitval ? [0, ''] : [1, a:diff]
  call s:get_diff_end(found_diff, 'svn', diff, a:do_register)
endfunction

" Function: #get_diff_bzr {{{1
function! sy#repo#get_diff_bzr(exitval, diff, do_register) abort
  call sy#verbose('get_diff_bzr()', 'bzr')
  let [found_diff, diff] = (a:exitval =~ '[012]') ? [1, a:diff] : [0, '']
  call s:get_diff_end(found_diff, 'bzr', diff, a:do_register)
endfunction

" Function: #get_diff_darcs {{{1
function! sy#repo#get_diff_darcs(exitval, diff, do_register) abort
  call sy#verbose('get_diff_darcs()', 'darcs')
  let [found_diff, diff] = a:exitval ? [0, ''] : [1, a:diff]
  call s:get_diff_end(found_diff, 'darcs', diff, a:do_register)
endfunction

" Function: #get_diff_fossil {{{1
function! sy#repo#get_diff_fossil(exitval, diff, do_register) abort
  call sy#verbose('get_diff_fossil()', 'fossil')
  let [found_diff, diff] = a:exitval ? [0, ''] : [1, a:diff]
  call s:get_diff_end(found_diff, 'fossil', diff, a:do_register)
endfunction

" Function: #get_diff_cvs {{{1
function! sy#repo#get_diff_cvs(exitval, diff, do_register) abort
  call sy#verbose('get_diff_cvs()', 'cvs')
  let [found_diff, diff] = [0, '']
  if a:exitval == 1
    for diffline in a:diff
      if diffline =~ '+++'
        let [found_diff, diff] = [1, a:diff]
        break
      endif
    endfor
  endif
  call s:get_diff_end(found_diff, 'cvs', diff, a:do_register)
endfunction

" Function: #get_diff_rcs {{{1
function! sy#repo#get_diff_rcs(exitval, diff, do_register) abort
  call sy#verbose('get_diff_rcs()', 'rcs')
  let [found_diff, diff] = a:exitval ? [0, ''] : [1, a:diff]
  call s:get_diff_end(found_diff, 'rcs', diff, a:do_register)
endfunction

" Function: #get_diff_accurev {{{1
function! sy#repo#get_diff_accurev(exitval, diff, do_register) abort
  call sy#verbose('get_diff_accurev()', 'accurev')
  let [found_diff, diff] = (a:exitval >= 2) ? [0, ''] : [1, a:diff]
  call s:get_diff_end(found_diff, 'accurev', diff, a:do_register)
endfunction

" Function: #get_diff_perforce {{{1
function! sy#repo#get_diff_perforce(exitval, diff, do_register) abort
  call sy#verbose('get_diff_perforce()', 'perforce')
  let [found_diff, diff] = a:exitval ? [0, ''] : [1, a:diff]
  call s:get_diff_end(found_diff, 'perforce', diff, a:do_register)
endfunction

" Function: #get_diff_tfs {{{1
function! sy#repo#get_diff_tfs(exitval, diff, do_register) abort
  call sy#verbose('get_diff_tfs()', 'tfs')
  let [found_diff, diff] = a:exitval ? [0, ''] : [1, s:strip_context(a:diff)]
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

  for vcs in s:vcs_list
    let cmd = s:expand_cmd(vcs)
    echohl Statement
    echo cmd
    echo repeat('=', len(cmd))
    echohl NONE

    let diff = s:run(vcs)
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

" Function: s:initialize_job {{{1
function! s:initialize_job(vcs, do_register) abort
  let cmd = s:expand_cmd(a:vcs)
  let cmd = (has('win32') && &shell =~ 'cmd')  ? cmd : ['sh', '-c', cmd]
  let options = {
        \ 'stdoutbuf':   [],
        \ 'vcs':         a:vcs,
        \ 'do_register': a:do_register,
        \ 'bufnr':       bufnr('%'),
        \ 'winid':       win_getid(),
        \ }
  return [cmd, options]
endfunction

" Function: s:get_vcs_path {{{1
function! s:get_vcs_path(vcs) abort
  return (a:vcs =~# '\v(git|cvs|accurev|tfs)') ? b:sy_info.file : b:sy_info.path
endfunction

" Function: s:expand_cmd {{{1
function! s:expand_cmd(vcs) abort
  let cmd = g:signify_vcs_cmds[a:vcs]
  let cmd = s:replace(cmd, '%f', s:get_vcs_path(a:vcs))
  let cmd = s:replace(cmd, '%d', s:difftool)
  let cmd = s:replace(cmd, '%n', s:devnull)
  let b:sy_info.cmd = cmd
  return cmd
endfunction

" Function: s:run {{{1
function! s:run(vcs)
  let [cwd, chdir] = sy#util#chdir()
  try
    execute chdir fnameescape(b:sy_info.dir)
    let ret = system(s:expand_cmd(a:vcs))
  catch
    " This exception message can be seen via :SignifyDebugUnknown.
    " E.g. unquoted VCS programs in vcd_cmds can lead to E484.
    let ret = v:exception .' at '. v:throwpoint
  finally
    execute chdir fnameescape(cwd)
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
