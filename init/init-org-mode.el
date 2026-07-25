;;; -*- lexical-binding: t; -*-
(add-to-list 'load-path "~/.emacs.d/package/org/lisp")
(add-to-list 'load-path "~/.emacs.d/package/org/contrib/lisp" t)

(require 'org-install)

;; Markdown Back-End for Org Export Engine
(eval-after-load "org"
  '(require 'ox-md nil t))

(global-set-key "\C-cc" 'org-capture)
(global-set-key "\C-cl" 'org-store-link)
(global-set-key "\C-ca" 'org-agenda)
(global-set-key "\C-cb" 'org-iswitchb)

(setq org-agenda-files '("~/.emacs.d/org-notes"))

;; Initial visibility
(setq org-startup-folded 'content)

;; Add the date to the CLOSED tag
(setq org-log-done 'time)

;; Pretty fontification of source code blocks
(setq org-src-fontify-natively t)

(setq org-todo-keywords
      '((sequence "NOTE" "TODO" "|" "DONE" "CANCELED")
        (sequence "|" "OK" "GOOD" "BAD")))

(setq org-todo-keywords-for-agenda
      '("TODO" "DONE" "CANCELED"))

(setq org-todo-keyword-faces
      '(("CANCELED" . (:foreground "blue" :weight bold))
        ("NOTE" . (:foreground "yellow" :weight bold))))

(setq org-latex-pdf-process '("xelatex -interaction nonstopmode %f"
                              "xelatex -interaction nonstopmode %f"))

;; Set to the location of your Org files on your local system
(setq org-directory "~/.emacs.d/org-notes")
;; Set to the name of the file where new notes will be stored
(setq org-mobile-inbox-for-pull "~/.emacs.d/org-notes/mobile.org")
;; Set to <your Dropbox root directory>/MobileOrg.
(setq org-mobile-directory "~/Dropbox/Apps/MobileOrg")

;; Emacs org-mode file/viewer associations
(add-hook 'org-mode-hook
          '(lambda ()
             (setq org-file-apps
                   (append '(
                             ("\\.png\\'" . default)
                             ("\\.jpe?g\\'" . default)
                             ("\\.gif\\'" . default)
                             ("\\.svg\\'" . default)
                             ) org-file-apps ))))

(provide 'init-org-mode)
