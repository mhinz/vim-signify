" vim: et sw=2 sts=2

scriptencoding utf-8

" Function: #list_active_buffers {{{1
function! sy#debug#list_active_buffers() abort
  for b in range(1, bufnr('$'))
    if !buflisted(b) || empty(getbufvar(b, 'sy'))
      continue
    endif

    let sy   = copy(getbufvar(b, 'sy'))
    let path = remove(sy, 'path')

    echo "\n". path ."\n". repeat('=', strlen(path))

    for k in ['active', 'buffer', 'vcs', 'stats', 'signid']
      if k == 'stats'
        echo printf("%10s  =  %d added, %d changed, %d removed\n",
              \ k,
              \ sy.stats[0],
              \ sy.stats[1],
              \ sy.stats[2])
      else
        echo printf("%10s  =  %s\n", k, string(sy[k]))
      endif
    endfor

    if empty(sy.hunks)
      echo printf("%10s  =  %s\n", 'hunks', '[]')
    else
      for i in range(len(sy.hunks))
        if i == 0
          echo printf("%10s  =  start: %d, end: %d, IDs: %s\n",
                \ 'hunks',
                \ sy.hunks[i].start,
                \ sy.hunks[i].end,
                \ string(sy.hunks[i].ids))
        else
          echo printf("%20s: %d, %s: %d, %s: %s\n",
                \ 'start', sy.hunks[i].start,
                \ 'end',   sy.hunks[i].end,
                \ 'IDs',   string(sy.hunks[i].ids))
        endif
      endfor
    endif
  endfor
endfunction
