scriptencoding utf-8

if exists('b:autoloaded_sy_util')
  finish
endif
let b:autoloaded_sy_util = 1

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

" vim: et sw=2 sts=2
