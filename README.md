# Emacs configuration

## Features

* Python (`python-ts-mode` + Eglot + Pyright + ruff)
* Java (`java-ts-mode`)
* JavaScript / TypeScript (`js-ts-mode`, `typescript-ts-mode`, `tsx-ts-mode`)
* Lisp (SLIME)
* Markdown
* Git (Magit)
* Completion (Corfu)
* On-the-fly syntax checks (Flycheck)
* Tree-sitter grammars pinned in `init/init-treesit-grammars.el`

## Requirements

* emacs >= 30
* git (Magit)
* clisp (SLIME)
* gcc (or cc) and git on PATH (tree-sitter grammar build)
* pyright-langserver and ruff on PATH (Python Eglot)

## Setting up

1. Clone this repository to your `$HOME/.emacs.d` directory:

    ```bash
    git clone --recursive https://github.com/cldotdev/emacs.d ~/.emacs.d
    ```

2. After the cloning, create a symbolic link to `~/init.el`:

    ```bash
    ln -s ~/.emacs.d/init.el ~/
    ```

3. Compilation:

    ```bash
    cd ~/.emacs.d/
    make
    ```

## Keymaps

### Global

* `M-;`: comment-dwim-line
* `C-_`: undo-tree-undo
* `M-_`: undo-tree-redo
* `M-up`: move-line-up
* `M-down`: move-line-down
* `C-j`: end-of-line-and-indent-new-line
* `M-#`: query-replace-regexp

### SLIME

* `M-x slime`: Start SLIME REPL
* `M- M-x slime RET <lisp>`: Start SLIME REPL with specified lisp program

*SLIME REPL*

* `, q`: Quit SLIME

[SLIME REPL documentation](http://common-lisp.net/project/slime/doc/html/REPL.html#REPL)

*lisp-mode*

* `C-c C-k`: slime-compile-and-load-file
* `C-c C-c`: slime-compile-defun
* `C-up`: slime-repl-forward-input
* `C-down`: slime-repl-backward-input
