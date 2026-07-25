;;; -*- lexical-binding: t; -*-
(add-to-list 'load-path "~/.emacs.d/package/ess-13.05/lisp")

(require 'ess-site)
(setq ess-eval-visibly-p nil)
(setq ess-ask-for-ess-directory nil)

;; ESS smart underscore
(add-to-list 'load-path "~/.emacs.d/package/ess-smart-underscore-0.74")
(require 'ess-smart-underscore)

;;; ESS auto complete
(add-to-list 'load-path "~/.emacs.d/package/auto-complete-1.4")
(require 'ac-R)

(provide 'init-ess)
