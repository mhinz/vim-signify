" vim: et sw=2 sts=2

scriptencoding utf-8

" Function: #detect {{{1
function! sy#repo#detect() abort
  for vcs in s:vcs_list
    let b:sy.detecting += 1
    call sy#repo#get_diff_start(vcs)
  endfor
endfunction

" Function: s:callback_nvim_stdout{{{1
function! s:callback_nvim_stdout(_job_id, data, _event) dict abort
  if empty(self.stdoutbuf) || empty(self.stdoutbuf[-1])
    let self.stdoutbuf += a:data
  else
    let self.stdoutbuf = self.stdoutbuf[:-2]
          \ + [self.stdoutbuf[-1] . get(a:data, 0, '')]
          \ + a:data[1:]
  endif
endfunction

" Function: s:callback_nvim_exit {{{1
function! s:callback_nvim_exit(_job_id, exitval, _event) dict abort
  call s:job_exit(self.bufnr, self.vcs, a:exitval, self.stdoutbuf)
endfunction

" Function: s:callback_vim_stdout {{{1
function! s:callback_vim_stdout(_job_id, data) dict abort
  let self.stdoutbuf += [a:data]
endfunction

" Function: s:callback_vim_close {{{1
function! s:callback_vim_close(channel) dict abort
  let job = ch_getjob(a:channel)
  while 1
    if job_status(job) == 'dead'
      let exitval = job_info(job).exitval
      break
    endif
    sleep 10m
  endwhile
  call s:job_exit(self.bufnr, self.vcs, exitval, self.stdoutbuf)
endfunction

" Function: s:job_exit {{{1
function! s:job_exit(bufnr, vcs, exitval, diff) abort
  call sy#verbose('job_exit()', a:vcs)
  let sy = getbufvar(a:bufnr, 'sy')
  if empty(sy)
    call sy#verbose(printf('No b:sy found for %s', bufname(a:bufnr)), a:vcs)
    return
  elseif !empty(sy.updated_by) && sy.updated_by != a:vcs
    call sy#verbose(printf('Signs already got updated by %s.', sy.updated_by), a:vcs)
    return
  elseif empty(sy.vcs) && sy.active
    let sy.detecting -= 1
  endif
  call sy#repo#get_diff_{a:vcs}(sy, a:exitval, a:diff)
  call setbufvar(a:bufnr, 'sy_job_id_'.a:vcs, 0)
endfunction

" Function: sy#get_diff_start {{{1
function! sy#repo#get_diff_start(vcs) abort
  call sy#verbose('get_diff_start()', a:vcs)

  let job_id = get(b:, 'sy_job_id_'.a:vcs)
  " Neovim
  if has('nvim')
    if job_id
      silent! call jobstop(job_id)
    endif

    let [cmd, options] = s:initialize_job(a:vcs)
    let [cwd, chdir] = sy#util#chdir()

    call sy#verbose(['CMD: '. string(cmd), 'CMD DIR:  '. b:sy.info.dir, 'ORIG DIR: '. cwd], a:vcs)

    try
      execute chdir fnameescape(b:sy.info.dir)
    catch
      echohl ErrorMsg
      echomsg 'signify: Changing directory failed: '. b:sy.info.dir
      echohl NONE
      return
    endtry
    let b:sy_job_id_{a:vcs} = jobstart(cmd, extend(options, {
          \ 'on_stdout': function('s:callback_nvim_stdout'),
          \ 'on_exit':   function('s:callback_nvim_exit'),
          \ }))
    execute chdir fnameescape(cwd)

  " Newer Vim
  elseif has('patch-7.4.1967')
    if type(job_id) != type(0)
      silent! call job_stop(job_id)
    endif

    let [cmd, options] = s:initialize_job(a:vcs)
    let [cwd, chdir] = sy#util#chdir()

    call sy#verbose(['CMD: '. string(cmd), 'CMD DIR:  '. b:sy.info.dir, 'ORIG DIR: '. cwd], a:vcs)

    try
      execute chdir fnameescape(b:sy.info.dir)
    catch
      echohl ErrorMsg
      echomsg 'signify: Changing directory failed: '. b:sy.info.dir
      echohl NONE
      return
    endtry
    let opts = {
          \ 'in_io':    'null',
          \ 'out_cb':   function('s:callback_vim_stdout', options),
          \ 'close_cb': function('s:callback_vim_close', options),
          \ }
    let b:sy_job_id_{a:vcs} = job_start(cmd, opts)
    execute chdir fnameescape(cwd)

  " Older Vim
  else
    let diff = split(s:run(a:vcs), '\n')
    call sy#repo#get_diff_{a:vcs}(b:sy, v:shell_error, diff)
  endif
endfunction

" Function: s:get_diff_end {{{1
function! s:get_diff_end(sy, found_diff, vcs, diff) abort
  call sy#verbose('get_diff_end()', a:vcs)
  if a:found_diff
    if index(a:sy.vcs, a:vcs) == -1
      let a:sy.vcs += [a:vcs]
    endif
    call sy#set_signs(a:sy, a:vcs, a:diff)
  else
    call sy#verbose('No valid diff found. Disabling this VCS.', a:vcs)
  endif
