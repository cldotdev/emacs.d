;;; init-company-mode.el --- Company mode configuration -*- lexical-binding: t -*-

(add-to-list 'load-path "~/.emacs.d/package/company-mode")

(require 'company)
(add-hook 'after-init-hook 'global-company-mode)

;; Always turned on except in text-mode buffer.
(setq company-global-modes '(not magit-status-mode))

;; Trigger completion immediately.
(setq company-idle-delay 0)

;; Number the candidates (use M-1, M-2 etc to select completions).
(setq company-show-quick-access t)

;; The minimum prefix length for idle completion.
(setq company-minimum-prefix-length 1)

;; Disable icons
(setq company-format-margin-function nil)

;; Do not downcase completion candidates from dabbrev.
(defvar company-dabbrev-downcase)
(with-eval-after-load 'company-dabbrev
  (setq company-dabbrev-downcase nil))

;; When the candidate window is active, use M-n/M-p to navigate items.
(with-eval-after-load 'company
  (keymap-unset company-active-map "C-n" 'remove)
  (keymap-unset company-active-map "C-p" 'remove)
  (define-key company-active-map (kbd "M-n") #'company-select-next)
  (define-key company-active-map (kbd "M-p") #'company-select-previous)

  ;; Fix "Args out of range" error when suffix length > value length.
  ;; Upstream has not fixed this issue as of 2025-12-29.
  (defun my/company--common-or-matches-fix (orig-fn value &optional suffix)
    "Wrapper to prevent negative indices in company--common-or-matches."
    (let ((result (funcall orig-fn value suffix)))
      (when result
        (cl-loop for pair in result
                 when (< (car pair) 0)
                 do (setcar pair 0)))
      result))

  (advice-add 'company--common-or-matches :around #'my/company--common-or-matches-fix))

(provide 'init-company-mode)
