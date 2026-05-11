;; Modern JS/TS via Emacs 30 built-in treesit.
;; Grammars at ~/.emacs.d/tree-sitter/libtree-sitter-{javascript,typescript,tsx}.so
;; Rebuild a grammar with: M-x treesit-install-language-grammar

(add-to-list 'treesit-extra-load-path
             (expand-file-name "tree-sitter/" user-emacs-directory))

(setq treesit-language-source-alist
      '((javascript "https://github.com/tree-sitter/tree-sitter-javascript" "v0.23.1")
        (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "v0.23.2" "typescript/src")
        (tsx        "https://github.com/tree-sitter/tree-sitter-typescript" "v0.23.2" "tsx/src")))

(add-to-list 'auto-mode-alist '("\\.[mc]?js\\'" . js-ts-mode))
(add-to-list 'auto-mode-alist '("\\.ts\\'"      . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.[jt]sx\\'"  . tsx-ts-mode))

(setq js-indent-level 2)
(setq typescript-ts-mode-indent-offset 2)

(provide 'init-js-ts)