endfunction

" Function: #get_diff_git {{{1
function! sy#repo#get_diff_git(sy, exitval, diff) abort
  call sy#verbose('get_diff_git()', 'git')
  let [found_diff, diff] = a:exitval ? [0, []] : [1, a:diff]
  call s:get_diff_end(a:sy, found_diff, 'git', diff)
endfunction

" Function: #get_diff_hg {{{1
function! sy#repo#get_diff_hg(sy, exitval, diff) abort
  call sy#verbose('get_diff_hg()', 'hg')
  let [found_diff, diff] = a:exitval ? [0, []] : [1, a:diff]
  call s:get_diff_end(a:sy, found_diff, 'hg', diff)
endfunction

" Function: #get_diff_svn {{{1
function! sy#repo#get_diff_svn(sy, exitval, diff) abort
  call sy#verbose('get_diff_svn()', 'svn')
  let [found_diff, diff] = a:exitval ? [0, []] : [1, a:diff]
  call s:get_diff_end(a:sy, found_diff, 'svn', diff)
endfunction

" Function: #get_diff_bzr {{{1
function! sy#repo#get_diff_bzr(sy, exitval, diff) abort
  call sy#verbose('get_diff_bzr()', 'bzr')
  let [found_diff, diff] = (a:exitval =~ '[012]') ? [1, a:diff] : [0, []]
  call s:get_diff_end(a:sy, found_diff, 'bzr', diff)
endfunction

" Function: #get_diff_darcs {{{1
function! sy#repo#get_diff_darcs(sy, exitval, diff) abort
  call sy#verbose('get_diff_darcs()', 'darcs')
  let [found_diff, diff] = a:exitval ? [0, []] : [1, a:diff]
  call s:get_diff_end(a:sy, found_diff, 'darcs', diff)
endfunction

" Function: #get_diff_fossil {{{1
function! sy#repo#get_diff_fossil(sy, exitval, diff) abort
  call sy#verbose('get_diff_fossil()', 'fossil')
  let [found_diff, diff] = a:exitval ? [0, []] : [1, a:diff]
  call s:get_diff_end(a:sy, found_diff, 'fossil', diff)
endfunction

" Function: #get_diff_cvs {{{1
function! sy#repo#get_diff_cvs(sy, exitval, diff) abort
  call sy#verbose('get_diff_cvs()', 'cvs')
  let [found_diff, diff] = [0, []]
  if a:exitval == 1
    for diffline in a:diff
      if diffline =~ '^+++'
        let [found_diff, diff] = [1, a:diff]
        break
      endif
    endfor
  endif
  call s:get_diff_end(a:sy, found_diff, 'cvs', diff)
endfunction

" Function: #get_diff_rcs {{{1
function! sy#repo#get_diff_rcs(sy, exitval, diff) abort
  call sy#verbose('get_diff_rcs()', 'rcs')
  let [found_diff, diff] = a:exitval == 2 ? [0, []] : [1, a:diff]
  call s:get_diff_end(a:sy, found_diff, 'rcs', diff)
endfunction

" Function: #get_diff_accurev {{{1
function! sy#repo#get_diff_accurev(sy, exitval, diff) abort
  call sy#verbose('get_diff_accurev()', 'accurev')
  let [found_diff, diff] = (a:exitval >= 2) ? [0, []] : [1, a:diff]
  call s:get_diff_end(a:sy, found_diff, 'accurev', diff)
endfunction

" Function: #get_diff_perforce {{{1
function! sy#repo#get_diff_perforce(sy, exitval, diff) abort
  call sy#verbose('get_diff_perforce()', 'perforce')
  let [found_diff, diff] = a:exitval ? [0, []] : [1, a:diff]
  call s:get_diff_end(a:sy, found_diff, 'perforce', diff)
endfunction

" Function: #get_diff_tfs {{{1
function! sy#repo#get_diff_tfs(sy, exitval, diff) abort
  call sy#verbose('get_diff_tfs()', 'tfs')
  let [found_diff, diff] = a:exitval ? [0, []] : [1, s:strip_context(a:diff)]
  call s:get_diff_end(a:sy, found_diff, 'tfs', diff)
endfunction

" Function: #get_stats {{{1
function! sy#repo#get_stats() abort
  return exists('b:sy') ? b:sy.stats : [-1, -1, -1]
endfunction

" Function: #debug_detection {{{1
function! sy#repo#debug_detection()
  if !exists('b:sy')
    echomsg 'signify: I cannot detect any changes!'
    return
  endif

  for vcs in s:vcs_list
    let cmd = s:expand_cmd(vcs, g:signify_vcs_cmds)
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

