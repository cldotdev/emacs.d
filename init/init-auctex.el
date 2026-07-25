;;; -*- lexical-binding: t; -*-
(add-to-list 'load-path "~/.emacs.d/package/auctex")
(add-to-list 'load-path "~/.emacs.d/package/auctex/preview")

(load "auctex.el" nil t t)
(load "preview-latex.el" nil t t)
(setq TeX-auto-save t)
(setq TeX-parse-self t)
(setq-default TeX-master nil)
(setq TeX-PDF-mode t)
(setq TeX-view-program-selection '((output-pdf "Okular")))

;; Auto complete for auctex
(require 'auto-complete-auctex)

;; Set XeLaTeX
(load "preview-latex.el" nil t t)
(setq TeX-engine-alist
      '((xelatex "XeLaTeX" "xetex" "xelatex" "xelatex")))
(add-hook 'LaTeX-mode-hook
          '(lambda ()
              (setq TeX-engine 'xelatex)))
(add-hook 'LaTeX-mode-hook (lambda()
                             (add-to-list 'TeX-command-list '("XeLaTeX" "%`xelatex%(mode)%' %t" TeX-run-TeX nil t))
                             (setq TeX-command-default "XeLaTeX")
                             (setq TeX-save-query  nil )
                             (setq TeX-show-compilation nil)
                             (flyspell-mode t)
                             ))

;; anything and LaCarte for Math Input
(setq LaTeX-math-menu-unicode t)
(define-key LaTeX-mode-map [?\M-`] 'anything-math-symbols)
(defvar anything-c-source-lacarte-math
  '((name . "Math Symbols")
    (init . (lambda()
              (setq anything-c-lacarte-major-mode major-mode)))
    (candidates
     . (lambda () (if (eq anything-c-lacarte-major-mode 'latex-mode)
                      (delete '(nil) (lacarte-get-a-menu-item-alist LaTeX-math-mode-map)))))
    (action . (("Open" . (lambda (candidate)
                           (call-interactively candidate)))))))
(defun anything-math-symbols ()
  "Anything for searching math menus"
  (interactive)
  (anything '(anything-c-source-lacarte-math)
            (thing-at-point 'symbol) "Symbol: "
	    nil nil "*anything math symbols*"))

(provide 'init-auctex)
