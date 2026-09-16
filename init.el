;;; Emacs configuration  -*- lexical-binding: t -*-
;;; requirement: emacs >= 30

;; (byte-recompile-directory (expand-file-name "~/.emacs.d") 0)

;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(package-initialize)

(add-to-list 'load-path "~/.emacs.d/init")
(add-to-list 'load-path "~/.emacs.d/package")

;; These packages are vendored as submodules, so a `lexical-binding'
;; cookie added here would be lost on the next `git submodule update'.
;; Listing each file leaves the warning in place for everything else.
(setq warning-inhibit-types
      '((files missing-lexbind-cookie "~/.emacs.d/package/imenu-list/imenu-list.el")
        (files missing-lexbind-cookie "~/.emacs.d/package/nord-emacs/nord-theme.el")
        (files missing-lexbind-cookie "~/.emacs.d/package/osx-clipboard-mode/osx-clipboard.el")
        (files missing-lexbind-cookie "~/.emacs.d/package/parent-mode/parent-mode.el")
        (files missing-lexbind-cookie "~/.emacs.d/package/s.el/s.el")
        (files missing-lexbind-cookie "~/.emacs.d/package/slime/slime-autoloads.el")
        (files missing-lexbind-cookie "~/.emacs.d/package/yard-mode.el/yard-mode.el")))

;; Theme
(require 'init-theme)

(require 'init-global)
(require 'init-mise)
(require 'init-ibuffer)
(require 'init-auto-minor-mode)

;; GCMH - the Garbage Collector Magic Hack
(require 'init-gcmh)

;; flycheck
(require 'init-flycheck)

;; Visual Fill Column
;; https://github.com/joostkremers/visual-fill-column
(require 'init-visual-fill-column)

;; corfu
;; Compact inline completion popup.  Terminal Emacs before 31 renders
;; it with popon to avoid the line-number / wide-CJK display artifacts
;; caused by company-pseudo-tooltip's overlay-based popup.
;; https://github.com/minad/corfu
(require 'init-corfu)

;; Magit - an emacs mode for interacting with the Git version control system
;; http://magit.github.io/magit/index.html
(require 'init-magit)

;; GPG loopback pinentry for passphrase prompt in minibuffer
(require 'init-pinentry)

;; insert-time
;; https://github.com/rmm5t/insert-time.el
(require 'init-insert-time)

;; indent-bars
(require 'init-indent-bars)

;; markdown mode
;; http://jblevins.org/projects/markdown-mode/
;; requirements: gfm preview: https://github.com/Gagle/Node-GFM
(require 'init-markdown-mode)

;; multiple cursors
;; https://github.com/emacsmirror/multiple-cursors
(require 'init-multiple-cursors)

;; Tree-sitter grammar repos / pinned revisions (single source of truth,
;; consumed by both interactive Emacs and `make grammars').
(require 'init-treesit-grammars)

;; Eglot (LSP) - built into Emacs 30. Wires pyright for python-ts-mode.
(require 'init-eglot)

;; Terminal clipboard integration
;; gnu/linux: clipetty for OSC 52 based clipboard sync
;; darwin: osx-clipboard-mode for pbcopy/pbpaste integration
(require 'init-clipboard)

;; Emacs server integration
;; Temp files visited via emacsclient adopt the caller's working
;; directory, so relative path completion works in e.g. Claude Code
;; ctrl-g prompt files.
(require 'init-server)

;; hightlight symbol
(require 'init-highlight-symbol)

;; vlf-mode - view large files
(require 'init-vlf-mode)

(require 'init-vertico)

;; visible mark
;; http://retroj.net/visible-mark
(require 'init-visible-mark)

;; La Carte
(require 'init-larcarte)

;; helm
(require 'init-helm)

;; undo tree
(require 'init-undo-tree)

;; erc
(require 'init-erc)

;; slime
;; http://www.common-lisp.net/project/slime/
;; https://github.com/slime/slime
(require 'init-slime)

(require 'init-makefile-mode)

;; web-mode
;; http://web-mode.org/
(require 'init-web-mode)

;; languages
(require 'init-sh-mode)
(require 'init-python-mode)
(require 'init-css-mode)
(require 'init-c-mode)
(require 'init-cheetah-mode)

;; php-mode
;; https://github.com/ejmr/php-mode
(require 'init-php-mode)

;; Modern JS/TS via Emacs 30 built-in treesit
(require 'init-js-ts)

(require 'init-go-mode)
(require 'init-go-mod-mode)

;; rust-mode
(require 'init-rust-mode)

(require 'init-yaml-mode)

(require 'init-json-mode)

;; toml-mode
(require 'init-toml)

(require 'init-dockerfile-mode)

;; csv-mode
;; http://elpa.gnu.org/packages/csv-mode.html
(require 'csv-mode)

;; ruby-mode
(require 'init-ruby-mode)

;; nginx-mode
;; https://github.com/ajc/nginx-mode
(require 'init-nginx-mode)

;; chinese-conv
;; A front end in emacs to convert between simplified and traditional Chinese with opencc or cconv.
;; https://github.com/gucong/emacs-chinese-conv
(require 'init-chinese-conv)

;; dumb-jump
;; an Emacs "jump to definition" package for 50+ languages
;; https://github.com/jacktasia/dumb-jump
(require 'init-dumb-jump)

;; sql-mode
(require 'init-sql-mode)

;; emacs-hcl-mode
;; Major mode for Hashicorp Configuration Language.
;; https://github.com/purcell/emacs-hcl-mode
(require 'init-hcl-mode)

;; highlight-numbers
;; An Emacs minor mode that highlights numeric literals in source code.
;; https://github.com/Fanael/highlight-numbers
(require 'init-highlight-numbers)

;; tree-sitter
;; https://github.com/emacs-tree-sitter/elisp-tree-sitter
(require 'init-tree-sitter)

;; imenu-list
;; https://github.com/bmag/imenu-list
(require 'init-imenu)
