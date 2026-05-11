;; Single source of truth for tree-sitter grammar repositories and pinned
;; revisions. Consumed by interactive Emacs (via `require') and by
;; `make grammars' (via batch Emacs) so both produce identical .so files.
;;
;; All revisions below are pinned to the latest tag whose parser.c still
;; targets ABI 14, which is the maximum supported by Emacs 30.2 (its
;; bundled libtree-sitter has TREE_SITTER_LANGUAGE_VERSION = 14). Bumping
;; past these tags requires either downgrading to an --abi 14 build via
;; tree-sitter CLI, or upgrading to an Emacs that supports ABI 15.

(require 'treesit)

(add-to-list 'treesit-extra-load-path
             (expand-file-name "tree-sitter/" user-emacs-directory))

(setq treesit-language-source-alist
      '((javascript "https://github.com/tree-sitter/tree-sitter-javascript"     "v0.23.1")
        (typescript "https://github.com/tree-sitter/tree-sitter-typescript"     "v0.23.2" "typescript/src")
        (tsx        "https://github.com/tree-sitter/tree-sitter-typescript"     "v0.23.2" "tsx/src")
        (rust       "https://github.com/tree-sitter/tree-sitter-rust"           "v0.23.3")
        (toml       "https://github.com/tree-sitter-grammars/tree-sitter-toml"  "v0.7.0")
        (python     "https://github.com/tree-sitter/tree-sitter-python"         "v0.23.6")
        (ruby       "https://github.com/tree-sitter/tree-sitter-ruby"           "v0.23.1")
        (go         "https://github.com/tree-sitter/tree-sitter-go"             "v0.23.4")
        (java       "https://github.com/tree-sitter/tree-sitter-java"           "v0.23.5")
        (json       "https://github.com/tree-sitter/tree-sitter-json"           "v0.24.8")
        (css        "https://github.com/tree-sitter/tree-sitter-css"            "v0.23.2")
        (bash       "https://github.com/tree-sitter/tree-sitter-bash"           "v0.23.3")
        (dockerfile "https://github.com/camdencheek/tree-sitter-dockerfile"     "v0.2.0")
        (yaml       "https://github.com/tree-sitter-grammars/tree-sitter-yaml"  "v0.7.2")))

(provide 'init-treesit-grammars)
