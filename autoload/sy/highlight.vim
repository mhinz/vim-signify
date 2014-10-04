" vim: et sw=2 sts=2

scriptencoding utf-8

" Init: values {{{1
let s:sign_add               = get(g:, 'signify_sign_add',               '+')
let s:sign_delete_first_line = get(g:, 'signify_sign_delete_first_line', '‾')
let s:sign_change            = get(g:, 'signify_sign_change',            '!')
let s:sign_changedelete      = get(g:, 'signify_sign_changedelete',      s:sign_change)

" Function: #setup {{{1
function! sy#highlight#setup() abort
  highlight default link SignifyLineAdd             DiffAdd
  highlight default link SignifyLineChange          DiffChange
  highlight default link SignifyLineChangeDelete    SignifyLineChange
  highlight default link SignifyLineDelete          DiffDelete
  highlight default link SignifyLineDeleteFirstLine SignifyLineDelete

  highlight default link SignifySignAdd             DiffAdd
  highlight default link SignifySignChange          DiffChange
  highlight default link SignifySignChangeDelete    SignifySignChange
  highlight default link SignifySignDelete          DiffDelete
  highlight default link SignifySignDeleteFirstLine SignifySignDelete
endfunction

" Function: #line_enable {{{1
function! sy#highlight#line_enable() abort
  execute 'sign define SignifyAdd text='. s:sign_add ' texthl=SignifySignAdd linehl=SignifyLineAdd'

  execute 'sign define SignifyChange text='. s:sign_change .' texthl=SignifySignChange linehl=SignifyLineChange'

  let changedelete_suffixes = split('123456789>','\zs')
  for suffix in changedelete_suffixes
    " append number suffix to sign text
    let text = s:sign_changedelete.suffix
    " sign text can only be 2 characters long
    let text = text[:1]

    let sign_name = suffix == '>' ? 'More' : suffix
    execute 'sign define SignifyChangeDelete'. sign_name .' text='. text .' texthl=SignifySignChangeDelete linehl=SignifyLineChangeDelete'
  endfor

  execute 'sign define SignifyRemoveFirstLine text='. s:sign_delete_first_line ' texthl=SignifySignDelete linehl=SignifyLineDeleteFirstLine'

  let g:signify_line_highlight = 1
endfunction

" Function: #line_disable {{{1
function! sy#highlight#line_disable() abort
  execute 'sign define SignifyAdd text='. s:sign_add .' texthl=SignifySignAdd linehl='

  execute 'sign define SignifyChange text='. s:sign_change .' texthl=SignifySignChange linehl='
  let changedelete_suffixes = split('123456789>','\zs')
  for suffix in changedelete_suffixes
    let text = s:sign_changedelete.suffix
    let text = text[:1]

    let sign_name = suffix == '>' ? 'More' : suffix
    execute 'sign define SignifyChangeDelete'. sign_name .' text='. text .' texthl=SignifySignChangeDelete linehl='
  endfor

  execute 'sign define SignifyRemoveFirstLine text='. s:sign_delete_first_line ' texthl=SignifySignDeleteFirstLine linehl='

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
