;;; -*- lexical-binding: t; -*-
;; Single source of truth for tree-sitter grammar repositories and pinned
;; revisions. Consumed by interactive Emacs (via `require') and by
;; `make grammars' (via batch Emacs) so both produce identical .so files.
;;
;; The positional tag entries are the latest tags whose parser.c targets
;; ABI 14, which libtree-sitter loads at ABI 14 and 15 alike. The entries
;; using the `:commit' form mirror the commits that Emacs 31.1's own modes
;; declare, so each mode gets the grammar it was written against.

(require 'treesit)

(add-to-list 'treesit-extra-load-path
             (expand-file-name "tree-sitter/" user-emacs-directory))

(setq treesit-language-source-alist
      `((javascript "https://github.com/tree-sitter/tree-sitter-javascript"     "v0.23.1")
        (typescript "https://github.com/tree-sitter/tree-sitter-typescript"     "v0.23.2" "typescript/src")
        (tsx        "https://github.com/tree-sitter/tree-sitter-typescript"     "v0.23.2" "tsx/src")
        (rust       "https://github.com/tree-sitter/tree-sitter-rust"           "v0.23.3")
        (toml       "https://github.com/tree-sitter-grammars/tree-sitter-toml"  "v0.7.0")
        (python     "https://github.com/tree-sitter/tree-sitter-python"         "v0.23.6")
        (ruby       "https://github.com/tree-sitter/tree-sitter-ruby"           "v0.23.1")
        (go         "https://github.com/tree-sitter/tree-sitter-go"             "v0.23.4")
        (json       "https://github.com/tree-sitter/tree-sitter-json"           "v0.24.8")
        (css        "https://github.com/tree-sitter/tree-sitter-css"            "v0.23.2")
        (bash       "https://github.com/tree-sitter/tree-sitter-bash"           "v0.23.3")
        (dockerfile "https://github.com/camdencheek/tree-sitter-dockerfile"     "v0.2.0")
        (yaml       "https://github.com/tree-sitter-grammars/tree-sitter-yaml"  "v0.7.2")
        (c          "https://github.com/tree-sitter/tree-sitter-c"
                    :commit "3aa2995549d5d8b26928e8d3fa2770fd4327414e")
        (cpp        "https://github.com/tree-sitter/tree-sitter-cpp"
                    :commit "f41b4f66a42100be405f96bdc4ebc4a61095d3e8")
        (html       "https://github.com/tree-sitter/tree-sitter-html"
                    :commit "d9219ada6e1a2c8f0ab0304a8bd9ca4285ae0468")
        (jsdoc      "https://github.com/tree-sitter/tree-sitter-jsdoc"
                    :commit "b253abf68a73217b7a52c0ec254f4b6a7bb86665")
        (phpdoc     "https://github.com/claytonrcarter/tree-sitter-phpdoc"
                    :commit "03bb10330704b0b371b044e937d5cc7cd40b4999")
        ;; Same ABI split as `php-ts-mode--language-source-alist'.
        (php        "https://github.com/tree-sitter/tree-sitter-php"
                    :commit ,(if (and (treesit-available-p)
                                      (< (treesit-library-abi-version) 15))
                                 "f7cf7348737d8cff1b13407a0bfedce02ee7b046"
                               "5b5627faaa290d89eb3d01b9bf47c3bb9e797dea")
                    :source-dir "php/src")))

(provide 'init-treesit-grammars)
