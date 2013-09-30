" vim: et sw=2 sts=2

scriptencoding utf-8

" Function: #escape {{{1
function! sy#util#escape(path) abort
  if exists('+shellslash')
    let old_ssl = &shellslash
    set noshellslash
  endif

  let path = shellescape(a:path)

  if exists('old_ssl')
    let &shellslash = old_ssl
  endif

  return path
endfunction

" Function: #separator {{{1
function! sy#util#separator() abort
  return !exists('+shellslash') || &shellslash ? '/' : '\'
endfunction
