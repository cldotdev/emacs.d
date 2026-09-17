;;; -*- lexical-binding: t; -*-
(add-to-list 'load-path "~/.emacs.d/package/vlf")

;; `vlf-setup' advises `abort-if-file-too-large', so a file past
;; `large-file-warning-threshold' offers VLF instead of the plain
;; "really open?" prompt.  It autoloads `vlf', so `M-x vlf' still works
;; without loading the rest up front.
(require 'vlf-setup)

(provide 'init-vlf-mode)
