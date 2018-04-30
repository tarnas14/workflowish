# Workflowish

Simple TODO list plugin for Vim, inspired by 

- [Workflowy.com](https://workflowy.com/)
- [vimflowy](https://github.com/WuTheFWasThat/vimflowy)

# FORKED FROM

[workflowish](https://github.com/lukaszkorecki/workflowish)

# Why?

I was using workflowy for a long time, then picked up vim and after learning 
some basic usage I decided it was the superior way to edit text and navigate documents.

I wanted the same navigation in workflowy, so I looked around and found [vimflowy](https://github.com/WuTheFWasThat/vimflowy)
Initially I wanted to use vimflowy and implement additional functionality there, but I gave up on the idea.

I used workflowy tags with dates to mark due dates and search engine to display
tasks to be done for particular days. Typing whole `#2017-05-08` is a pain in the ass,
so I wanted shortcuts (something like `today` which would get translated to `#YYYY-MM-DD` format)

I turned towards [workflowish](https://github.com/lukaszkorecki/workflowish) !
And decided to fiddle with vim to get something done that would fit my needs :)

## prerequisites ...

To make this work like workflowy in vim you only have to learn to work with `vim folding` and `vimgrep` and `quickfix`...

# Features and syntax

Thanks to the long running tradition, *workflowish* files have `.wofl` extension.

## provided by vim

- searching (Vim is pretty good at it)
- deleting (as above)
- split windows in vim makes it easy to organize big lists
- [vimgrep](http://vimdoc.sourceforge.net/htmldoc/quickfix.html#:vimgrep) for filtering lines

## provided by this plugin

- folding and a `zoom/focus` mode
  - `zq` to focus on current item / toggle off
  - `zp` move focus to parent item
  - `za` toggles folding. See [Vim wiki: Folding](http://vim.wikia.com/wiki/Folding#Opening_and_closing_folds)
- convert from workflowy plain text export
  - in a `.wofl` file or after `:set ft=workflowish`, run `:call workflowish#convert_from_workflowy()` to convert the whole buffer
- vimgrep shortcut (`:G`) that greps current buffer, based on a great plugin [VimGrepBuffer](https://github.com/vim-scripts/VimgrepBuffer)
- notes (just add `\` in the beginning of the line to start a comment)
- todos:
  - a todo which is not completed is a line which starts with `*`
  - completed todo starts with a `-`
  - `:Done`/`:D` command marks line as done (changes first character to `-`)
  - `:Task`/`:T` command marks line as task (changes first character to `+`)
  - `:Note`/`:WN` command marks line as regular dot (changes first character to `*`)

### task management

this is the basic convention: task date is marked by tags in `#YYYY-MM-DD` format

shortcut commands for `NORMAL` mode:

`:Today` adds current date `#YYYY-MM-DD` tag at the end of current line
`:Tomorrow` adds tomorrow `#YYYY-MM-DD` tag at the end of current line
`:Do <offset>` adds a `#YYYY-MM-DD` for today + <offset> (note, if offset is '-1' it will add yesterday's date)
`:Undo`/`:U` removes `#YYYY-MM-DD` from the end of current line

`:TodoToday`/`:TT` uses `:G` to look for `#YYYY-MM-DD` tags for current date
`:TodoTomorrow`/`:TTr` uses `:G` to look for `#YYYY-MM-DD` tags for date of next day 
`:Todo <offset>` uses `:G` to look for `#YYYY-MM-DD` tags for date offset by <offset> from today

### project management

Projects are dots which have a dot and their first child (the line directly below them without any notes) is `+ actions`.
Project actions are dots that are direct childs of the `+ actions`. Actions marked by `-` are considered done.

- `:A` will show all not done actions per project (first project name, then actions)
- `:P` will show all projects

# Installing

[Use Tim Pope's Pathogen](https://github.com/tpope/vim-pathogen).
[or vim plug](https://github.com/junegunn/vim-plug)

## Optional configuration tweak

This is not necessary for most users, but if you're a perfectionist you can do it. Add this to your .vimrc to fix [an edge-case with folding single-items](https://github.com/lukaszkorecki/workflowish/issues/5):

```
autocmd BufWinLeave *.wofl mkview
autocmd BufWinEnter *.wofl silent loadview
```

# Legal

MIT (c)
