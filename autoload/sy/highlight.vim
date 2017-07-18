" vim: et sw=2 sts=2

scriptencoding utf-8

" Init: values {{{1
if get(g:, 'signify_sign_show_text', 1)
  let s:sign_add               = get(g:, 'signify_sign_add',               '+')
  let s:sign_delete_first_line = get(g:, 'signify_sign_delete_first_line', '‾')
  let s:sign_change            = get(g:, 'signify_sign_change',            '!')
  let s:sign_changedelete      = get(g:, 'signify_sign_changedelete',      s:sign_change)
else
  let s:sign_add               = ' '
  let s:sign_delete_first_line = ' '
  let s:sign_change            = ' '
  let s:sign_changedelete      = ' '
endif

let s:sign_show_count = get(g:, 'signify_sign_show_count', 1)

" Function: #setup {{{1
function! sy#highlight#setup() abort
  highlight default link SignifyLineAdd             DiffAdd
  highlight default link SignifyLineDelete          DiffDelete
  highlight default link SignifyLineDeleteFirstLine SignifyLineDelete
  highlight default link SignifyLineChange          DiffChange
  highlight default link SignifyLineChangeDelete    SignifyLineChange

  highlight default link SignifySignAdd             DiffAdd
  highlight default link SignifySignDelete          DiffDelete
  highlight default link SignifySignDeleteFirstLine SignifySignDelete
  highlight default link SignifySignChange          DiffChange
  highlight default link SignifySignChangeDelete    SignifySignChange
endfunction

" Function: #line_enable {{{1
function! sy#highlight#line_enable() abort
  execute 'sign define SignifyAdd text='. s:sign_add 'texthl=SignifySignAdd linehl=SignifyLineAdd'
  execute 'sign define SignifyChange text='. s:sign_change 'texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyRemoveFirstLine text='. s:sign_delete_first_line 'texthl=SignifySignDeleteFirstLine linehl=SignifyLineDeleteFirstLine'

  if s:sign_show_count
    let s:sign_changedelete = substitute(s:sign_changedelete, '^.\zs.*', '', '')
    for n in range(1, 9)
      execute 'sign define SignifyChangeDelete'. n 'text='. s:sign_changedelete . n 'texthl=SignifySignChangeDelete linehl=SignifyLineChangeDelete'
    endfor
    execute 'sign define SignifyChangeDeleteMore text='. s:sign_changedelete .'> texthl=SignifySignChangeDelete linehl=SignifyLineChangeDelete'
  else
    for n in range(1, 9)
      execute 'sign define SignifyChangeDelete'. n 'text='. s:sign_changedelete 'texthl=SignifySignChangeDelete linehl=SignifyLineChangeDelete'
    endfor
    execute 'sign define SignifyChangeDeleteMore text='. s:sign_changedelete 'texthl=SignifySignChangeDelete linehl=SignifyLineChangeDelete'
  endif

  let g:signify_line_highlight = 1
endfunction

" Function: #line_disable {{{1
function! sy#highlight#line_disable() abort
  execute 'sign define SignifyAdd text='. s:sign_add 'texthl=SignifySignAdd linehl='
  execute 'sign define SignifyChange text='. s:sign_change 'texthl=SignifySignChange linehl='
  execute 'sign define SignifyRemoveFirstLine text='. s:sign_delete_first_line 'texthl=SignifySignDeleteFirstLine linehl='

  if s:sign_show_count
    while strwidth(s:sign_changedelete) > 1
      let s:sign_changedelete = substitute(s:sign_changedelete, '.', '', '')
    endwhile
    for n in range(1, 9)
      execute 'sign define SignifyChangeDelete'. n 'text='. s:sign_changedelete . n 'texthl=SignifySignChangeDelete linehl='
    endfor
    execute 'sign define SignifyChangeDeleteMore text='. s:sign_changedelete .'> texthl=SignifySignChangeDelete linehl='
  else
    for n in range(1, 9)
      execute 'sign define SignifyChangeDelete'. n 'text='. s:sign_changedelete 'texthl=SignifySignChangeDelete linehl='
    endfor
    execute 'sign define SignifyChangeDeleteMore text='. s:sign_changedelete 'texthl=SignifySignChangeDelete linehl='
  endif

  let g:signify_line_highlight = 0
endfunction

" Function: #line_toggle {{{1
function! sy#highlight#line_toggle() abort
  if get(g:, 'signify_line_highlight')
    call sy#highlight#line_disable()
  else
    call sy#highlight#line_enable()
  endif

  redraw!
  call sy#start()
endfunction
" }}}

call sy#highlight#setup()
