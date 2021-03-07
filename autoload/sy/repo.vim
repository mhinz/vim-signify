" vim: et sw=2 sts=2 fdm=marker

scriptencoding utf-8

" #detect {{{1
function! sy#repo#detect(bufnr) abort
  let sy = getbufvar(a:bufnr, 'sy')
  for vcs in s:vcs_list
    let sy.detecting += 1
    call sy#repo#get_diff(a:bufnr, vcs, function('sy#sign#set_signs'))
  endfor
endfunction

" s:callback_nvim_stdout{{{1
function! s:callback_nvim_stdout(_job_id, data, _event) dict abort
  let self.stdoutbuf[-1] .= a:data[0]
  call extend(self.stdoutbuf, a:data[1:])
endfunction

" s:callback_nvim_exit {{{1
function! s:callback_nvim_exit(_job_id, exitval, _event) dict abort
  return s:handle_diff(self, a:exitval)
endfunction

" s:callback_vim_stdout {{{1
function! s:callback_vim_stdout(_job_id, data) dict abort
  let self.stdoutbuf += [a:data]
endfunction

" s:callback_vim_close {{{1
function! s:callback_vim_close(channel) dict abort
  let job = ch_getjob(a:channel)
  while 1
    if job_status(job) == 'dead'
      let exitval = job_info(job).exitval
      break
    endif
    sleep 10m
  endwhile
  return s:handle_diff(self, exitval)
endfunction

" s:write_buffer {{{1
function! s:write_buffer(bufnr, file)
  let bufcontents = getbufline(a:bufnr, 1, '$')

  if bufcontents == [''] && line2byte(1) == -1
    " Special case: completely empty buffer.
    " A nearly empty buffer of only a newline has line2byte(1) == 1.
    call writefile([], a:file)
    return
  endif

  if getbufvar(a:bufnr, '&fileformat') ==# 'dos'
    call map(bufcontents, 'v:val."\r"')
  endif

  let fenc = getbufvar(a:bufnr, '&fileencoding')
  let enc  = getbufvar(a:bufnr, '&encoding')
  if fenc !=# enc
    call map(bufcontents, 'iconv(v:val, "'.enc.'", "'.fenc.'")')
  endif

  if getbufvar(a:bufnr, '&bomb')
    let bufcontents[0]='﻿'.bufcontents[0]
  endif

  call writefile(bufcontents, a:file)
endfunction

" sy#get_diff {{{1
function! sy#repo#get_diff(bufnr, vcs, func) abort
  call sy#verbose('sy#repo#get_diff()', a:vcs)

  let job_id = getbufvar(a:bufnr, 'sy_job_id_'.a:vcs)

  if getbufvar(a:bufnr, '&modified')
    let [cmd, options] = s:initialize_buffer_job(a:bufnr, a:vcs)
    let options.difftool = 'diff'
  else
    let [cmd, options] = s:initialize_job(a:bufnr, a:vcs)
    let options.difftool = a:vcs
  endif

  let options.func = a:func

  if has('nvim')
    if job_id
      silent! call jobstop(job_id)
    endif
    let job_id = jobstart(cmd, extend(options, {
          \ 'cwd':       getbufvar(a:bufnr, 'sy').info.dir,
          \ 'on_stdout': function('s:callback_nvim_stdout'),
          \ 'on_exit':   function('s:callback_nvim_exit'),
          \ }))
    call setbufvar(a:bufnr, 'sy_job_id_'.a:vcs, job_id)
  elseif has('patch-8.0.902')
    if type(job_id) != type(0)
      silent! call job_stop(job_id)
    endif
    let opts = {
          \ 'cwd':      getbufvar(a:bufnr, 'sy').info.dir,
          \ 'in_io':    'null',
          \ 'out_cb':   function('s:callback_vim_stdout', options),
          \ 'close_cb': function('s:callback_vim_close', options),
          \ }
    let job_id = job_start(cmd, opts)
    call setbufvar(a:bufnr, 'sy_job_id_'.a:vcs, job_id)
  else
    let options.stdoutbuf = split(s:run(a:vcs), '\n')
    call s:handle_diff(options, v:shell_error)
  endif
