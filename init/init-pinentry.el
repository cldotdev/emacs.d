(setq epa-pinentry-mode 'loopback)

(with-eval-after-load 'magit
  (setq magit-git-global-arguments
        (append magit-git-global-arguments
                '("-c" "gpg.program=gpg-loopback"))))

(provide 'init-pinentry)
