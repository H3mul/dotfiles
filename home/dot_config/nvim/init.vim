set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath

let $NVIM_HOME=expand("$HOME/.config/nvim")

runtime pre_settings.vim
runtime plugins.vim
runtime settings.vim
runtime zet.vim
runtime keybinds.vim