endfunction

" s:handle_diff {{{1
function! s:handle_diff(options, exitval) abort
  call sy#verbose('s:handle_diff()', a:options.vcs)

  if has_key(a:options, 'tempfiles')
    for f in a:options.tempfiles
      call delete(f)
    endfor
  endif

  let sy = getbufvar(a:options.bufnr, 'sy')
  if empty(sy)
    call sy#verbose(printf('No b:sy found for %s', bufname(a:options.bufnr)), a:options.vcs)
    return
  elseif !empty(sy.updated_by) && sy.updated_by != a:options.vcs
    call sy#verbose(printf('Signs already got updated by %s.', sy.updated_by), a:options.vcs)
    return
  elseif empty(sy.vcs)
    let sy.detecting -= 1
  endif

  let fenc = getbufvar(a:options.bufnr, '&fenc')
  let enc  = getbufvar(a:options.bufnr, '&enc')
  if (fenc != enc) && has('iconv')
    call map(a:options.stdoutbuf, printf('iconv(v:val, "%s", "%s")', fenc, enc))
  endif

  let [found_diff, diff] = s:check_diff_{a:options.difftool}(a:exitval, a:options.stdoutbuf)
  if found_diff
    if index(sy.vcs, a:options.vcs) == -1
      let sy.vcs += [a:options.vcs]
    endif
    call a:options.func(sy, a:options.vcs, diff)
  else
    call sy#verbose('No valid diff found. Disabling this VCS.', a:options.vcs)
  endif

  call setbufvar(a:options.bufnr, 'sy_job_id_'.a:options.vcs, 0)
endfunction

" s:check_diff_diff {{{1
function! s:check_diff_diff(exitval, diff) abort
  return a:exitval <= 1 ? [1, a:diff] : [0, []]
endfunction

" s:check_diff_git {{{1
function! s:check_diff_git(exitval, diff) abort
  return a:exitval ? [0, []] : [1, a:diff]
endfunction

" s:check_diff_yadm {{{1
function! s:check_diff_yadm(exitval, diff) abort
  return a:exitval ? [0, []] : [1, a:diff]
endfunction

" s:check_diff_hg {{{1
function! s:check_diff_hg(exitval, diff) abort
  return a:exitval ? [0, []] : [1, a:diff]
endfunction

" s:check_diff_svn {{{1
function! s:check_diff_svn(exitval, diff) abort
  return a:exitval ? [0, []] : [1, a:diff]
endfunction

" s:check_diff_bzr {{{1
function! s:check_diff_bzr(exitval, diff) abort
  return (a:exitval =~ '[012]') ? [1, a:diff] : [0, []]
endfunction

" s:check_diff_darcs {{{1
function! s:check_diff_darcs(exitval, diff) abort
  return a:exitval ? [0, []] : [1, a:diff]
endfunction

" s:check_diff_fossil {{{1
function! s:check_diff_fossil(exitval, diff) abort
  return a:exitval ? [0, []] : [1, a:diff]
endfunction

" s:check_diff_cvs {{{1
function! s:check_diff_cvs(exitval, diff) abort
  let [found_diff, diff] = [0, []]
  if a:exitval == 1
    for diffline in a:diff
      if diffline =~ '^+++'
        let [found_diff, diff] = [1, a:diff]
        break
      endif
    endfor
  elseif a:exitval == 0 && len(a:diff) == 0
    let found_diff = 1
  endif
  return [found_diff, diff]
endfunction

" s:check_diff_rcs {{{1
function! s:check_diff_rcs(exitval, diff) abort
  return (a:exitval == 2) ? [0, []] : [1, a:diff]
endfunction

