(add-to-list 'major-mode-remap-alist '(css-mode . css-ts-mode))

;; indentation: 2 spaces (css-indent-offset applies to css-ts-mode too)
(setq-default css-indent-offset 2)

(provide 'init-css-mode)
