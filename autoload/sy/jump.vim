" vim: et sw=2 sts=2 fdm=marker

scriptencoding utf-8

" s:jump_to_hunk {{{1
function! s:jump_to_hunk(hunk_idx)
  let hunk = b:sy.hunks[a:hunk_idx]
  let hunks_len = len(b:sy.hunks)
  execute 'sign jump '. hunk.ids[0] .' buffer='. b:sy.buffer
  echo printf('Hunk %d of %d', a:hunk_idx + 1, hunks_len)
endfunction

" #next_hunk {{{1
function! sy#jump#next_hunk(count)
  execute sy#util#return_if_no_changes()

  let lnum = line('.')
  let hunks_len = len(b:sy.hunks)
  if a:count > hunks_len
    call s:jump_to_hunk(hunks_len - 1)
    return
  endif
  let idx = 0
  while idx < hunks_len
    if b:sy.hunks[idx].start > lnum
      let target_idx = idx + a:count - 1
      if target_idx >= hunks_len
        let target_idx = hunks_len - 1
      endif
      call s:jump_to_hunk(target_idx)
      break
    endif
    let idx += 1
  endwhile
endfunction

" #prev_hunk {{{1
function! sy#jump#prev_hunk(count)
  execute sy#util#return_if_no_changes()

  let lnum = line('.')
  let hunks_len = len(b:sy.hunks)
  if a:count > hunks_len
    call s:jump_to_hunk(0)
    return
  endif
  let idx = hunks_len - 1
  while idx >= 0
    if b:sy.hunks[idx].start < lnum
      let target_idx = idx - a:count + 1
      if target_idx < 0
        let target_idx = 0
      endif
      call s:jump_to_hunk(target_idx)
      break
    endif
    let idx -= 1
  endwhile
endfunction
