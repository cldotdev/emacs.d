;;; -*- lexical-binding: t; -*-
(add-to-list 'load-path "~/.emacs.d/package/osx-clipboard-mode")
(require 'osx-clipboard)

(osx-clipboard-mode +1)

(provide 'init-osx-clipboard-mode)