" s:check_diff_accurev {{{1
function! s:check_diff_accurev(exitval, diff) abort
  return (a:exitval >= 2) ? [0, []] : [1, a:diff]
endfunction

" s:check_diff_perforce {{{1
function! s:check_diff_perforce(exitval, diff) abort
  return a:exitval ? [0, []] : [1, a:diff]
endfunction

" s:check_diff_tfs {{{1
function! s:check_diff_tfs(exitval, diff) abort
  return a:exitval ? [0, []] : [1, s:strip_context(a:diff)]
endfunction

" #get_stats {{{1
function! sy#repo#get_stats(...) abort
  let sy = getbufvar(a:0 ? a:1 : bufnr(''), 'sy')
  return empty(sy) ? [-1, -1, -1] : sy.stats
endfunction

" #get_stats_decorated {{{1
function! sy#repo#get_stats_decorated(...)
  let bufnr = a:0 ? a:1 : bufnr('')
  let [added, modified, removed] = sy#repo#get_stats(bufnr)
  let symbols = ['+', '-', '~']
  let stats = [added, removed, modified]  " reorder
  let statline = ''

  for i in range(3)
    if stats[i] > 0
      let statline .= printf('%s%s ', symbols[i], stats[i])
    endif
  endfor

  if !empty(statline)
    let statline = printf('[%s]', statline[:-2])
  endif

  return statline
endfunction

" #debug_detection {{{1
function! sy#repo#debug_detection()
  if empty(getbufvar(bufnr(''), 'sy'))
    echomsg 'signify: I cannot detect any changes!'
    return
  endif

  for vcs in s:vcs_list
    let cmd = s:get_base_cmd(bufnr(''), vcs, g:signify_vcs_cmds)
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

function! s:system_in_dir(cmd) abort
  let [cwd, chdir] = sy#util#chdir()
  try
    execute chdir fnameescape(b:sy.info.dir)
    return system(a:cmd)
  finally
    execute chdir fnameescape(cwd)
  endtry
endfunction

" #diffmode {{{1
function! sy#repo#diffmode(do_tab) abort
  execute sy#util#return_if_no_changes()

  let vcs = b:sy.updated_by

  call sy#verbose('SignifyDiff', vcs)
  let ft = &filetype
  let fenc = &fenc
  if a:do_tab
    tabedit %
  endif
  diffthis

  let base = s:get_base(bufnr(''), vcs)

  leftabove vnew
  if (fenc != &enc) && has('iconv')
    silent put =iconv(base, fenc, &enc)
  else
    silent put =base
  endif

  silent 1delete
  set buftype=nofile bufhidden=wipe nomodified
  let &filetype = ft
  diffthis
  wincmd p
  normal! ]czt
endfunction

" s:extract_current_hunk {{{1
function! s:extract_current_hunk(diff) abort
  let header = ''
  let hunk = []

  for line in a:diff
    if header != ''
      if line[:2] == '@@ ' || empty(line)
        break
      endif
      call add(hunk, line)
    elseif line[:2] == '@@ ' && s:is_cur_line_in_hunk(line)
      let header = line
    endif
  endfor

  return [header, hunk]
endfunction

function! s:is_cur_line_in_hunk(hunkline) abort
  let cur_line = line('.')
  let [_old_line, old_count, new_line, new_count] = sy#sign#parse_hunk(a:hunkline)

  if cur_line == 1 && new_line == 0
    " deleted first line
    return 1
  endif

  if cur_line == new_line && new_count < old_count
    " deleted lines
    return 1
  endif

  if cur_line >= new_line && cur_line < (new_line + new_count)
    " added/changed lines
    return 1
  endif

  return 0
endfunction

" #diff_hunk {{{1
function! sy#repo#diff_hunk() abort
  let bufnr = bufnr('')
  let sy = getbufvar(bufnr, 'sy')
  if !empty(sy) && !empty(sy.updated_by)
    call sy#repo#get_diff(bufnr, sy.updated_by, function('s:diff_hunk'))
  endif
