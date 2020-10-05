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

" Windows only!
if has('win32') || has('win64')
  command! -nargs=* -complete=customlist,quickitunes#complete QuickiTunes
        \ call quickitunes#request(<q-args>)
  command! -nargs=0 QuickiTunesInfo
        \ call quickitunes#request('trackInfo ' . g:quickitunes_quickinfo)
endif

let &cpoptions = s:save_cpo
unlet s:save_cpo
