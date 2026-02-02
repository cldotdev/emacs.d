(add-to-list 'load-path "~/.emacs.d/package/imenu-list")
(require 'imenu-list)

(global-set-key (kbd "C-c i") #'imenu-list-smart-toggle)
(setq imenu-list-idle-update-delay-time 0)

;; Use a ">" marker instead of hl-line to indicate the current entry.
;; The marker is only shown when imenu-list is not the active window.
(with-eval-after-load 'hl-line
  (setq hl-line-global-modes '(not imenu-list-major-mode)))

(defun my/imenu-list--clear-markers ()
  "Restore all > markers in the imenu-list buffer back to spaces."
  (let ((inhibit-read-only t))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^\\( *\\)> " nil t)
        (replace-match "\\1  ")))))

(defun my/imenu-list--show-current-entry (&rest _)
  "Indicate the current entry with > adjacent to the entry name."
  (let ((ilist-win (get-buffer-window (imenu-list-get-buffer-create))))
    (when ilist-win
      (let ((active-win (selected-window))
            (line-number (cl-position (imenu-list--current-entry)
                                      imenu-list--line-entries
                                      :test 'equal)))
        (when line-number
          (with-selected-window ilist-win
            (my/imenu-list--clear-markers)
            (when (not (eq active-win ilist-win))
              (goto-char (point-min))
              (forward-line line-number)
              (let* ((bol (line-beginning-position))
                     (inhibit-read-only t)
                     (text-start (save-excursion
                                   (goto-char bol)
                                   (skip-chars-forward " ")
                                   (point))))
                (when (>= (- text-start bol) 2)
                  (save-excursion
                    (goto-char (- text-start 2))
                    (delete-char 2)
                    (insert "> ")))))))))))

(advice-add 'imenu-list--show-current-entry
            :override #'my/imenu-list--show-current-entry)

(defvar my/imenu-list-ret-dwim-and-quit nil
  "When non-nil, RET in imenu-list jumps to entry and closes the window.
For subalist entries, toggle folding instead.")

(with-eval-after-load 'imenu-list
  (defun my/imenu-list-ret-dwim-and-quit ()
    "Jump to entry at point and close the imenu-list window.
For subalist entries, toggle folding instead."
    (interactive)
    (let ((entry (imenu-list--find-entry)))
      (if (imenu--subalist-p entry)
          (hs-toggle-hiding)
        (imenu-list--goto-entry entry)
        (imenu-list-minor-mode -1))))
  (when my/imenu-list-ret-dwim-and-quit
    (define-key imenu-list-major-mode-map (kbd "RET") #'my/imenu-list-ret-dwim-and-quit)))

(provide 'init-imenu)
