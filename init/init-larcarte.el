;;; -*- lexical-binding: t; -*-
(add-to-list 'load-path "~/.emacs.d/package/lacarte")
(require 'lacarte)
(global-set-key [?\e ?\M-x] 'lacarte-execute-command)
(global-set-key [?\M-`] 'lacarte-execute-command)

(provide 'init-larcarte)
