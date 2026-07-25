;;; -*- lexical-binding: t; -*-
(setq c-default-style "linux")
(setq comment-style 'extra-line)
(add-hook 'c-mode-hook
          '(lambda ()
             (setq ac-sources (delq 'ac-source-yasnippet ac-sources))
             (flymake-mode t)))

(provide 'init-c-mode)
