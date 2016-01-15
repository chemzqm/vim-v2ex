if exists('did_v2ex_plugin_loaded') || !has('gui')
  finish
endif

let did_v2ex_plugin_loaded = 1
let s:save_cpo = &cpo
set cpo&vim

let s:root = expand('<sfile>:p:h:h')
let s:cached = []

function! s:RestartProcess()
  call s:killProcess()
  let valid = s:StartProcess()
  return valid
endfunction

function! s:StartProcess()
  let cwd = getcwd()
  let s:process = vimproc#plineopen3('node '. s:root . '/index.js')
  let valid = s:process.is_valid
  if !valid
    echohl Error | echon '[v2ex] process start failed' | echohl None
    return 0
  endif
  return 1
endfunction

function! s:killProcess()
  if exists('s:process')
    call s:process.kill(15)
    unlet s:process
  endif
endfunction

function! s:toggleList()
  let tpbl=[]
  call map(range(1, tabpagenr('$')), 'extend(tpbl, tabpagebuflist(v:val))')
  for nr in tpbl
    if bufname(nr) ==# '__v2ex_latest__'
      execute 'bd ' . nr
      return
    endif
  endfor
  exec 'keepalt 8split __v2ex_latest__'
  setl bufhidden=delete filetype=v2ex_list buftype=nofile nobuflisted noswapfile
  setl scrolloff=0 conceallevel=2 concealcursor=nc
  if exists('s:process')
    let lines = s:process.stdout.read_lines(2000)
    let s:cached = s:cached + lines
    call setline(1, s:cached[0])
    call append(1, s:cached[1:])
    execute 'normal! G'
  endif
  nnoremap <silent> <buffer> q     :<C-U>call <SID>QuitAll()<cr>
  nnoremap <silent> <buffer> <cr>  :<C-U>call <SID>OpenInBrowser()<cr>
  nnoremap <silent> <buffer> p     :<C-U>call <SID>PreviewTopic()<cr>
  nnoremap <silent> <buffer> <c-l> :<C-U>call <SID>RefreshList()<cr>
  call s:highlightList()
endfunction

function! s:QuitAll()
  for nr in range(1, winnr('$'))
    let name = bufname(winbufnr(nr))
    if name =~# '\v_v2ex$'
      execute 'bdelete! ' . name
    endif
  endfor
  silent bdelete!
endfunction

function! s:PreviewTopic()
  let tmp = tempname() . '_v2ex'
  let id = matchstr(getline('.'), '\v^\d+')
  let command = 'node ' . s:root . '/get.js ' . id . ' > ' . tmp
  let cwd = getcwd()
  let output = system(command)
  if v:shell_error && output !=# ""
    echohl Error | echon output | echohl None
    return
  endif
  exe 'pedit ' . tmp
endfunction

" Refresh current buffer
function! s:RefreshList()
  let valid = s:RestartProcess()
  if !valid | return | endif
  execute 'normal! ggdG'
  let lines = s:process.stdout.read_lines(2000)
  let s:cached = lines
  if len(lines)
    call setline(1, lines[0])
    call append(1, lines[1:])
    execute 'normal! G'
  endif
endfunction

function! s:highlightList()
  let b:current_syntax = 'v2exlist'
  syntax match v2exList__Item /^.*$/
  syntax match v2exList__id /^\v\d+\|/ contained conceal
      \ containedin=v2exList__Item
      \ nextgroup=v2exList_Time
  syntax match v2exList__Time /\v\d{2}:\d{2}/ contained
      \ containedin=v2exList__Item
      \ nextgroup=v2exList__Tag
  syntax match v2exList__Tag /\v%14c.{-}\]/ contained
      \ containedin=v2exList__Item
      \ nextgroup=v2exList__Title
  syntax match v2exList__Title /\v\]@<=.*$/ contained
      \ containedin=v2exList__Item
  highlight default link v2exList__Time Type
  highlight default link v2exList__Tag Identifier
  highlight default link v2exList__Title Statement
endfunction

function! s:OpenInBrowser()
  let id = matchstr(getline('.'), '\v^\d+')
  if len(id) && exists(':Open')
    execute 'Open http://v2ex.com/t/' . id
  elseif executable('open')
    execute 'silent !open http://v2ex.com/t/' . id
  endif
endfunction

function! s:_on_curser_hold()
  if !exists('s:process') | return | endif
  " zombie process
  if s:process.kill(0)
    unlet s:process
    return
  endif
  let cnr = winnr()
  let wnr = 0
  for nr in range(1, winnr('$'))
    let name = bufname(winbufnr(nr))
    if name ==# '__v2ex_latest__'
      let wnr = nr
    endif
  endfor
  if !wnr | return | endif
  exe wnr . 'wincmd w'
  let stderr = s:process.stderr
  let err = stderr.read_lines(1000)
  if !empty(err) | call s:printError(err) | endif
  if s:process.stdout.eof
    let [cond, status] = s:process.waitpid()
    echohl Error | echon '[v2ex] process ended with ' . status | echohl None
    unlet s:process
  else
    let lines = s:process.stdout.read_lines(2000)
    let s:cached = s:cached + lines
    if !empty(lines)
      call append(line('$'), lines)
      exe 'normal! G'
    endif
  end
  if cnr != wnr | exe 'wincmd p' | endif
  call feedkeys("g\<ESC>" . (v:count > 0 ? v:count : ''), 'n')
endfunction

function! s:printError(list)
  echohl Error
  for str in a:list
    echo '[v2ex]: ' . str
  endfor
  echohl None
endfunction

call s:StartProcess()

augroup v2ex
  autocmd!
  autocmd CursorHold,CursorHoldI * :call s:_on_curser_hold()
  autocmd VimLeavePre * :call s:killProcess()
  autocmd WinEnter __v2ex_latest__ :resize 8
  autocmd BufHidden *_v2ex :execute 'bd ' . expand('<abuf>')
augroup end

command! -nargs=0 V2toggle :call s:toggleList()

nnoremap <silent> <Plug>(V2exToggle) :<c-u>V2toggle<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
