;; Starting message
(setq initial-scratch-message "")
(setq initial-major-mode 'text-mode)

;; Copy whole line when no region is active
(defun kill-ring-save-line-or-region ()
  "Copy the current line to the kill ring if no region is active.
Otherwise copy the region as usual."
  (interactive)
  (if (use-region-p)
      (kill-ring-save (region-beginning) (region-end))
    (copy-region-as-kill (line-beginning-position) (line-beginning-position 2))
    (message "Copied line")))
(global-set-key (kbd "M-w") 'kill-ring-save-line-or-region)

;; Query-replace-regexp
(global-set-key (kbd "M-#") 'query-replace-regexp)

;; Occur
(global-set-key (kbd "C-c o") 'occur)

;; Show trailing whitespace
(global-set-key (kbd "C-<f12>") 'whitespace-mode)
;; (add-hook 'prog-mode-hook 'whitespace-mode)

;; Delete trailing whitespace
;; Preserve trailing whitespace on line 1 when it starts with "/" (slash
;; commands for Claude prompts need a trailing space after the command).
(add-hook 'before-save-hook
          (lambda ()
            (unless (eq major-mode 'csv-mode)
              (save-restriction
                (widen)
                (let (first-line-trailing-ws)
                  (save-excursion
                    (goto-char (point-min))
                    (when (looking-at "/\\S-")
                      (let ((eol (line-end-position)))
                        (goto-char eol)
                        (skip-chars-backward " \t")
                        (when (< (point) eol)
                          (setq first-line-trailing-ws
                                (buffer-substring (point) eol)))))
                    (delete-trailing-whitespace)
                    (when first-line-trailing-ws
                      (goto-char (point-min))
                      (end-of-line)
                      (insert first-line-trailing-ws))))))))

(setq copy-region-blink-delay 0)

;; Inhibit startup message
(setq inhibit-startup-screen t)

;; Buffer to show after starting Emacs.
;; (setq initial-buffer-choice "~")

;; Cursor, please do not blink
(blink-cursor-mode nil)

;; Show column number in mode line
(setq column-number-mode t)

;; When point is on paranthesis, highlight the matching one
(show-paren-mode t)
(setq show-paren-style 'parenthesis
      show-paren-context-when-offscreen 'overlay)

;; Turn on highlighting current line
(global-hl-line-mode 1)

;; Switch windows
(global-set-key (kbd "<up>") 'windmove-up)
(global-set-key (kbd "<down>") 'windmove-down)
(global-set-key (kbd "<right>") 'windmove-right)
(global-set-key (kbd "<left>") 'windmove-left)

;; Leave point at same position in window when scrolling page
(global-set-key (kbd "M-]") 'scroll-lock-mode)

;; Daemon
;; (setq server-use-tcp t)
;; (setq-default server-socket-dir "~/.emacs.d/server")

;; Find-file default location
(find-file "~/.")

;; Backup configuration
(defvar my-backup-directory "~/.emacs.d/backup"
  "Directory to store backup files.")

(defvar my-max-backup-files 1000
  "Maximum number of backup files to keep.")

(defvar my-max-backup-file-size 204800
  "Maximum file size (in bytes) to backup. Files larger than this will not be backed up. Default is 200KB.")

;; Create backup directory if it doesn't exist
(let ((backup-dir (expand-file-name my-backup-directory)))
  (unless (file-directory-p backup-dir)
    (make-directory backup-dir t)
    (set-file-modes backup-dir #o700)))

;; Sensitive file patterns to exclude from backup
(defvar my-sensitive-file-patterns
  '(;; Environment files
    "/\\.env" "\\.env\\." "\\.env$"
    ;; Certificate and key files
    "\\.key$" "\\.pem$" "\\.crt$" "\\.p12$" "\\.pfx$" "\\.cer$"
    "\\.keystore$" "\\.jks$" "\\.pkcs12$"
    ;; SSH and GPG files
    "/\\.ssh/" "/\\.gnupg/"
    ;; Cloud provider credentials
    "/\\.aws/" "/\\.azure/" "/\\.gcloud/"
    ;; Database files
    "\\.db$" "\\.sqlite$" "\\.sqlite3$" "database\\.yml$"
    ;; Security-related files
    "/secrets/" "/vault/" "password" "passwd" "credentials"
    "auth\\.json$" "token" ".*_token" "apikey" "api_key"
    "secret" ".*_secret$" "github_pat"
    ;; Configuration files that may contain secrets
    "/\\.kube/" "kubeconfig"
    ;; Docker secrets
    "docker-compose\\.override\\.yml$" "/\\.docker/"
    ;; Production data directories
    "/\\.srv/"
    ;; Application-specific sensitive files
    "\\.npmrc$" "\\.pypirc$" "\\.netrc$" "\\.dockercfg$"
    ;; Backup and temporary files that might contain secrets
    "\\.bak$" "\\.tmp$" "\\.temp$" "core$")
  "List of regex patterns for sensitive files that should not be backed up.")

;; Backup enable predicate (allows /tmp files, excludes sensitive files)
;; Only check path-based conditions here; transient conditions (empty,
;; oversized, unchanged) are handled in before-save-hook, because this
;; predicate runs once at visit time and permanently sets backup-inhibited.
(setq backup-enable-predicate
      (lambda (name)
        (not (cl-some (lambda (pattern)
                        (string-match-p pattern name))
                      my-sensitive-file-patterns))))

;; Centralized backup directory (predicate already excludes sensitive files)
(setq backup-directory-alist
      `(("." . ,my-backup-directory)))

(setq
 delete-old-versions t    ; Auto-delete old versions per file
 version-control t
 kept-new-versions 7      ; Keep 7 newest versions
 kept-old-versions 3)     ; Keep 3 oldest versions (total 10 per file)

;; Limit total number of backup files (runs on idle timer, not every save)
(defun my-cleanup-old-backup-files ()
  "Keep only the N most recent backup files in backup directory."
  (let ((backup-dir (expand-file-name my-backup-directory)))
    (when (file-directory-p backup-dir)
      (let* ((files (directory-files backup-dir t "^[^.]"))
             ;; Collect attributes once to avoid repeated stat calls in sort
             (file-mtimes (mapcar (lambda (f)
                                    (cons f (nth 5 (file-attributes f))))
                                  files))
             (sorted (sort file-mtimes
                           (lambda (a b)
                             (time-less-p (cdr b) (cdr a)))))
             (to-delete (nthcdr my-max-backup-files sorted)))
        (dolist (entry to-delete)
          (when (file-regular-p (car entry))
            (delete-file (car entry))))))))

;; Suppress Emacs' built-in backup (which copies the OLD on-disk file).
;; We create backups ourselves in after-save-hook so that each backup
;; contains the just-saved content (post-processed by all hooks).
;;
;; | Step | Action          | Buffer  | Latest backup      | Match? | Backup created?        |
;; |------+-----------------+---------+--------------------+--------+------------------------|
;; |    1 | new file, save  | "1"     | (none)             | --     | backup.~1~ = "1"       |
;; |    2 | edit to "123"   | "123"   | backup.~1~ = "1"   | no     | backup.~2~ = "123"     |
;; |    3 | edit to "12345" | "12345" | backup.~2~ = "123" | no     | backup.~3~ = "12345"   |
;; |    4 | save unchanged  | "12345" | backup.~3~ = "12345" | yes  | skipped                |
(defun my-backup-before-save ()
  "Suppress Emacs' built-in backup; handled in `my-backup-after-save'."
  (when buffer-file-name
    (setq buffer-backed-up t)))

(add-hook 'before-save-hook #'my-backup-before-save 90)

;; After every save, compare the just-saved file with the latest backup.
;; Create a new numbered backup when content differs and file is non-empty
;; and not oversized.  This ensures each backup is a snapshot of the saved
;; content rather than the old on-disk content.
(defun my-backup-after-save ()
  "Copy the just-saved file to a numbered backup when it differs from
the latest existing backup.  Skip empty or oversized files."
  (when (and buffer-file-name (not backup-inhibited))
    (let ((file-size (nth 7 (file-attributes buffer-file-name))))
      (when (and file-size (> file-size 0)
                 (< file-size my-max-backup-file-size))
        (let* ((backups (file-backup-file-names buffer-file-name))
               (latest-backup (when backups
                                (cl-reduce (lambda (a b)
                                             (if (file-newer-than-file-p a b) a b))
                                           backups))))
          (unless (and latest-backup
                       (let ((backup-size (nth 7 (file-attributes latest-backup))))
                         (and backup-size
                              (= file-size backup-size)
                              (zerop (call-process "cmp" nil nil nil
                                                   "-s" buffer-file-name
                                                   latest-backup)))))
            (let* ((result (find-backup-file-name buffer-file-name))
                   (target (car result)))
              (when target
                (copy-file buffer-file-name target t)
                (dolist (old (cdr result))
                  (ignore-errors (delete-file old)))))))))))

(add-hook 'after-save-hook #'my-backup-after-save)

;; Run cleanup on idle instead of every save
(run-with-idle-timer 30 t #'my-cleanup-old-backup-files)

;; Default indentation
(setq-default indent-tabs-mode nil)
(setq-default tab-width 2)

;; Insert a new line and jump to it (shift+RET)
(defun end-of-line-and-indent-new-line ()
  (interactive)
  (end-of-line)
  (electric-indent-just-newline t)
  (indent-according-to-mode))
(global-set-key (kbd "C-j") 'end-of-line-and-indent-new-line)

;; NOTE: In CSV mode, if you want to do indentation without
;; removing the trailing whitespaces, use C-j.
;;
;; (defun indent-new-line ()
;;   (interactive)
;;   (electric-indent-just-newline t)
;;   (indent-according-to-mode))
;; (global-set-key (kbd "RET") 'indent-new-line)

;; Display line number
(when (version<= "26.0.50" emacs-version)
  (global-display-line-numbers-mode))

;; Word wrap
(setq-default truncate-lines t)
(global-set-key (kbd "C-c t") 'toggle-truncate-lines)

;; Enabling font lock
(if (fboundp 'global-font-lock-mode)
    (global-font-lock-mode 1))

;; Visual line mode
(setq-default visual-line-mode t)
(setq-default global-visual-line-mode t)

;; Dired-mode
(setq dired-listing-switches "-alh")

;; Shells
(global-set-key [f12]
		'(lambda ()
		   (interactive)
		   (shell)))

;; Transpose lines
(defun move-line (n)
  "Move the current line up or down by N lines."
  (interactive "p")
  (setq col (current-column))
  (beginning-of-line) (setq start (point))
  (end-of-line) (forward-char) (setq end (point))
  (let ((line-text (delete-and-extract-region start end)))
    (forward-line n)
    (insert line-text)
    ;; restore point to original column in moved line
    (forward-line -1)
    (forward-char col)))
(defun move-line-up (n)
  "Move the current line up by N lines."
  (interactive "p")
  (move-line (if (null n) -1 (- n))))
(defun move-line-down (n)
  "Move the current line down by N lines."
  (interactive "p")
  (move-line (if (null n) 1 n)))
(global-set-key (kbd "M-<up>") 'move-line-up)
(global-set-key (kbd "M-<down>") 'move-line-down)

;; Original idea from
;; http://www.opensubscriber.com/message/emacs-devel@gnu.org/10971693.html
(defun comment-dwim-line (&optional arg)
  "Replacement for the comment-dwim command.
        If no region is selected and current line is not blank and we are not at the end of the line,
        then comment current line.
        Replaces default behaviour of comment-dwim, when it inserts comment at the end of the line."
  (interactive "*P")
  (comment-normalize-vars)
  (if (and (not (region-active-p)) (not (looking-at "[ \t]*$")))
      (comment-or-uncomment-region (line-beginning-position) (line-end-position))
    (comment-dwim arg)))
(global-set-key (kbd "M-;") 'comment-dwim-line)

;; Electric pair mode
(require 'elec-pair)
(electric-pair-mode)
(setq electric-pair-skip-whitespace nil)

(setq electric-pair-inhibit-predicate
      (lambda (c)
        (or (minibufferp)
            ;; Never auto-pair " in any mode.
            (eq c ?\")
            (electric-pair-conservative-inhibit c))))

;; Drop ASCII " from the unconditional-pair tables; otherwise in modes where
;; " has punctuation syntax (text-mode, markdown-mode) it would bypass
;; `electric-pair-inhibit-predicate' and always pair.
(setq electric-pair-pairs
      (remove '(?\" . ?\") electric-pair-pairs))
(setq electric-pair-text-pairs
      (remove '(?\" . ?\") electric-pair-text-pairs))

;; Joins the current line and the previous line, by deleting a newline
;; and all surrounding spaces, usually leaving a single space.
(global-set-key (kbd "M-i") 'delete-indentation)

;; Numbered window shortcuts
;; use M-1 through M-0 to navigate
(require 'window-numbering)
(with-eval-after-load 'window-numbering
  (window-numbering-mode 1))

;; Smex is a M-x enhancement for Emacs. Built on top of Ido,
;; it provides a convenient interface to your recently and most
;; frequently used commands. And to all the other commands, too.
;; (require 'smex)
;; (smex-initialize)
;; (global-set-key (kbd "M-x") 'smex)
;; (global-set-key (kbd "M-X") 'smex-major-mode-commands)
;; ;; This is your old M-x.
;; (global-set-key (kbd "C-c C-c M-x") 'execute-extended-command)

;; Save minibuffer history
(savehist-mode t)

;; Accept UTF-8 (uppercase) encoding
(define-coding-system-alias 'UTF-8 'utf-8)

;; Fix emoji display corruption in terminal mode
;; Problem: Emacs tries to compose emoji sequences (char + VS-16) but the
;; composed glyph width doesn't match what the terminal actually renders,
;; causing cursor position mismatch and display corruption.
;; See: https://lists.gnu.org/archive/html/bug-gnu-emacs/2021-09/msg02648.html
(when (not (display-graphic-p))
  ;; Disable composition for Variation Selectors (U+FE00-U+FE0F) in terminal mode.
  ;; VS-16 (U+FE0F) tells the terminal to render the preceding character as a
  ;; colored emoji, but Emacs' composition system doesn't handle the width change
  ;; correctly, leading to display artifacts.
  (set-char-table-range composition-function-table '(#xFE00 . #xFE0F) nil)

  ;; Make Variation Selectors completely invisible (zero-width) instead of
  ;; displaying as thin-space, which can cause rendering issues in split windows.
  (set-char-table-range glyphless-char-display '(#xFE00 . #xFE0F) 'zero-width))

;; Add keybinding to manually redraw display when mode-line gets garbled
(global-set-key (kbd "C-c r") 'redraw-display)

;; Previous buffer
(global-set-key (kbd "C-c p") 'previous-buffer)

;; Next buffer
(global-set-key (kbd "C-c n") 'next-buffer)

;; Remap xref navigation
(global-set-key (kbd "C-c [") #'xref-go-back)
(global-set-key (kbd "C-c ]") #'xref-go-forward)

;; GUI settings
(if (fboundp 'menu-bar-mode)
        (menu-bar-mode -1))
(if (fboundp 'tool-bar-mode)
         (tool-bar-mode -1))
(if (fboundp 'blink-cursor-mode)
    (blink-cursor-mode 0))

;; Font settings
;; (cond
;;  ((string-equal system-type "darwin")
;;   (progn
;;     (add-to-list 'default-frame-alist '(font . "Monaco-14"))
;;     (set-fontset-font "fontset-default" 'big5' ("Heiti TC" . "unicode-bmp"))))
;;  ((string-equal system-type "gnu/linux")
;;   (progn
;;     (add-to-list 'default-frame-alist '(font . "Inconsolata-14"))))
;;  ((string-equal system-type "windows-nt")
;;   (progn
;;     (add-to-list 'default-frame-alist '(font . "Consolas-14"))
;;     (set-fontset-font "fontset-default" 'big5' ("微軟正黑體" . "unicode-bmp"))))
;;  )

;; Launch emacsclient maximized from the commandline
;; 1. $ emacsclient -nc -F "((fullscreen . maximized))"
;; 2. $ emacsclient -nc -F "((fullscreen . fullboth))"
(add-to-list 'default-frame-alist '(fullscreen . maximized))
;; Set the frame title in the titlebar
(setq frame-title-format (list "Emacs - " (getenv "USERNAME") "@" system-name ": "
                               '(buffer-file-name
                                 "%f"
                                 (dired-directory dired-directory "%b"))))

(desktop-save-mode 1)

;; Disable the menu bar
(menu-bar-mode -1)

;; Disable backslash character in line wrapping
(set-display-table-slot standard-display-table 'wrap ?\ )

;; Move cursor by camelCase
(global-subword-mode 1)
;; (add-hook 'prog-mode-hook 'subword-mode)

;; Fix: subword-backward skips script boundaries (e.g. Latin <-> CJK)
(defun my/subword-backward-with-script-boundary ()
  "Like `subword-backward-internal' but also stop at script boundaries.
Prevents backward word motion from skipping across Latin/CJK transitions."
  (let ((start (point)))
    (subword-backward-internal)
    (let ((end (point)))
      (when (< end start)
        ;; Scan backward from start to find the nearest script boundary
        (let ((pos (1- start)))
          (while (> pos end)
            (let* ((c1 (char-after (1- pos)))
                   (c2 (char-after pos))
                   (s1 (and c1 (aref char-script-table c1)))
                   (s2 (and c2 (aref char-script-table c2))))
              (when (and s1 s2
                         (eq (char-syntax c1) ?w)
                         (eq (char-syntax c2) ?w)
                         (not (eq s1 s2)))
                (goto-char pos)
                (setq pos end)))  ; break
            (setq pos (1- pos))))))))

(setq subword-backward-function #'my/subword-backward-with-script-boundary)

;; Switch focus after buffer split in emacs.
;; https://stackoverflow.com/questions/6464738/how-can-i-switch-focus-after-buffer-split-in-emacs
(defun split-window-vertically-and-focus ()
  "Split the window vertically and switch to the new window."
  (interactive)
  (split-window-vertically)
  (other-window 1))

(defun split-window-horizontally-and-focus ()
  "Split the window horizontally and switch to the new window."
  (interactive)
  (split-window-horizontally)
  (other-window 1))

(global-set-key "\C-x2" 'split-window-vertically-and-focus)
(global-set-key "\C-x3" 'split-window-horizontally-and-focus)

;; This is a workaround for the issue of large minified files of
;; programming code (i.e., code that has been compacted into the
;; smallest file size possible, which often entails removing newlines
;; should they not be strictly necessary) bringing Emacs to its knees
;; on account of the relevant modes not being (remotely) optimised for
;; that use-case. (Requires Emacs >= 27)
(global-so-long-mode 1)

;; Finding Non Ascii Characters
;; https://www.emacswiki.org/emacs/FindingNonAsciiCharacters
(defun occur-non-ascii ()
  "Find any non-ascii characters in the current buffer."
  (interactive)
  (occur "[^[:ascii:]]"))

;; Keeping buffers automatically up-to-date.
(global-auto-revert-mode 1)

;; Disable VC backend to prevent Git index.lock conflicts with auto-revert-mode
;; This prevents Emacs from freezing when using emacsclient with Git operations
(setq vc-handled-backends nil)

;; Silently discard stray CSI ? (private mode) terminal responses that
;; tmux may relay during session switches, preventing garbage text and
;; unwanted Help buffers.
(add-hook 'terminal-init-xterm-hook
          (lambda ()
            (when (getenv "TMUX")
              (define-key input-decode-map "\e[?"
                (lambda (_prompt)
                  (let (ch)
                    (while (and (setq ch (read-event nil nil 0.1))
                                (not (and (characterp ch) (<= ?@ ch ?~))))
                      (unless (characterp ch)
                        (push ch unread-command-events))))
                  [])))))

(provide 'init-global)
