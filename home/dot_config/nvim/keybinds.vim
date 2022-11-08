" Global leader based keymaps
"
nnoremap <SPACE> <Nop>
let mapleader = ' '

nmap <Leader>f [fzf-p]
xmap <Leader>f [fzf-p]

nmap <Leader>g [git]
xmap <Leader>g [git]

nmap <Leader>z [zet]
xmap <Leader>z [zet]


nnoremap <silent> [fzf-p]p  :<C-u>Files<CR>

nnoremap <silent> [git]s    :<C-u>GFiles?<CR>
nnoremap <silent> [git]c    :<C-u>GitMessenger<CR>
nnoremap <silent> [git]l    :<C-u>BCommits<CR>
let g:gh_line_map = '<leader>gg'

nnoremap <silent> [zet]z    :<C-u>ZetList<CR>
nnoremap          [zet]n    :<C-u>ZetNew


" nnoremap [zet]n :ZettelNew<space>
nnoremap <M-CR> :VimwikiTabnewLink<CR>

" Navigate tabs

noremap g1 1gt
noremap g2 2gt
noremap g3 3gt
noremap g4 4gt
noremap g5 5gt
noremap g6 6gt
noremap g7 7gt
noremap g8 8gt
noremap g9 9gt
noremap g0 10gt

" Navigate wrapped lines
:nnoremap k gk
:nnoremap j gj

" Window management
map  <F10>      <C-W>=
imap <F10>      <C-O><C-W>=
map  <F11>      <C-W>-
imap <F11>      <C-O><C-W>-
map  <F12>      <C-W>+
imap <F12>      <C-O><C-W>+
map  <C-F11>    :res 1<CR>
imap <C-F11>    <C-O>:res 1<CR>
map  <C-F12>    <C-W>_
imap <C-F12>    <C-O><C-W>_
map  <C-Up>     <C-W><Up>
imap <C-Up>     <C-O><C-W><Up>
map  <C-Down>   <C-W><Down>
imap <C-Down>   <C-O><C-W><Down>
map  <C-Left>   <C-W><Left>
imap <C-Left>   <C-O><C-W><Left>
map  <C-Right>  <C-W><Right>
imap <C-Right>  <C-O><C-W><Right>
map  <C-K>      <C-W><Up>
imap <C-K>      <C-O><C-W><Up>
map  <C-J>      <C-W><Down>
imap <C-J>      <C-O><C-W><Down>
map  <C-H>      <C-W><Left>
imap <C-H>      <C-O><C-W><Left>
map  <C-L>      <C-W><Right>
imap <C-L>      <C-O><C-W><Right>

" Toggle search highlighting
map <F5> :set hlsearch!<Bar>set hlsearch?<CR>

" Toggle git gutter
map <F7> :GitGutterToggle<CR>

" Toggle paste
set pastetoggle=<F6>
map <F6> :set paste!<CR>i
imap <F6> <C-O>:set paste!<CR>

" Format json using python json.tool
map <F4> :%!python -m json.tool<CR>
imap <F4> <C-O>:%!python -m json.tool<CR>

" Trim trailing whitespace
nnoremap <leader>t :%s/\s\+$//e <CR>

" tagbar shortcut
nmap <F9> :Vista!!<CR>
nmap <F8> :NERDTreeToggle<CR>

" Dont show help on F1
map <F1> <nop>
imap <F1> <nop>

" Set ga to easy-align
nmap ga <Plug>(EasyAlign)
xmap ga <Plug>(EasyAlign)

" w!! to write with sudo even if not opened with sudo
cmap w!! w !sudo tee >/dev/null %

nmap <Leader>v [vimux]
xmap <Leader>v [vimux]

" Prompt for a command to run
map [vimux]p :VimuxPromptCommand<CR>
" Run last command executed by VimuxRunCommand
map [vimux]l :VimuxRunLastCommand<CR>
" Inspect runner pane
map [vimux]i :VimuxInspectRunner<CR>
" zoom runner pane
map [vimux]z :VimuxZoomRunner<CR>

nnoremap <leader>r :source ~/.config/nvim/init.vim<CR>

nnoremap <silent> <leader>p :read !date<CR>

" Ranger keybinds
nmap <Leader>m [ranger]
xmap <Leader>m [ranger]

nnoremap <silent> [ranger]o :RnvimrToggle<CR>
tnoremap <silent> [ranger]o <C-\><C-n>:RnvimrToggle<CR>
tnoremap <silent> [ranger]i <C-\><C-n>:RnvimrResize<CR>

nnoremap gO :silent !xdg-open <cfile><CR>
