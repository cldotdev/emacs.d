(add-to-list 'load-path "~/.emacs.d/package/imenu-list")
(require 'imenu-list)

(global-set-key (kbd "C-c i") #'imenu-list-smart-toggle)
(setq imenu-list-idle-update-delay-time 0)
(setq imenu-list-auto-resize t)

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

;; Pin imenu-list to the window that was active when it was opened.
;; Prevents imenu-list from following window switches.

(defvar my/imenu-list--pinned-window nil
  "Window pinned to the imenu-list sidebar.
When non-nil, imenu-list tracks this window's buffer and point
regardless of which window is currently selected.")

(defun my/imenu-list-smart-toggle--pin (orig-fn)
  "Around advice: set pin when opening imenu-list, clear when closing."
  (if (get-buffer-window imenu-list-buffer-name t)
      (progn
        (setq my/imenu-list--pinned-window nil)
        (funcall orig-fn))
    (setq my/imenu-list--pinned-window (selected-window))
    (funcall orig-fn)))

(advice-add 'imenu-list-smart-toggle
            :around #'my/imenu-list-smart-toggle--pin)

(defun my/imenu-list-update--pin (orig-fn &optional force-update)
  "Around advice: redirect imenu-list-update to the pinned window."
  (cond
   ((and my/imenu-list--pinned-window
         (window-live-p my/imenu-list--pinned-window))
    (with-selected-window my/imenu-list--pinned-window
      (funcall orig-fn force-update)))
   (my/imenu-list--pinned-window
    (setq my/imenu-list--pinned-window nil)
    (imenu-list-minor-mode -1))
   (t
    (funcall orig-fn force-update))))

(advice-add 'imenu-list-update
            :around #'my/imenu-list-update--pin)

(defun my/imenu-list--on-pinned-buffer-kill ()
  "Clean up imenu-list when the pinned window's buffer is killed."
  (when (and my/imenu-list--pinned-window
             (window-live-p my/imenu-list--pinned-window)
             (eq (current-buffer) (window-buffer my/imenu-list--pinned-window)))
    (setq my/imenu-list--pinned-window nil)
    (imenu-list-minor-mode -1)))

(add-hook 'kill-buffer-hook #'my/imenu-list--on-pinned-buffer-kill)

;; Optional: RET jumps to entry and closes the imenu-list window.

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

;; Push marker before imenu-list jump so xref-go-back (M-,) returns to
;; the previous position.

(defun my/imenu-list-push-marker (&rest _)
  "Save position in the displayed buffer before imenu-list jumps."
  (when (buffer-live-p imenu-list--displayed-buffer)
    (with-current-buffer imenu-list--displayed-buffer
      (xref-push-marker-stack))))

(advice-add 'imenu-list--goto-entry :before #'my/imenu-list-push-marker)

(provide 'init-imenu)
