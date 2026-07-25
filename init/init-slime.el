;;; -*- lexical-binding: t; -*-
(add-to-list 'load-path "~/.emacs.d/package/slime")
(require 'slime-autoloads)

(setq inferior-lisp-program "clisp")
(setq slime-contribs '(slime-fancy))

(provide 'init-slime)
