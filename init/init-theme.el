;;; -*- lexical-binding: t; -*-
;; color theme
;; (add-to-list 'load-path "~/.emacs.d/package/color-theme")
;; (require 'color-theme)
;; (require 'color-theme-customized)
;; (color-theme-initialize)
;; (color-theme-customized)
;; (color-theme-select)
;; (color-theme-comidia)

;; customized faces for python mode
;; (font-lock-add-keywords 'python-mode
;;                         '(;;("\\<\\(object\\|str\\|else\\|except\\|finally\\|try\\|\\)\\>" 0 'py-builtins-face)  ; adds object and str and fixes it so that keywords that often appear with : are assigned as builtin-face
;;                           ;; ("\\<[\\+-]?[0-9]+\\(.[0-9]+\\)?\\>" 0 'font-lock-defaults) ; FIXME: negative or positive prefixes do not highlight to this regexp but does to one below
;;                           ("\\([][{}()~^<>:=,.\\+*/%-]\\)" 0 'font-lock-type-face)))

;; Zenburn-theme
;; https://github.com/bbatsov/zenburn-emacs
;; (add-to-list 'load-path "~/.emacs.d/package/zenburn-emacs")
;; (require 'zenburn-theme)
;; (load-theme 'zenburn t)
;; (custom-set-faces
;;  '(line-number-current-line ((t (:inherit line-number :foreground "#6F6F6F"))))
;; )

;; Nord theme
;; https://github.com/arcticicestudio/nord-emacs
(add-to-list 'custom-theme-load-path "~/.emacs.d/package/nord-emacs")

(if (daemonp)
    (add-hook 'after-make-frame-functions
        (lambda (frame)
            (select-frame frame)
            (load-theme 'nord t)))
    (load-theme 'nord t))

(provide 'init-theme)
