;;; init-flycheck.el --- Flycheck configuration -*- lexical-binding: t -*-

(add-to-list 'load-path "~/.emacs.d/package/flycheck")
(add-to-list 'load-path "~/.emacs.d/package/s.el")
(add-to-list 'load-path "~/.emacs.d/package/dash.el")
(add-to-list 'load-path "~/.emacs.d/package/f.el")

(require 'flycheck)
(add-hook 'after-init-hook #'global-flycheck-mode)
(setq-default flycheck-disabled-checkers
              '(emacs-lisp-checkdoc sh-bash sh-zsh))

;; https://github.com/flycheck/flycheck/issues/1559#issuecomment-478569550
(setq flycheck-emacs-lisp-load-path 'inherit)

;; Configure Flycheck to use project Ruby version via mise
(defun my-flycheck-ruby-setup ()
  "Setup Flycheck to use project Ruby version via mise."
  (when-let* ((file (buffer-file-name))
              (project-root (expand-file-name
                             (locate-dominating-file file "Gemfile"))))
    (setq-local flycheck-command-wrapper-function
                (lambda (command)
                  ;; Use mise x with explicit project directory (-C) to ensure
                  ;; the correct Ruby version is used
                  (if (executable-find "mise")
                      (append (list "mise" "x" "-C" project-root "--") command)
                    command)))))

(add-hook 'ruby-mode-hook 'my-flycheck-ruby-setup)

;; Disable shellcheck for .env files since environment variables are
;; meant to be sourced externally and SC2034 warnings are false positives
(defun my-flycheck-disable-shellcheck-for-env-files ()
  "Disable shellcheck for .env files."
  (when (and (buffer-file-name)
             (string-match-p "\\.env\\(\\..*\\)?\\'" (buffer-file-name)))
    (setq-local flycheck-disabled-checkers
                (append flycheck-disabled-checkers '(sh-shellcheck)))))

(add-hook 'sh-mode-hook 'my-flycheck-disable-shellcheck-for-env-files)

;; Re-detect shell dialect from shebang before Flycheck runs.
;; When creating new .sh files, sh-mode sets sh-shell to `sh` (default)
;; before the shebang is written, causing ShellCheck to use POSIX mode.
(defun my-flycheck-set-shell-from-shebang ()
  "Re-detect shell from shebang before Flycheck runs."
  (save-excursion
    (goto-char (point-min))
    (when (looking-at auto-mode-interpreter-regexp)
      (let ((interp (file-name-nondirectory (match-string 2))))
        (when (and interp (not (string= interp (symbol-name sh-shell))))
          (sh-set-shell interp nil nil))))))

(add-hook 'sh-mode-hook
          (lambda ()
            (add-hook 'flycheck-before-syntax-check-hook
                      #'my-flycheck-set-shell-from-shebang nil t)))

;; Disable SC1091 (Not following sourced file) since shellcheck cannot
;; resolve relative paths in source commands at static analysis time
(setq flycheck-shellcheck-excluded-warnings '("SC1091"))

(provide 'init-flycheck)
