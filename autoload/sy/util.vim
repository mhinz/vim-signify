" vim: et sw=2 sts=2

scriptencoding utf-8

" Function: #escape {{{1
function! sy#util#escape(path) abort
  if exists('+shellslash')
    let old_ssl = &shellslash
    if fnamemodify(&shell, ':t') == 'cmd.exe'
      set noshellslash
    else
      set shellslash
    endif
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

" Function: #run_in_dir {{{1
function! sy#util#run_in_dir(dir, cmd) abort
  let chdir = haslocaldir() ? 'lcd' : 'cd'
  let cwd = getcwd()
  try
    exe chdir .' '. fnameescape(fnamemodify(a:dir, ':p'))
    let resp = system(a:cmd)
  finally
    exe chdir .' '. fnameescape(cwd)
  endtry
  return resp
endfunction
