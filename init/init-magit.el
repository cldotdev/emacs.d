(add-to-list 'load-path "~/.emacs.d/package/compat")
(add-to-list 'load-path "~/.emacs.d/package/llama")
(add-to-list 'load-path "~/.emacs.d/package/with-editor/lisp")
(add-to-list 'load-path "~/.emacs.d/package/dash.el")
(add-to-list 'load-path "~/.emacs.d/package/magit/lisp")
(add-to-list 'load-path "~/.emacs.d/package/magit-popup")
(add-to-list 'load-path "~/.emacs.d/package/ghub/lisp")
(add-to-list 'load-path "~/.emacs.d/package/transient/lisp")
(add-to-list 'load-path "~/.emacs.d/package/libegit2")
(add-to-list 'load-path "~/.emacs.d/package/graphql.el")
(add-to-list 'load-path "~/.emacs.d/package/treepy.el")

(add-to-list 'load-path "~/.emacs.d/package/yaml.el")
(add-to-list 'load-path "~/.emacs.d/package/emacsql")
(add-to-list 'load-path "~/.emacs.d/package/closql")
(add-to-list 'load-path "~/.emacs.d/package/forge/lisp")
(add-to-list 'load-path "~/.emacs.d/package/cond-let")

(require 'magit)

;; Suppress "same file" warnings when opening files through symlinks
;; This prevents the message "X and Y are the same file" when visiting
;; files in magit that are accessed through symlinks.
(setq find-file-suppress-same-file-warnings t)

;; Keep the regular region overlay when the region is a valid Magit
;; selection (sibling sections or a hunk-internal region).  By default
;; Magit hides the overlay there, which leaves multi-line selections
;; with no visible highlight when copying text.  Section commands still
;; act on whole lines or sections, not on the exact region.
(setq magit-section-keep-region-overlay t)

;; With the region overlay kept above, Magit's own selection styling is
;; redundant: do not recolor the headings of selected sections, and do
;; not embolden the selected hunk lines nor dim the rest of the hunk.
(setq magit-section-highlight-selection nil)
(setq magit-diff-highlight-hunk-region-functions nil)

;; Custom function to follow symlinks when calling magit-status
(defun my/magit-status-follow-symlink ()
  "Call magit-status, following symlinks to their real path.
When visiting a file through a symlink, this ensures magit-status
opens the repository of the real file location instead of the
symlink location."
  (interactive)
  (let* ((file-name (buffer-file-name))
         (real-file (when file-name (file-truename file-name)))
         (default-directory
           (if real-file
               (file-name-directory real-file)
             default-directory)))
    (call-interactively #'magit-status)))

(global-set-key (kbd "C-x g") 'my/magit-status-follow-symlink)

;; Make magit-status always open in current window.
;; https://github.com/magit/magit/issues/2541#issuecomment-195420321
(setq magit-display-buffer-function
      (lambda (buffer)
        (display-buffer
         buffer
         (cond ((and (derived-mode-p 'magit-mode)
                     (eq (with-current-buffer buffer major-mode)
                         'magit-status-mode))
                nil)
               ((memq (with-current-buffer buffer major-mode)
                      '(magit-process-mode
                        magit-revision-mode
                        magit-diff-mode
                        magit-stash-mode))
                nil)
               (t
                '(display-buffer-same-window))))))

(defun my/git-commit-fill-paragraph (&optional justify)
  "Fill paragraph in git commit buffer with proper list item handling.
Treats list items like markdown-mode: first line and indented continuations separately."
  (interactive)
  (save-excursion
    (let ((orig-point (point))
          start end)
      (beginning-of-line)
      (cond
       ;; Case 1: We're on a list marker line (-, *, or +)
       ((looking-at "^[ \t]*[-*+][ \t]+")
        (let ((marker-indent (current-indentation))
              (marker-length (length (match-string 0))))
          (setq start (point))
          ;; Find the end of the first paragraph (before indented continuation or next list item)
          (forward-line 1)
          (while (and (not (eobp))
                      (not (looking-at "^[ \t]*[-*+][ \t]+"))  ; Not another list item
                      (not (looking-at "^[ \t]+[^ \t\n]"))     ; Not an indented line
                      (not (looking-at "^[ \t]*$")))            ; Not a blank line
            (forward-line 1))
          (setq end (point))
          ;; Fill with proper indentation for continuation lines
          (let ((fill-prefix (make-string (+ marker-indent marker-length) ?\s)))
            (fill-region start end justify nil))))

       ;; Case 2: We're on an indented continuation line within a list item
       ((and (looking-at "^[ \t]+[^ \t\n]")
             (save-excursion
               ;; Check if there's a list marker above
               (let ((found-marker nil))
                 (while (and (not (bobp))
                             (not found-marker))
                   (forward-line -1)
                   (when (looking-at "^[ \t]*[-*+][ \t]+")
                     (setq found-marker t)))
                 found-marker)))
        ;; Find the extent of indented continuation lines
        (let ((base-indent (current-indentation)))
          ;; Start from current line (don't search backwards)
          (setq start (point))

          ;; Find end of indented block with same or greater indentation
          (while (and (not (eobp))
                      (looking-at "^[ \t]+[^ \t\n]")
                      (>= (current-indentation) base-indent))
            (forward-line 1))
          (setq end (point))

          ;; Fill the indented region with proper hanging indent
          (let ((fill-prefix (make-string base-indent ?\s)))
            (fill-region start end justify nil))))

       ;; Case 3: Not in a list, use default fill
       (t
        (fill-paragraph justify t))))))

;; Advice log-edit-fill-entry to use our custom fill logic for list items
(defun my/git-commit-fill-entry-advice (orig-fun &rest args)
  "Advice for log-edit-fill-entry to handle list items properly."
  (if (save-excursion
        (beginning-of-line)
        (or (looking-at "^[ \t]*[-*+][ \t]+")    ; On a list marker line
            (and (looking-at "^[ \t]+[^ \t\n]")  ; On an indented line
                 (let ((found-marker nil))
                   (save-excursion
                     (while (and (not (bobp)) (not found-marker))
                       (forward-line -1)
                       (when (looking-at "^[ \t]*[-*+][ \t]+")
                         (setq found-marker t))))
                   found-marker))))
      ;; We're in a list item, use our custom fill function
      (my/git-commit-fill-paragraph)
    ;; Not in a list item, use the original function
    (apply orig-fun args)))

(advice-add 'log-edit-fill-entry :around #'my/git-commit-fill-entry-advice)

(defun my/git-commit-reformat-revert--reformat-subject (original-subject)
  "Return the reformatted subject for a revert commit.
ORIGINAL-SUBJECT is the text quoted inside the Git revert message.
Returns \"revert(scope): desc\" or \"revert: desc\"."
  (if (string-match "^[a-z]+\\(?:(\\([^)]+\\))\\)?: \\(.+\\)$" original-subject)
      (if (match-string 1 original-subject)
          (format "revert(%s): %s"
                  (match-string 1 original-subject)
                  (match-string 2 original-subject))
        (format "revert: %s" (match-string 2 original-subject)))
    (format "revert: %s" original-subject)))

(defun my/git-commit-reformat-revert ()
  "Reformat a Git revert commit message to Conventional Commits style.
Transforms the subject line and body hash line, then moves point to the
end of the subject line.  Does nothing when the buffer does not start
with a Git revert subject."
  (save-match-data
    (goto-char (point-min))
    (when (looking-at "^Revert \"\\(.+\\)\"$")
      (let* ((original-subject (match-string 1))
             (new-subject (my/git-commit-reformat-revert--reformat-subject
                           original-subject)))
        (delete-region (point) (line-end-position))
        (insert new-subject)
        (when (re-search-forward
               "^This reverts commit \\([0-9a-f]+\\)\\.$" nil t)
          (replace-match (format "Refs: %s" (substring (match-string 1) 0 7))))
        (goto-char (point-min))
        (end-of-line)))))

;; 50/72 formatting for Git commit message
(add-hook 'git-commit-setup-hook
          (lambda()
            (setq git-commit-summary-max-length 72)
            (auto-fill-mode t)
            (setq fill-column 72)))

(add-hook 'git-commit-setup-hook #'my/git-commit-reformat-revert)

(setq magit-section-visibility-indicator nil)

;; https://www.reddit.com/r/emacs/comments/bdsfb7/comment/el0lowt/?utm_source=share&utm_medium=web2x&context=3
;; https://emacs.stackexchange.com/a/52040
;; https://irreal.org/blog/?p=8877
(setq magit-section-initial-visibility-alist
      '((unpushed . show)
        (untracked .show)))

(setq transient-default-level 7)

(with-eval-after-load 'magit
  (require 'forge))

;; Fix for visiting renamed files without content changes
;; https://github.com/magit/magit/issues/2446
;; When a file is renamed without content changes, magit-diff-visit-file
;; fails because there's no hunk section to determine position.
;; Also fixes "Not inside Git repository" error when visiting files from
;; symlinked paths.
(defun magit-diff-visit-file--handle-no-hunk (orig-fun &rest args)
  "Advice for magit-diff-visit-file--noselect to handle files without hunks.
This fixes the 'Wrong type argument: number-or-marker-p, nil' error when
visiting renamed files that have no content changes, and also handles
'Not inside Git repository' error when working with symlinked paths."
  (let ((toplevel (magit-toplevel)))  ; Capture toplevel in correct context
    (condition-case err
        (apply orig-fun args)
      ((wrong-type-argument magit-outside-git-repo)
       ;; If we get wrong-type-argument error (no hunk) or
       ;; magit-outside-git-repo error (symlink path issue),
       ;; fall back to visiting the worktree file at the beginning.
       (let* ((file-section (magit-diff--file-section))
              (file (oref file-section value))
              (full-path (expand-file-name file toplevel)))  ; Use captured toplevel
         (list (find-file-noselect full-path) nil))))))

(advice-add 'magit-diff-visit-file--noselect
            :around #'magit-diff-visit-file--handle-no-hunk)

;; Fix for "Not inside Git repository" error when visiting files
;; This ensures magit-status buffer always has correct default-directory
(defun magit-status--ensure-correct-default-directory (&rest _args)
  "Ensure magit-status buffer has correct default-directory.
This fixes issues where magit-status is called from a buffer whose
default-directory is not inside a git repository, causing subsequent
operations like visiting files to fail with 'Not inside Git repository' error."
  (when-let ((toplevel (magit-toplevel)))
    (setq-local default-directory toplevel)))

(advice-add 'magit-status-setup-buffer :after
            #'magit-status--ensure-correct-default-directory)

(provide 'init-magit)
