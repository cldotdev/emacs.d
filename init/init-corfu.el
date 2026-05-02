;;; init-corfu.el --- Corfu completion configuration -*- lexical-binding: t -*-

;;; Commentary:

;; In terminal Emacs the popup is rendered with popon (via
;; corfu-terminal) instead of a child frame, which avoids the
;; line-number / wide-CJK display artifacts caused by company-mode's
;; pseudo-tooltip overlay.

;;; Code:

(add-to-list 'load-path "~/.emacs.d/package/compat")
(add-to-list 'load-path "~/.emacs.d/package/corfu")
(add-to-list 'load-path "~/.emacs.d/package/corfu/extensions")
(add-to-list 'load-path "~/.emacs.d/package/cape")
(add-to-list 'load-path "~/.emacs.d/package/popon")
(add-to-list 'load-path "~/.emacs.d/package/corfu-terminal")

(require 'corfu)
(require 'corfu-auto)
(require 'cape)
(require 'cape-keyword)
(require 'dabbrev)
(require 'project)
(require 'seq)

(declare-function corfu-terminal-mode "corfu-terminal" (&optional arg))

(setq corfu-auto t
      corfu-auto-delay 0
      corfu-auto-prefix 1
      corfu-count 10
      corfu-min-width 30
      corfu-max-width 60
      corfu-bar-width 0
      corfu-cycle t
      corfu-quit-no-match 'separator
      corfu-preselect 'first)

;; Cap candidate list to `corfu-count' so cycling never exposes entries
;; beyond the visible window, and force prefix matching for non-file
;; categories so completion-at-point ignores the global orderless config.
(defun init-corfu--compute-advice (orig-fun input table pred)
  (let* ((before (substring (car input) 0 (cdr input)))
         (file-p (eq (completion-metadata-get
                      (completion-metadata before table pred) 'category)
                     'file))
         (completion-styles (if file-p completion-styles '(basic)))
         (state (funcall orig-fun input table pred))
         (cell (assq 'corfu--candidates state))
         (tail (and cell (nthcdr (1- corfu-count) (cdr cell)))))
    (when (and tail (cdr tail))
      (setcdr tail nil)
      (setcdr (assq 'corfu--total state) corfu-count))
    state))

(advice-add 'corfu--compute :around #'init-corfu--compute-advice)

;; Free C-n / C-p / C-a for buffer navigation while the popup is open;
;; navigate the popup with M-n / M-p instead.
(define-key corfu-map (kbd "M-n") #'corfu-next)
(define-key corfu-map (kbd "M-p") #'corfu-previous)
(keymap-unset corfu-map "<remap> <next-line>" t)
(keymap-unset corfu-map "<remap> <previous-line>" t)
(keymap-unset corfu-map "<remap> <move-beginning-of-line>" t)

;; Numeric quick-select: M-1..M-9 picks the 1st..9th visible candidate;
;; M-0 picks the 10th.  Indexed against `corfu--scroll' so it still
;; works if scrolling is later re-enabled.
(defun init-corfu--quick-select (n)
  "Insert the Nth visible corfu candidate (0-indexed)."
  (when (< (+ corfu--scroll n) corfu--total)
    (setq corfu--index (+ corfu--scroll n))
    (corfu-insert)))

(dotimes (i 10)
  (define-key corfu-map (kbd (format "M-%d" (mod (1+ i) 10)))
              (lambda () (interactive) (init-corfu--quick-select i))))

(defconst init-corfu--quick-labels
  (let ((v (make-vector 10 nil)))
    (dotimes (i 10)
      (aset v i (propertize (format "%d " (mod (1+ i) 10))
                            'face '(bold font-lock-keyword-face))))
    v)
  "Precomputed propertized labels for `init-corfu--annotate-numbers'.")

;; :filter-return so margin formatters (kind-icon etc.) still run; the
;; label is prepended to whatever prefix they produced.
(defun init-corfu--annotate-numbers (result)
  "Prepend numeric quick-select labels to each candidate prefix in RESULT."
  (let ((i 0))
    (dolist (cand (cdr result))
      (setf (cadr cand) (concat (aref init-corfu--quick-labels i)
                                (cadr cand)))
      (setq i (1+ i))))
  result)

(advice-add 'corfu--affixate :filter-return #'init-corfu--annotate-numbers)

(add-hook 'completion-at-point-functions #'cape-dabbrev)
(add-hook 'completion-at-point-functions #'cape-keyword)
(add-hook 'completion-at-point-functions #'cape-file)

;; Case-sensitive dabbrev: "cre" matches "createElement" but not "CREATE".
(setq dabbrev-case-replace nil
      dabbrev-case-fold-search nil)

;; Scope cape-dabbrev to file-visiting buffers in the current project
;; instead of all same-mode buffers (cape default).
(defun init-corfu--dabbrev-project-buffers ()
  "Return file-visiting buffers under the current project root."
  (if-let* ((proj (project-current)))
      (seq-filter #'buffer-file-name (project-buffers proj))
    (list (current-buffer))))

(setq cape-dabbrev-buffer-function #'init-corfu--dabbrev-project-buffers)

(unless (display-graphic-p)
  (require 'corfu-terminal)
  (corfu-terminal-mode 1))

;; Disable in magit-status.
(setq global-corfu-modes '((not magit-status-mode) t))

(global-corfu-mode 1)

(provide 'init-corfu)

;;; init-corfu.el ends here
