" vim: et sw=2 sts=2

scriptencoding utf-8

" Init: values {{{1

let s:diffoptions = get(g:, 'signify_diffoptions', {})
let s:difftool    = get(g:, 'signify_difftool', 'diff')

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

" Function: #detect {{{1
function! sy#repo#detect(path) abort
  let dir = fnamemodify(a:path, ':h')

  " Simple cache. If there is a registered VCS-controlled file in this
  " directory already, assume that this file is probably controlled by
  " the same VCS. Thus we shuffle that VCS to the top of our vcs_list.
  if has_key(g:sy_cache, dir)
    let idx = index(s:vcs_list, g:sy_cache[dir])
    if idx != -1
      call remove(s:vcs_list, idx)
      call insert(s:vcs_list, g:sy_cache[dir], 0)
    endif
  endif

  for type in s:vcs_list
    let [istype, diff] = sy#repo#get_diff_{type}(a:path)
    if istype
      return [ diff, type ]
    endif
  endfor

  return [ '', 'unknown' ]
endfunction

" Function: #get_diff_git {{{1
function! sy#repo#get_diff_git(path) abort
  let diffoptions = has_key(s:diffoptions, 'git') ? s:diffoptions.git : ''
  let diff = system('cd '. sy#util#escape(fnamemodify(a:path, ':h')) .' && git diff --no-color --no-ext-diff -U0 '. diffoptions .' -- '. sy#util#escape(a:path))

  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_stat_git {{{1
function! sy#repo#get_stat_git() abort
  let s:stats = []
  let root  = finddir('.git', fnamemodify(g:sy_path, ':h') .';')
  if empty(root)
    echohl ErrorMsg | echomsg 'Cannot find the git root directory: '. g:sy_path | echohl None
    return
  endif
  let root   = fnamemodify(root, ':h')
  let output = system('cd '. sy#util#escape(root) .' && git diff --numstat')
  if v:shell_error
    echohl ErrorMsg | echomsg "'git diff --numstat' failed" | echohl None
    return
  endif
  for stat in split(output, '\n')
    let tokens = matchlist(stat, '\v([0-9-]+)\t([0-9-]+)\t(.*)')
    if empty(tokens)
      echohl ErrorMsg | echomsg 'Cannot parse this line: '. stat | echohl None
    elseif tokens[1] == '-'
      continue
    else
      let path = root . sy#util#separator() . tokens[3]
      if !bufexists(path)
        execute 'argadd '. path
      endif
      call add(s:stats, { 'bufnr': bufnr(path), 'text': tokens[1] .' additions, '. tokens[2] .' deletions', 'lnum': 1, 'col': 1 })
    endif
  endfor
  "call setqflist(stats)
endfunction

" Function: #get_diff_hg {{{1
function! sy#repo#get_diff_hg(path) abort
  let diffoptions = has_key(s:diffoptions, 'hg') ? s:diffoptions.hg : ''
  let diff = system('hg diff --nodates -U0 '. diffoptions .' -- '. sy#util#escape(a:path))

  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_svn {{{1
function! sy#repo#get_diff_svn(path) abort
  let diffoptions = has_key(s:diffoptions, 'svn') ? s:diffoptions.svn : ''
  let diff = system('svn diff --diff-cmd '. s:difftool .' -x -U0 '. diffoptions .' -- '. sy#util#escape(a:path))

  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_bzr {{{1
function! sy#repo#get_diff_bzr(path) abort
  let diffoptions = has_key(s:diffoptions, 'bzr') ? s:diffoptions.bzr : ''
  let diff = system('bzr diff --using '. s:difftool .' --diff-options=-U0 '. diffoptions .' -- '. sy#util#escape(a:path))

  return (v:shell_error =~ '[012]') ? [1, diff] : [0, '']
endfunction

" Function: #get_diff_darcs {{{1
function! sy#repo#get_diff_darcs(path) abort
  let diffoptions = has_key(s:diffoptions, 'darcs') ? s:diffoptions.darcs : ''
  let diff = system('cd '. sy#util#escape(fnamemodify(a:path, ':h')) .' && darcs diff --no-pause-for-gui --diff-command="'. s:difftool .' -U0 %1 %2 '. diffoptions .'" -- '. sy#util#escape(a:path))
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_fossil {{{1
function! sy#repo#get_diff_fossil(path) abort
  let diffoptions = has_key(s:diffoptions, 'fossil') ? s:diffoptions.fossil : ''
  let diff = system('cd '. sy#util#escape(fnamemodify(a:path, ':h')) .' && fossil set diff-command "'. s:difftool .' -U 0" && fossil diff --unified -c 0 '. diffoptions .' -- '. sy#util#escape(a:path))
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_cvs {{{1
function! sy#repo#get_diff_cvs(path) abort
  let diffoptions = has_key(s:diffoptions, 'cvs') ? s:diffoptions.cvs : ''
  let diff = system('cd '. sy#util#escape(fnamemodify(a:path, ':h')) .' && cvs diff -U0 '. diffoptions .' -- '. sy#util#escape(fnamemodify(a:path, ':t')))
  return ((v:shell_error == 1) && (diff =~ '+++')) ? [1, diff] : [0, '']
endfunction

" Function: #get_diff_rcs {{{1
function! sy#repo#get_diff_rcs(path) abort
  let diffoptions = has_key(s:diffoptions, 'rcs') ? s:diffoptions.rcs : ''
  let diff = system('rcsdiff -U0 '. diffoptions .' '. sy#util#escape(a:path) .' 2>/dev/null')
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_accurev {{{1
function! sy#repo#get_diff_accurev(path) abort
  let diffoptions = has_key(s:diffoptions, 'accurev') ? s:diffoptions.accurev : ''
  let diff = system('cd '. sy#util#escape(fnamemodify(a:path, ':h')) .' && accurev diff '. sy#util#escape(fnamemodify(a:path, ':t')) . ' -- -U0 '. diffoptions)
  return (v:shell_error != 1) ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_perforce {{{1
function! sy#repo#get_diff_perforce(path) abort
  let diffoptions = has_key(s:diffoptions, 'perforce') ? s:diffoptions.perforce : ''
  let diff = system('env P4DIFF=diff p4 diff -du0 '. diffoptions .' '. sy#util#escape(a:path))
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #process_diff {{{1
function! sy#repo#process_diff(path, diff) abort
  let added    = 0
  let deleted  = 0
  let modified = 0

  " Determine where we have to put our signs.
  for line in filter(split(a:diff, '\n'), 'v:val =~ "^@@ "')
    let tokens = matchlist(line, '^@@ -\v(\d+),?(\d*) \+(\d+),?(\d*)')

    let old_line = str2nr(tokens[1])
    let new_line = str2nr(tokens[3])

    let old_count = empty(tokens[2]) ? 1 : str2nr(tokens[2])
    let new_count = empty(tokens[4]) ? 1 : str2nr(tokens[4])

    let signs = []

    " 2 lines added:

    " @@ -5,0 +6,2 @@ this is line 5
    " +this is line 5
    " +this is line 5

    if (old_count == 0) && (new_count >= 1)
      let added += new_count
      let offset = 0

      while offset < new_count
        call add(signs, {
              \ 'type': 'SignifyAdd',
              \ 'lnum': new_line + offset,
              \ 'path': a:path })
        let offset += 1
      endwhile

    " 2 lines removed:

    " @@ -6,2 +5,0 @@ this is line 5
    " -this is line 6
    " -this is line 7

    elseif (old_count >= 1) && (new_count == 0)
      let deleted += old_count

      if new_line == 0
        call add(signs, {
              \ 'type': 'SignifyDeleteFirstLine',
              \ 'lnum': 1,
              \ 'path': a:path })
      else
        call add(signs, {
              \ 'type': (old_count > 9) ? 'SignifyDeleteMore' : 'SignifyDelete'. old_count,
              \ 'lnum': new_line,
              \ 'path': a:path })
      endif

    " 2 lines changed:

    " @@ -5,2 +5,2 @@ this is line 4
    " -this is line 5
    " -this is line 6
    " +this os line 5
    " +this os line 6

    elseif old_count == new_count
      let modified += old_count
      let offset    = 0

      while offset < new_count
        call add(signs, {
              \ 'type': 'SignifyChange',
              \ 'lnum': new_line + offset,
              \ 'path': a:path })
        let offset += 1
      endwhile
    else

      " 2 lines changed; 2 lines deleted:

      " @@ -5,4 +5,2 @@ this is line 4
      " -this is line 5
      " -this is line 6
      " -this is line 7
      " -this is line 8
      " +this os line 5
      " +this os line 6

      if old_count > new_count
        let modified += new_count
        let removed   = (old_count - new_count)
        let deleted  += removed
        let offset    = 0

        while offset < (new_count - 1)
          call add(signs, {
                \ 'type': 'SignifyChange',
                \ 'lnum': new_line + offset,
                \ 'path': a:path })
          let offset += 1
        endwhile

        call add(signs, {
              \ 'type': (removed > 9) ? 'SignifyChangeDeleteMore' : 'SignifyChangeDelete'. removed,
              \ 'lnum': new_line,
              \ 'path': a:path })

      " lines changed and added:

      " @@ -5 +5,3 @@ this is line 4
      " -this is line 5
      " +this os line 5
      " +this is line 42
      " +this is line 666

      else
        let modified += old_count
        let added    += (new_count - old_count)
        let offset    = 0

        while offset < old_count
          call add(signs, {
                \ 'type': 'SignifyChange',
                \ 'lnum': new_line + offset,
                \ 'path': a:path })
          let offset += 1
        endwhile

        while offset < new_count
          call add(signs, {
                \ 'type': 'SignifyAdd',
                \ 'lnum': new_line + offset,
                \ 'path': a:path })
          let offset += 1
        endwhile
      endif
    endif

    call sy#sign#set(signs)
  endfor

  let g:sy[g:sy_path].stats = [added, modified, deleted]
endfunction

" Function: #get_stats {{{1
function! sy#repo#get_stats() abort
  if !exists('g:sy_path') || !has_key(g:sy, g:sy_path)
    return [-1, -1, -1]
  endif

  return g:sy[g:sy_path].stats
endfunction
