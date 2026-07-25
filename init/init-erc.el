;;; -*- lexical-binding: t; -*-
;; erc: hide join part messages
(setq erc-hide-list '("JOIN" "PART" "QUIT"))
(setq erc-log-channels t)
(setq erc-log-channels-directory "~/.emacs.d/erc/log/")
(setq erc-log-insert-log-on-open t)
(setq erc-hide-timestamps nil)
(setq erc-log-file-coding-system 'utf-8)
(add-hook 'erc-insert-post-hook 'erc-save-buffer-in-logs)

(provide 'init-erc)
