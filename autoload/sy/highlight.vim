" vim: et sw=2 sts=2

scriptencoding utf-8

" Init: values {{{1
let s:sign_add               = get(g:, 'signify_sign_add',               '+')
let s:sign_delete_first_line = get(g:, 'signify_sign_delete_first_line', '‾')
let s:sign_change            = get(g:, 'signify_sign_change',            '!')
let s:sign_changedelete      = get(g:, 'signify_sign_changedelete',      s:sign_change)
let s:sign_changedelete      = substitute(s:sign_changedelete, '^.\zs.*', '', '')

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
  execute 'sign define SignifyAdd text='.
        \ s:sign_add 'texthl=SignifySignAdd linehl=SignifyLineAdd'

  execute 'sign define SignifyChange text='.
        \ s:sign_change 'texthl=SignifySignChange linehl=SignifyLineChange'

  execute 'sign define SignifyChangeDelete1 text='.
        \ s:sign_changedelete .'1 texthl=SignifySignChangeDelete linehl=SignifyLineChangeDelete'
  execute 'sign define SignifyChangeDelete2 text='.
        \ s:sign_changedelete .'2 texthl=SignifySignChangeDelete linehl=SignifyLineChangeDelete'
  execute 'sign define SignifyChangeDelete3 text='.
        \ s:sign_changedelete .'3 texthl=SignifySignChangeDelete linehl=SignifyLineChangeDelete'
  execute 'sign define SignifyChangeDelete4 text='.
        \ s:sign_changedelete .'4 texthl=SignifySignChangeDelete linehl=SignifyLineChangeDelete'
  execute 'sign define SignifyChangeDelete5 text='.
        \ s:sign_changedelete .'5 texthl=SignifySignChangeDelete linehl=SignifyLineChangeDelete'
  execute 'sign define SignifyChangeDelete6 text='.
        \ s:sign_changedelete .'6 texthl=SignifySignChangeDelete linehl=SignifyLineChangeDelete'
  execute 'sign define SignifyChangeDelete7 text='.
        \ s:sign_changedelete .'7 texthl=SignifySignChangeDelete linehl=SignifyLineChangeDelete'
  execute 'sign define SignifyChangeDelete8 text='.
        \ s:sign_changedelete .'8 texthl=SignifySignChangeDelete linehl=SignifyLineChangeDelete'
  execute 'sign define SignifyChangeDelete9 text='.
        \ s:sign_changedelete .'9 texthl=SignifySignChangeDelete linehl=SignifyLineChangeDelete'
  execute 'sign define SignifyChangeDeleteMore text='.
        \ s:sign_changedelete .'> texthl=SignifySignChangeDelete linehl=SignifyLineChangeDelete'

  execute 'sign define SignifyRemoveFirstLine text='.
        \ s:sign_delete_first_line 'texthl=SignifySignDelete linehl=SignifyLineDeleteFirstLine'

  let g:signify_line_highlight = 1
endfunction

" Function: #line_disable {{{1
function! sy#highlight#line_disable() abort
  execute 'sign define SignifyAdd text='.
        \ s:sign_add 'texthl=SignifySignAdd linehl='

  execute 'sign define SignifyChange text='.
        \ s:sign_change 'texthl=SignifySignChange linehl='

  execute 'sign define SignifyChangeDelete1 text='.
        \ s:sign_changedelete .'1 texthl=SignifySignChangeDelete linehl='
  execute 'sign define SignifyChangeDelete2 text='.
        \ s:sign_changedelete .'2 texthl=SignifySignChangeDelete linehl='
  execute 'sign define SignifyChangeDelete3 text='.
        \ s:sign_changedelete .'3 texthl=SignifySignChangeDelete linehl='
  execute 'sign define SignifyChangeDelete4 text='.
        \ s:sign_changedelete .'4 texthl=SignifySignChangeDelete linehl='
  execute 'sign define SignifyChangeDelete5 text='.
        \ s:sign_changedelete .'5 texthl=SignifySignChangeDelete linehl='
  execute 'sign define SignifyChangeDelete6 text='.
        \ s:sign_changedelete .'6 texthl=SignifySignChangeDelete linehl='
  execute 'sign define SignifyChangeDelete7 text='.
        \ s:sign_changedelete .'7 texthl=SignifySignChangeDelete linehl='
  execute 'sign define SignifyChangeDelete8 text='.
        \ s:sign_changedelete .'8 texthl=SignifySignChangeDelete linehl='
  execute 'sign define SignifyChangeDelete9 text='.
        \ s:sign_changedelete .'9 texthl=SignifySignChangeDelete linehl='
  execute 'sign define SignifyChangeDeleteMore text='.
        \ s:sign_changedelete .'> texthl=SignifySignChangeDelete linehl='

  execute 'sign define SignifyRemoveFirstLine text='.
        \ s:sign_delete_first_line 'texthl=SignifySignDelete linehl='

  let g:signify_line_highlight = 0
endfunction

" Function: #line_toggle {{{1
function! sy#highlight#line_toggle() abort
  if !exists('b:sy')
    echomsg 'signify: I cannot detect any changes!'
    return
  endif

  if get(g:, 'signify_line_highlight')
    call sy#highlight#line_disable()
  else
    call sy#highlight#line_enable()
  endif

  call sy#start()
endfunction
