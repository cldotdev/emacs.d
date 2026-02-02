(add-to-list 'load-path "~/.emacs.d/package/imenu-list")
(require 'imenu-list)

(global-set-key (kbd "C-c i") #'imenu-list-smart-toggle)
(setq imenu-list-idle-update-delay-time 0)

;; (with-eval-after-load 'imenu-list
;;   (defun my/imenu-list-ret-dwim-and-quit ()
;;     "Jump to entry at point and close the imenu-list window.
;; For subalist entries, toggle folding instead."
;;     (interactive)
;;     (let ((entry (imenu-list--find-entry)))
;;       (if (imenu--subalist-p entry)
;;           (hs-toggle-hiding)
;;         (imenu-list--goto-entry entry)
;;         (imenu-list-minor-mode -1))))
;;   (define-key imenu-list-major-mode-map (kbd "RET") #'my/imenu-list-ret-dwim-and-quit))

(provide 'init-imenu)
