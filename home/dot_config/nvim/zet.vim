func! zet#new(...)
    let cmd = join([g:zet_command, "--noedit", "new", join(a:000, ' ')])
    let note_file = system(cmd)
    silent exec join(["tabedit", "+$", note_file])
endfunc

let g:zet_command = "zet"

command! -nargs=+ ZetNew call zet#new(<f-args>)

command! -bang -nargs=? -complete=dir ZetList
            \ call fzf#vim#files(expand($ZETTEL_HOME), {'options': ['--info=inline', '--preview', 'bat --color=always --decorations=never {}']}, <bang>0)
