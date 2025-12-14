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

;; Configure Flycheck to use bundler for RuboCop in Ruby projects
(defun my-flycheck-ruby-setup ()
  "Setup Flycheck to use bundler for RuboCop when Gemfile exists.
Also ensures the correct Ruby version is used via mise."
  (when (and (buffer-file-name)
             (locate-dominating-file (buffer-file-name) "Gemfile"))
    (setq-local flycheck-command-wrapper-function
                (lambda (command)
                  ;; Use mise x to execute bundle exec in the correct Ruby environment
                  (if (executable-find "mise")
                      (append '("mise" "x" "--" "bundle" "exec") command)
                    (append '("bundle" "exec") command))))))

(add-hook 'ruby-mode-hook 'my-flycheck-ruby-setup)

;; Custom error handler for bundler failures
(defun my-flycheck-handle-bundler-error (err)
  "Handle bundler errors more gracefully."
  (when (and (flycheck-error-p err)
             (string-match-p "bundler.*failed" (flycheck-error-message err)))
    (message "Bundler failed - check Ruby version and Gemfile compatibility")))

(add-hook 'flycheck-after-syntax-check-hook
          (lambda ()
            (dolist (err flycheck-current-errors)
              (my-flycheck-handle-bundler-error err))))

;; Disable shellcheck for .env files since environment variables are
;; meant to be sourced externally and SC2034 warnings are false positives
(defun my-flycheck-disable-shellcheck-for-env-files ()
  "Disable shellcheck for .env files."
  (when (and (buffer-file-name)
             (string-match-p "\\.env\\(\\..*\\)?\\'" (buffer-file-name)))
    (setq-local flycheck-disabled-checkers
                (append flycheck-disabled-checkers '(sh-shellcheck)))))

(add-hook 'sh-mode-hook 'my-flycheck-disable-shellcheck-for-env-files)

(provide 'init-flycheck)
