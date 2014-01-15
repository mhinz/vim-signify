" vim: et sw=2 sts=2

scriptencoding utf-8

" Init: values {{{1
let s:sign_add               = get(g:, 'signify_sign_add',               '+')
let s:sign_delete_first_line = get(g:, 'signify_sign_delete_first_line', '‾')
let s:sign_change            = get(g:, 'signify_sign_change',            '!')

" Function: #setup {{{1
function! sy#highlight#setup() abort
  highlight default link SignifyLineAdd    DiffAdd
  highlight default link SignifyLineChange DiffChange
  highlight default link SignifyLineDelete DiffDelete

  highlight default link SignifySignAdd    DiffAdd
  highlight default link SignifySignChange DiffChange
  highlight default link SignifySignDelete DiffDelete
endfunction

" Function: #line_enable {{{1
function! sy#highlight#line_enable() abort
  execute 'sign define SignifyAdd text='. s:sign_add ' texthl=SignifySignAdd linehl=SignifyLineAdd'

  execute 'sign define SignifyChange text='. s:sign_change ' texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyChangeDelete1 text='. s:sign_change .'1 texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyChangeDelete2 text='. s:sign_change .'2 texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyChangeDelete3 text='. s:sign_change .'3 texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyChangeDelete4 text='. s:sign_change .'4 texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyChangeDelete5 text='. s:sign_change .'5 texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyChangeDelete6 text='. s:sign_change .'6 texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyChangeDelete7 text='. s:sign_change .'7 texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyChangeDelete8 text='. s:sign_change .'8 texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyChangeDelete9 text='. s:sign_change .'9 texthl=SignifySignChange linehl=SignifyLineChange'
  execute 'sign define SignifyChangeDeleteMore text='. s:sign_change .'> texthl=SignifySignChange linehl=SignifyLineChange'

  execute 'sign define SignifyRemoveFirstLine text='. s:sign_delete_first_line ' texthl=SignifySignDelete linehl=SignifyLineDelete'

  let g:signify_line_highlight = 1
endfunction

" Function: #line_disable {{{1
function! sy#highlight#line_disable() abort
  execute 'sign define SignifyAdd text='. s:sign_add ' texthl=SignifySignAdd linehl='

  execute 'sign define SignifyChange text='. s:sign_change ' texthl=SignifySignChange linehl='
  execute 'sign define SignifyChangeDelete1 text='. s:sign_change .'1 texthl=SignifySignChange linehl='
  execute 'sign define SignifyChangeDelete2 text='. s:sign_change .'2 texthl=SignifySignChange linehl='
  execute 'sign define SignifyChangeDelete3 text='. s:sign_change .'3 texthl=SignifySignChange linehl='
  execute 'sign define SignifyChangeDelete4 text='. s:sign_change .'4 texthl=SignifySignChange linehl='
  execute 'sign define SignifyChangeDelete5 text='. s:sign_change .'5 texthl=SignifySignChange linehl='
  execute 'sign define SignifyChangeDelete6 text='. s:sign_change .'6 texthl=SignifySignChange linehl='
  execute 'sign define SignifyChangeDelete7 text='. s:sign_change .'7 texthl=SignifySignChange linehl='
  execute 'sign define SignifyChangeDelete8 text='. s:sign_change .'8 texthl=SignifySignChange linehl='
  execute 'sign define SignifyChangeDelete9 text='. s:sign_change .'9 texthl=SignifySignChange linehl='
  execute 'sign define SignifyChangeDeleteMore text='. s:sign_change .'> texthl=SignifySignChange linehl='

  execute 'sign define SignifyRemoveFirstLine text='. s:sign_delete_first_line ' texthl=SignifySignDelete linehl='

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

  call sy#start(b:sy.path)
endfunction
