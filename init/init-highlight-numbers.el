;;; -*- lexical-binding: t; -*-
(add-to-list 'load-path "~/.emacs.d/package/parent-mode")
(add-to-list 'load-path "~/.emacs.d/package/highlight-numbers")

(require 'highlight-numbers)

(add-hook 'prog-mode-hook 'highlight-numbers-mode)


(provide 'init-highlight-numbers)
