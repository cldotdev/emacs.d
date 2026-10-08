;;; -*- lexical-binding: t; -*-
;; Its :set function, which a plain `setq' would skip, adds the built-in
;; remap of each ts-mode listed here to `major-mode-remap-alist' and deletes
;; the remaps of the rest, so this list is the one place a built-in ts-mode
;; is switched on.
(custom-set-variables
 '(treesit-enabled-modes
   '(bash-ts-mode
     c++-ts-mode
     c-or-c++-ts-mode
     c-ts-mode
     css-ts-mode
     dockerfile-ts-mode
     go-ts-mode
     js-ts-mode
     json-ts-mode
     php-ts-mode
     python-ts-mode
     ruby-ts-mode
     toml-ts-mode
     tsx-ts-mode
     typescript-ts-mode
     yaml-ts-mode)))

(provide 'init-treesit)
