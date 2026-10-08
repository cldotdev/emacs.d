;;; -*- lexical-binding: t; -*-
;; c-ts-mode's `linux' style turns on tabs but, unlike cc-mode's, leaves
;; the offset at 2, so the 8-column indentation is set here.
(custom-set-variables
 '(c-ts-mode-indent-style 'linux)
 '(c-ts-indent-offset 8))
(add-hook 'c-ts-base-mode-hook (lambda () (setq-local tab-width 8)))

(setq comment-style 'extra-line)

(provide 'init-c-mode)
