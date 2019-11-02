" vim: et sw=2 sts=2 fdm=marker

scriptencoding utf-8

" Variables {{{1
if get(g:, 'signify_sign_show_text', 1)
  let s:sign_add               = get(g:, 'signify_sign_add',               '+')
  let s:sign_delete_first_line = get(g:, 'signify_sign_delete_first_line', '‾')
  let s:sign_change            = get(g:, 'signify_sign_change',            '!')
else
  let s:sign_add               = ' '
  let s:sign_delete_first_line = ' '
  let s:sign_change            = ' '
endif

let s:sign_show_count = get(g:, 'signify_sign_show_count', 1)
" 1}}}

" #setup {{{1
function! sy#highlight#setup() abort
  highlight default link SignifyLineAdd             DiffAdd
  highlight default link SignifyLineDelete          DiffDelete
  highlight default link SignifyLineDeleteFirstLine SignifyLineDelete
  highlight default link SignifyLineChange          DiffChange

  highlight default link SignifySignAdd             DiffAdd
  highlight default link SignifySignDelete          DiffDelete
  highlight default link SignifySignDeleteFirstLine SignifySignDelete
  highlight default link SignifySignChange          DiffChange
endfunction

" #line_enable {{{1
function! sy#highlight#line_enable() abort
  execute 'sign define SignifyAdd text='. s:sign_add 'texthl=SignifySignAdd linehl=SignifyLineAdd'
  execute 'sign define SignifyChange text='. s:sign_change 'texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyRemoveFirstLine text='. s:sign_delete_first_line 'texthl=SignifySignDeleteFirstLine linehl=SignifyLineDeleteFirstLine'
  let g:signify_line_highlight = 1
endfunction

" #line_disable {{{1
function! sy#highlight#line_disable() abort
  execute 'sign define SignifyAdd text='. s:sign_add 'texthl=SignifySignAdd linehl='
  execute 'sign define SignifyChange text='. s:sign_change 'texthl=SignifySignChange linehl='
  execute 'sign define SignifyRemoveFirstLine text='. s:sign_delete_first_line 'texthl=SignifySignDeleteFirstLine linehl='
  let g:signify_line_highlight = 0
endfunction

" #line_toggle {{{1
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
