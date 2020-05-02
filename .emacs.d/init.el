;; Doom emacs, which I stole this from, has it in both early-init.el and
;; init.el. I don't know if that is a mistake or if it's necessary but
;; putting it here too doesn't seem to negatively effect start up time
;; so I may as well just do it.
(setq gc-cons-threshold most-positive-fixnum)

;; Some more doom-emacs startup time optimizations

;; Concatenate all autoloads files into one giant file
(setq-default package-quickstart t)

;; file-name-handler-alist is most likely not necessary during startup.
;; Disable it until after emacs starts.
(defvar luke/file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist luke/file-name-handler-alist)))

(setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3")

(require 'package)
(setq package-archives '(("ELPA"  . "http://tromey.com/elpa/")
			 ("gnu"   . "http://elpa.gnu.org/packages/")
			 ("melpa" . "https://melpa.org/packages/")
			 ("org"   . "https://orgmode.org/elpa/")))

(unless (bound-and-true-p package--initialized)
  (setq pacakge-enable-at-startup nil)
  (package-initialize))

;; Make sure use package is installed
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))

(use-package cus-edit
  :config
  (setq custom-file "~/.emacs.d/custom.el")

  (unless (file-exists-p custom-file)
    (write-region "" nil custom-file))

  (load custom-file))

