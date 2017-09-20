setlocal foldlevel=1
setlocal foldenable
setlocal sw=2 sts=2
setlocal expandtab
setlocal foldtext=WorkflowishFoldText()
setlocal foldmethod=expr
setlocal foldexpr=WorkflowishCompactFoldLevel(v:lnum)

setlocal autoindent

" Settings {{{

" This will use horizontal scroll in focus mode
" The current problems is that the foldtext isn't scrolled auto
" and it's easy to 'lose' the horizontal scroll when using certain commands
" also, there seems to be quite a few bugs
if !exists("g:workflowish_experimental_horizontal_focus")
  let g:workflowish_experimental_horizontal_focus = 0
endif

if !exists("g:workflowish_disable_zq_warning")
  let g:workflowish_disable_zq_warning = 0
endif

"}}}
" Keybindings {{{

nnoremap <buffer> zq :call WorkflowishFocusToggle(line("."))<cr>
nnoremap <buffer> zp :call WorkflowishFocusPrevious()<cr>

if g:workflowish_disable_zq_warning == 0
  nnoremap <buffer> ZQ :call WorkflowishZQWarningMessage()<cr>
endif

"}}}
" Missing framework functions {{{

" unicode length, from https://github.com/gregsexton/gitv/pull/14
if exists("*strwidth")
  "introduced in Vim 7.3
  fu! s:StringWidth(string)
    return strwidth(a:string)
  endfu
else
  fu! s:StringWidth(string)
    return len(split(a:string,'\zs'))
  endfu
end

function! s:WindowWidth()
  " TODO: signcolumn takes up 2 columns, hardcoded
  return winwidth(0) - &fdc - &number*&numberwidth - 2
endfunction

function! s:StripEnd(str)
  return substitute(a:str, " *$", "", "")
endfunction

"}}}
" Workflowish utility functions {{{

function! WorkflowishZQWarningMessage()
  echohl WarningMsg
  echo "ZQ is not zq. Did you leave caps lock on? Put this in config to disable this message: let g:workflowish_disable_zq_warning = 1"
  echohl None
endfunction

function! s:CleanLineForBreadcrumb(lnum)
  return s:StripEnd(substitute(getline(a:lnum), "\\v^( *)(\\\\|\\*|\\-) ", "", ""))
endfunction

function! s:PreviousIndent(lnum)
  let lastindent = indent(a:lnum)
  for line in range(a:lnum-1, 1, -1)
    if lastindent > indent(line)
      return line
    end
  endfor
  return 0
endfunction

"}}}
" Window attribute methods {{{
" Couldn't find any other 'sane' way to initialize window variables

function! s:GetFocusOn()
  if !exists("w:workflowish_focus_on")
    let w:workflowish_focus_on = 0
  endif
  return w:workflowish_focus_on
endfunction

function! s:SetFocusOn(lnum)
  let w:workflowish_focus_on = a:lnum
endfunction

" Yes it looks horrible, and it is.
" This will be checked row for row, i.e. 1,2,3,4,5,6,7,8 and then maybe 4,5,6,7,8 and
" 4,5 which will trigger a recompute 3 times for row 1, 4 and 4 again using
" the cache the other times.
function! s:GetFocusOnEnd(lnum, focusOn)
  if !exists("w:workflowish_focus_on_end")
    let w:workflowish_focus_on_end = 0
  endif
  if !exists("w:workflowish_focus_on_end_last_accessed_row")
    let w:workflowish_focus_on_end_last_accessed_row = 0
  endif
  if a:focusOn > 0
    if w:workflowish_focus_on_end_last_accessed_row == a:lnum
      " take it easy
    elseif w:workflowish_focus_on_end_last_accessed_row == a:lnum-1
      let w:workflowish_focus_on_end_last_accessed_row = a:lnum
    else
      let w:workflowish_focus_on_end_last_accessed_row = a:lnum
      call s:RecomputeFocusOnEnd(a:focusOn)
    end
  else
    let w:workflowish_focus_on_end = 0
  end
  return w:workflowish_focus_on_end
endfunction

" This method is quite slow in big files
function! s:RecomputeFocusOnEnd(lfrom)
  let lend = line('$')
  if a:lfrom > 0
    let foldindent = indent(a:lfrom)

    let w:workflowish_focus_on_end = lend
    let lnum = a:lfrom+1
    while lnum < lend
      if indent(lnum) <= foldindent && getline(lnum) !~ "^\\s*$"
        let w:workflowish_focus_on_end = lnum-1
        break
      endif
      let lnum = lnum + 1
    endwhile
  else
    let w:workflowish_focus_on_end = 0
  endif
  return w:workflowish_focus_on_end
endfunction

"}}}
" Feature : Folds {{{

