;;; -*- lexical-binding: t; -*-
(add-hook 'makefile-mode-hook
          '(lambda ()
             (setq tab-width 8)))

(provide 'init-makefile-mode)
