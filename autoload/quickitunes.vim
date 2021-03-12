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

function! quickitunes#getlyricspath(...)
  " a:1 - fuzzy filename (string)
  if ! isdirectory(g:quickitunes_lyrics_rootdir)
    echohl ErrorMsg | echo 'Lyrics directory does not exist.' | echohl None
    return ''
  endif
  let trackinfo = {}
  let trackinfo._re_skippairs = '\V\s\*\%(' . join(map(
        \  filter(copy(g:quickitunes_lyrics_skippairs), {k, v -> strchars(v) == 2}),
        \  {k, v -> substitute(v, '\m^\(.\)\(.\)$', {m -> m[1] . '\[^' . m[2] . ']\*' . m[2]}, '')}
        \), '\|') . '\)\s\*'
  function! trackinfo._get(key) " {{{
    if ! has_key(self, a:key)
      if match(a:key, '^fuzzy_') > -1
        let self[a:key] = self._get(matchstr(a:key, '\m^fuzzy_\zs.*'))
              \ ->substitute(self._re_skippairs, '*', 'g')
              \ ->substitute('\m\*\+', '*', 'g')
      else
        let self[a:key] = quickitunes#request('trackInfo ' . a:key)
      endif
    endif
    return self[a:key]
  endfunction " }}}
  let rules = get(a:, 1, '') !=# ''
        \ ? ['*' . substitute(a:1, '\m^\*\|\*$', '', 'g') . '*']
        \ : g:quickitunes_lyrics_findrule
  for rule in rules
    let files = globpath(g:quickitunes_lyrics_rootdir,
          \ substitute(rule, '\m<\([^> ]*\)>', {m -> trackinfo._get(m[1])}, 'g'),
          \ 0, 1)
    if len(files) == 1
      return files[0]
    endif
  endfor
  echohl ErrorMsg | echo 'Lyrics not found, or too many lyrics found.' | echohl None
  return ''
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