endfunction

function! s:diff_hunk(_sy, vcs, diff) abort
  call sy#verbose('s:preview_hunk()', a:vcs)

  let [_, hunk] = s:extract_current_hunk(a:diff)
  if empty(hunk)
    return
  endif

  if sy#util#popup_create(hunk)
    return
  endif

  silent! wincmd P
  if !&previewwindow
    noautocmd botright new
  endif
  call setline(1, hunk)
  silent! %foldopen!
  setlocal previewwindow filetype=diff buftype=nofile bufhidden=delete
  " With :noautocmd wincmd p, the first line of the preview window would show
  " the 'cursorline', although it's not focused. Use feedkeys() instead.
  noautocmd call feedkeys("\<c-w>p", 'nt')
endfunction

" #undo_hunk {{{1
function! sy#repo#undo_hunk() abort
  let bufnr = bufnr('')
  let sy = getbufvar(bufnr, 'sy')
  if !empty(sy) && !empty(sy.updated_by)
    call sy#repo#get_diff(bufnr, sy.updated_by, function('s:undo_hunk'))
  endif
endfunction

function! s:undo_hunk(sy, vcs, diff) abort
  call sy#verbose('s:undo_hunk()', a:vcs)

  let [header, hunk] = s:extract_current_hunk(a:diff)
  if empty(hunk)
    return
  endif

  let [_old_line, _old_count, new_line, new_count] = sy#sign#parse_hunk(header)

  for line in hunk
    let op = line[0]
    let text = line[1:]
    if op == ' '
      if text != getline(new_line)
        echoerr 'Could not apply context hunk for undo. Try saving the buffer first.'
        return
      endif
      let new_line += 1
    elseif op == '-'
      call append(new_count == 0 ? new_line : new_line - 1, text)
      let new_line += 1
    elseif op == '+'
      if text != getline(new_line)
        echoerr 'Could not apply addition hunk for undo. Try saving the buffer first.'
        return
      endif
      execute 'silent' new_line 'delete _'
    else
      echoer 'Unknown diff operation ' . line
      return
    endif
  endfor

  " Undoing altered the buffer, so update signs.
  call setbufvar(a:sy.buffer, 'sy_job_id_'.a:vcs, 0)
  return sy#start()
endfunction

" s:initialize_job {{{1
function! s:initialize_job(bufnr, vcs) abort
  return s:wrap_cmd(a:bufnr, a:vcs, s:get_base_cmd(a:bufnr, a:vcs, g:signify_vcs_cmds))
endfunction

" s:initialize_buffer_job {{{1
function! s:initialize_buffer_job(bufnr, vcs) abort
  let bufferfile = tempname()
  call s:write_buffer(a:bufnr, bufferfile)

  let basefile = tempname()
  let base_cmd = s:get_base_cmd(a:bufnr, a:vcs, g:signify_vcs_cmds_diffmode) . '>' . fnameescape(basefile) . ' && '

  let diff_cmd = base_cmd .  s:difftool . ' -U0 ' . fnameescape(basefile) . ' ' . fnameescape(bufferfile)
  let [cmd, options] = s:wrap_cmd(a:bufnr, a:vcs, diff_cmd)

  let options.tempfiles = [basefile, bufferfile]

  return [cmd, options]
endfunction

" s:wrap_cmd {{{1
function! s:wrap_cmd(bufnr, vcs, cmd) abort
  if has('win32')
    if has('nvim')
      let cmd = &shell =~ '\v%(cmd|powershell|pwsh)' ? a:cmd : ['sh', '-c', a:cmd]
    else
      if &shell =~ 'cmd'
        let cmd = join([&shell, &shellcmdflag, '(', a:cmd, ')'])
      elseif empty(&shellxquote)
        let cmd = join([&shell, &shellcmdflag, &shellquote, a:cmd, &shellquote])
      else
        let cmd = join([&shell, &shellcmdflag, &shellxquote, a:cmd, &shellxquote])
      endif
    endif
  else
    let cmd = ['sh', '-c', a:cmd]
  endif
  let options = {
        \ 'stdoutbuf': [''],
        \ 'vcs': a:vcs,
        \ 'bufnr': a:bufnr,
        \ }
  return [cmd, options]
