" vim: et sw=2 sts=2

scriptencoding utf-8

" Function: #next_hunk {{{1
function! sy#jump#next_hunk(count)
  if !exists('b:sy')
    echomsg 'signify: I cannot detect any changes!'
    return
  endif

  let lnum = line('.')
  let hunks = filter(copy(b:sy.hunks), 'v:val.start > lnum')
  let hunk = get(hunks, a:count - 1, get(hunks, -1, {}))

  if !empty(hunk)
    execute 'sign jump '. hunk.ids[0] .' buffer='. b:sy.buffer
  endif
endfunction

" Function: #prev_hunk {{{1
function! sy#jump#prev_hunk(count)
  if !exists('b:sy')
    echomsg 'signify: I cannot detect any changes!'
    return
  endif

  let lnum = line('.')
  let hunks = filter(copy(b:sy.hunks), 'v:val.start < lnum')
  let hunk = get(hunks, 0 - a:count, get(hunks, 0, {}))

  if !empty(hunk)
    execute 'sign jump '. hunk.ids[0] .' buffer='. b:sy.buffer
  endif
endfunction
