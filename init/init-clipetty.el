;;; init-clipetty.el --- Clipetty configuration -*- lexical-binding: t -*-

;;; Commentary:

;;; Code:

(add-to-list 'load-path "~/.emacs.d/package/clipetty")
(require 'clipetty)
(require 'subr-x)

(defvar my/clipetty--tmux-executable (executable-find "tmux"))

(defun my/clipetty-tmux-output (&rest args)
  "Run tmux with ARGS and return trimmed output, or nil."
  (when my/clipetty--tmux-executable
    (with-temp-buffer
      (when (zerop (apply #'call-process my/clipetty--tmux-executable nil t nil args))
        (let ((output (string-trim (buffer-string))))
          (unless (string-empty-p output)
            output))))))

(defun my/clipetty-frame-client-tty (pane)
  "Return the tmux client tty for PANE."
  (my/clipetty-tmux-output "display-message" "-p" "-t" pane "#{client_tty}"))

(defun my/clipetty-frame-session-id (pane)
  "Return the tmux session id for PANE."
  (my/clipetty-tmux-output "display-message" "-p" "-t" pane "#{session_id}"))

(defun my/clipetty-frame-single-client-tty (pane)
  "Return the tty when PANE's session has exactly one tmux client."
  (let ((session-id (my/clipetty-frame-session-id pane)))
    (when session-id
      (let ((output (my/clipetty-tmux-output
                     "list-clients" "-t" session-id "-F" "#{client_tty}")))
        (when output
          (let ((clients (split-string output "\n" t)))
            (when (= (length clients) 1)
              (car clients))))))))

(defun my/clipetty-tty (orig-fun ssh-tty tmux)
  "Advice around `clipetty--tty' (ORIG-FUN SSH-TTY TMUX) to use the frame's tmux client."
  (or (and tmux
           (let ((pane (getenv "TMUX_PANE" (selected-frame)))
                 (tmux-env (getenv "TMUX" (selected-frame))))
             (when (and pane tmux-env)
               (let ((process-environment (copy-sequence process-environment)))
                 (setenv "TMUX" tmux-env)
                 (or (my/clipetty-frame-client-tty pane)
                     (my/clipetty-frame-single-client-tty pane))))))
      (funcall orig-fun ssh-tty tmux)))

(unless (advice-member-p #'my/clipetty-tty 'clipetty--tty)
  (advice-add 'clipetty--tty :around #'my/clipetty-tty))

(unless (display-graphic-p)
  (global-clipetty-mode 1))

(provide 'init-clipetty)
;;; init-clipetty.el ends here
