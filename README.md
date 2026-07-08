# Emacs Configuration

## Features

- Python (`python-ts-mode` + Eglot + Pyright + ruff)
- Java (`java-ts-mode`)
- JavaScript / TypeScript (`js-ts-mode`, `typescript-ts-mode`, `tsx-ts-mode`)
- Lisp (SLIME)
- Markdown
- Git (Magit)
- Completion (Corfu)
- On-the-fly syntax checks (Flycheck)
- Emacsclient temp files adopt the caller's working directory, so
  relative path completion works in e.g. Claude Code prompt files
- Tree-sitter grammars pinned in `init/init-treesit-grammars.el`

## Requirements

- emacs >= 30
- git (Magit)
- clisp (SLIME)
- gcc (or cc) and git on PATH (tree-sitter grammar build)
- pyright-langserver and ruff on PATH (Python Eglot)

## Setting Up

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

| Key | Action |
| --- | --- |
| `M-;` | comment-dwim-line |
| `C-_` | undo-tree-undo |
| `M-_` | undo-tree-redo |
| `M-up` | move-line-up |
| `M-down` | move-line-down |
| `C-j` | end-of-line-and-indent-new-line |
| `M-#` | query-replace-regexp |

### Markdown

| Key | Action |
| --- | --- |
| `C-c TAB` | my/markdown-table-compress (compress the table at point) |
| `C-c \|` | my/markdown-table-compress-buffer (compress all tables in the buffer) |
| `C-c C-x i` | markdown-insert-image (relocated from `C-c C-i`, which `C-c TAB` shadows in a terminal) |

### SLIME

| Key | Action |
| --- | --- |
| `M-x slime` | Start SLIME REPL |
| `M- M-x slime RET <lisp>` | Start SLIME REPL with specified lisp program |

**SLIME REPL**

| Key | Action |
| --- | --- |
| `, q` | Quit SLIME |

[SLIME REPL documentation](http://common-lisp.net/project/slime/doc/html/REPL.html#REPL)

**lisp-mode**

| Key | Action |
| --- | --- |
| `C-c C-k` | slime-compile-and-load-file |
| `C-c C-c` | slime-compile-defun |
| `C-up` | slime-repl-forward-input |
| `C-down` | slime-repl-backward-input |
