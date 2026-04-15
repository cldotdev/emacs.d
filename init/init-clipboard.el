(unless noninteractive
  (cond ((eq system-type 'gnu/linux)
         (require 'init-clipetty))
        ((eq system-type 'darwin)
         (require 'init-osx-clipboard-mode))))

(provide 'init-clipboard)
