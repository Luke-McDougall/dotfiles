" Fresh start
" Plugins
call plug#begin('~/.vim/plugged')
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'chriskempson/base16-vim'
Plug 'tpope/vim-commentary'
Plug 'Raimondi/delimitMate'
Plug 'dense-analysis/ale'
call plug#end()

" Colourscheme
let base16colorspace=256
colorscheme base16-atelier-dune

" Normal defaults
set number relativenumber

set tabstop=4
set shiftwidth=4
set expandtab
set backspace=2
let delimitMate_expand_cr = 1

set autoindent
set smartindent

set incsearch
set ignorecase
set smartcase

set wildmenu

set encoding=utf-8

" Keybindings
:let mapleader = "\<Space>"
:nmap zk zt
:nmap zj zb
:nnoremap ; :
:inoremap <C-j> <Esc>/[)}"'\]>]<CR>:nohl<CR>a
:nmap <Leader>wv <C-w>v
:nmap <Leader>ws <C-w>s
:nmap <Leader>wh <C-w>h
:nmap <Leader>wj <C-w>j
:nmap <Leader>wl <C-w>l
:nmap <Leader>wk <C-w>k
:nmap <Leader>ww <C-w>o
:nmap <Leader>bl :Lines<CR>
:nmap <Leader>bs :Buffers<CR>
:nmap <Leader>bq :bd<CR>
:nmap <Leader>l :BLines<CR>
:nmap gd :ALEGoToDefinition<CR>
