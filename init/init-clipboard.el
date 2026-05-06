(cond ((eq system-type 'gnu/linux)
       (require 'init-clipetty))
      ;; init-osx-clipboard-mode activates its mode at load; skip under batch.
      ((and (eq system-type 'darwin) (not noninteractive))
       (require 'init-osx-clipboard-mode)))

(provide 'init-clipboard)
