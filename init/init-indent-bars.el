;;; -*- lexical-binding: t; -*-
(add-to-list 'load-path "~/.emacs.d/package/indent-bars")

(require 'indent-bars)

;; Minimal layout
;; https://github.com/jdtsmith/indent-bars/blob/main/examples.md#minimal
(setq
 indent-bars-color '(highlight :face-bg t :blend 0)
 indent-bars-pattern "."
 indent-bars-width-frac 0.1
 indent-bars-pad-frac 0.1
 indent-bars-zigzag nil
 indent-bars-color-by-depth nil
 indent-bars-highlight-current-depth nil
 indent-bars-display-on-blank-lines nil)

(add-hook 'prog-mode-hook #'indent-bars-mode)
(add-hook 'yaml-ts-mode-hook #'indent-bars-mode)
(add-hook 'markdown-mode-hook #'indent-bars-mode)

(provide 'init-indent-bars)
