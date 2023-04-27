" vim: et sw=2 sts=2 fdm=marker

" SignifyFoldExpr {{{1
function! SignifyFoldExpr(lnum)
  return s:levels[a:lnum]
endfunction

" SignifyFoldText {{{1
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

" #dispatch {{{1
function! sy#fold#dispatch(do_tab) abort
  if a:do_tab
    call sy#fold#enable(1)
  else
    call sy#fold#toggle()
  endif
endfunction

" #enable {{{1
function! sy#fold#enable(do_tab) abort
  execute sy#util#return_if_no_changes()

  if a:do_tab
    tabedit %
  endif

  let [s:context0, s:context1] = get(g:, 'signify_fold_context', [3, 8])
  let s:levels = s:get_levels(s:get_lines())

  setlocal foldexpr=SignifyFoldExpr(v:lnum)
  setlocal foldtext=SignifyFoldText()
  setlocal foldmethod=expr
  setlocal foldlevel=0
endfunction

" #disable {{{1
function! sy#fold#disable() abort
  let &l:foldmethod = b:sy_folded.method
  let &l:foldtext = b:sy_folded.text
  normal! zv
endfunction

" #toggle {{{1
function! sy#fold#toggle() abort
  if exists('b:sy_folded')
    call sy#fold#disable()
    if b:sy_folded.method == 'manual'
      loadview
    endif
    unlet b:sy_folded
  else
    let b:sy_folded = { 'method': &foldmethod, 'text': &foldtext }
    if &foldmethod == 'manual'
      let old_vop = &viewoptions
      mkview
      let &viewoptions = old_vop
    endif
    call sy#fold#enable(0)
  endif

  redraw!
  call sy#start()
endfunction

" s:get_lines {{{1
function! s:get_lines() abort
  return map(sy#util#get_signs(b:sy.buffer), {_, val -> val.lnum})
endfunction

" s:get_levels {{{1
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
