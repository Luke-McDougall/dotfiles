;; Doom emacs, which I stole this from, has it in both early-init.el and init.el.
;; I don't know if that is a mistake or if it's necessary but putting it here too
;; doesn't seem to negatively effect start up time so I may as well just do it.
(setq gc-cons-threshold most-positive-fixnum)

;; Some more doom-emacs startup time optimizations

;; file-name-handler-alist is most likely not necessary during startup. Disable
;; it until after emacs starts.
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

(defun luke/jump-to-closing-paren ()
  "Moves point to be after the next closing paren in the buffer"
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

;; This function should only be called from visual mode i.e. use-region-p should
;; always be true.
(defun luke/eval-region-replace (beg end)
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

;; Function taken from here `https://gitlab.com/ambrevar/emacs-windower/-/blob/master/windower.el'
(defun luke/switch-to-last-buffer ()
  "Switch to last open buffer in current window"
  (interactive)
  (if (window-dedicated-p)
      (message "Window is dedicated to its buffer")
    (switch-to-buffer (other-buffer (current-buffer) 1))))

(defun luke/save-and-kill-buffer ()
  (interactive)
  (save-buffer)
  (kill-buffer)
)

(defun luke/kill-buffer-and-window ()
  "Kills buffer, also deletes window if there is more than one active."
  (interactive)
  (kill-buffer)
  (when (> (count-windows) 1)
    (delete-window)))

(defun luke/kill-all-buffers ()
  (interactive)
  (mapc 'kill-buffer (buffer-list)))

(defun luke/open-terminal-in-default-directory ()
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
  ;; Make wdired start in normal mode instead of insert mode
  (evil-set-initial-state 'wdired-mode 'normal)

  ;; Center point after any jumps
  (defun luke/center-line (&rest _)
    (evil-scroll-line-to-center nil))

  (advice-add 'evil-ex-search-next :after #'luke/center-line)
  (advice-add 'evil-jump-forward :after #'luke/center-line)
  (advice-add 'evil-jump-backward :after #'luke/center-line)

  ;; Get rid of search highlighting after 'j' is pressed
  (defun luke/nohighlight (&rest _)
    (evil-ex-nohighlight))

  (advice-add 'evil-next-line :after #'luke/nohighlight)
  
  ;; It annoys me that I have to switch to the rg buffer manually
  (defun luke/switch-to-window-rg (&rest _)
    (select-window (get-buffer-window "*rg*")))

  (advice-add 'rg :after #'luke/switch-to-window-rg)
  (advice-add 'luke/rg-search-file :after #'luke/switch-to-window-rg)
  (advice-add 'luke/rg-search-directory :after #'luke/switch-to-window-rg)

  (defun luke/config ()
    (interactive)
    (find-file "~/.emacs.d/init.el"))

  (defun luke/config-other-window ()
    (interactive)
    (find-file-other-window "~/.emacs.d/init.el"))

  (evil-ex-define-cmd "format" 'luke/format-rust)
  (evil-ex-define-cmd "build"  'luke/cargo-build)
  (evil-ex-define-cmd "test"   'luke/cargo-test)
  (evil-ex-define-cmd "run"    'luke/cargo-run)

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
	      ("SPC b i"   . ibuffer)
	      ("SPC b I"   . ibuffer-other-window)
	      ("SPC b e"   . eval-buffer)
	      ("SPC b q"   . kill-this-buffer)
	      ("SPC b k a" . luke/kill-all-buffers)
	      ("SPC b x"   . luke/save-and-kill-buffer)

              ;; Prefix-f for 'find' commands
	      ("SPC f r"   . luke/icomplete-find-recent-file)
	      ("SPC f R"   . luke/icomplete-find-recent-file-other-window)
	      ("SPC f o"   . find-file-other-window)
	      ("SPC f f"   . find-file)
	      ("SPC f l"   . find-library)
	      ("SPC f c"   . luke/config)
	      ("SPC f C"   . luke/config-other-window)
	      ("SPC f m"   . man)
	      ("SPC f p"   . luke/icomplete-open-pdf)
	      ("SPC f d"   . dired)
	      ("SPC f D"   . dired-other-window)

              ;; Prefix-p for project commands
	      ("SPC p f"   . luke/project-find-file)

              ;; Prefix-o for org commands
              ("SPC o t"   . org-todo-list)
              
              ;; Prefix-r for ripgrep or regex commands
              ("SPC r r"   . rg)
              ("SPC r p"   . rg-project)
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
              ("SPC d d"   . dired-jump)
              ("SPC d o"   . dired-jump-other-window)
              ("SPC d e"   . wdired-change-to-wdired-mode)
              ("SPC d w"   . wdired-finish-edit)

              ;; Prefix-s for 'shell' commands
              ;; Note check that any command added here is not duplicated in org
              ;; mode section. In org mode those bindings will intercept any here.
              ("SPC s a"   . async-shell-command)

              ;; Miscellaneous
	      ("SPC SPC"   . luke/switch-to-last-buffer)
	      ("SPC \r"    . luke/open-terminal-in-default-directory)
              ("<f5>"      . compile)
	      (";"         . evil-ex)
              ("SPC x"     . amx)

	      :map evil-insert-state-map
	      ("C-j"       . luke/jump-to-closing-paren)
	      ("C-k"       . evil-normal-state)

              :map evil-visual-state-map
	      (";"         . evil-ex)
	      ("H"         . evil-first-non-blank-of-visual-line)
	      ("L"         . evil-end-of-visual-line)
	      ("SPC e"     . luke/eval-region-replace)

              :map evil-motion-state-map
	      ("H"         . evil-first-non-blank-of-visual-line)
	      ("L"         . evil-end-of-visual-line)
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

(use-package man
  :config
  (defun man-mode-keybindings ()
    (define-key evil-normal-state-local-map (kbd "\r")    'man-follow)
    (define-key evil-normal-state-local-map (kbd "C-j")  'Man-next-section)
    (define-key evil-normal-state-local-map (kbd "C-k")  'Man-previous-section)
    (define-key evil-normal-state-local-map (kbd "\en")   'Man-next-manpage)
    (define-key evil-normal-state-local-map (kbd "\ep")   'Man-previous-manpage)
    (define-key evil-normal-state-local-map (kbd "g")     'beginning-of-buffer)
    (define-key evil-normal-state-local-map (kbd "r")     'Man-follow-manual-reference)
    (define-key evil-normal-state-local-map (kbd "SPC g") 'Man-goto-section)
    (define-key evil-normal-state-local-map (kbd "s")     'Man-goto-see-also-section)
    (define-key evil-normal-state-local-map (kbd "q")     'Man-kill)
    (define-key evil-normal-state-local-map (kbd "u")     'Man-update-manpage)
    (define-key evil-normal-state-local-map (kbd "m")     'man))

  :hook ((Man-mode . man-mode-keybindings))
  )

(use-package info
  :config
  (defun luke/info-mode-settings ()
    (define-key evil-normal-state-local-map (kbd "g")     'beginning-of-buffer)
    (define-key evil-normal-state-local-map (kbd "\C-m")  'Info-follow-nearest-node)
    (define-key evil-normal-state-local-map (kbd "\t")    'Info-next-reference)
    (define-key evil-normal-state-local-map (kbd "\e\t")  'Info-prev-reference)
    (define-key evil-normal-state-local-map (kbd "1")     'Info-nth-menu-item)
    (define-key evil-normal-state-local-map (kbd "2")     'Info-nth-menu-item)
    (define-key evil-normal-state-local-map (kbd "3")     'Info-nth-menu-item)
    (define-key evil-normal-state-local-map (kbd "4")     'Info-nth-menu-item)
    (define-key evil-normal-state-local-map (kbd "5")     'Info-nth-menu-item)
    (define-key evil-normal-state-local-map (kbd "6")     'Info-nth-menu-item)
    (define-key evil-normal-state-local-map (kbd "7")     'Info-nth-menu-item)
    (define-key evil-normal-state-local-map (kbd "8")     'Info-nth-menu-item)
    (define-key evil-normal-state-local-map (kbd "9")     'Info-nth-menu-item)
    (define-key evil-normal-state-local-map (kbd "0")     'undefined)
    (define-key evil-normal-state-local-map (kbd "?")     'Info-summary)
    (define-key evil-normal-state-local-map (kbd "]")     'Info-forward-node)
    (define-key evil-normal-state-local-map (kbd "[")     'Info-backward-node)
    (define-key evil-normal-state-local-map (kbd "<")     'Info-top-node)
    (define-key evil-normal-state-local-map (kbd ">")     'Info-final-node)
    (define-key evil-normal-state-local-map (kbd "d")     'Info-directory)
    (define-key evil-normal-state-local-map (kbd "G")     'end-of-buffer)
    (define-key evil-normal-state-local-map (kbd "f")     'Info-follow-reference)
    (define-key evil-normal-state-local-map (kbd "SPC g") 'Info-goto-node)
    (define-key evil-normal-state-local-map (kbd "SPC h") 'Info-help)

    (define-key evil-normal-state-local-map (kbd "SPC H") 'describe-mode)
    (define-key evil-normal-state-local-map (kbd "i")     'Info-index)
    (define-key evil-normal-state-local-map (kbd "I")     'Info-virtual-index)
    (define-key evil-normal-state-local-map (kbd "l")     'Info-history-back)
    (define-key evil-normal-state-local-map (kbd "L")     'Info-history)
    (define-key evil-normal-state-local-map (kbd "m")     'Info-menu)
    (define-key evil-normal-state-local-map (kbd "\C-n")  'Info-next)
    (define-key evil-normal-state-local-map (kbd "\C-p")  'Info-prev)
    (define-key evil-normal-state-local-map (kbd "q")     'quit-window)
    (define-key evil-normal-state-local-map (kbd "r")     'Info-history-forward)
    (define-key evil-normal-state-local-map (kbd "\M-n")  'clone-buffer)
    (define-key evil-normal-state-local-map (kbd "t")     'Info-top-node)
    (define-key evil-normal-state-local-map (kbd "T")     'Info-toc)
    (define-key evil-normal-state-local-map (kbd "u")     'Info-up)

    (define-key evil-normal-state-local-map (kbd ",")     'Info-index-next)
    (define-key evil-normal-state-local-map (kbd "\177")  'Info-scroll-down)
    )
  :bind (:map Info-mode-map
              ("n" . nil)
              ("N" . nil)
              ("b" . nil)
              ("B" . nil)
              ("w" . nil)
              ("e" . nil)
              )
  :hook (Info-mode . luke/info-mode-settings)
  )

(use-package info-colors
  :ensure t
  :hook (Info-selection . info-colors-fontify-node))

(use-package help-mode
  :config
  (defun luke/help-mode-settings ()
    (define-key evil-normal-state-local-map (kbd "q") 'luke/kill-buffer-and-window))
  :hook (help-mode . luke/help-mode-settings)
  )

(use-package vc
  :config
  (setq vc-follow-symlinks t))

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
                    ((eq evil-state 'operator) "OPERATOR")
                    ((eq evil-state 'replace) "REPLACE")
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
                  "%c | %I"
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
    ;; Keybindings
    (define-key evil-insert-state-local-map (kbd "M-l")     'org-metaright)
    (define-key evil-insert-state-local-map (kbd "M-h")     'org-metaleft)
    (define-key evil-normal-state-local-map (kbd "SPC s i") 'org-insert-structure-template)
    (define-key evil-normal-state-local-map (kbd "SPC s e") 'org-edit-special)
    (define-key evil-normal-state-local-map (kbd "C-u")     'outline-up-heading)
    (define-key evil-normal-state-local-map (kbd "C-j")     'org-next-visible-heading)
    (define-key evil-normal-state-local-map (kbd "C-k")     'org-previous-visible-heading)
    (define-key evil-normal-state-local-map (kbd "SPC s w") 'flyspell-auto-correct-word)
    (define-key xah-math-input-keymap (kbd "S-SPC") nil)
    (define-key xah-math-input-keymap (kbd "<f1>") 'xah-math-input-change-to-symbol)

    ;; Other settings
    (xah-math-input-mode 1)
    (auto-fill-mode 1)
    (flyspell-mode 1))

  (defun org-src-buffer-map ()
    (define-key evil-normal-state-local-map (kbd "SPC s e") 'org-edit-src-exit)
    )

  :hook ((org-mode     . org-buffer-map)
         (org-src-mode . org-src-buffer-map))
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
  :config
  (defun dired-buffer-map ()
    "Setup bindings for dired buffer."
    (define-key evil-normal-state-local-map (kbd "<backspace>") 'dired-up-directory)
    (define-key evil-normal-state-local-map "q" 'kill-this-buffer)
    (define-key evil-normal-state-local-map "y" 'dired-do-copy)
    (define-key evil-normal-state-local-map "r" 'dired-do-rename)
    (define-key evil-normal-state-local-map "v" 'dired-do-kill-lines)
    (define-key evil-normal-state-local-map "R" 'revert-buffer)
    (define-key evil-normal-state-local-map "i" 'dired-maybe-insert-subdir)
    (define-key evil-normal-state-local-map "\C-j" 'dired-next-subdir)
    (define-key evil-normal-state-local-map "\C-k" 'dired-prev-subdir)
    (define-key evil-normal-state-local-map (kbd "\r") 'dired-find-file)
    (define-key evil-normal-state-local-map (kbd "M-\r") 'dired-find-file-other-window))


  (setq dired-recursive-copies 'always)
  (setq dired-recursive-deletes 'always)
  (setq dired-delete-by-moving-to-trash t)
  (setq dired-listing-switches "-AFlv --group-directories-first")
  (setq dired-dwim-target t)

  :bind (:map dired-mode-map
              ;; Keys I don't want to be intercept by dired-mode-map
              ("SPC" . nil)
              ("g"   . nil)
              ("G"   . nil)
              ("n"   . nil)
              ("N"   . nil))

  :hook ((dired-mode . dired-hide-details-mode)
	 (dired-mode . dired-buffer-map))
)

(use-package wdired
  :after dired
  :config
  (setq wdired-allow-to-change-permissions t)
  (setq wdired-create-parent-directories t))

(use-package dired-x)

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

  (defun luke/case-indent-settings ()
    "My preferred settings for case statement indenting"
    (c-set-offset 'substatement-open 0)
    (c-set-offset 'case-label '+)
    (c-set-offset 'inline-open 0)
    (c-set-offset 'statement-case-intro 0))

  (defun luke/java-settings ()
    "Set case indent settings and turn on subword mode for java files"
    (luke/case-indent-settings)
    (subword-mode 1))

  :hook ((java-mode . luke/java-settings)
         (c-mode    . luke/case-indent-settings))
  )

(use-package gdb-mi
  :init
  (setq gdb-many-windows t))

(use-package rust-mode
  :ensure t
  :config
  (defun luke/format-rust ()
    (interactive)
    (shell-command (concat  "~/.cargo/bin/rustfmt " buffer-file-name)))

  (defun luke/cargo-build ()
    (interactive)
    (compile "~/.cargo/bin/cargo build"))

  (defun luke/cargo-test ()
    (interactive)
    (compile "~/.cargo/bin/cargo test"))

  (defun luke/cargo-run ()
    (interactive)
    (shell-command "~/.cargo/bin/cargo run"))
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

  (defun describe-symbol-at-point ()
    (interactive)
    (let ((symbol (symbol-at-point)))
      (when symbol
        (describe-symbol symbol))))

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

(use-package icomplete-vertical
  :ensure t)

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

  (defun luke/icomplete-open-pdf ()
    "Open a pdf file present in ~/PDF with mupdf"
    (interactive)
    (let* ((file-list (directory-files-recursively "~/PDF" "" nil))
           (files (mapcar 'file-name-nondirectory file-list))
           (file (completing-read "Open PDF: " files)))
      (when file
        (start-process-shell-command "*pdf*" nil (concat "mupdf ~/PDF/" file))))
    )

  (defun luke/icomplete-find-recent-file ()
    (interactive)
    (let ((file
           (icomplete-vertical-do ()
             (completing-read "Choose recent file: "
                              (mapcar 'abbreviate-file-name recentf-list) nil t))))
      (when file
        (find-file file)))
    )

  (defun luke/icomplete-find-recent-file-other-window ()
    (interactive)
    (let ((file
           (icomplete-vertical-do ()
             (completing-read "Choose recent file: "
                              (mapcar 'abbreviate-file-name recentf-list) nil t))))
      (when file
        (find-file-other-window file)))
    )

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

(use-package pdf-tools
  :init
  (pdf-loader-install)
  :config
  (defun luke/pdf-view-mode-hook ()
    ;; Keybindings
    (define-key evil-normal-state-local-map "j"             'pdf-view-next-line-or-next-page)
    (define-key evil-normal-state-local-map "k"             'pdf-view-previous-line-or-previous-page)
    (define-key evil-normal-state-local-map "g"             'pdf-view-first-page)
    (define-key evil-normal-state-local-map "G"             'pdf-view-last-page)
    (define-key evil-normal-state-local-map (kbd "C-j")     'pdf-view-next-page-command)
    (define-key evil-normal-state-local-map (kbd "C-k")     'pdf-view-previous-page-command)
    (define-key evil-normal-state-local-map (kbd "SPC g l") 'pdf-view-goto-label)
    (define-key evil-normal-state-local-map (kbd "\r")      'pdf-links-action-perform)
    (define-key evil-normal-state-local-map (kbd "-")       'pdf-view-shrink)
    (define-key evil-normal-state-local-map (kbd "+")       'pdf-view-enlarge)
    (define-key evil-normal-state-local-map (kbd "0")       'pdf-view-scale-reset)
    ;; I think just using pdf-occur is better than isearch in general but I might come back to this
    ;; (define-key evil-normal-state-local-map (kbd "/")       'isearch-forward)
    ;; (define-key evil-normal-state-local-map (kbd "n")       'isearch-repeat-forward)
    ;; (define-key evil-normal-state-local-map (kbd "N")       'isearch-repeat-backward)
    (define-key evil-normal-state-local-map (kbd "SPC o")   'pdf-occur)

    ;; Other settings
    (set (make-local-variable 'evil-normal-state-cursor) (list nil))) ; Get rid of cursor

  :hook (pdf-view-mode . luke/pdf-view-mode-hook)
  )

(use-package pdf-occur
  :after pdf-tools
  :config
  (defun luke/pdf-occur-buffer-map ()
    (define-key evil-normal-state-local-map (kbd "\r") 'pdf-occur-goto-occurrence)
    (define-key evil-normal-state-local-map (kbd "o")  'pdf-occur-view-occurrence)
    )
  :hook (pdf-occur-buffer-mode . luke/pdf-occur-buffer-map)
  )

(use-package project
  :after (minibuffer icomplete icomplete-vertical)
  :config
  (defun luke/project-find-file ()
    "I probably would've written something like this"
    (interactive)
    (icomplete-vertical-do ()
      (project-find-file)))
  )

(use-package savehist
  :config
  (setq savehist-file "~/.emacs.d/savehist")
  (setq history-length 30000)
  (setq history-delete-duplicates nil)
  (setq savehist-save-minibuffer-history t)
  (savehist-mode 1))

(use-package amx
  :ensure t
  :init
  (setq amx-ignored-command-matchers nil)
  (setq amx-show-key-bindings nil)
  (amx-mode 1))


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
  :hook (after-init . modus-vivendi)
  )

(use-package xah-math-input
  :ensure t)

(use-package display-line-numbers
  :config
  (defcustom display-line-numbers-exempt-modes '(pdf-view-mode)
    "Major modes on which to disable line number mode, exempts them from global requirement"
    :group 'display-line-numbers
    :type  'list
    :version "green")

  (defun display-line-numbers--turn-on ()
    "Turn on line numbers but exempting certain major modes defined in `display-line-numbers-exempt-modes'"
    (if (and
         (not (member major-mode display-line-numbers-exempt-modes))
         (not (minibufferp)))
        (display-line-numbers-mode)))

  (global-display-line-numbers-mode)
  (setq-default display-line-numbers-type 'relative))

(add-hook 'after-init-hook 'global-hl-line-mode)
(add-hook 'after-init-hook
          (lambda ()
            (blink-cursor-mode 0)))
(electric-pair-mode 1)
(setq-default show-paren-delay 0)
(show-paren-mode 1)

(add-to-list 'default-frame-alist '(fullscreen . maximized))
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))

(add-to-list 'default-frame-alist '(font . "Hack-11"))
(setq inhibit-startup-screen t)
(setq scroll-conservatively 100)
(defalias 'yes-or-no-p 'y-or-n-p)

;; Turn the garbage collector back on
(add-to-list 'load-path "~/.emacs.d/gcmh")
(require 'gcmh)
(gcmh-mode 1)
