;;; -*- lexical-binding: t; -*-
(add-to-list 'load-path "~/.emacs.d/package/imenu-list")
(require 'imenu-list)

(global-set-key (kbd "C-c i") #'imenu-list-smart-toggle)
(setq imenu-list-idle-update-delay-time 0)
(setq imenu-list-auto-resize t)
(setq imenu-max-item-length nil)

(provide 'init-imenu)
