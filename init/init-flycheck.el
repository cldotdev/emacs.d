;;; init-flycheck.el --- Flycheck configuration -*- lexical-binding: t -*-

(declare-function sh-set-shell "sh-script")

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

(defvar my-flycheck-ruby-project-cache (make-hash-table :test 'equal))

;; `mise where ruby' exits non-zero when the version is not installed and
;; never triggers an on-demand install, unlike `mise x' or `mise current'.
(defun my-flycheck-ruby-project-ready-p (root)
  "Return non-nil if mise reports Ruby installed for ROOT.
Result is cached per project for the rest of the Emacs session."
  (let* ((key (expand-file-name root))
         (cached (gethash key my-flycheck-ruby-project-cache 'unset)))
    (if (not (eq cached 'unset))
        cached
      (let* ((default-directory key)
             (ready (eq 0 (call-process "mise" nil nil nil "where" "ruby"))))
        (puthash key ready my-flycheck-ruby-project-cache)
        ready))))

;; Wrap Ruby checkers with `mise x -C <root> -- bundle exec' so the project's
;; bundled rubocop (and its plugins) runs instead of whatever system rubocop
;; happens to be on the daemon's PATH.  Skip rubocop entirely when mise has
;; no Ruby installed, otherwise the wrapped subprocess blocks Emacs trying
;; to install on demand.  `--server' keeps a rubocop daemon hot for ~10x
;; faster checks; the daemon detaches via `Process.daemon' so it survives
;; Emacs daemon restarts.
(defun my-flycheck-ruby-setup ()
  "Setup Flycheck to use project Ruby version and gems via mise + bundler."
  ;; Skip `idle-change' / `new-line' triggers so typing pauses do not spawn
  ;; `mise x -- bundle exec rubocop' (~700ms-2s per invocation).
  (setq-local flycheck-check-syntax-automatically '(save mode-enabled))
  (when-let* ((file (buffer-file-name))
              (root (locate-dominating-file file "Gemfile")))
    (cond
     ((not (executable-find "mise")) nil)
     ((not (my-flycheck-ruby-project-ready-p root))
      (setq-local flycheck-disabled-checkers
                  (cons 'ruby-rubocop flycheck-disabled-checkers))
      (message "flycheck: mise has no Ruby for %s, rubocop disabled" root))
     (t
      (let ((project-root (expand-file-name root)))
        (setq-local flycheck-command-wrapper-function
                    (lambda (command)
                      (let* ((bin (file-name-nondirectory (car command)))
                             (extra (and (string= bin "rubocop") '("--server"))))
                        `("mise" "x" "-C" ,project-root "--"
                          "bundle" "exec" ,bin ,@extra ,@(cdr command))))))))))

(dolist (hook '(ruby-mode-hook ruby-ts-mode-hook enh-ruby-mode-hook))
  (add-hook hook #'my-flycheck-ruby-setup))

(defun my-rubocop--stop-server-in (root)
  "Send `rubocop --stop-server' for the project at ROOT (fire-and-forget)."
  (let ((default-directory root))
    (start-process "rubocop-stop-server" nil "mise" "x" "--"
                   "bundle" "exec" "rubocop" "--stop-server")))

(defun my-rubocop-stop-server-here ()
  "Stop the rubocop server for the current buffer's project."
  (interactive)
  (if-let* ((file (buffer-file-name))
            (root (locate-dominating-file file "Gemfile")))
      (progn
        (my-rubocop--stop-server-in root)
        (message "rubocop --stop-server sent for %s" root))
    (user-error "No Gemfile found for current buffer")))

(defun my-rubocop-stop-all-servers ()
  "Stop rubocop servers for every project touched in this session."
  (interactive)
  (let ((count 0))
    (maphash
     (lambda (root ready)
       (when ready
         (my-rubocop--stop-server-in root)
         (setq count (1+ count))))
     my-flycheck-ruby-project-cache)
    (message "rubocop --stop-server sent for %d project(s)" count)))

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