" Function: #diffmode {{{1
function! sy#repo#diffmode(do_tab) abort
  execute sy#util#return_if_no_changes()

  let vcs = b:sy.updated_by
  if !has_key(g:signify_vcs_cmds_diffmode, vcs)
    echomsg 'SignifyDiff has no support for: '. vcs
    echomsg 'Open an issue for it at: https://github.com/mhinz/vim-signify/issues'
    return
  endif
  let cmd = s:expand_cmd(vcs, g:signify_vcs_cmds_diffmode)
  call sy#verbose('SignifyDiff: '. cmd, vcs)
  let ft = &filetype
  let fenc = &fenc
  if a:do_tab
    tabedit %
  endif
  diffthis
  let [cwd, chdir] = sy#util#chdir()
  try
    execute chdir fnameescape(b:sy.info.dir)
    leftabove vnew
    if has('iconv')
      silent put =iconv(system(cmd), fenc, &enc)
    else
      silent put =system(cmd)
    endif
  finally
    execute chdir fnameescape(cwd)
  endtry
  silent 1delete
  set buftype=nofile bufhidden=wipe nomodified
  let &filetype = ft
  diffthis
  wincmd p
  normal! ]czt
endfunction

" Function: s:initialize_job {{{1
function! s:initialize_job(vcs) abort
  let vcs_cmd = s:expand_cmd(a:vcs, g:signify_vcs_cmds)
  if has('win32')
    if has('nvim')
      let cmd = &shell =~ '\v%(cmd|powershell)' ? vcs_cmd : ['sh', '-c', vcs_cmd]
    else
      if &shell =~ 'cmd'
        let cmd = vcs_cmd
      elseif empty(&shellxquote)
        let cmd = join([&shell, &shellcmdflag, &shellquote, vcs_cmd, &shellquote])
      else
        let cmd = join([&shell, &shellcmdflag, &shellxquote, vcs_cmd, &shellxquote])
      endif
    endif
  else
    let cmd = ['sh', '-c', vcs_cmd]
  endif
  let options = {
        \ 'stdoutbuf':   [],
        \ 'vcs':         a:vcs,
        \ 'bufnr':       bufnr('%'),
        \ }
  return [cmd, options]
endfunction

" Function: s:get_vcs_path {{{1
function! s:get_vcs_path(vcs) abort
  return (a:vcs =~# '\v(git|cvs|accurev|tfs)') ? b:sy.info.file : b:sy.info.path
endfunction

" Function: s:expand_cmd {{{1
function! s:expand_cmd(vcs, vcs_cmds) abort
  let cmd = a:vcs_cmds[a:vcs]
  let cmd = s:replace(cmd, '%f', s:get_vcs_path(a:vcs))
  let cmd = s:replace(cmd, '%d', s:difftool)
  let cmd = s:replace(cmd, '%n', s:devnull)
  return cmd
endfunction

" Function: s:run {{{1
function! s:run(vcs)
  let [cwd, chdir] = sy#util#chdir()
  try
    execute chdir fnameescape(b:sy.info.dir)
    let ret = system(s:expand_cmd(a:vcs, g:signify_vcs_cmds))
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
  let lines = a:context
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
  return diff
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
  call sy#verbose('No "diff" executable found. Disable support for svn, darcs, bzr, fossil.')
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

let s:default_vcs_cmds = {
      \ 'git':      'git diff --no-color --no-ext-diff -U0 -- %f',
      \ 'hg':       'hg diff --color=never --config aliases.diff= --nodates -U0 -- %f',
      \ 'svn':      'svn diff --diff-cmd %d -x -U0 -- %f',
      \ 'bzr':      'bzr diff --using %d --diff-options=-U0 -- %f',
      \ 'darcs':    'darcs diff --no-pause-for-gui --no-unified --diff-opts=-U0 -- %f',
      \ 'fossil':   'fossil diff --unified -c 0 -- %f',
      \ 'cvs':      'cvs diff -U0 -- %f',
      \ 'rcs':      'rcsdiff -U0 %f 2>%n',
      \ 'accurev':  'accurev diff %f -- -U0',
      \ 'perforce': 'p4 info '. sy#util#shell_redirect('%n') . (has('win32') ? ' &&' : ' && env P4DIFF= P4COLORS=') .' p4 diff -du0 %f',
      \ 'tfs':      'tf diff -version:W -noprompt -format:Unified %f'
      \ }

let s:default_vcs_cmds_diffmode = {
      \ 'git':      'git show HEAD:./%f',
      \ 'hg':       'hg cat %f',
      \ 'svn':      'svn cat %f',
      \ 'bzr':      'bzr cat %f',
      \ 'darcs':    'darcs show contents -- %f',
      \ 'cvs':      'cvs up -p -- %f 2>%n',
      \ 'perforce': 'p4 print %f',
      \ }

if exists('g:signify_vcs_cmds')
  call extend(g:signify_vcs_cmds, s:default_vcs_cmds, 'keep')
else
  let g:signify_vcs_cmds = s:default_vcs_cmds
endif
if exists('g:signify_vcs_cmds_diffmode')
  call extend(g:signify_vcs_cmds_diffmode, s:default_vcs_cmds_diffmode, 'keep')
else
  let g:signify_vcs_cmds_diffmode = s:default_vcs_cmds_diffmode
endif

let s:difftool = sy#util#escape(s:difftool)
let s:devnull  = has('win32') || has ('win64') ? 'NUL' : '/dev/null'
