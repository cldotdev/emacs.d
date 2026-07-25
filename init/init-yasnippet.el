;;; -*- lexical-binding: t; -*-
(add-to-list 'load-path "~/.emacs.d/package/yasnippet")

;; yas/trigger-key "C-c C-i"
(require 'yasnippet)
(yas/global-mode 1)
(yas/minor-mode-on)
(setq yas/prompt-functions
      '(yas/dropdown-prompt
        yas/x-prompt
        yas/completing-prompt
        yas/ido-prompt
        yas/no-prompt))


;; Set another trigger key
(define-key yas-minor-mode-map (kbd "M-TAB")  'yas-expand)
(define-key yas-minor-mode-map [(tab)] nil)
(define-key yas-minor-mode-map (kbd "TAB") nil)
(define-key yas-minor-mode-map (kbd "<tab>") nil)

(provide 'init-yasnippet)
