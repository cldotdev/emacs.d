;;; init-corfu.el --- Corfu completion configuration -*- lexical-binding: t -*-

;;; Commentary:

;; Replaces company-mode.  In terminal Emacs the popup is rendered with
;; popon (via corfu-terminal) instead of a child frame, which avoids the
;; line-number / wide-CJK display artifacts caused by company's
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

(declare-function corfu-terminal-mode "corfu-terminal" (&optional arg))

;; Mirror the previous company-mode timing: trigger immediately and need
;; only one character of prefix.
(setq corfu-auto t
      corfu-auto-delay 0
      corfu-auto-prefix 1
      corfu-cycle t
      corfu-quit-no-match 'separator
      corfu-preselect 'prompt)

;; Mirror the previous M-n / M-p navigation in company-active-map.
(define-key corfu-map (kbd "M-n") #'corfu-next)
(define-key corfu-map (kbd "M-p") #'corfu-previous)

;; Mirror company-mode's default backends: dabbrev (buffer words),
;; keyword (mode-specific reserved words), and file (paths).
(add-hook 'completion-at-point-functions #'cape-dabbrev)
(add-hook 'completion-at-point-functions #'cape-keyword)
(add-hook 'completion-at-point-functions #'cape-file)

;; Keep dabbrev case-sensitive, mirroring company-dabbrev-ignore-case nil
;; and company-dabbrev-downcase nil so "cre" still matches "createElement"
;; but not "CREATE".
(setq dabbrev-case-replace nil
      dabbrev-case-fold-search nil)

;; In terminal Emacs, render the popup with popon instead of a child frame.
(unless (display-graphic-p)
  (require 'corfu-terminal)
  (corfu-terminal-mode 1))

;; Mirror company-global-modes '(not magit-status-mode).
(setq global-corfu-modes '((not magit-status-mode) t))

(global-corfu-mode 1)

(provide 'init-corfu)

;;; init-corfu.el ends here
