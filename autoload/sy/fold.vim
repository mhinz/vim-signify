" vim: et sw=2 sts=2

" Function: SignifyFoldExpr {{{1
function! SignifyFoldExpr(lnum)
  return s:levels[a:lnum]
endfunction

" Function: SignifyFoldText {{{1
function! SignifyFoldText()
  let linelen = &textwidth ? &textwidth : 80
  let marker  = &foldmarker[:stridx(&foldmarker, ',')-1]
  let range   = foldclosedend(v:foldstart) - foldclosed(v:foldstart) + 1

  let left    = substitute(getline(v:foldstart), marker, '', '')
  let leftlen = len(left)

  let right    = printf('%d [%d]', range, v:foldlevel)
  let rightlen = len(right)

  let tmp    = strpart(left, 0, linelen - rightlen)
  let tmplen = len(tmp)

  if leftlen > tmplen
    let left    = strpart(tmp, 0, tmplen - 4) . '... '
    let leftlen = tmplen
  endif

  let fill = repeat(' ', linelen - (leftlen + rightlen))

  " return left . fill . right . repeat(' ', 100)
  return left . fill . right
endfunction

" Function: #do {{{1
function! sy#fold#do() abort
  if !exists('b:sy')
    echomsg 'signify: I cannot detect any changes!'
    return
  endif

  tabedit %
  let [s:context0, s:context1] = get(g:, 'signify_fold_context', [3, 8])
  let s:levels = s:get_levels(s:get_lines())

  set foldexpr=SignifyFoldExpr(v:lnum)
  set foldtext=SignifyFoldText()
  set foldmethod=expr
  set foldlevel=0
endfunction

" Function: s:get_lines {{{1
function! s:get_lines() abort
  let lang = v:lang
  language message C
  redir => signlist
    silent! execute 'sign place buffer='. b:sy.buffer
  redir END
  silent! execute 'language message' lang

  let lines = []
  for line in split(signlist, '\n')[2:]
    call insert(lines, matchlist(line, '\v^\s+line\=(\d+)')[1], 0)
  endfor

  return reverse(lines)
endfunction

" Function: s:get_levels {{{1
function! s:get_levels(lines) abort
  let levels = {}

  for line in range(1, line('$'))
    let levels[line] = 2
  endfor

  for line in a:lines
    for l in range(line - s:context1, line + s:context1)
      if (l < 1) || (l > line('$'))
        continue
      endif
      if levels[l] == 2
        let levels[l] = 1
      endif
      for ll in range(line - s:context0, line + s:context0)
        let levels[ll] = 0
      endfor
    endfor
  endfor

  return levels
endfunction
