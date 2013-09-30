" vim: et sw=2 sts=2

scriptencoding utf-8

" Function: #list_active_buffers {{{1
function! sy#debug#list_active_buffers() abort
  if empty(g:sy)
    echomsg 'No active buffers!'
    return
  endif

  for [path, stats] in items(g:sy)
    echo "\n". path ."\n". repeat('=', strlen(path))
    for stat in sort(keys(stats))
      echo printf("%20s  =  %s\n", stat, string(stats[stat]))
    endfor
  endfor
endfunction
