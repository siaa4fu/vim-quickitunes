scriptencoding utf-8

let s:has_vimproc = 0
silent! let s:has_vimproc = vimproc#version()

" let s:script = {{{
let s:script = {}
let s:script.path = substitute(expand('<sfile>:p:h'), '\\', '/', 'g') . '/quickitunes.js'
let s:script.commands = filter([
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
      \], {i, cmd -> cmd !~# '\V\^\%(' . join(g:quickitunes_hide_completes, '\|') . '\)\$'})
let s:script.trackinfo = [
      \ 'album',
      \ 'albumartist',
      \ 'albumrating',
      \ 'albumratingkind',
      \ 'artist',
      \ 'bitrate',
      \ 'bpm',
      \ 'category',
      \ 'comment',
      \ 'compilation',
      \ 'composer',
      \ 'dateadded',
      \ 'description',
      \ 'disccount',
      \ 'discnumber',
      \ 'duration',
      \ 'enabled',
      \ 'episodeid',
      \ 'episodenumber',
      \ 'eq',
      \ 'finish',
      \ 'genre',
      \ 'grouping',
      \ 'kind',
      \ 'longdescription',
      \ 'lyrics',
      \ 'modificationdate',
      \ 'name',
      \ 'playedcount',
      \ 'playeddate',
      \ 'podcast',
      \ 'rating',
      \ 'ratingkind',
      \ 'samplerate',
      \ 'seasonnumber',
      \ 'show',
      \ 'size',
      \ 'skippedcount',
      \ 'skippeddate',
      \ 'start',
      \ 'time',
      \ 'trackcount',
      \ 'tracknumber',
      \ 'unplayed',
      \ 'videokind',
      \ 'volumeadjustment',
      \ 'year'
      \]
"}}}
function! quickitunes#request(command)
  return substitute(iconv(call(
        \ s:has_vimproc ? 'vimproc#system' : 'system',
        \ ['cscript //nologo ' . s:script.path . ' ' . a:command],
        \), 'sjis', &encoding), '\m^\n\+\|\n\+$', '', 'g')
endfunction

function! quickitunes#getlyricspath(echoerror, ...)
  " a:1 - fuzzy filename (string)
  if ! isdirectory(g:quickitunes_lyrics_rootdir)
    echoerr 'Lyrics directory does not exist.'
    return ''
  endif
  let trackinfo = {}
  let trackinfo._re_skippairs = '\V\s\*\%(' . join(map(
        \  filter(copy(g:quickitunes_lyrics_skippairs), {k, v -> strchars(v) == 2}),
        \  {k, v -> substitute(v, '\m^\(.\)\(.\)$', {m -> m[1] . '\[^' . m[2] . ']\*' . m[2]}, '')}
        \), '\|') . '\)\s\*'
  function! trackinfo._get(key) "{{{
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
  endfunction "}}}
  let rules = get(a:, 1, '') !=# ''
        \ ? ['*' . substitute(a:1, '\m^\*\|\*$', '', 'g') . '*']
        \ : g:quickitunes_lyrics_findrule
  let multipleLyricsFound = v:false
  for rule in rules
    let files = globpath(g:quickitunes_lyrics_rootdir,
          \ substitute(rule, '\m<\([^> ]*\)>', {m -> trackinfo._get(m[1])}, 'g'),
          \ 0, 1)
    if len(files) == 1
      return files[0]
    elseif len(files) > 1
      let multipleLyricsFound = v:true
    endif
  endfor
  if a:echoerror
    echohl ErrorMsg | echo (multipleLyricsFound ? 'Multiple' : 'No') 'lyrics found.' | echohl None
  endif
  return ''
endfunction

let s:lyric_bufnr = -1
function! quickitunes#openlyric(openmode, lyricfilename, ...)
  " a:1 - open command (string)
  if a:openmode ==# 'view'
    let lyricpath = quickitunes#getlyricspath(v:true, a:lyricfilename)
    if ! filereadable(lyricpath) | return | endif
  elseif a:openmode ==# 'edit'
    let lyricpath = quickitunes#getlyricspath(v:false, a:lyricfilename)
    if ! filereadable(lyricpath)
      let lyricpath = empty(a:lyricfilename) ? input('Lyrics filename: ') : a:lyricfilename
      if empty(lyricpath) | return | endif
      let lyricpath = g:quickitunes_lyrics_rootdir . '/' . lyricpath
    endif
  else
    echoerr 'Invalid mode.' a:openmode
    return
  endif
  let opencmd = a:0 > 0 ? a:1 : 'split'
  if ! bufexists(s:lyric_bufnr)
    " open new buffer
    execute opencmd
  else
    " reuse the buffer
    let winnr = bufwinnr(s:lyric_bufnr)
    if winnr > -1
      execute winnr 'wincmd w'
    else
      execute opencmd
      execute s:lyric_bufnr 'buffer!'
    endif
  endif
  execute 'edit' lyricpath
  if a:openmode ==# 'view'
    setlocal nomodifiable noswapfile nobuflisted bufhidden=wipe
  endif
  let s:lyric_bufnr = bufnr('%')
endfunction

function! quickitunes#complete_QuickiTunes(arglead, cmdline, cursorpos) "{{{
  let cmdline = a:cmdline[: a:cursorpos - 1]
  let [cmdname; cmdargs] = split(cmdline, '\m\s\+')
        \ + (strlen(a:arglead) == 0 && cmdline =~# '\m\s$' ? [''] : [])
  if len(cmdargs) == 1
    return filter(copy(s:script.commands),
          \ {i, cmd -> cmd =~ '\V' . escape(a:arglead, '\')})
  elseif len(cmdargs) > 1 && cmdargs[0] ==# 'trackInfo'
    return filter(copy(s:script.trackinfo),
          \ {i, info -> info !~ '\V\^\%('
          \                     . join(map(cmdargs[: -2], {i, v -> escape(v, '\')}), '\|')
          \                     . '\)\$'
          \             && info =~ '\V' . escape(a:arglead, '\')})
  endif
  return []
endfunction "}}}

function! quickitunes#complete_QuickiTunesLyrics(arglead, cmdline, cursorpos) "{{{
  if ! isdirectory(g:quickitunes_lyrics_rootdir) | return [] | endif
  let cmdline = a:cmdline[: a:cursorpos - 1]
  let [cmdname; cmdargs] = split(cmdline, '\%([^\\]\@<=\s\)\+')
        \ + (strlen(a:arglead) == 0 && cmdline =~# '\m[^\\]\s$' ? [''] : [])
  return len(cmdargs) == 1
        \ ? map(globpath(
        \     g:quickitunes_lyrics_rootdir,
        \     '*' . substitute(cmdargs[0], '\m^\*\|\*$', '', 'g') . '*',
        \     0, 1
        \   ), {i, path -> fnameescape(substitute(path, glob2regpat(g:quickitunes_lyrics_rootdir)[: -2], '', ''))})
        \ : []
endfunction "}}}
