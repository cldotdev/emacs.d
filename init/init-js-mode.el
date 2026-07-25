;;; -*- lexical-binding: t; -*-
;; js-mode
(setq js-indent-level 2)
(add-to-list 'auto-mode-alist '("\\.gs$" . js-mode))

;; Bind M-. to find-tag
(eval-after-load 'js
  (define-key js-mode-map (kbd "M-.") nil))

;; tern-mode
;; (add-to-list 'load-path "~/.emacs.d/package/tern")
;; (autoload 'tern-mode "tern.el" nil t)
;; (add-hook 'js2-mode-hook (lambda () (tern-mode t)))
;; (defun my-tern-ac-complete ()
;;   "Complete code at point by tern."
;;   (interactive)
;;   (tern-ac-complete-request
;;    (lambda ()
;;      (let ((ac-sources (cons 'ac-source-tern-completion ac-sources)))
;;        (auto-complete)))))
;; (eval-after-load 'tern
;;   '(progn
;;      (require 'tern-auto-complete)
;;      (setq tern-ac-on-dot nil)
;;      (define-key tern-mode-keymap (kbd "C-.") 'my-tern-ac-complete)
;;      (tern-ac-setup)))

;; skewer-mode
(add-to-list 'load-path "~/.emacs.d/package/emacs-web-server")
(add-to-list 'load-path "~/.emacs.d/package/js2-mode")
(add-to-list 'load-path "~/.emacs.d/package/skewer-mode")
(require 'skewer-mode)
(add-hook 'js2-mode-hook 'skewer-mode)
(add-hook 'css-mode-hook 'skewer-css-mode)
(add-hook 'html-mode-hook 'skewer-html-mode)

;; nodejs-repl
(require 'nodejs-repl)

;; js-doc
;; https://github.com/mooz/js-doc
(add-to-list 'load-path "~/.emacs.d/package/js-doc")
(require 'js-doc)

(add-hook 'js-mode-hook
          '(lambda ()
             (define-key js-mode-map "\C-ci" 'js-doc-insert-function-doc)
             (define-key js-mode-map "@" 'js-doc-insert-tag)))

(provide 'init-js-mode)
