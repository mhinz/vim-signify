" vim: et sw=2 sts=2 fdm=marker

scriptencoding utf-8

" #escape {{{1
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

" #refresh_windows {{{1
function! sy#util#refresh_windows() abort
  if exists('*win_getid')
    let winid = win_getid()
  else
    let winnr = winnr()
  endif

  if !get(g:, 'signify_cmdwin_active')
    for bufnr in tabpagebuflist()
      call sy#start({'bufnr': bufnr})
    endfor
  endif

  if exists('winid')
    call win_gotoid(winid)
  else
    execute winnr .'wincmd w'
  endif
endfunction

" #hunk_text_object {{{1
function! sy#util#hunk_text_object(emptylines) abort
  execute sy#util#return_if_no_changes()

  let lnum  = line('.')
  let hunks = filter(copy(b:sy.hunks), 'v:val.start <= lnum && v:val.end >= lnum')

  if empty(hunks)
    echomsg 'signify: Here is no hunk.'
    return
  endif

  execute hunks[0].start
  normal! V

  if a:emptylines
    let lnum = hunks[0].end
    while getline(lnum+1) =~ '^$'
      let lnum += 1
    endwhile
    execute lnum
  else
    execute hunks[0].end
  endif
endfunction

" #shell_redirect {{{1
function! sy#util#shell_redirect(path) abort
  " if shellredir contains a %s it is replaced with the path
  " otherwise, just append it (from :help shellredir:
  "   The name of the temporary file can be represented by '%s' if necessary
  "   (the file name is appended automatically if no %s appears in the value
  "   of this option)
  if &shellredir =~# '%s'
    return substitute(&shellredir, '\C%s', a:path, 'g')
  else
    return &shellredir .' '. a:path
  endif
endfunction

" #chdir {{{1
function! sy#util#chdir() abort
  let chdir = haslocaldir()
        \ ? 'lcd'
        \ : (exists(':tcd') && haslocaldir(-1, 0)) ? 'tcd' : 'cd'
  return [getcwd(), chdir]
endfunction

" #return_if_no_changes {{{1
function! sy#util#return_if_no_changes() abort
  if !exists('b:sy') || empty(b:sy.hunks)
    echomsg 'signify: There are no changes.'
    return 'return'
  endif
  return ''
endfunction

" #execute {{{1
function! sy#util#execute(cmd) abort
  let lang = v:lang
  redir => output
    silent! execute a:cmd
  redir END
  silent! execute 'language message' lang
  return output
endfunction

let s:popup_window = 0

" #popup_close {{{1
function! sy#util#popup_close() abort
  if s:popup_window
    call nvim_win_close(s:popup_window, 1)
    let s:popup_window = 0
  endif
endfunction

" #popup_create {{{1
function! sy#util#popup_create(hunkdiff) abort
  let offset      = s:offset()
  let winline     = winline()
  let min_height  = 6
  let max_height  = winheight('%') - winline
  let diff_height = len(a:hunkdiff)
  let height      = min([diff_height, max_height])

  if diff_height > max_height && max_height < min_height
    let max_scroll = min_height - max_height
    let scroll     = min([max_scroll, diff_height - max_height])
    " Old versions don't have feedkeys(..., 'x')
    execute 'normal!' scroll.''
    let winline -= scroll
    let height  += scroll
  endif

  let padding = repeat(' ', offset - 1)

  if exists('*nvim_open_win')
    call sy#util#popup_close()
    let buf = nvim_create_buf(0, 1)
    call nvim_buf_set_option(buf, 'syntax', 'diff')
    call nvim_buf_set_lines(buf, 0, -1, 0, map(a:hunkdiff, 'v:val[0].padding.v:val[1:]'))
    let s:popup_window = nvim_open_win(buf, v:false, {
          \ 'relative': 'win',
          \ 'row': winline,
          \ 'col': 0,
          \ 'width': winwidth('%'),
          \ 'height': height,
          \ })
    call nvim_win_set_option(s:popup_window, 'cursorline', v:false)
    call nvim_win_set_option(s:popup_window, 'foldcolumn', 0)
    call nvim_win_set_option(s:popup_window, 'foldenable', v:false)
    call nvim_win_set_option(s:popup_window, 'number', v:false)
    call nvim_win_set_option(s:popup_window, 'relativenumber', v:false)
    call nvim_win_set_option(s:popup_window, 'wrap', v:true)
    autocmd CursorMoved * ++once call sy#util#popup_close()
  elseif exists('*popup_create')
    let s:popup_window = popup_create(map(a:hunkdiff, 'v:val[0].padding.v:val[1:]'), {
          \ 'line': 'cursor+1',
          \ 'col': 0,
          \ 'minwidth': winwidth('%'),
          \ 'maxheight': height,
          \ 'moved': 'any',
          \ 'zindex': 1000,
          \ })
    call setbufvar(winbufnr(s:popup_window), '&syntax', 'diff')
  else
    return 0
  endif

  return 1
endfunction

" s:offset {{{1
function! s:offset() abort
  let offset = &foldcolumn
  let offset += 2  " FIXME: Find better way to calculate the sign column width.
  if &number
    let l = len(line('$')) + 1
    let offset += (&numberwidth > l) ? &numberwidth : l
  elseif &relativenumber
    let l = len(winheight('%')) + 1
    let offset += (&numberwidth > l) ? &numberwidth : l
  endif
  return offset
endfunction
