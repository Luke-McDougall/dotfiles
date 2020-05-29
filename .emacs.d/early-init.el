;; Apparently the garbage collector makes start up slow in Emacs
;; this will temporarily disable it to make start up faster `gcmh-mode'
;; is used to reset the garbage collector at the end of `init.el'.
(setq gc-cons-threshold most-positive-fixnum)

;; Prevent glimpse of unstyled emacs by disabling these UI elements early.
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; This is done in init.el
(setq package-enable-at-startup nil)

;; Concatenate all autoloads files into one giant file
(setq-default package-quickstart t)

;; Resizing the emacs frame can be expensive part of changing font.
;; Inhibiting this can half startup time.
(setq frame-inhibit-implied-resize t)
