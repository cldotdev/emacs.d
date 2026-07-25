;;; -*- lexical-binding: t; -*-
;; Eglot is built into Emacs >= 29; just `require' it.
;;
;; Python is wired to pyright (managed by mise as `npm:pyright') for type
;; checking and ruff (~/.local/bin/ruff) for linting/formatting via
;; `ruff server'. Both binaries are expected on PATH at call time.

(require 'eglot)

;; Run pyright then ruff server in parallel; eglot will multiplex.
(add-to-list 'eglot-server-programs
             '((python-ts-mode python-mode)
               . ("pyright-langserver" "--stdio")))

(add-hook 'python-ts-mode-hook #'eglot-ensure)

(provide 'init-eglot)
