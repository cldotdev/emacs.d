(require 'json-reformat)
(require 'json-snatcher)

(setq json-reformat:indent-width 2)
(setq json-reformat:pretty-string? t)

(add-to-list 'auto-mode-alist '("\\.json\\'" . json-ts-mode))

(add-hook 'json-ts-mode-hook
          (lambda ()
            (setq indent-tabs-mode nil)
            (setq tab-width 2)
            (setq json-ts-mode-indent-offset 2)))

(provide 'init-json-mode)
