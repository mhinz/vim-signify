" vim: et sw=2 sts=2 fdm=marker

scriptencoding utf-8

" Variables {{{1
let s:sign_delete = get(g:, 'signify_sign_delete', '_')

" Support for sign priority was added together with sign_place().
if exists('*sign_place')
  let s:sign_priority = printf('priority=%d', get(g:, 'signify_priority', 10))
else
  let s:sign_priority = ''
endif

let s:sign_show_count  = get(g:, 'signify_sign_show_count', 1)
let s:delete_highlight = ['', 'SignifyLineDelete']
" 1}}}

" #id_next {{{1
function! sy#sign#id_next(sy) abort
  let id = a:sy.signid
  let a:sy.signid += 1
  return id
endfunction

" #get_current_signs {{{1
function! sy#sign#get_current_signs(sy) abort
  let a:sy.internal = {}
  let a:sy.external = {}

  let signlist = sy#util#execute('sign place buffer='. a:sy.buffer)

  for signline in split(signlist, '\n')[2:]
    let tokens = matchlist(signline, '\v^\s+\S+\=(\d+)\s+\S+\=(\d+)\s+\S+\=(.*)$')
    let line   = str2nr(tokens[1])
    let id     = str2nr(tokens[2])
    let type   = tokens[3]

    if type =~# '^Signify'
      " Handle ambiguous signs. Assume you have signs on line 3 and 4.
      " Removing line 3 would lead to the second sign to be shifted up
      " to line 3. Now there are still 2 signs, both one line 3.
      if has_key(a:sy.internal, line)
        execute 'sign unplace' a:sy.internal[line].id 'buffer='.a:sy.buffer
      endif
      let a:sy.internal[line] = { 'type': type, 'id': id }
    else
      let a:sy.external[line] = id
    endif
  endfor
endfunction


" #process_diff {{{1
function! sy#sign#process_diff(sy, vcs, diff) abort
  let a:sy.signtable             = {}
  let a:sy.hunks                 = []
  let [added, modified, deleted] = [0, 0, 0]

  call sy#sign#get_current_signs(a:sy)

  " Determine where we have to put our signs.
  for line in filter(a:diff, 'v:val =~ "^@@ "')
    let a:sy.lines = []
    let ids        = []

    let [old_line, old_count, new_line, new_count] = sy#sign#parse_hunk(line)

    " Workaround for non-conventional diff output in older Fossil versions:
    " https://fossil-scm.org/forum/forumpost/834ce0f1e1
    " Fixed as of: https://fossil-scm.org/index.html/info/7fd2a3652ea7368a
    if a:vcs == 'fossil' && new_line == 0
      let new_line = old_line - 1 - deleted
    endif

    " Pure add:

    " @@ -5,0 +6,2 @@ this is line 5
    " +this is line 5
    " +this is line 5
    if old_count == 0 && new_count > 0
      let added += new_count
      let offset = 0
      while offset < new_count
        let line    = new_line + offset
        let offset += 1
        if s:external_sign_present(a:sy, line) | continue | endif
        call add(ids, s:add_sign(a:sy, line, 'SignifyAdd'))
      endwhile

    " Pure delete

    " @@ -6,2 +5,0 @@ this is line 5
    " -this is line 6
    " -this is line 7
    elseif old_count > 0 && new_count == 0
      if s:external_sign_present(a:sy, new_line) | continue | endif
      let deleted += old_count
      if new_line == 0
        call add(ids, s:add_sign(a:sy, 1, 'SignifyRemoveFirstLine'))
      elseif s:sign_show_count
        if old_count > 99
          let text = s:sign_delete . '>'
        elseif old_count < 2
          let text = s:sign_delete
        else
          let text = s:sign_delete . old_count
        endif
        while strwidth(text) > 2
          let text = substitute(text, '.', '', '')
        endwhile
        call add(ids, s:add_sign(a:sy, new_line, 'SignifyDelete'. old_count, text))
      else
        call add(ids, s:add_sign(a:sy, new_line, 'SignifyDeleteMore', s:sign_delete))
      endif
    " All lines are modified.
    elseif old_count > 0 && new_count > 0 && old_count == new_count
      let modified += new_count
      let offset = 0
      while offset < new_count
        let line    = new_line + offset
        let offset += 1
        if s:external_sign_present(a:sy, line) | continue | endif
        call add(ids, s:add_sign(a:sy, line, 'SignifyChange'))
      endwhile
    " Some lines are modified and some new lines are added.
    elseif old_count > 0 && new_count > 0 && old_count < new_count
      let modified += old_count
      let added += new_count - old_count
      let offset = 0
      while offset < old_count
        let line    = new_line + offset
        let offset += 1
        if s:external_sign_present(a:sy, line) | continue | endif
        call add(ids, s:add_sign(a:sy, line, 'SignifyChange'))
      endwhile
      while offset < new_count
        let line    = new_line + offset
        let offset += 1
        if s:external_sign_present(a:sy, line) | continue | endif
        call add(ids, s:add_sign(a:sy, line, 'SignifyAdd'))
      endwhile
    " Some lines are modified and some lines are deleted.
    elseif old_count > 0 && new_count > 0 && old_count > new_count
      let modified += new_count
      let deleted_count = old_count - new_count
      let deleted += deleted_count

      let prev_line_available = new_line > 1 && !get(a:sy.signtable, new_line - 1, 0)
      if prev_line_available
        if s:sign_show_count
          if deleted_count > 99
            let text = s:sign_delete . '>'
          elseif deleted_count < 2
            let text = s:sign_delete
          else
            let text = s:sign_delete . deleted_count
          endif
          while strwidth(text) > 2
            let text = substitute(text, '.', '', '')
          endwhile
          call add(ids, s:add_sign(a:sy, new_line - 1, 'SignifyDelete'. deleted_count, text))
        else
          call add(ids, s:add_sign(a:sy, new_line - 1, 'SignifyDeleteMore', s:sign_delete))
        endif
      endif

      let offset = 0
      while offset < new_count
        let line    = new_line + offset
        if s:external_sign_present(a:sy, line) | continue | endif
        if !prev_line_available && offset == 0
          call add(ids, s:add_sign(a:sy, line, 'SignifyChangeDelete'))
        else
          call add(ids, s:add_sign(a:sy, line, 'SignifyChange'))
        endif
        let offset += 1
      endwhile
    endif

    if !empty(ids)
      call add(a:sy.hunks, {
            \ 'ids'  : ids,
            \ 'start': a:sy.lines[0],
            \ 'end'  : a:sy.lines[-1] })
    endif
  endfor

  " Remove obsoleted signs.
  for line in filter(keys(a:sy.internal), '!has_key(a:sy.signtable, v:val)')
    execute 'sign unplace' a:sy.internal[line].id 'buffer='.a:sy.buffer
  endfor

  if empty(a:sy.updated_by) && empty(a:sy.hunks)
    call sy#verbose('Successful exit value, but no diff. Keep VCS for time being.', a:vcs)
    return
  endif

  call sy#verbose('Signs updated.', a:vcs)
  let a:sy.updated_by = a:vcs
  if len(a:sy.vcs) > 1
    call sy#verbose('Disable all other VCS.', a:vcs)
    let a:sy.vcs = [a:vcs]
  endif

  let a:sy.stats = [added, modified, deleted]
