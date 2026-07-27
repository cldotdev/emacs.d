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
- Ordered Markdown lists renumber themselves when `RET` inserts an item or an item changes its indentation level
- Text nested under a Markdown list item, be it another item or a continuation line, lines up with the content column of the item that holds it, rather than a fixed indent width
- Emacsclient temp files adopt the caller's working directory, so relative path completion works in e.g. Claude Code prompt files
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
| `RET` | my/markdown-insert-list-item-on-enter (continue the list at point and renumber it; shadows the default markdown-enter-key) |
| `TAB` | markdown-cycle (cycle the line at point through the columns it can nest at under the list above, then renumber the list; the stock binding, with the columns from my/markdown-indent-line and the renumbering from advice) |
| `<backtab>` | markdown-promote (move the list item at point out one level, nested items included, then renumber the list; shadows markdown-shifttab, whose global heading cycling stays on `C-u TAB`) |
| `C-c C-=` | markdown-demote (move the list item at point in one level, nested items included, then renumber the list; the stock binding, with both behaviors added by advice) |
| `C-c C-c n` | my/markdown-renumber-list-at-point (renumber the list at point, restarting each nested level at 1 and leaving code blocks and the first item of the outermost level alone; shadows markdown-cleanup-list-numbers, which stays available through `M-x`) |
| `C-c TAB` | my/markdown-table-compress (compress the table at point) |
| `C-c \|` | my/markdown-table-compress-buffer (compress all tables in the buffer) |
| `C-c C-x i` | markdown-insert-image (relocated from `C-c C-i`, which `C-c TAB` shadows in a terminal) |
| `C-c q` | my/markdown-toggle-blockquote (quote or unquote the region, or the line at point; the built-in `C-c C-s q` and `C-c C-s Q` only ever add a marker) |
| `M-;` | my/gfm-comment-dwim (comment with the syntax of the code block's language inside a fence and with HTML comments outside; gfm-mode only, shadows the global comment-dwim-line) |

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