(defun jump-to-closing-paren ()
  "Pretty self explanatory dude."
  (interactive)
  (while (not (or (eq ?\) (char-after))
		  (eq ?\] (char-after))
		  (eq ?}  (char-after))
		  (eq ?>  (char-after))
		  (eq ?'  (char-after))
		  (eq ?\" (char-after))))
    (forward-char 1)
  )
  (forward-char 1)
)

;; This function should only be called from visual mode
;; i.e. use-region-p should always be true.
(defun eval-region-replace (beg end)
  (interactive
       (list (region-beginning) (region-end)))
  (save-excursion
    (setq result (eval (read (buffer-substring-no-properties beg end)))))
  (kill-region beg end)
  (setq result-text
        (cond
         ((stringp result) result)
         ((numberp result) (number-to-string result))
         ("Error: Expression must evaluate to a string or a number")))
  (insert result-text)
)

(defun save-and-kill-buffer ()
  "Pretty self explanatory dude."
  (interactive)
  (save-buffer)
  (kill-buffer)
)

(defun kill-all-buffers ()
  "It kills all the buffers."
  (interactive)
  (mapc 'kill-buffer (buffer-list)))

(defun open-terminal-in-default-directory ()
  "Opens a terminal (alacritty) in the default-directory of the current buffer."
  (interactive)
  (start-process "*terminal*" nil "alacritty" "--working-directory" default-directory)
)

(use-package autorevert
  :config
  (setq auto-revert-verbose t)
  :hook (after-init . global-auto-revert-mode))

;; Evil-mode
(use-package evil
  :ensure t
  :init (setq evil-vsplit-window-right t
              evil-split-window-below t
              evil-want-Y-yank-to-eol t
              evil-search-module 'evil-search
              evil-emacs-state-modes '(org-agenda-mode)
              evil-motion-state-modes 
              '(apropos-mode
                Buffer-menu-mode
                calendar-mode
                color-theme-mode
                command-history-mode
                compilation-mode
                dictionary-mode
                ert-results-mode
                speedbar-mode
                undo-tree-visualizer-mode
                woman-mode))

  :config 
  ;; Center point after any jumps
  (defun my-center-line (&rest _)
    (evil-scroll-line-to-center nil))

  (advice-add 'evil-ex-search-next :after #'my-center-line)
  (advice-add 'evil-jump-forward :after #'my-center-line)
  (advice-add 'evil-jump-backward :after #'my-center-line)

  ;; Get rid of search highlighting after 'j' is pressed
  (defun luke/nohighlight (&rest _)
    (evil-ex-nohighlight))

  (advice-add 'evil-next-line :after #'luke/nohighlight)
  
  ;; It annoys me that I have to switch to the rg buffer manually
  (defun switch-to-window-rg (&rest _)
    (select-window (get-buffer-window "*rg*")))

  (advice-add 'rg :after #'switch-to-window-rg)
  (advice-add 'luke/rg-search-file :after #'switch-to-window-rg)
  (advice-add 'luke/rg-search-directory :after #'switch-to-window-rg)
  (defun luke/config ()
    (interactive)
    (find-file "~/.emacs.d/init.el"))

  (defun luke/config-other-window ()
    (interactive)
    (find-file-other-window "~/.emacs.d/init.el"))

  (evil-ex-define-cmd "config" 'luke/config)
  (evil-ex-define-cmd "format" 'luke/format-rust)

  (evil-mode 1)
  :bind (:map evil-normal-state-map
              ;; Movement commands
	      ("H"         . evil-first-non-blank-of-visual-line)
	      ("L"         . evil-end-of-visual-line)
              ("zk"        . evil-scroll-line-to-top)
              ("zj"        . evil-scroll-line-to-bottom)
	      ("C-j"       . evil-scroll-down)
	      ("C-k"       . evil-scroll-up)

              ;; Prefix-w for 'window' commands
	      ("SPC w h"   . evil-window-left)
	      ("SPC w l"   . evil-window-right)
	      ("SPC w k"   . evil-window-up)
	      ("SPC w j"   . evil-window-down)
	      ("SPC w v"   . evil-window-vsplit)
	      ("SPC w s"   . evil-window-split)
	      ("SPC w q"   . delete-window)
	      ("SPC w w"   . delete-other-windows)

              ;; Prefix-b for 'buffer' commands
	      ("SPC b s"   . switch-to-buffer)
	      ("SPC b o"   . switch-to-buffer-other-window)
	      ("SPC b i"   . ibuffer-other-window)
	      ("SPC b e"   . eval-buffer)
	      ("SPC b q"   . kill-this-buffer)
	      ("SPC b k a" . kill-all-buffers)
	      ("SPC b x"   . save-and-kill-buffer)

              ;; Prefix-f for 'find' commands
	      ("SPC f r"   . luke/icomplete-find-recent-file)
	      ("SPC f o"   . find-file-other-window)
	      ("SPC f f"   . find-file)
	      ("SPC f l"   . find-library)
	      ("SPC f c"   . luke/config)
	      ("SPC f C"   . luke/config-other-window)
	      ("SPC f m"   . man)
	      ("SPC f p"   . luke/icomplete-open-pdf)

              ;; Prefix-o for org commands
              ("SPC o t"   . org-todo-list)
              
              ;; Prefix-r for ripgrep or regex commands
              ("SPC r r"   . rg)
              ("SPC r f"   . luke/rg-search-file)
              ("SPC r d"   . luke/rg-search-directory)

              ;; Prefix-h for 'help' commands
              ("SPC h"     . describe-symbol-at-point)

              ;; Prefix-e for 'error' commands
              ("SPC e n"   . next-error)
	      ("SPC e p"   . previous-error)

              ;; Prefix-j for 'jump' commands
              ("SPC j n"   . evil-jump-forward)
              ("SPC j p"   . evil-jump-backward)

              ;; Prefix-d for 'dired' commands
              ("SPC d d"   . luke/dired-cwd)
              ("SPC d o"   . dired-other-window)
              ("SPC D"     . dired)

              ;; Prefix-s for 'shell' commands
              ("SPC s a"   . async-shell-command)

              ;; Miscellaneous
	      ("SPC SPC"   . find-file)
	      ("SPC \r"    . open-terminal-in-default-directory)
              ("<f5>"      . compile)
	      (";"         . evil-ex)

	      :map evil-insert-state-map
	      ("C-j"       . jump-to-closing-paren)
	      ("C-k"       . evil-normal-state)

              :map evil-visual-state-map
	      ("H"         . evil-first-non-blank-of-visual-line)
	      ("L"         . evil-end-of-visual-line)
	      ("SPC e"     . eval-region-replace)
          )
)

(use-package evil-commentary
  :ensure t
  :config
  (evil-commentary-mode))

(use-package evil-snipe
  :ensure t
  :config
  (evil-snipe-mode +1))

(use-package window
  :init
  (setq display-buffer-alist
        '(("\\*Ibuffer*"
           (display-buffer-in-side-window)
           (window-height . 0.2)
           (side . bottom)
           (slot . 0))))
  :bind (("<f8>" . window-toggle-side-windows))
)

(use-package man
  :config
  (defun man-mode-keybindings ()
    (define-key evil-normal-state-local-map (kbd "\r")  'man-follow)
    (define-key evil-normal-state-local-map (kbd "p")   'Man-next-section)
    (define-key evil-normal-state-local-map (kbd "o")   'Man-previous-section)
    (define-key evil-normal-state-local-map (kbd "\en") 'Man-next-manpage)
    (define-key evil-normal-state-local-map (kbd "\ep") 'Man-previous-manpage)
    (define-key evil-normal-state-local-map (kbd ".")   'beginning-of-buffer)
    (define-key evil-normal-state-local-map (kbd "r")   'Man-follow-manual-reference)
    (define-key evil-normal-state-local-map (kbd "g")   'Man-goto-section)
    (define-key evil-normal-state-local-map (kbd "s")   'Man-goto-see-also-section)
    (define-key evil-normal-state-local-map (kbd "q")   'Man-kill)
    (define-key evil-normal-state-local-map (kbd "u")   'Man-update-manpage)
    (define-key evil-normal-state-local-map (kbd "m")   'man))

  :hook ((Man-mode . man-mode-keybindings))
  )

(use-package vc
  :config
  (setq vc-follow-symlinks t)
  :bind (:map evil-normal-state-map
              ("SPC v p" . vc-push)
              )
  )

(use-package emacs
  :config
  (setq mode-line-percent-position nil)
  (setq-default mode-line-format
                '(
                  "%e"
                  mode-line-front-space
                  " ["
                  (:eval
                   (cond
                    ((eq evil-state 'motion) "MOTION")
                    ((eq evil-state 'emacs)  "EMACS")
                    ((eq evil-state 'normal) "NORMAL")
                    ((eq evil-state 'visual) "VISUAL")
                    ((eq evil-state 'insert) "INSERT")))
                  "] ["
                  (:eval
                   (cond
                    (buffer-read-only "%b | RO")
                    ((buffer-modified-p) "%b | +")
                    ("%b")))
                  "] "
                  buffer-file-truename
                  "  "
                  mode-name
                  "  "
                  "%I"
                  ;;display-time-string
                  mode-line-end-spaces))
)

(use-package time
  :disabled
  :config
  (setq display-time-format "%a %e %b <%H:%M>")
  (setq display-time-interval 60)
  (setq display-time-mail-directory nil)
  (setq display-time-default-load-average nil)
  :hook ((after-init . display-time-mode)))

(use-package org
  :config
  (defun org-buffer-map ()
    (define-key evil-insert-state-local-map (kbd "M-l")     'org-metaright)
    (define-key evil-insert-state-local-map (kbd "M-h")     'org-metaleft)
    (define-key evil-insert-state-local-map (kbd "M-s")     'org-insert-structure-template)
    (define-key evil-normal-state-local-map (kbd "C-u")     'outline-up-heading)
    (define-key evil-normal-state-local-map (kbd "C-j")     'org-next-visible-heading)
    (define-key evil-normal-state-local-map (kbd "C-k")     'org-previous-visible-heading)
    (define-key evil-normal-state-local-map (kbd "SPC s w") 'flyspell-auto-correct-word)
    (define-key xah-math-input-keymap (kbd "S-SPC") nil)
    (define-key xah-math-input-keymap (kbd "<f1>") 'xah-math-input-change-to-symbol)
    (xah-math-input-mode 1)
    (auto-fill-mode 1)
    (flyspell-mode 1))

  :hook ((org-mode . org-buffer-map))
)

(use-package org-agenda
  :init
  (setq-default org-agenda-files '("~/org_agenda"))
  (setq-default org-agenda-window-setup 'only-window)
  (setq-default org-agenda-restore-windows-after-quit t)

  ;; I've just swapped 'n' and 'p' for 'j' and 'k'.
  :bind (:map org-agenda-mode-map
              ("j" . org-agenda-next-line)
              ("n" . org-agenda-goto-date)
              ("k" . org-agenda-previous-line)
              ("p" . org-agenda-capture))
  )

(use-package which-key
  :ensure t
  :init (which-key-mode))

(use-package ibuffer
  :config
  (setq ibuffer-expert t)
  (setq ibuffer-use-header-line t)

  (defun ibuffer-buffer-map ()
    (local-unset-key (kbd "SPC"))
    (define-key evil-normal-state-local-map (kbd "J") 'ibuffer-jump-to-buffer)
    (define-key evil-normal-state-local-map (kbd "j") 'ibuffer-forward-line)
    (define-key evil-normal-state-local-map (kbd "k") 'ibuffer-backward-line)
    (define-key evil-normal-state-local-map (kbd "q") 'kill-this-buffer)
  )

  :hook ((ibuffer . ibuffer-buffer-map))
)

(use-package rg
  :ensure t
  :config
  (rg-define-search luke/rg-search-directory
    :query ask
    :format regexp
    :files current
    :dir current)

  (rg-define-search luke/rg-search-file
    :query ask
    :format regexp
    :files (file-name-nondirectory (buffer-file-name))
    :dir current)

  (setq rg-group-result t))

(use-package dired
  :init
  (defun luke/dired-cwd ()
    (interactive)
    (dired default-directory))

  :config
  (defun dired-buffer-map ()
    "Setup bindings for dired buffer."
    (define-key evil-normal-state-local-map (kbd "<backspace>") 'dired-up-directory)
    (define-key evil-normal-state-local-map "q" 'kill-this-buffer)
    (define-key evil-normal-state-local-map "y" 'dired-do-copy)
    (define-key evil-normal-state-local-map "r" 'dired-do-rename)
    (define-key evil-normal-state-local-map (kbd "\r") 'dired-find-file))


  (setq dired-recursive-copies 'always)
  (setq dired-recursive-deletes 'always)
  (setq dired-delete-by-moving-to-trash t)
  (setq dired-listing-switches "-AFlv --group-directories-first")
  (setq dired-dwim-target t)

  :bind (:map dired-mode-map
              ("SPC" . nil)  ; Don't intercept leader key
              ("n"   . nil)  ; Evil mode next/previous match keys
              ("N"   . nil))

  :hook ((dired-mode . dired-hide-details-mode)
	 (dired-mode . dired-buffer-map))
)

(use-package async
  :ensure t)

(use-package dired-async
  :after (dired async)
  :hook (dired-mode . dired-async-mode))

;; C mode
(setq-default indent-tabs-mode nil)

(use-package cc-mode
  :config
  (setq-default c-basic-offset 4)
  (setq-default c-default-style "k&r")

  (defun java-custom-indent-settings ()
    "My preferred settings for indentation of java code."
    (c-set-offset 'substatement-open 0)
    (c-set-offset 'case-label '+)
    (c-set-offset 'inline-open 0)
    (c-set-offset 'statement-case-intro 0))

  :hook ((java-mode . java-custom-indent-settings))
  )

(use-package rust-mode
  :ensure t
  :config
  (defun luke/format-rust ()
    (interactive)
    (shell-command (concat  "~/.cargo/bin/rustfmt " buffer-file-name)))
  )

;; Recentf
(use-package recentf
  :init
  (setq recentf-max-menu-items 10)
  (setq recentf-max-saved-items 25)
  (setq recentf-exclude '(".+autoloads\.el"
                          "ido\.last"
                          ".*/TAGS"))
  :config
  (recentf-mode 1)
)

(use-package minibuffer
  :config
  (setq completion-cycle-threshold 3)
  (setq completion-flex-nospace nil)
  (setq completion-ignore-case t)
  (setq completion-pcm-complete-word-inserts-delimiters t)
  (setq completion-pcm-word-delimiters "-_./:| ")
  (setq completion-show-help nil)
  (setq completion-styles '(flex))
  (setq completions-format 'vertical)
  (setq enable-recursive-minibuffers t)
  (setq read-answer-short t)
  (setq read-buffer-completion-ignore-case t)
  (setq read-file-name-completion-ignore-case t)
  (setq resize-mini-windows t)

  (file-name-shadow-mode 1)
  (minibuffer-depth-indicate-mode 1)
  (minibuffer-electric-default-mode 1)

  (defun focus-minibuffer ()
    "Focus the active minibuffer"
    (interactive)
    (let ((mini (active-minibuffer-window)))
      (when mini
        (select-window mini))))

  (defun describe-symbol-at-point (&optional arg)
    "Get help (documentation) for the symbol at point.
With a prefix argument, switch to the \\*Help\\* window. If that
is already focused, switch to the most recently used window
instead"
    (interactive "P")
    (let ((symbol (symbol-at-point)))
      (when symbol
        (describe-symbol symbol)))
    (when current-prefix-arg
      (let ((help (get-buffer-window "*Help*")))
        (when help
          (if (not (eq (selected-window) help))
              (select-window help)
            (select-window (get-mru-window)))))))

  (defun completion-list-buffer-bindings ()
    (define-key evil-normal-state-local-map (kbd "H")        'describe-symbol-at-point)
    (define-key evil-normal-state-local-map (kbd "j")        'next-line)
    (define-key evil-normal-state-local-map (kbd "k")        'previous-line)
    (define-key evil-normal-state-local-map (kbd "h")        'previous-completion)
    (define-key evil-normal-state-local-map (kbd "l")        'next-completion)
    (define-key evil-normal-state-local-map (kbd "<return>") 'choose-completion))

  :bind (:map completion-list-mode-map
              ("M-v" . focus-minibuffer))
  :hook (completion-list-mode . completion-list-buffer-bindings))

(use-package icomplete
  :demand
  :after minibuffer
  :config
  (setq icomplete-delay-completions-threshold 0)
  (setq icomplete-max-delay-chars 0)
  (setq icomplete-compute-delay 0)
  (setq icomplete-show-matches-on-no-input t)
  (setq icomplete-hide-common-prefix nil)
  (setq icomplete-prospects-height 1)
  (setq icomplete-separator " · ")           ; mid dot, not full stop
  (setq icomplete-with-completion-tables t)
  (setq icomplete-in-buffer t)

  (fido-mode -1)
  (icomplete-mode 1)

  (add-to-list 'load-path "~/.emacs.d/icomplete-vertical")
  (require 'icomplete-vertical)

  (defun luke/icomplete-open-pdf ()
    "Open a pdf file present in ~/PDF with mupdf"
    (interactive)
    (icomplete-vertical-toggle)
    (let* ((file-list (directory-files-recursively "~/PDF" "" nil))
           (files (mapcar 'file-name-nondirectory file-list))
           (file (completing-read "Open PDF: " files)))
      (when file
        (start-process-shell-command "*pdf*" nil (concat "mupdf ~/PDF/" file))))
    (icomplete-vertical-toggle)
    )

  (defun luke/icomplete-find-recent-file ()
    (interactive)
    (let ((file
           (completing-read "Choose recent file: "
                                (mapcar 'abbreviate-file-name recentf-list) nil t)))
      (when file
	(find-file file))))

  (defun luke/icomplete-set-basic ()
    "Change to basic completion for current icomplete minibuffer"
    (interactive)
    (setq-local completion-styles '(basic)))

  :bind (:map icomplete-minibuffer-map
              ("<right>"     . icomplete-forward-completions)
              ("<left>"      . icomplete-backward-completions)
              ("C-f"         . luke/icomplete-set-basic)
              ("C-SPC"       . icomplete-vertical-toggle)
              ("<backspace>" . icomplete-fido-backward-updir)
              ("<tab>"       . icomplete-forward-completions)
              ("<M-return>"  . icomplete-force-complete-and-exit)
              ("<return>"    . icomplete-fido-ret))
  )

(use-package savehist
  :config
  (setq savehist-file "~/.emacs.d/savehist")
  (setq history-length 30000)
  (setq history-delete-duplicates nil)
  (setq savehist-save-minibuffer-history t)
  (savehist-mode 1))

;; Paren zone
(electric-pair-mode 1)
(setq-default show-paren-delay 0)
(show-paren-mode 1)

(use-package emacs
  :config
  (use-package modus-vivendi-theme
    :ensure t)

  (use-package modus-operandi-theme
    :ensure t)

  (defun modus-themes-toggle ()
    (interactive)
    (if (eq (car custom-enabled-themes) 'modus-operandi)
        (modus-vivendi)
      (modus-operandi)))

  (defun modus-vivendi ()
    (setq modus-vivendi-theme-slanted-constructs t
          modus-vivendi-theme-bold-constructs t
          modus-vivendi-theme-proportional-fonts nil
          modus-vivendi-theme-scale-headings t
          modus-vivendi-theme-scale-1 1.05
          modus-vivendi-theme-scale-2 1.1
          modus-vivendi-theme-scale-3 1.15
          modus-vivendi-theme-scale-4 1.2)
    (load-theme 'modus-vivendi t))

  (defun modus-operandi ()
    (setq modus-operandi-theme-slanted-constructs t
          modus-operandi-theme-bold-constructs t
          modus-operandi-theme-proportional-fonts nil
          modus-operandi-theme-scale-headings t
          modus-operandi-theme-scale-1 1.05
          modus-operandi-theme-scale-2 1.1
          modus-operandi-theme-scale-3 1.15
          modus-operandi-theme-scale-4 1.2)
    (load-theme 'modus-operandi t))

  :bind (("<f3>" . modus-themes-toggle))
  :hook (after-init . modus-operandi)
  )

(use-package xah-math-input
  :ensure t)

(add-hook 'after-init-hook 'global-hl-line-mode)
(add-to-list 'default-frame-alist '(fullscreen . maximized))
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))

;; Clean Screen
(add-to-list 'default-frame-alist '(font . "DejaVu Sans Mono-11"))
(setq inhibit-startup-screen t)
(setq scroll-conservatively 100)
(global-display-line-numbers-mode t)
(setq-default display-line-numbers-type 'relative)

;; Turn the garbage collector back on
(add-to-list 'load-path "~/.emacs.d/gcmh")
(require 'gcmh)
(gcmh-mode 1)
