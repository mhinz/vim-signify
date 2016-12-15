" vim: et sw=2 sts=2

scriptencoding utf-8

" Init: values {{{1
if get(g:, 'signify_sign_show_text', 1)
  let s:sign_delete      = get(g:, 'signify_sign_delete', '_')
  let s:sign_show_count  = get(g:, 'signify_sign_show_count', 1)
else
  let s:sign_delete     = ' '
  let s:sign_show_count = 0
endif
let s:delete_highlight = ['', 'SignifyLineDelete']

" Function: #get_next_id {{{1
function! sy#sign#get_next_id() abort
  let tmp = g:id_top
  let g:id_top += 1
  return tmp
endfunction

" Function: #get_current_signs {{{1
function! sy#sign#get_current_signs() abort
  let b:sy.internal = {}
  let b:sy.external = {}

  redir => signlist
    silent! execute 'sign place buffer='. b:sy.buffer
  redir END

  for signline in split(signlist, '\n')[2:]
    let tokens = matchlist(signline, '\v^\s+\S+\=(\d+)\s+\S+\=(\d+)\s+\S+\=(.*)$')
    let line   = str2nr(tokens[1])
    let id     = str2nr(tokens[2])
    let type   = tokens[3]

    if type =~# '^Signify'
      " Handle ambiguous signs. Assume you have signs on line 3 and 4.
      " Removing line 3 would lead to the second sign to be shifted up
      " to line 3. Now there are still 2 signs, both one line 3.
      if has_key(b:sy.internal, line)
        execute 'sign unplace' b:sy.internal[line].id
      endif
      let b:sy.internal[line] = { 'type': type, 'id': id }
    else
      let b:sy.external[line] = id
    endif
  endfor
endfunction


