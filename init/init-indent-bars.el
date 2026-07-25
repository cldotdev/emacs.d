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
(add-hook 'yaml-mode-hook #'indent-bars-mode)
(add-hook 'markdown-mode-hook #'indent-bars-mode)

;; tree-sitter-hl-mode bypasses indent-bars' font-lock wrapper.
;; Re-setup indent-bars after tree-sitter-hl-mode so it wraps the
;; updated fontify function and draws bars after tree-sitter highlights.
(defun my/indent-bars-reset-after-tree-sitter ()
  "Re-setup indent-bars after tree-sitter-hl-mode activation."
  (when (bound-and-true-p indent-bars-mode)
    (indent-bars-reset)))

(with-eval-after-load 'tree-sitter-hl
  (add-hook 'tree-sitter-after-on-hook
            #'my/indent-bars-reset-after-tree-sitter
            'append))

(provide 'init-indent-bars)
