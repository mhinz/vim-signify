" vim: et sw=2 sts=2

scriptencoding utf-8

" Init: values {{{1
if !exists('g:signify_diffoptions')
  let g:signify_diffoptions = {}
endif

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

" Function: #detect {{{1
function! sy#repo#detect() abort
  let dir = fnamemodify(b:sy.path, ':h')

  let vcs_list = s:vcs_list
  " Simple cache. If there is a registered VCS-controlled file in this
  " directory already, assume that this file is probably controlled by
  " the same VCS. Thus we shuffle that VCS to the top of our copy of
  " s:vcs_list, so we don't affect the preference order of s:vcs_list.
  if has_key(g:sy_cache, dir)
    let vcs_list = [g:sy_cache[dir]] + filter(copy(s:vcs_list), 'v:val != "'. g:sy_cache[dir] .'"')
  endif

  for type in vcs_list
    let [istype, diff] = sy#repo#get_diff_{type}()
    if istype
      return [ diff, type ]
    endif
  endfor

  return [ '', 'unknown' ]
endfunction

" Function: #get_diff_git {{{1
function! sy#repo#get_diff_git() abort
  let diffoptions = has_key(g:signify_diffoptions, 'git') ? g:signify_diffoptions.git : ''
  let diff = sy#util#run_in_dir(fnamemodify(b:sy.path, ':h'), 'git diff --no-color --no-ext-diff -U0 '. diffoptions .' -- '. sy#util#escape(fnamemodify(b:sy.path, ':t')))

  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_stat_git {{{1
function! sy#repo#get_stat_git() abort
  let s:stats = []
  let root  = finddir('.git', fnamemodify(b:sy.path, ':h') .';')
  if empty(root)
    echohl ErrorMsg | echomsg 'Cannot find the git root directory: '. b:sy.path | echohl None
    return
  endif
  let root   = fnamemodify(root, ':h')
  let output = sy#util#run_in_dir(root, 'git diff --numstat')
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
function! sy#repo#get_diff_hg() abort
  let diffoptions = has_key(g:signify_diffoptions, 'hg') ? g:signify_diffoptions.hg : ''
  let diff = system('hg diff --nodates -U0 '. diffoptions .' -- '. sy#util#escape(b:sy.path))

  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_svn {{{1
function! sy#repo#get_diff_svn() abort
  let diffoptions = has_key(g:signify_diffoptions, 'svn') ? g:signify_diffoptions.svn : ''
  let diff = system('svn diff --diff-cmd '. s:difftool .' -x -U0 '. diffoptions .' -- '. sy#util#escape(b:sy.path))

  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_bzr {{{1
function! sy#repo#get_diff_bzr() abort
  let diffoptions = has_key(g:signify_diffoptions, 'bzr') ? g:signify_diffoptions.bzr : ''
  let diff = system('bzr diff --using '. s:difftool .' --diff-options=-U0 '. diffoptions .' -- '. sy#util#escape(b:sy.path))

  return (v:shell_error =~ '[012]') ? [1, diff] : [0, '']
endfunction

" Function: #get_diff_darcs {{{1
function! sy#repo#get_diff_darcs() abort
  let diffoptions = has_key(g:signify_diffoptions, 'darcs') ? g:signify_diffoptions.darcs : ''
  let diff = sy#util#run_in_dir(fnamemodify(b:sy.path, ':h'), 'darcs diff --no-pause-for-gui --diff-command="'. s:difftool .' -U0 %1 %2 '. diffoptions .'" -- '. sy#util#escape(b:sy.path))
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_fossil {{{1
function! sy#repo#get_diff_fossil() abort
  let diffoptions = has_key(g:signify_diffoptions, 'fossil') ? g:signify_diffoptions.fossil : ''
  let diff = sy#util#run_in_dir(fnamemodify(b:sy.path, ':h'), 'fossil set diff-command "'. s:difftool .' -U 0" && fossil diff --unified -c 0 '. diffoptions .' -- '. sy#util#escape(b:sy.path))
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_cvs {{{1
function! sy#repo#get_diff_cvs() abort
  let diffoptions = has_key(g:signify_diffoptions, 'cvs') ? g:signify_diffoptions.cvs : ''
  let diff = sy#util#run_in_dir(fnamemodify(b:sy.path, ':h'), 'cvs diff -U0 '. diffoptions .' -- '. sy#util#escape(fnamemodify(b:sy.path, ':t')))
  return ((v:shell_error == 1) && (diff =~ '+++')) ? [1, diff] : [0, '']
endfunction

" Function: #get_diff_rcs {{{1
function! sy#repo#get_diff_rcs() abort
  let diffoptions = has_key(g:signify_diffoptions, 'rcs') ? g:signify_diffoptions.rcs : ''
  let diff = system('rcsdiff -U0 '. diffoptions .' '. sy#util#escape(b:sy.path) .' 2>/dev/null')
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_accurev {{{1
function! sy#repo#get_diff_accurev() abort
  let diffoptions = has_key(g:signify_diffoptions, 'accurev') ? g:signify_diffoptions.accurev : ''
  let diff = sy#util#run_in_dir(fnamemodify(b:sy.path, ':h'), 'accurev diff '. sy#util#escape(fnamemodify(b:sy.path, ':t')) . ' -- -U0 '. diffoptions)
  return (v:shell_error != 1) ? [0, ''] : [1, diff]
endfunction

" Function: #get_diff_perforce {{{1
function! sy#repo#get_diff_perforce() abort
  let diffoptions = has_key(g:signify_diffoptions, 'perforce') ? g:signify_diffoptions.perforce : ''
  let diff = system('p4 monitor show 2>&1 >/dev/null && env P4DIFF=diff p4 diff -dU0 '. diffoptions .' '. sy#util#escape(b:sy.path))
  return v:shell_error ? [0, ''] : [1, diff]
endfunction

" Function: #get_stats {{{1
function! sy#repo#get_stats() abort
  if !exists('b:sy') || !has_key(b:sy, 'stats')
    return [-1, -1, -1]
  endif

  return b:sy.stats
endfunction
