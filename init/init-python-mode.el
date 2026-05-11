(add-to-list 'auto-mode-alist '("\\.py\\'" . python-ts-mode))

(add-hook 'python-ts-mode-hook
          (lambda ()
            (setq indent-tabs-mode nil)
            (setq tab-width 4)
            (setq python-indent-offset 4)))

(provide 'init-python-mode)
