;;; -*- lexical-binding: t; -*-
(add-to-list 'load-path "~/.emacs.d/package/rust-mode")
(autoload 'rust-mode "rust-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-mode))

(require 'flycheck-rust)
(with-eval-after-load 'rust-mode
  (add-hook 'flycheck-mode-hook #'flycheck-rust-setup))

(setq rust-mode-treesitter-derive t)

(provide 'init-rust-mode)
