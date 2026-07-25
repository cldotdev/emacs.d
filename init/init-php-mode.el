;;; -*- lexical-binding: t; -*-
(add-to-list 'load-path "~/.emacs.d/package/php-mode/lisp")

(require 'php-mode)
(add-hook 'php-mode-hook
          (lambda ()
            (subword-mode 1)))

(provide 'init-php-mode)
