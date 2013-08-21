scriptencoding utf-8

if exists('b:autoloaded_sy_highlight')
  finish
endif
let b:autoloaded_sy_highlight = 1

" Init: values {{{1
let s:sign_add               = get(g:, 'signify_sign_add',               '+')
let s:sign_delete            = get(g:, 'signify_sign_delete',            '_')
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

  execute 'sign define SignifyDelete1 text='. s:sign_delete .'1 texthl=SignifySignDelete linehl=SignifyLineDelete'
  execute 'sign define SignifyDelete2 text='. s:sign_delete .'2 texthl=SignifySignDelete linehl=SignifyLineDelete'
  execute 'sign define SignifyDelete3 text='. s:sign_delete .'3 texthl=SignifySignDelete linehl=SignifyLineDelete'
  execute 'sign define SignifyDelete4 text='. s:sign_delete .'4 texthl=SignifySignDelete linehl=SignifyLineDelete'
  execute 'sign define SignifyDelete5 text='. s:sign_delete .'5 texthl=SignifySignDelete linehl=SignifyLineDelete'
  execute 'sign define SignifyDelete6 text='. s:sign_delete .'6 texthl=SignifySignDelete linehl=SignifyLineDelete'
  execute 'sign define SignifyDelete7 text='. s:sign_delete .'7 texthl=SignifySignDelete linehl=SignifyLineDelete'
  execute 'sign define SignifyDelete8 text='. s:sign_delete .'8 texthl=SignifySignDelete linehl=SignifyLineDelete'
  execute 'sign define SignifyDelete9 text='. s:sign_delete .'9 texthl=SignifySignDelete linehl=SignifyLineDelete'
  execute 'sign define SignifyDeleteMore text='. s:sign_delete .'> texthl=SignifySignDelete linehl=SignifyLineDelete'

  execute 'sign define SignifyDeleteFirstLine text='. s:sign_delete_first_line ' texthl=SignifySignDelete linehl=SignifyLineDelete'

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

  execute 'sign define SignifyDelete1 text='. s:sign_delete .'1 texthl=SignifySignDelete linehl='
  execute 'sign define SignifyDelete2 text='. s:sign_delete .'2 texthl=SignifySignDelete linehl='
  execute 'sign define SignifyDelete3 text='. s:sign_delete .'3 texthl=SignifySignDelete linehl='
  execute 'sign define SignifyDelete4 text='. s:sign_delete .'4 texthl=SignifySignDelete linehl='
  execute 'sign define SignifyDelete5 text='. s:sign_delete .'5 texthl=SignifySignDelete linehl='
  execute 'sign define SignifyDelete6 text='. s:sign_delete .'6 texthl=SignifySignDelete linehl='
  execute 'sign define SignifyDelete7 text='. s:sign_delete .'7 texthl=SignifySignDelete linehl='
  execute 'sign define SignifyDelete8 text='. s:sign_delete .'8 texthl=SignifySignDelete linehl='
  execute 'sign define SignifyDelete9 text='. s:sign_delete .'9 texthl=SignifySignDelete linehl='
  execute 'sign define SignifyDeleteMore text='. s:sign_delete .'> texthl=SignifySignDelete linehl='

  execute 'sign define SignifyDeleteFirstLine text='. s:sign_delete_first_line ' texthl=SignifySignDelete linehl='

  let g:signify_line_highlight = 0
endfunction

" Function: #line_toggle {{{1
function! sy#highlight#line_toggle() abort
  if !has_key(g:sy, g:sy_path)
    echomsg 'signify: I cannot detect any changes!'
    return
  endif

  if get(g:, 'signify_line_highlight')
    call sy#highlight#line_disable()
  else
    call sy#highlight#line_enable()
  endif

  call sy#start(g:sy_path)
endfunction

" vim: et sw=2 sts=2
