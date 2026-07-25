;;; -*- lexical-binding: t; -*-
;;; init-mise.el --- Mise (Ruby version manager) integration

(defun my-mise-setup-environment ()
  "Setup mise environment in Emacs."
  (when (executable-find "mise")
    (let* ((mise-output (shell-command-to-string "mise env -s bash"))
           (env-vars (split-string mise-output "\n" t)))
      (dolist (env-var env-vars)
        (when (string-match "^export \\([^=]+\\)=\\(.+\\)" env-var)
          (let ((var-name (match-string 1 env-var))
                (var-value (match-string 2 env-var)))
            ;; Remove surrounding quotes if present
            (setq var-value (replace-regexp-in-string "^[\"']\\|[\"']$" "" var-value))
            (setenv var-name var-value)
            (when (string= var-name "PATH")
              (setq exec-path (split-string var-value path-separator)))))))))

(my-mise-setup-environment)

(provide 'init-mise)
