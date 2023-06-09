scriptencoding utf-8

function! s:get_channel() abort
  if !exists('s:job') || job_status(s:job) !=# 'run'
    let s:job = job_start(['python3.11', '/usr/local/bin/chatgpt'], {'in_mode': 'json', 'out_mode': 'nl', 'noblock': 1})
    let s:ch = job_getchannel(s:job)
  endif
  return s:ch
endfunction

function! s:chatgpt_cb_out(ch, msg) abort
  let l:msg = json_decode(a:msg)
  let l:winid = bufwinid('__CHATGPT__')
  if l:winid ==# -1
    silent noautocmd split __CHATGPT__
    setlocal buftype=nofile bufhidden=wipe noswapfile
    setlocal wrap nonumber signcolumn=no filetype=markdown
    wincmd p
    let l:winid = bufwinid('__CHATGPT__')
  endif
  call win_execute(l:winid, 'setlocal modifiable', 1)
  call win_execute(l:winid, 'silent normal! GA' .. l:msg['text'], 1)
  if l:msg['error'] != ''
    call win_execute(l:winid, 'silent normal! Go' .. l:msg['error'], 1)
  elseif l:msg['eof']
    call win_execute(l:winid, 'silent normal! Go', 1)
  endif
  call win_execute(l:winid, 'setlocal nomodifiable nomodified', 1)
endfunction

function! s:chatgpt_cb_err(ch, msg) abort
  echohl ErrorMsg | echom '[chatgpt ch err] ' .. a:msg | echohl None
endfunction

function! chatgpt#send(text) abort
  let l:ch = s:get_channel()
 
  let l:role = get(g:, 'chatgpt_role', $ROLE)
  
  call ch_setoptions(l:ch, {'out_cb': function('s:chatgpt_cb_out'), 'err_cb': function('s:chatgpt_cb_err')})
  call ch_sendraw(l:ch, printf("%s\n", json_encode({'text': a:text, 'role': l:role})))
endfunction

function! chatgpt#raw(text) abort
  call s:chatgpt_cb_out("", json_encode({'eof': 0, 'error': '', 'text': printf(">>> %s\n", a:text) })) 
  let yanked_text = s:get_visual_selection()
  let l:lines = [
  \ a:text,
  \ yanked_text,
  \]
     
" echo join(l:lines, "\n")
  call chatgpt#send(join(l:lines, "\n"))
endfunction


function! s:get_visual_selection()
    " Why is this not a built-in Vim script function?!
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
        return ''
    endif
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    return join(lines, "\n")
endfunction



function! chatgpt#explain(text) abort
  let yanked_text = s:get_visual_selection()
  let l:lang = get(g:, 'chatgpt_lang', $LANG)
  let l:question = l:lang =~# '^ja' ? 'このプログラムをレビューして下さい。' : 'please explain this code.'
  let l:lines = [
  \ a:text,
  \  l:question,
  \  '',
  \  '```',
  \ yanked_text,
  \  '```',
  \]
      
  call s:chatgpt_cb_out("", json_encode({'eof': 0, 'error': '', 'text': printf(">>> %s\n", join([a:text, l:question], "\n")) })) 
  call chatgpt#send(join(l:lines, "\n"))
endfunction


function! chatgpt#rewrite(text) abort
   
  let yanked_text = s:get_visual_selection()

  let l:lang = get(g:, 'chatgpt_lang', $LANG)
  let l:question = l:lang =~# '^ja' ? 'このプログラムをレビューして下さい。' : 'please re-write this code.'
  let l:lines = [
  \ a:text,
  \  l:question,
  \  '',
  \  '```',
  \ yanked_text,
  \  '```',
  \]
      
  call s:chatgpt_cb_out("", json_encode({'eof': 0, 'error': '', 'text': printf(">>> %s\n", join([a:text, l:question], "\n")) })) 
  call chatgpt#send(join(l:lines, "\n"))

endfunction

function! chatgpt#fix(text) abort
  let yanked_text = s:get_visual_selection()
  let l:lang = get(g:, 'chatgpt_lang', $LANG)
  let l:question = l:lang =~# '^ja' ? 'このプログラムをレビューして下さい。' : 'please fix this code.'
  let l:lines = [
  \ a:text,
  \  l:question,
  \  '',
  \  '```',
  \ yanked_text,
  \  '```',
  \]
      
  call s:chatgpt_cb_out("", json_encode({'eof': 0, 'error': '', 'text': printf(">>> %s\n", join([a:text, l:question], "\n")) })) 
  call chatgpt#send(join(l:lines, "\n"))


endfunction


function! chatgpt#set_role(text) abort
 let g:chatgpt_role = a:text
 echo "Role set to " . a:text
endfunction



function! chatgpt#review(text) abort
  let yanked_text = s:get_visual_selection()
  let l:lang = get(g:, 'chatgpt_lang', $LANG)
  let l:question = l:lang =~# '^ja' ? 'このプログラムをレビューして下さい。' : 'please review this code.'
  let l:lines = [
  \ a:text,
  \  l:question,
  \  '',
  \  '```',
  \ yanked_text,
  \  '```',
  \]
      
  call s:chatgpt_cb_out("", json_encode({'eof': 0, 'error': '', 'text': printf(">>> %s\n", join([a:text, l:question], "\n")) })) 
  call chatgpt#send(join(l:lines, "\n"))


endfunction







function! chatgpt#code_review_please() abort
  let l:lang = get(g:, 'chatgpt_lang', $LANG)
  let l:question = l:lang =~# '^ja' ? 'このプログラムをレビューして下さい。' : 'please code review'
  let l:lines = [
  \  l:question,
  \  '',
  A
  \] + getline(1, '$')
  call chatgpt#send(join(l:lines, "\n"))
endfunction
