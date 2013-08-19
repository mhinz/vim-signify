scriptencoding utf-8

if exists('b:autoloaded_sy_jump')
  finish
endif
let b:autoloaded_sy_jump = 1

" Function: #next_hunk {{{1
function! sy#jump#next_hunk(count)
  if !has_key(g:sy, g:sy_path)
    echomsg 'signify: I cannot detect any changes!'
    return
  endif

  let lnum = line('.')
  let hunks = filter(copy(g:sy[g:sy_path].hunks), 'v:val.start > lnum')
  let hunk = get(hunks, a:count - 1, get(hunks, -1, {}))

  if !empty(hunk)
    execute 'sign jump '. hunk.ids[0] .' file='. g:sy_path
  endif
endfunction

" Function: #prev_hunk {{{1
function! sy#jump#prev_hunk(count)
  if !has_key(g:sy, g:sy_path)
    echomsg 'signify: I cannot detect any changes!'
    return
  endif

  let lnum = line('.')
  let hunks = filter(copy(g:sy[g:sy_path].hunks), 'v:val.start < lnum')
  let hunk = get(hunks, 0 - a:count, get(hunks, 0, {}))

  if !empty(hunk)
    execute 'sign jump '. hunk.ids[0] .' file='. g:sy_path
  endif
endfunction

" vim: et sw=2 sts=2
