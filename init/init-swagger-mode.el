;;; -*- lexical-binding: t; -*-
(require 'swagger-mode)
(add-to-list 'auto-minor-mode-alist '("\\swagger.y[a]ml\\'" . swagger-mode))
(add-to-list 'auto-minor-mode-alist '("\\swagger.json\\'" . swagger-mode))
(provide 'init-swagger-mode)
