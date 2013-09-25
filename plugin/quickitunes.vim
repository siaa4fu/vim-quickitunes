" File:        plugin/quickitunes.vim
" Author:      sima (TwitterID: sima_fu)
" Namespace:   http://f-u.seesaa.net/
" Last Change: 2013-09-10.

scriptencoding utf-8

if exists('g:loaded_quickitunes')
  finish
endif
let g:loaded_quickitunes = 1

let g:quickitunes_hide_completes = get(g:, 'quickitunes_hide_completes', [])
let g:quickitunes_quickinfo = get(g:, 'quickitunes_quickinfo', 'name artist album year rating')

" Windows only!
if !has('win32') && !has('win64')
  finish
endif

command! -nargs=* -complete=customlist,quickitunes#complete QuickiTunes call quickitunes#request(<q-args>)
command! -nargs=0 QuickiTunesInfo call quickitunes#request('trackInfo ' . g:quickitunes_quickinfo)