" Function: #process_diff {{{1
function! sy#sign#process_diff(diff) abort
  let b:sy.signtable             = {}
  let b:sy.hunks                 = []
  let [added, modified, deleted] = [0, 0, 0]

  call sy#sign#get_current_signs()

  " Determine where we have to put our signs.
  for line in filter(split(a:diff, '\n'), 'v:val =~ "^@@ "')
    let b:sy.lines = []
    let ids        = []

    let tokens = matchlist(line, '^@@ -\v(\d+),?(\d*) \+(\d+),?(\d*)')

    let old_line = str2nr(tokens[1])
    let new_line = str2nr(tokens[3])

    let old_count = empty(tokens[2]) ? 1 : str2nr(tokens[2])
    let new_count = empty(tokens[4]) ? 1 : str2nr(tokens[4])

    " 2 lines added:

    " @@ -5,0 +6,2 @@ this is line 5
    " +this is line 5
    " +this is line 5
    if (old_count == 0) && (new_count >= 1)
      let added += new_count
      let offset = 0
      while offset < new_count
        let line    = new_line + offset
        let offset += 1
        if s:external_sign_present(line) | continue | endif
        call add(ids, s:add_sign(line, 'SignifyAdd'))
      endwhile

    " 2 lines removed:

    " @@ -6,2 +5,0 @@ this is line 5
    " -this is line 6
    " -this is line 7
    elseif (old_count >= 1) && (new_count == 0)
      if s:external_sign_present(new_line) | continue | endif
      let deleted += old_count
      if new_line == 0
        call add(ids, s:add_sign(1, 'SignifyRemoveFirstLine'))
      elseif s:sign_show_count
        if old_count <= 99
          let text = substitute(s:sign_delete . old_count, '.*\ze..$', '', '')
        else
          let text = s:sign_delete .'>'
        endif
        call add(ids, s:add_sign(new_line, 'SignifyDelete'. old_count, text))
      else
        call add(ids, s:add_sign(new_line, 'SignifyDeleteMore', s:sign_delete))
      endif

    " 2 lines changed:

    " @@ -5,2 +5,2 @@ this is line 4
    " -this is line 5
    " -this is line 6
    " +this os line 5
    " +this os line 6
    elseif old_count == new_count
      let modified += old_count
      let offset    = 0
      while offset < new_count
        let line    = new_line + offset
        let offset += 1
        if s:external_sign_present(line) | continue | endif
        call add(ids, s:add_sign(line, 'SignifyChange'))
      endwhile
    else

      " 2 lines changed; 2 lines removed:

      " @@ -5,4 +5,2 @@ this is line 4
      " -this is line 5
      " -this is line 6
      " -this is line 7
      " -this is line 8
      " +this os line 5
      " +this os line 6
      if old_count > new_count
        let modified += new_count
        let removed   = old_count - new_count
        let deleted  += removed
        let offset    = 0
        while offset < new_count - 1
          let line    = new_line + offset
          let offset += 1
          if s:external_sign_present(line) | continue | endif
          call add(ids, s:add_sign(line, 'SignifyChange'))
        endwhile
        let line = new_line + offset
        if s:external_sign_present(line) | continue | endif
        call add(ids, s:add_sign(line, (removed > 9) ? 'SignifyChangeDeleteMore' : 'SignifyChangeDelete'. removed))

      " lines changed and added:

      " @@ -5 +5,3 @@ this is line 4
      " -this is line 5
      " +this os line 5
      " +this is line 42
      " +this is line 666
      else
        let modified += old_count
        let offset    = 0
        while offset < old_count
          let line    = new_line + offset
          let offset += 1
          if s:external_sign_present(line) | continue | endif
          call add(ids, s:add_sign(line, 'SignifyChange'))
          let added += 1
        endwhile
        while offset < new_count
          let line    = new_line + offset
          let offset += 1
          if s:external_sign_present(line) | continue | endif
          call add(ids, s:add_sign(line, 'SignifyAdd'))
        endwhile
      endif
    endif

    if !empty(ids)
      call add(b:sy.hunks, {
            \ 'ids'  : ids,
            \ 'start': b:sy.lines[0],
            \ 'end'  : b:sy.lines[-1] })
    endif
  endfor

  " Remove obsoleted signs.
  for line in filter(keys(b:sy.internal), '!has_key(b:sy.signtable, v:val)')
    execute 'sign unplace' b:sy.internal[line].id
  endfor

  let b:sy.stats = [added, modified, deleted]
endfunction

" Function: #remove_all_signs {{{1
function! sy#sign#remove_all_signs(bufnr) abort
  let sy = getbufvar(a:bufnr, 'sy')

  for hunk in sy.hunks
    for id in hunk.ids
      execute 'sign unplace' id
    endfor
  endfor

  let sy.hunks = []
endfunction

" Function: s:add_sign {{{1
function! s:add_sign(line, type, ...) abort
  call add(b:sy.lines, a:line)
  let b:sy.signtable[a:line] = 1

  if has_key(b:sy.internal, a:line)
    " There is a sign on this line already.
    if a:type == b:sy.internal[a:line].type
      " Keep current sign since the new one is of the same type.
      return b:sy.internal[a:line].id
    else
      " Update sign by overwriting the ID of the current sign.
      let id = b:sy.internal[a:line].id
    endif
  endif

  if !exists('id')
    let id = sy#sign#get_next_id()
  endif

  if a:type =~# 'SignifyDelete'
    execute printf('sign define %s text=%s texthl=SignifySignDelete linehl=%s',
          \ a:type,
          \ a:1,
          \ s:delete_highlight[g:signify_line_highlight])
  endif
  execute printf('sign place %d line=%d name=%s buffer=%s',
        \ id,
        \ a:line,
        \ a:type,
        \ b:sy.buffer)

  return id
endfunction

" Function: s:external_sign_present {{{1
function! s:external_sign_present(line) abort
  if has_key(b:sy.external, a:line)
    if has_key(b:sy.internal, a:line)
      " Remove Sy signs from lines with other signs.
      execute 'sign unplace' b:sy.internal[a:line].id
    endif
    return 1
  endif
endfunction

