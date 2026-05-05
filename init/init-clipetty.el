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

;; Cache the resolved tmux client tty per pane so each kill no longer
;; spawns 1-3 synchronous tmux subprocesses.
(defvar my/clipetty--tty-cache (make-hash-table :test 'equal))

(defun my/clipetty-flush-tty-cache (&optional frame &rest _)
  "Invalidate cached tmux client ttys for FRAME, or all entries when nil."
  (interactive)
  (if (framep frame)
      (when-let ((pane (getenv "TMUX_PANE" frame)))
        (remhash pane my/clipetty--tty-cache))
    (clrhash my/clipetty--tty-cache)))

(add-hook 'after-make-frame-functions #'my/clipetty-flush-tty-cache)
(add-hook 'delete-frame-functions #'my/clipetty-flush-tty-cache)

(defun my/clipetty-tty (orig-fun ssh-tty tmux)
  "Advice around `clipetty--tty' (ORIG-FUN SSH-TTY TMUX) to use the frame's tmux client."
  (or (and tmux
           (let ((pane (getenv "TMUX_PANE" (selected-frame)))
                 (tmux-env (getenv "TMUX" (selected-frame))))
             (when (and pane tmux-env)
               (or (gethash pane my/clipetty--tty-cache)
                   (let ((process-environment (copy-sequence process-environment)))
                     (setenv "TMUX" tmux-env)
                     (when-let ((tty (or (my/clipetty-frame-client-tty pane)
                                         (my/clipetty-frame-single-client-tty pane))))
                       (puthash pane tty my/clipetty--tty-cache)
                       tty))))))
      (funcall orig-fun ssh-tty tmux)))

(unless (advice-member-p #'my/clipetty-tty 'clipetty--tty)
  (advice-add 'clipetty--tty :around #'my/clipetty-tty))

;; Coalesce clipboard syncs during continuous kills.  `kill-append'
;; rebuilds a growing string and `interprogram-cut-function' re-emits
;; the whole thing each time, so holding C-k is O(N^2) in OSC 52 bytes
;; written to the tty.  Defer to an idle timer and fire one sync once
;; the user stops killing.

(defcustom my/clipetty-coalesce-idle-delay 0.3
  "Idle seconds before flushing a deferred clipetty sync."
  :type 'number
  :group 'clipetty)

(defvar my/clipetty--pending nil
  "Cons (CUT-FN . STRING) awaiting deferred emission, or nil.
CUT-FN is the unadvised `clipetty-cut'; STRING is the latest kill text.")

(defvar my/clipetty--idle-timer nil
  "Idle timer scheduled to flush `my/clipetty--pending'.")

(defun my/clipetty--kill-command-p (command)
  "Return non-nil if COMMAND is a kill command that may chain to `kill-append'."
  (and (symbolp command)
       (let ((name (symbol-name command)))
         (or (string-prefix-p "kill-" name)
             (string-prefix-p "backward-kill-" name)
             (string-suffix-p "-kill" name)
             (string-match-p "-kill-" name)))))

(defun my/clipetty--cancel-pending ()
  "Cancel any deferred clipetty sync and drop the pending payload."
  (when my/clipetty--idle-timer
    (cancel-timer my/clipetty--idle-timer)
    (setq my/clipetty--idle-timer nil))
  (setq my/clipetty--pending nil))

(defun my/clipetty--flush-pending ()
  "Emit the deferred kill via the captured `clipetty-cut' body."
  (setq my/clipetty--idle-timer nil)
  (when-let ((pending my/clipetty--pending))
    (setq my/clipetty--pending nil)
    ;; Pass `ignore' as the cut-chain tail: intermediate kills already
    ;; funcalled the real tail, so we only need the OSC 52 emission here.
    (funcall (car pending) #'ignore (cdr pending))))

(defun my/clipetty--reschedule-flush ()
  "Schedule `my/clipetty--flush-pending' to run after idle delay."
  (when my/clipetty--idle-timer
    (cancel-timer my/clipetty--idle-timer))
  (setq my/clipetty--idle-timer
        (run-with-idle-timer my/clipetty-coalesce-idle-delay nil
                             #'my/clipetty--flush-pending)))

(defun my/clipetty-cut-coalesce (orig-clipetty-cut orig-cut-fn string)
  "Around advice for `clipetty-cut' that defers OSC 52 during a continuous kill.
ORIG-CLIPETTY-CUT is the unadvised `clipetty-cut'; ORIG-CUT-FN is the next
link in the `interprogram-cut-function' chain; STRING is the kill text."
  (cond
   ((display-graphic-p)
    (funcall orig-clipetty-cut orig-cut-fn string))
   ((my/clipetty--kill-command-p last-command)
    (setq my/clipetty--pending (cons orig-clipetty-cut string))
    (my/clipetty--reschedule-flush)
    (funcall orig-cut-fn string))
   (t
    (my/clipetty--cancel-pending)
    (funcall orig-clipetty-cut orig-cut-fn string))))

(unless (advice-member-p #'my/clipetty-cut-coalesce 'clipetty-cut)
  (advice-add 'clipetty-cut :around #'my/clipetty-cut-coalesce))

(unless (display-graphic-p)
  (global-clipetty-mode 1))

(provide 'init-clipetty)
;;; init-clipetty.el ends here
