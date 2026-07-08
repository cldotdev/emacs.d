;;; init-server.el --- Emacs server integration -*- lexical-binding: t -*-

;;; Commentary:

;; emacsclient reports the caller's working directory to the server
;; (stored as the `server-client-directory' property on the client
;; process).  For files visited under `temporary-file-directory' the
;; buffer's own directory carries no useful context, so adopt the
;; caller's directory instead.  This makes relative path completion
;; (cape-file) and `find-file' resolve against the directory the
;; client was invoked from, e.g. the project directory of a Claude
;; Code ctrl-g prompt file or a `crontab -e' session.

;;; Code:

(require 'server)

(defun init-server--adopt-client-directory ()
  "Use the emacsclient caller's cwd as `default-directory' for temp files."
  (when (and buffer-file-name
             server-buffer-clients
             (file-in-directory-p buffer-file-name temporary-file-directory))
    (when-let* ((dir (process-get (car server-buffer-clients)
                                  'server-client-directory)))
      (setq-local default-directory (file-name-as-directory dir)))))

;; `server-switch-hook' (unlike `server-visit-hook') runs after
;; `server-buffer-clients' is populated, with the visited buffer current.
(add-hook 'server-switch-hook #'init-server--adopt-client-directory)

(provide 'init-server)

;;; init-server.el ends here
