" vim: et sw=2 sts=2 fdm=marker

scriptencoding utf-8

" #next_hunk {{{1
function! sy#jump#next_hunk(count)
  execute sy#util#return_if_no_changes()

  let lnum = line('.')
  let hunks = filter(copy(b:sy.hunks), 'v:val.start > lnum')
  let hunk = get(hunks, a:count - 1, get(hunks, -1, {}))

  if !empty(hunk)
    execute 'sign jump '. hunk.ids[0] .' buffer='. b:sy.buffer
  endif

  if exists('#User#SignifyHunk')
    doautocmd <nomodeline> User SignifyHunk
  endif
endfunction

" #prev_hunk {{{1
function! sy#jump#prev_hunk(count)
  execute sy#util#return_if_no_changes()

  let lnum = line('.')
  let hunks = filter(copy(b:sy.hunks), 'v:val.start < lnum')
  let hunk = get(hunks, 0 - a:count, get(hunks, 0, {}))

  if !empty(hunk)
    execute 'sign jump '. hunk.ids[0] .' buffer='. b:sy.buffer
  endif

  if exists('#User#SignifyHunk')
    doautocmd <nomodeline> User SignifyHunk
  endif
endfunction
