let mapleader = "\<Space>"
syntax on
set tabstop=4
set softtabstop=4
set expandtab
set smarttab
set autoindent
set smartindent
set number relativenumber
set wildmenu
set nocompatible
set splitright
set splitbelow
set scrolloff=2
set guioptions-=T
set backspace=2 " Backspace over newlines
set lazyredraw
filetype plugin on
nnoremap <Leader>p :setlocal spell! spelllang=en_au<CR>
set shiftwidth=4
" Convenient code completion-esque stuff.
:inoremap ( ()<Esc>i
:inoremap " ""<Esc>i
:inoremap [ []<Esc>i
:inoremap <C-j> <Esc>/[)}"'\]>]<CR>:nohl<CR>a
:inoremap {<CR> {<CR><BS>}<Esc>ko
:inoremap {} {}<Esc>i
:inoremap {; {};<Esc>hi<CR><Esc>O
" Sane move to end/start of line keys
map H ^
map L $
" Normal mode enter
nnoremap <CR> i<CR><Esc>
" Disable arrow keys
nnoremap <up> <nop>
nnoremap <down> <nop>
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>
" A genius came up with this, you never use semicolon in normal mode
nnoremap ; :
" Left and right can switch buffers
nnoremap <left> :bp<CR>
nnoremap <right> :bn<CR>
" Center search result
nnoremap n nzz
" Make capital Y do what you'd think it would do
nnoremap Y y$
" Vertical movement in long lines should work correctly now
nnoremap j gj
nnoremap k gk
" Jump between blank lines for faster vertical movement
nnoremap <C-j> }
nnoremap <C-k> {
" Better split navigation keys
nnoremap <leader>h <C-w>h
nnoremap <leader>l <C-w>l
nnoremap <leader>j <C-w>j
nnoremap <leader>k <C-w>k
" <leader>s search and replace shortcut
nnoremap <leader>s :%s/
" Jump to definition in vertical split
map <A-]> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>
" Set rustc as compiler
set makeprg=rustc
" Set commands for next and previous error functions
nnoremap <C-c> :cnext<CR>
nnoremap <C-x> :cprevious<CR>
" Compile current rust file with rustc and display any errors in quickfix
" window
nnoremap <F6> :make<CR>
" Test current rust project to see if it will build using cargo
nnoremap <F7> :!cargo test<CR>
" Build and run current rust project using cargo
nnoremap <C-F7> :!cargo run<CR>
" Ctags thing button 
nnoremap <F8> :TagbarToggle<CR>
" Vertical split shortcut to open current file in both windows.
nnoremap <Leader>v :vsp %<CR>
" Quick save and quick savequit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :wq<CR>
nnoremap <leader>o :Files<CR>
