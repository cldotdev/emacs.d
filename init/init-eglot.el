;;; -*- lexical-binding: t; -*-
;; Eglot is built into Emacs >= 29; just `require' it.
;;
;; Ruff is not an Eglot server here: Flycheck's `python-ruff' checker
;; runs it.

(require 'eglot)

(add-to-list 'eglot-server-programs
             '((python-ts-mode python-mode)
               . ("pyright-langserver" "--stdio")))

(add-hook 'python-ts-mode-hook #'eglot-ensure)

(provide 'init-eglot)
