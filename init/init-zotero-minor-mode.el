;;; -*- lexical-binding: t; -*-
;; C-c z c         zotelo-set-collection (also C-c z s)
;; C-c z u         zotelo-update-database
;; C-c z e         zotelo-export-secondary
;; C-c z r         zotelo-reset
;; C-c z t         zotelo-set-translator

(require 'zotelo)
(add-hook 'TeX-mode-hook 'zotelo-minor-mode)

(provide 'init-zotero-minor-mode)
