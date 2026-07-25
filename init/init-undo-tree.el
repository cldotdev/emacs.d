;;; -*- lexical-binding: t; -*-
(add-to-list 'load-path "~/.emacs.d/package/queue")

;; Undo with C-_ and redo with M-_. Watch the undo-tree with C-x u
(require 'queue)
(require 'undo-tree)
(global-undo-tree-mode t)

;; Store all undo-tree history files in a single directory
(setq undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo")))

;; Disable automatic on-disk history files for undo-tree
(with-eval-after-load 'undo-tree
  (setq undo-tree-auto-save-history nil))

(provide 'init-undo-tree)
