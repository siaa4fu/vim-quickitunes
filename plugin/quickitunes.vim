" File: plugin/quickitunes.vim

scriptencoding utf-8
if exists('g:loaded_quickitunes') | finish | endif
let g:loaded_quickitunes = 1
let s:save_cpo = &cpoptions
set cpoptions&vim

let g:quickitunes_hide_completes =
      \ get(g:, 'quickitunes_hide_completes', [])
let g:quickitunes_quickinfo =
      \ get(g:, 'quickitunes_quickinfo', 'name artist album year rating')
let g:quickitunes_lyrics_rootdir =
      \ substitute(get(g:, 'quickitunes_lyrics_rootdir', ''), '\m[\\/]$', '', '')

" Windows only!
if has('win32') || has('win64')
  command! -nargs=+ -complete=customlist,quickitunes#complete QuickiTunes
        \ echohl WarningMsg | echo quickitunes#request(<q-args>) | echohl None
  command! -nargs=0 QuickiTunesInfo
        \ echo quickitunes#request('trackInfo ' . g:quickitunes_quickinfo)
  command! -bar -bang -nargs=* QuickiTunesLyrics
        \ try |
        \   if ! isdirectory(g:quickitunes_lyrics_rootdir) | throw 'Directory does not exist.' | endif |
        \   execute (<bang>1 ? 'split ' : 'edit ') . g:quickitunes_lyrics_rootdir . '/'
        \         . '*' . (<q-args> ==# '' ? g:quickitunes#request('trackInfo name') : <q-args>) . '*' |
        \ catch |
        \   echohl ErrorMsg | echo 'Lyrics not found. (or too many lyrics found.)' | echohl None |
        \ endtry
endif

let &cpoptions = s:save_cpo
unlet s:save_cpo
