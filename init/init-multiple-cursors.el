;;; -*- lexical-binding: t; -*-
(add-to-list 'load-path "~/.emacs.d/package/multiple-cursors-1.2.0")

(global-set-key (kbd "C-c :") 'mc/edit-lines)
(global-set-key (kbd "C-c >") 'mc/mark-next-like-this)
(global-set-key (kbd "C-c <") 'mc/mark-previous-like-this)
(global-set-key (kbd "C-c ;") 'mc/mark-all-like-this-dwim)

(provide 'init-multiple-cursors)
