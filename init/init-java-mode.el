(add-to-list 'major-mode-remap-alist '(java-mode . java-ts-mode))

(add-hook 'java-ts-mode-hook
          (lambda ()
            (flymake-mode t)
            (setq java-ts-mode-indent-offset 4)))

(provide 'init-java-mode)