endfunction

" s:get_vcs_path {{{1
function! s:get_vcs_path(bufnr, vcs) abort
  return (a:vcs =~# '\v(git|cvs|accurev|tfs|yadm)')
        \ ? getbufvar(a:bufnr, 'sy').info.file
        \ : getbufvar(a:bufnr, 'sy').info.path
endfunction

" s:get_base_cmd {{{1
function! s:get_base_cmd(bufnr, vcs, vcs_cmds) abort
  let cmd = a:vcs_cmds[a:vcs]
  let cmd = s:replace(cmd, '%f', s:get_vcs_path(a:bufnr, a:vcs))
  let cmd = s:replace(cmd, '%d', s:difftool)
  let cmd = s:replace(cmd, '%n', s:devnull)
  return cmd
endfunction

" s:get_base {{{1
" Get the "base" version of the current buffer as a string.
function! s:get_base(bufnr, vcs) abort
  return s:system_in_dir(s:get_base_cmd(a:bufnr, a:vcs, g:signify_vcs_cmds_diffmode))
endfunction

" s:run {{{1
function! s:run(vcs)
  try
    let ret = s:system_in_dir(s:get_base_cmd(bufnr(''), a:vcs, g:signify_vcs_cmds))
  catch
    " This exception message can be seen via :SignifyDebugUnknown.
    " E.g. unquoted VCS programs in vcd_cmds can lead to E484.
    let ret = v:exception .' at '. v:throwpoint
  finally
    return ret
  endtry
endfunction

" s:replace {{{1
function! s:replace(cmd, pat, sub)
  let parts = split(a:cmd, a:pat, 1)
  return join(parts, a:sub)
endfunction

" s:strip_context {{{1
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
        let [old_line, old_count, new_line, new_count] = sy#sign#parse_hunk(line)
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
" 1}}}

" Variables {{{1
let s:default_vcs_cmds = {
      \ 'git':      'git diff --no-color --no-ext-diff -U0 -- %f',
      \ 'yadm':     'yadm diff --no-color --no-ext-diff -U0 -- %f',
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
      \ 'yadm':     'yadm show HEAD:./%f',
      \ 'hg':       'hg cat %f',
      \ 'svn':      'svn cat %f',
      \ 'bzr':      'bzr cat %f',
      \ 'darcs':    'darcs show contents -- %f',
      \ 'fossil':   'fossil cat %f',
      \ 'cvs':      'cvs up -p -- %f 2>%n',
      \ 'rcs':      'co -q -p %f',
      \ 'accurev':  'accurev cat %f',
      \ 'perforce': 'p4 print %f',
      \ 'tfs':      'tf view -version:W -noprompt %f',
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

let s:vcs_dict = map(copy(g:signify_vcs_cmds), 'split(v:val)[0]')

if exists('g:signify_skip') && has_key(g:signify_skip, 'vcs')
  if has_key(g:signify_skip.vcs, 'allow')
    let s:vcs_list = filter(copy(g:signify_skip.vcs.allow), 'executable(s:vcs_dict[v:val])')
  elseif has_key(g:signify_skip.vcs, 'deny')
    for vcs in g:signify_skip.vcs.deny
      silent! call remove(s:vcs_dict, vcs)
    endfor
    let s:vcs_list = keys(filter(s:vcs_dict, 'executable(v:val)'))
  end
else
  let s:vcs_list = keys(filter(s:vcs_dict, 'executable(v:val)'))
endif

let s:difftool = sy#util#escape(get(g:, 'signify_difftool', 'diff'))
let s:devnull  = has('win32') || has ('win64') ? 'NUL' : '/dev/null'
