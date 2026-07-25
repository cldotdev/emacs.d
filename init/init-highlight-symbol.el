;;; -*- lexical-binding: t; -*-
(require 'highlight-symbol)

(global-set-key [(f8)] 'highlight-symbol-at-point)
(global-set-key [(f9)] 'highlight-symbol-remove-all)

;; Nord theme Aurora colors
(setq highlight-symbol-colors
      '("#bf616a" "#d08770" "#ebcb8b" "#a3be8c" "#b48ead"))

(provide 'init-highlight-symbol)
