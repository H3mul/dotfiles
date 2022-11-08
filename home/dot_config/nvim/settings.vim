set number
set cursorline
set wildmode=longest,list,full
set wildmenu

let g:secure_modelines_allowed_items = [
                \ "textwidth",   "tw",
                \ "softtabstop", "sts",
                \ "tabstop",     "ts",
                \ "shiftwidth",  "sw",
                \ "expandtab",   "et",   "noexpandtab", "noet",
                \ "filetype",    "ft",
                \ "foldmethod",  "fdm",
                \ "readonly",    "ro",   "noreadonly", "noro",
                \ "rightleft",   "rl",   "norightleft", "norl"
                \ ]

" turn off auto commenting
autocmd BufRead,BufNewFile * set formatoptions-=o

set mouse=a

" highlight search by default
set hlsearch

" Wrapping with gq
set textwidth=80

" Search
set incsearch
set ignorecase
set smartcase
set gdefault
" Go to match as they are found when typed
set incsearch

" Turn on syntax highlighting if it's supported
if has('syntax') && &t_Co > 2
    syntax on
endif

if has('autocmd')
    filetype plugin indent on

" Jump to the last known cursor position when editing a file.
    autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal g`\"" | endif

" Change the indent amount for css and javascript files
    au FileType css set shiftwidth=2
    au FileType js set shiftwidth=4
endif

" vi mode - yuck!
set nocompatible

" Copy indent from current line when starting a new line
set autoindent
" Automatically indent new lines after certain characters
set smartindent
" Expand tabs into spaces
set expandtab
" Handle expanded tab spaces
set smarttab
" Use a 4 space tab
set shiftwidth=4
" Number of spaces a <Tab> is displayed as
set tabstop=8

" Make backspace work 'normally' in Insert mode
set backspace=indent,eol,start

" Show incomplete commands
set showcmd
" Parse files for vim line
set modeline

set background=dark
" Increase the command-line height to avoid hit-enter prompts
set cmdheight=2
" Always show the status line
set laststatus=2
" Change the default status line format
set statusline=%<%f%(\ %h%m%r%)%a%=%b\ 0x%B\ \ %l,%c%V\ %P

" list mode
set list
set listchars=tab:>-,precedes:<,extends:>
" String to put at the start of lines that have been wrapped
"set showbreak=>
" Don't display text as wrapped
set nowrap

" vim won't set the title of the terminal window unless $DISPLAY and $WINDOWID
" are set.  If bash's $PROMPT_COMMAND is set, then the title can be safely
" set.
if &term =~ "rxvt.*" || &term =~ "xterm.*"
    if exists("$PROMPT_COMMAND")
        set title
        set t_ts=]0;
    endif
endif


" Netrw Settings:

" set tree view
let g:netrw_liststyle = 3

" remove info banner
let g:netrw_banner = 0

set noequalalways

" Remove line at the bottom of screen
set cmdheight=1
set noshowmode

" NORD STUFF
let g:lightline = {'colorscheme': 'nord'}
colorscheme nord

set encoding=UTF-8

let g:nord_uniform_diff_background = 1
let g:nord_italic = 1
let g:nord_italic_comments = 1
let g:nord_underline = 1

" Dont underline things in markdown
au FileType markdown setlocal nospell

" Editor settings
set scrolloff=2
set hidden
set nojoinspaces

" Use clipboard all the time
set clipboard+=unnamedplus

set ttyfast
set lazyredraw

let g:fzf_preview_window = 'right:50%'

" vimwiki settings
let g:vimwiki_list = [{"path":expand("$ZETTEL_HOME"), 'syntax': 'markdown',
                        \ 'ext': '.md', 'auto_tags': 1, 'auto_toc': 1}]

let g:vimwiki_use_mouse = 1
let g:vimwiki_auto_chdir = 1

" zettel-vim settings
let g:zettel_options = [{"front_matter" : {"tags" : ""},
                        \ "template": expand("$ZETTEL_HOME/../template.tpl")}]
let g:zettel_format = '%Y%m%d%H%M%S-%title'
let g:zettel_fzf_command = "fd --type f .md ."

let g:indentLine_char = '¦'

" Fix issue with vimwiki conceal
" https://github.com/Yggdroot/indentLine/issues/303
let g:indentLine_concealcursor=""
let g:indentLine_conceallevel=2

" Vista settings
let g:vista_icon_indent = ["▸ ", ""]
let g:vista#renderer#enable_icon = 0

" ----------------------
" Ranger config

" Make Ranger replace Netrw and be the file explorer
let g:rnvimr_enable_ex = 1
" Make Ranger to be hidden after picking a file
let g:rnvimr_enable_picker = 1
" Disable a border for floating window
let g:rnvimr_draw_border = 1
let g:rnvimr_presets = [{'width': 0.900, 'height': 0.800}]

au Bufnewfile,bufRead *.pm,*.t,*.pl set filetype=perl

" Github link
let g:gh_line_map_default = 0
let g:gh_line_blame_map_default = 0
" Copy to clipboard
let g:gh_open_command = 'fn() { echo "$@" | xclip -selection clipboard -rmlastnl; }; fn '

" enable vim-rainbow
let g:rainbow_active = 1 
