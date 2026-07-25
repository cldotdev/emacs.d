;;; -*- lexical-binding: t; -*-
;; file extension: *.jinja2 and *.html
(require 'jinja2-mode)
(add-hook  'jinja2-mode-hook
           (lambda ()
             (when (require 'auto-complete nil t) ; no error whatever auto-complete.el is not installed.
               (auto-complete-mode t))))
(setq auto-mode-alist
            (append '(("\\.html" . jinja2-mode)) auto-mode-alist))

(provide 'init-jinja2-mode)
