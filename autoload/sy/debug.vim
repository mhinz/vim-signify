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
    for stat in sort(keys(sy))
      echo printf("%20s  =  %s\n", stat, string(sy[stat]))
    endfor
  endfor
endfunction
