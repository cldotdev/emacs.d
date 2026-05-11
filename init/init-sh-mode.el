(setq-default sh-basic-offset 2)
(setq-default sh-indentation 2)
(setq bash-ts-mode-indent-offset 2)

(add-to-list 'auto-mode-alist '("\\.sh\\'"   . bash-ts-mode))
(add-to-list 'auto-mode-alist '("\\.bash\\'" . bash-ts-mode))
(add-to-list 'auto-mode-alist '("\\.bats\\'" . bash-ts-mode))
(add-to-list 'auto-mode-alist
             '("\\.?\\(bashrc\\|bash_profile\\|profile\\|env\\(\\..*\\)?\\)\\'"
               . bash-ts-mode))

(add-to-list 'major-mode-remap-alist '(sh-mode . bash-ts-mode))

(provide 'init-sh-mode)
