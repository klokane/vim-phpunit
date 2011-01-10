" Author:  KLoK <klok at klok.cz>
" License: The MIT License
" URL:     https://github.com/klokane/vim-phpunit 
" Version: 0.1
"
" default mapping:
" nnoremap <Leader>t :PhpUnit<Enter>
" nnoremap <Leader>tf :PhpUnitFile<Enter>
" nnoremap <Leader>ts :PhpUnitSwitchFile<Enter>
" 
" TODO:
" * PhpUnitSwitchFile - test if path exists and allow to create it on way
" * PhpUnitSwitchFile - create skeleton if file not exists (configurable)
" * PhpUnitSwitchFile - allow configure way to open complement file
" * PhpUnitFile - run last test if cursor is in output buffer
" * output - allow jump throw Fail assert and Errors
" * output - while processing tests
"
" IDEA: (maybe in deep future)
" * support call throught :make 
" * send bugs to <quickfix> buffer
"

" 
" binary file to run default
"
if !exists('g:phpunit_bin')
  let g:phpunit_bin = 'phpunit'
endif

"
" root of unit tests
"
if !exists('g:phpunit_testroot')
  let g:phpunit_testroot = 'tests'
endif

"
" you can set there subset of tests if you do not want to run
" full set
"
if !exists('g:phpunit_tests')
  let g:phpunit_tests = g:phpunit_testroot
endif


"
" flags to run phpunit
"
if !exists('g:phpunit_params')
  let g:phpunit_params = '--stop-on-failure'
endif

if !exists('g:phpunit_highlights')
  highlight default PhpUnitFail ctermbg=Red ctermfg=White
  highlight default PhpUnitOK ctermbg=LightGreen ctermfg=White
  highlight default PhpUnitAssertFail ctermfg=LightRed
  let g:phpunit_highlights = 1
endif


"
" call shell with phpunit
"  $ <phpunit_bin> [[<phpunit_params>] <args>]
"
"  args default is <phpunit_tests>
"
function! s:PhpUnitSystem(args)
  return system(g:phpunit_bin . ' ' . g:phpunit_params . ' ' . a:args)
endfunction

"
" @command :PhpUnit [path]
"
" run all tests specified in [path]
" if [path] is not set it use <phpunit_tests>
"
function! PhpUnitRun(path)
  let tests_path = strlen(a:path) ? a:path : g:phpunit_tests
  echohl Title
  echo "* Running PHP Unit test(s) [" . tests_path . "] *"
  echohl None
  echo ""
  let phpunit_out = s:PhpUnitSystem(tests_path)
  silent call <SID>PhpUnitOpenBuffer(phpunit_out)
endfunction

"
" @command
" :PhpUnitFile
" 
" call PhpUnitRun() with path set to current file
" (you need no care if you are on main file, or testing file)
"
function! PhpUnitRunEditedFile() 
  let path = expand('%:r')
  if expand('%:t') !~ "Test\."
    let path = g:phpunit_testroot . "/" . expand('%:r') . "Test"
  endif
  call PhpUnitRun(path)
endfunction

"
" @command
" :PhpUnitSwitchFile 
" 
" switch between file/test
" if one of them is not open it open complement file by vsplit
" default: file in left split, test in right split
"
function! PhpUnitSwitchFile()
  let f = expand('%')
  let cmd = ''
  let is_test = expand('%:t') =~ "Test\."
  if is_test
    " remove phpunit_testroot
    let f = substitute(f,'^'.g:phpunit_testroot.'/','','')
    " remove 'Test.' from filename
    let f = substitute(f,'Test\.','.','')
    let cmd = 'bo '
  else
    let f = g:phpunit_testroot . "/" . expand('%:r') . "Test.php"
    let cmd = 'to '
  endif
  " is there window with complent file open?
  let win = bufwinnr(f)
  if win > 0
    execute win . "wincmd w"
  else
    execute cmd . "vsplit " . f
  endif
endfunction

"
"render output to scratch buffer
"
function! s:PhpUnitOpenBuffer(content)
  " is there phpunit_buffer?
  if exists('g:phpunit_buffer') && bufexists(g:phpunit_buffer)
    let phpunit_win = bufwinnr(g:phpunit_buffer)
    " is buffer visible?
    if phpunit_win > 0
      " switch to visible phpunit buffer
      execute phpunit_win . "wincmd w"
    else
      " split current buffer, with phpunit_buffer
      execute "sb ".g:phpunit_buffer
    endif
    " well, phpunit_buffer is opened, clear content
    setlocal modifiable
    silent %d
  else
    " there is no phpunit_buffer create new one
    new
    let g:phpunit_buffer=bufnr('%')
  endif

  setlocal buftype=nofile modifiable bufhidden=hide
  silent put=a:content
  "efm=%E%\\d%\\+)\ %m,%CFailed%m,%Z%f:%l,%-G
  call matchadd("PhpUnitFail","^FAILURES.*$")
  call matchadd("PhpUnitOK","^OK .*$")
  call matchadd("PhpUnitAssertFail","^Failed asserting.*$")
  setlocal nomodifiable
endfunction

command! -nargs=? -complete=file PhpUnit call PhpUnitRun(<q-args>)
command! PhpUnitFile call PhpUnitRunEditedFile()
command! PhpUnitSwitchFile call PhpUnitSwitchFile()

if !exists('g:phpunit_key_map') || !g:phpunit_key_map
    nnoremap <Leader>t :PhpUnit<Enter>
    nnoremap <Leader>tf :PhpUnitFile<Enter>
    nnoremap <Leader>ts :PhpUnitSwitchFile<Enter>
endif