" This feature hides all nested lines under the main one, like workflowy.
function! WorkflowishCompactFoldLevel(lnum)
  let focusOn = s:GetFocusOn()
  if l:focusOn > 0
    if a:lnum == 1
      call s:RecomputeFocusOnEnd(l:focusOn)
    end
    if a:lnum ==# 1 || a:lnum ==# s:GetFocusOnEnd(a:lnum, l:focusOn) + 1
      return '>1'
    elseif (a:lnum ># 1 && a:lnum <# l:focusOn) || a:lnum > s:GetFocusOnEnd(a:lnum, l:focusOn) + 1
      return 1
    else
      return s:ComputeFoldLevel(a:lnum, indent(l:focusOn) * -1)
    endif
  else
    return s:ComputeFoldLevel(a:lnum, 0)
  endif
endfunction

function! s:ComputeFoldLevel(lnum, indent_offset)
  " TODO: check why vspec can't handle options like &shiftwidth instead of
  " hardcoded 2
  let this_indent = (indent(a:lnum) + a:indent_offset) / 2
  let next_indent = (indent(a:lnum + 1) + a:indent_offset) / 2

  if next_indent > this_indent
    return '>' . next_indent
  else
    return this_indent
  endif
endfunction

function! WorkflowishFoldText()
  let focusOn = s:GetFocusOn()
  if l:focusOn > 0 && !(v:foldstart >= l:focusOn && v:foldstart <= s:RecomputeFocusOnEnd(l:focusOn))
    if v:foldstart ==# 1
      return WorkflowishBreadcrumbs(v:foldstart, v:foldend)
    else
      return repeat("- ", s:WindowWidth() / 2)
    endif
  else
    let lines = v:foldend - v:foldstart
    let firstline = getline(v:foldstart)
    let textend = '|' . lines . '| '

    if g:workflowish_experimental_horizontal_focus == 1 && s:GetFocusOn() > 0
      let firstline = substitute(firstline, "\\v^ {".w:workflowish_focus_indent."}", "", "")
    end

    return firstline . repeat(" ", s:WindowWidth()-s:StringWidth(firstline.textend)) . textend
  endif
endfunction

function! WorkflowishBreadcrumbs(lstart, lend)
  let breadtrace = ""
  let lastindent = indent(a:lend+1)
  for line in range(a:lend, a:lstart, -1)
    if lastindent > indent(line)
      let breadtrace = s:CleanLineForBreadcrumb(line) . " > " . breadtrace
      let lastindent = indent(line)
    end
  endfor
  let breadtrace = substitute(breadtrace, " > $", "", "")
  if breadtrace == ""
    let breadtrace = "Root"
  endif
  return breadtrace . repeat(" ", s:WindowWidth()-s:StringWidth(breadtrace))
endfunction
"}}}
" Feature : Focus {{{

function! WorkflowishFocusToggle(lnum)
  if a:lnum == s:GetFocusOn()
    call WorkflowishFocusOff()
  else
    call WorkflowishFocusOn(a:lnum)
  endif
endfunction

function! WorkflowishFocusOn(lnum)
  if a:lnum == 0
    return WorkflowishFocusOff()
  end
  call s:SetFocusOn(a:lnum)
  if g:workflowish_experimental_horizontal_focus == 1
    let w:workflowish_focus_indent = indent(a:lnum)
    " nowrap is needed to scroll horizontally
    setlocal nowrap
    normal! "0zs"
  endif
  " reparse folds, close top/line1 unless focused, close bottom, go back
  normal zx
  if a:lnum != 1
    normal 1Gzc
  endif
  if a:lnum != line('$')
    normal Gzc
  end
  execute "normal" a:lnum . "Gzv"
endfunction

function! WorkflowishFocusOff()
  call s:SetFocusOn(0)
  if g:workflowish_experimental_horizontal_focus == 1
    setlocal wrap
  end
  normal zx
endfunction

function! WorkflowishFocusPrevious()
  if s:GetFocusOn() > 0
    call WorkflowishFocusOn(s:PreviousIndent(s:GetFocusOn()))
  end
endfunction

"}}}
" Feature : Convert {{{

function! workflowish#convert_from_workflowy()
  " Replace all - with *
  silent %s/\v^( *)- /\1* /e

  " Fix notes under other notes or items (whitespace hack, copies the number of spaces in submatch \1 from last row), max 1000 rows in one comment block
  " The try will catch nomatch early and stop
  try
    let c = 1
    while c < 1000
      silent %s/\v^( *)(  \\|\*)( .*\n)\1  ( *)([^\-\* ]|$)/\1\2\3\1  \\\4 \5/
      let c += 1
    endwhile
  catch /^Vim(substitute):E486:/
  endtry
  " Change completed items to -
  silent %s/\v^( *)\* \[COMPLETE\] /\1- /e
endfunction

"}}}

" vim:set fdm=marker sw=2 sts=2 et:

""""""""""""""""""""""""""""""""""""""""""""""""
" BLATANTLY COPIED AND MODIFIED, BASED ON
" https://github.com/vim-scripts/VimgrepBuffer
" Original Author: Jeet Sukumaran
""""""""""""""""""""""""""""""""""""""""""""""""
"
" Run vimgrep on buffers.
"
" This plugin provides easy application of the 'vimgrep' command on buffers
" (as opposed to the filesystem, which is its normal mode of operation).  It
" provides two commands: one to search just the current buffer, and the other
" to search all listed buffers.  The QuickFix buffer will be populated with
" the search results, if any, and opened for viewing. The search pattern will
" also be assigned to the search register, so that matches will be highlighted
" if 'hlsearch' is on (':set hlsearch').
"
" One command is provided, ':G', which searches the current buffer"
"
" The pattern specification is *exactly* like that for 'vimgrep'.  This means
" that if the pattern starts with a non-identifier or contains any literal whitespace
" characters, for correct behavior you will have to enclose the pattern in
" delimiter characters (e.g. "/", "@", "#"):
"
"    :G /\s*print "\d/
"    :G /\s*def\s\+\w\+(/
"    :G /\(def\s\+\|class\s+\)/
"    :G /\cisland/
"    :G /the quick brown \w+/
"    :G /except \+\w\+Error/
"
" If your pattern starts with an identifier you can omit the enclosing
" delimiters:
"
"    :G def\s\+\w\+(.*\*\*kwargs)
"    :G except\s\+\w\+Error
"
" In this latter case, the pattern will be considered to be
" whitespace-delimited, and so if your pattern contains any literal whitespace
" you may get incorrect results. This behavior is exactly like that of
" 'vimgrep'.
"

command! -nargs=1 G call s:VimgrepBuffer(<q-args>)

" Search for pattern in current buffer and add hits to QuickFix
"     First argument (mandatory): search pattern
"     Second argument (optional): 0 = add to results instead of replacing; default = 1
"     Third argument (optional): 0 = do not assign pattern to search register; default = 1
"     Fourth argument (optional): 0 = do not open quickfix window; default = 1
function! s:VimgrepBuffer(pattern, ...)
    let l:vg = "vimgrep"
    let l:replace_results = 1
    let l:set_search_register = 1
    let l:view_results = 1
    if a:0 >= 1 && !a:1
        let l:replace_results = 0
        let l:vg = "vimgrepadd"
    else
        call setqflist([])
    endif
    if a:0 >= 2 && !a:2
        let l:set_search_register = 0
    endif
    if a:0 >= 3 && !a:3
        let l:view_results = 0
    endif
    try
        silent execute l:vg." ".a:pattern." %"
    catch /^Vim\%((\a\+)\)\=:E480/   " no match
        " ignore
    catch /^Vim\%((\a\+)\)\=:E499/   " empty file name for %
        " ignore
    endtry
    call s:ViewVimgrepBufferResults(a:pattern, l:set_search_register, l:view_results, bufnr("%"), getpos("."))
endfunction

" Present search results.
function! s:ViewVimgrepBufferResults(pattern, set_search_register, view_results, restore_buffer, restore_pos)
    if a:set_search_register
        let @/=a:pattern
    endif
    if a:view_results
        if len(getqflist()) > 0
            copen
            set conceallevel=2 concealcursor=nc
            syntax match qfFileName /^[^|]*/ transparent conceal
            1cc
        else
            cclose
            silent execute "buffer ".a:restore_buffer
            silent call setpos('.', a:restore_pos)
            redraw
            echohl WarningMsg
            echo "No matches found for: ".a:pattern
            echohl None
        endif
    endif
endfunction

" FOR MANIPULATING TASKS ON WORKFLOWY
" setting due dates for tasks (in not too distant future, based on 'offset' in days from today)

function! s:InsertAtEnd(text)
  " Append space + result to current line without moving cursor.
  let spaceOrNoSpace = empty(getline('.')) ? '' : ' '
  call setline(line('.'), getline('.') . spaceOrNoSpace . '#' . a:text)
endfunction

function! s:GetDateTag(days)
  let days = empty(a:days) ? '+0' : a:days
  let cmd = '/bin/date +\%F -d ' . shellescape(days . ' day')
  let result = substitute(system(cmd), '[\]\|[[:cntrl:]]', '', 'g')
  return result
endfunction

command! -bar -nargs=1 Do call s:InsertAtEnd(s:GetDateTag(<f-args>))
command! Today Do 0 | TT | <c-o>
command! Tomorrow Do +1 | TTr

command! -bar -nargs=1 Todo execute 'G /' . s:GetDateTag(<f-args>) . '/'
command! TodoToday Todo 0 | noh
command! TT TodoToday
command! TodoTomorrow Todo +1
command! TTr TodoTomorrow

command! Task s/\S/+/ <bar> noh
command! T Task

command! Note s/\S/*/ <bar> noh
command! WN Note

command! -bar Undo s/\s*#\d\d\d\d-\d\d-\d\d\s*$// <bar> noh
command! U Undo | TT

command! -bar Done s/\S/-/ <bar> noh
command! D Done | Undo | TT
