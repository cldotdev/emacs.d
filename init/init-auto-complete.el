;;; -*- lexical-binding: t; -*-
(add-to-list 'load-path "~/.emacs.d/package/auto-complete")
(add-to-list 'load-path "~/.emacs.d/package/popup-el")

(require 'auto-complete)
(require 'auto-complete-config)
(ac-config-default)

;; Disable ac-source-abbrev to fix: Error running timer ‘ac-update-greedy’: (wrong-type-argument sequencep #<obarray n=1>)
;; https://github.com/auto-complete/auto-complete/issues/533
(setq-default ac-sources
              '(ac-source-filename
                ;; ac-source-abbrev
                ac-source-dictionary
                ac-source-words-in-same-mode-buffers))

(setq ac-auto-start nil)
(setq ac-ignore-case nil)
(ac-set-trigger-key "TAB")
(global-auto-complete-mode t)
(define-key ac-completing-map (kbd "<up>") nil)
(define-key ac-completing-map (kbd "<down>") nil)
(define-key ac-completing-map (kbd "RET") nil)
(define-key ac-completing-map (kbd "<return>") nil)

;; ac/yas color
(defface ac-yasnippet-candidate-face
  '((t (:background "sandybrown" :foreground "black")))
  "Face for yasnippet candidate.")

(defface ac-yasnippet-selection-face
  '((t (:background "coral3" :foreground "white")))
  "Face for the yasnippet selected candidate.")

(defvar ac-source-yasnippet
  '((candidates . ac-yasnippet-candidate)
    (action . yas/expand)
    (candidate-face . ac-yasnippet-candidate-face)
    (selection-face . ac-yasnippet-selection-face))
  "Source for Yasnippet.")

(provide 'init-auto-complete)
