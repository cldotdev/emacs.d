;;; -*- lexical-binding: t; -*-
(add-to-list 'load-path "~/.emacs.d/package/ace-jump-mode")

(autoload
  'ace-jump-mode
  "ace-jump-mode"
  "Emacs quick move minor mode"
  t)

;; you can select the key you prefer to
(define-key global-map (kbd "C-c SPC") 'ace-jump-mode)

;; enable a more powerful jump back function from ace jump mode
(autoload
  'ace-jump-mode-pop-mark
  "ace-jump-mode"
  "Ace jump back:-)"
  t)
(eval-after-load "ace-jump-mode"
  '(ace-jump-mode-enable-mark-sync))
(define-key global-map (kbd "C-x SPC") 'ace-jump-mode-pop-mark)

;; if you use viper mode :
;; (define-key viper-vi-global-user-map (kbd "SPC") 'ace-jump-mode)
;; if you use evil
;; (define-key evil-normal-state-map (kbd "SPC") 'ace-jump-mode)

;; disable gray background
(setq ace-jump-mode-gray-background nil)

;; set ace-jump-face
(defface ace-jump-face-foreground
  '((((class color)) (:foreground "black" :background "light goldenrod"))
    (((background dark)) (:foreground "gray100"))
    (((background light)) (:foreground "gray0"))
    (t (:foreground "gray100")))
  "Face for foreground of AceJump motion"
  :group 'ace-jump)

;; set submode-list
(setq ace-jump-mode-submode-list
      '(ace-jump-char-mode              ;; the first one always map to : C-c SPC
        ace-jump-word-mode              ;; the second one always map to: C-u C-c SPC
        ace-jump-line-mode) )           ;; the third one always map to ：C-u C-u C-c SPC

;; move keys
(require 'cl-lib)
(setq ace-jump-mode-move-keys
      (cl-loop for i from ?a to ?z collect i))

(provide 'init-ace-jump-mode)
