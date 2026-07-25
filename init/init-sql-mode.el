;;; -*- lexical-binding: t; -*-
;; https://github.com/sql-formatter-org/sql-formatter
(add-to-list 'load-path "~/.emacs.d/package/emacs-reformatter")
(add-to-list 'load-path "~/.emacs.d/package/sqlformat")

(require 'sqlformat)

(setq sqlformat-command 'sql-formatter)
(setq sqlformat-args '("--config" "{ \"language\": \"postgresql\", \
\"logicalOperatorNewline\": \"after\", \"keywordCase\": \"upper\", \
\"dataTypeCase\": \"upper\", \"functionCase\": \"lower\" }"))

(add-hook 'sql-mode-hook
          (lambda ()
            (define-key sql-mode-map (kbd "C-c C-f") 'sqlformat-buffer)))

(provide 'init-sql-mode)
