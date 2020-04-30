" Fresh start
syntax on
set relativenumber

set tabstop=4
set shiftwidth=4

set expandtab
set autoindent
set smartindent

set incsearch
set ignorecase
set smartcase

set encoding=utf-8


" Keys
:let mapleader = "\<Space>"
:nnoremap ; :
:nnoremap : ;
:nmap zk zt
:nmap zj zb
:inoremap ( ()<left>
:inoremap [ []<left>
:inoremap " ""<left>
:inoremap {} {}<left>
:inoremap {<CR> {}<left><CR><Esc>O
:nmap <Leader>wv <C-w>v
:nmap <Leader>ws <C-w>s
:nmap <Leader>wh <C-w>h
:nmap <Leader>wj <C-w>j
:nmap <Leader>wl <C-w>l
:nmap <Leader>wk <C-w>k
:nmap <Leader>wo <C-w>o
