;;; -*- lexical-binding: t; -*-
(add-to-list 'auto-mode-alist '("\\.[mc]?js\\'" . js-ts-mode))
(add-to-list 'auto-mode-alist '("\\.ts\\'"      . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.[jt]sx\\'"  . tsx-ts-mode))

(setq js-indent-level 2)
(setq typescript-ts-mode-indent-offset 2)

(provide 'init-js-ts)
