scriptencoding utf-8
if exists('g:loaded_quickitunes') | finish | endif
let g:loaded_quickitunes = 1

let g:quickitunes_hide_completes =
      \ get(g:, 'quickitunes_hide_completes', [])
let g:quickitunes_quickinfo =
      \ get(g:, 'quickitunes_quickinfo', 'name artist album year rating')
let g:quickitunes_lyrics_rootdir =
      \ substitute(get(g:, 'quickitunes_lyrics_rootdir', ''), '\m[\\/]$', '', '') . '/'
let g:quickitunes_lyrics_findrule =
      \ get(g:, 'quickitunes_lyrics_findrule', [
      \   '<artist> - <name>.txt',
      \   '<artist> - <fuzzy_name>.txt',
      \   '* - <name>.txt',
      \   '* - <fuzzy_name>.txt',
      \   '* - <fuzzy_name>*'
      \ ])
let g:quickitunes_lyrics_skippairs =
      \ get(g:, 'quickitunes_lyrics_skippairs', ['()', '{}', '[]', '<>'])

" Windows only!
if has('win32') || has('win64')
  command! -nargs=1 -complete=customlist,quickitunes#complete_QuickiTunes QuickiTunes
        \ echohl WarningMsg | echo quickitunes#request(<q-args>) | echohl None
  command! -nargs=0 QuickiTunesInfo
        \ echo quickitunes#request('trackInfo ' . g:quickitunes_quickinfo)
  command! -bar -bang -nargs=? -complete=customlist,quickitunes#complete_QuickiTunesLyrics QuickiTunesLyrics
        \ call quickitunes#openlyric('view', <q-args>, <bang>1 ? <q-mods> . ' split' : 'enew')
  command! -bar -bang -nargs=? -complete=customlist,quickitunes#complete_QuickiTunesLyrics QuickiTunesEditLyrics
        \ call quickitunes#openlyric('edit', <q-args>, <bang>1 ? <q-mods> . ' split' : 'enew')
endif
