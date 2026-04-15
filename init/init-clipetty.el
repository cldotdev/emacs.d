(add-to-list 'load-path "~/.emacs.d/package/clipetty")
(require 'clipetty)

(unless (display-graphic-p)
  (global-clipetty-mode 1))

(provide 'init-clipetty)
