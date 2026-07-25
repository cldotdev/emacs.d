;;; -*- lexical-binding: t; -*-
(add-to-list 'load-path "~/.emacs.d/package/popup-el")
(add-to-list 'load-path "~/.emacs.d/package/dumb-jump")
(require 'dumb-jump)

(add-hook 'xref-backend-functions #'dumb-jump-xref-activate)

(provide 'init-dumb-jump)