endfunction

" #remove_all_signs {{{1
function! sy#sign#remove_all_signs(bufnr) abort
  let sy = getbufvar(a:bufnr, 'sy', {})

  for hunk in get(sy, 'hunks', [])
    for id in get(hunk, 'ids', [])
      execute 'sign unplace' id 'buffer='.a:bufnr
    endfor
  endfor

  let sy.hunks = []
endfunction

" #parse_hunk {{{1
" Parse a hunk as '@@ -273,3 +267,14' into [old_line, old_count, new_line, new_count]
function! sy#sign#parse_hunk(diffline) abort
  let tokens = matchlist(a:diffline, '^@@ -\v(\d+),?(\d*) \+(\d+),?(\d*)')
  return [
        \ str2nr(tokens[1]),
        \ empty(tokens[2]) ? 1 : str2nr(tokens[2]),
        \ str2nr(tokens[3]),
        \ empty(tokens[4]) ? 1 : str2nr(tokens[4])
        \ ]
endfunction

" #set_signs {{{1
function! sy#sign#set_signs(sy, vcs, diff) abort
  call sy#verbose('sy#sign#set_signs()', a:vcs)

  if a:sy.stats == [-1, -1, -1]
    let a:sy.stats = [0, 0, 0]
  endif

  if empty(a:diff)
    call sy#verbose('No changes found.', a:vcs)
    let a:sy.stats = [0, 0, 0]
    call sy#sign#remove_all_signs(a:sy.buffer)
    return
  endif

  if get(g:, 'signify_line_highlight')
    call sy#highlight#line_enable()
  else
    call sy#highlight#line_disable()
  endif

  call sy#sign#process_diff(a:sy, a:vcs, a:diff)

  if exists('#User#Signify')
    doautocmd <nomodeline> User Signify
  endif
endfunction

" s:add_sign {{{1
function! s:add_sign(sy, line, type, ...) abort
  call add(a:sy.lines, a:line)
  let a:sy.signtable[a:line] = 1

  if has_key(a:sy.internal, a:line)
    " There is a sign on this line already.
    if a:type == a:sy.internal[a:line].type
      " Keep current sign since the new one is of the same type.
      return a:sy.internal[a:line].id
    else
      " Update sign by overwriting the ID of the current sign.
      let id = a:sy.internal[a:line].id
    endif
  endif

  if !exists('id')
    let id = sy#sign#id_next(a:sy)
  endif

  if a:type =~# 'SignifyDelete'
    execute printf('sign define %s text=%s texthl=SignifySignDelete linehl=%s',
          \ a:type,
          \ a:1,
          \ s:delete_highlight[g:signify_line_highlight])
  endif
  execute printf('sign place %d line=%d name=%s %s buffer=%s',
        \ id,
        \ a:line,
        \ a:type,
        \ s:sign_priority,
        \ a:sy.buffer)

  return id
endfunction

" s:external_sign_present {{{1
function! s:external_sign_present(sy, line) abort
  " If sign priority is supported, so are multiple signs per line.
  " Therefore, we can report no external signs present and let
  " g:signify_priority control whether Sy's signs are shown.
  if !empty(s:sign_priority)
    return
  endif
  if has_key(a:sy.external, a:line)
    if has_key(a:sy.internal, a:line)
      " Remove Sy signs from lines with other signs.
      execute 'sign unplace' a:sy.internal[a:line].id 'buffer='.a:sy.buffer
    endif
    return 1
  endif
endfunction
