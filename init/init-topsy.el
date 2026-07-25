;;; -*- lexical-binding: t; -*-
(add-to-list 'load-path "~/.emacs.d/package/topsy.el")
(require 'topsy)

(add-hook 'prog-mode-hook #'topsy-mode)
;; (add-hook 'magit-section-mode-hook #'topsy-mode)

(provide 'init-topsy)
