" File: autoload/quickitunes.vim

scriptencoding utf-8
let s:save_cpo = &cpoptions
set cpoptions&vim

let s:root = substitute(expand('<sfile>:p:h'), '\\', '/', 'g')
let s:files = {
\ 'script' : s:root . '/quickitunes.js',
\ 'trackinfo_completes' : s:root . '/quickitunes_trackinfo.complete'
\}

let s:has_vimproc = 0
silent! let s:has_vimproc = vimproc#version()

function! quickitunes#request(command)
  return substitute(iconv(call(
        \ s:has_vimproc ? 'vimproc#system' : 'system',
        \ ['cscript //nologo ' . s:files.script . ' ' . a:command],
        \), 'sjis', &encoding), '\m^\n\+\|\n\+$', '', 'g')
endfunction

" variables for complete {{{
let s:completes = {}
let s:completes.commands = filter([
\ 'run',
\ 'quit',
\ 'play',
\ 'pause',
\ 'playPause',
\ 'stop',
\ 'rewind',
\ 'forward',
\ 'resume',
\ 'volume',
\ 'volumeUp',
\ 'volumeDown',
\ 'mute',
\ 'back',
\ 'prev',
\ 'next',
\ 'repeat',
\ 'repeatOff',
\ 'repeatOne',
\ 'repeatAll',
\ 'shuffle',
\ 'rating',
\ 'ratingUp',
\ 'ratingDown',
\ 'trackInfo',
\], printf(
\     'v:val !~ ''%s''',
\     '^\%(' . join(g:quickitunes_hide_completes, '\|') . '\)$'
\))
let s:completes.trackinfo = filereadable(s:files.trackinfo_completes)
      \ ? readfile(s:files.trackinfo_completes) : []
" }}}
function! quickitunes#complete(arglead, cmdline, cursorpos) " {{{
  let cmd = split(a:cmdline, ' ') " ['QuickiTunes', {command}, {argument}, ...]
  if len(cmd) < 2 || len(cmd) == 2 && strlen(a:arglead) > 0
    return filter(copy(s:completes.commands), 'v:val =~ a:arglead')
  elseif cmd[1] ==# 'trackInfo'
    return filter(copy(s:completes.trackinfo), printf(
          \ 'v:val !~ ''%s'' && v:val =~ ''%s''',
          \   '^\%(' . join(cmd, '\|') . '\)$',
          \   '^' . substitute(a:arglead, '*', '.*', 'g')
          \ ))
  endif
endfunction " }}}

let &cpoptions = s:save_cpo
unlet s:save_cpo
