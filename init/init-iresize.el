;;; -*- lexical-binding: t; -*-
(defvar iresize-mode-map
  (let ((m (make-sparse-keymap)))
    (define-key m (kbd "j") 'enlarge-window)
    (define-key m (kbd "k") 'shrink-window)
    (define-key m (kbd "f") 'enlarge-window-horizontally)
    (define-key m (kbd "d") 'shrink-window-horizontally)
    (define-key m (kbd "0") 'balance-windows)
    (define-key m (kbd "q") 'iresize-mode)
    m))

(define-minor-mode iresize-mode
  :initial-value nil
  :lighter " IResize"
  :keymap iresize-mode-map
  :group 'iresize)

(global-set-key (kbd "C-x w") 'iresize-mode)

(provide 'init-iresize)
