# Emacs Configuration

## Features

### Languages

- Python: `python-ts-mode` with Eglot and Pyright for type checking, and ruff for linting through Flycheck
- JavaScript / TypeScript: `js-ts-mode`, `typescript-ts-mode`, `tsx-ts-mode`
- Go: `go-ts-mode` and `go-mod-mode`, with `M-x golint`
- Rust: `rust-mode` deriving from tree-sitter, with flycheck-rust
- Ruby: `ruby-ts-mode` with yard-mode, ruby-end, and RuboCop run through mise and bundler
- Common Lisp: SLIME
- PHP: `php-mode`
- C: `c-mode`
- SQL: `sql-mode`, formatted by sql-formatter
- Shell: `sh-mode`, checked by ShellCheck
- Markdown: `markdown-mode` and `gfm-mode`, with the list and table behaviour below
- Web templates: `web-mode` and `cheetah-mode`
- Data and configuration: YAML, JSON, TOML, Dockerfile, CSV, nginx, HCL

### Editing

- Minibuffer completion with Vertico and Orderless, including directory navigation, a grid layout for files, and per-category layouts
- In-buffer completion with Corfu and Cape. Emacs 31 draws the popup on a terminal itself; earlier versions fall back to popon through corfu-terminal, which avoids the line-number and wide-CJK display artifacts
- On-the-fly syntax checks with Flycheck
- Git with Magit and Forge
- undo-tree, multiple-cursors, imenu-list, indent-bars, highlight-symbol, highlight-numbers, visible-mark, window-numbering
- Helm, loaded for its own `helm-` commands; nothing is rebound to it
- dumb-jump for jumping to a definition without a language server
- VLF for files too large to visit whole
- Nord theme
- Terminal clipboard integration: OSC 52 through clipetty on GNU/Linux, pbcopy and pbpaste on macOS
- mise supplies PATH and the rest of the environment at startup
- Emacsclient temp files adopt the caller's working directory, so relative path completion works in e.g. Claude Code prompt files
- Tree-sitter grammars pinned in `init/init-treesit-grammars.el`

### Markdown Lists and Tables

- Ordered lists renumber themselves when `RET` inserts an item or an item changes its indentation level
- Text nested under a list item, be it another item or a continuation line, lines up with the content column of the item that holds it, rather than a fixed indent width
- `DEL` right after the marker of a list item takes the marker away, leaving the line indented as a continuation of the item above; further presses unindent the line through the same columns `TAB` cycles through
- Tables can be compressed to their narrowest padding, one table or the whole buffer at a time

## Requirements

- emacs >= 30
- git, for Magit and for the tree-sitter grammar build
- gcc (or cc), for the tree-sitter grammar build

Each of the following is needed only by the feature named beside it, and everything else keeps working without it:

- clisp: SLIME
- pyright-langserver, ruff: Python
- mise: the startup environment, and the RuboCop wrapper that runs `mise x -- bundle exec rubocop`
- shellcheck: shell linting
- golint: `M-x golint`
- sql-formatter: `C-c C-f` in `sql-mode`
- opencc, with its data under `/usr/local/share/opencc/`: chinese-conv. The path is hardcoded in `init/init-chinese-conv.el`
- gpg-loopback: the gpg wrapper Magit is told to sign with, in `init/init-pinentry.el`

## Setting Up

1. Clone this repository to your `$HOME/.emacs.d` directory:

   ```bash
   git clone --recursive https://github.com/cldotdev/emacs.d ~/.emacs.d
   ```

2. Build:

   ```bash
   cd ~/.emacs.d/
   make
   ```

   `make` byte-compiles the configuration and its packages, then clones and compiles every tree-sitter grammar pinned in `init/init-treesit-grammars.el`, which needs network access. Run `make compile` instead to do the byte-compilation alone.

   `make compile` builds magit and helm through their own makefiles, then walks `init/` and `package/` with `make-compile.el`. Every package is compiled in an Emacs of its own, against the `load-path` the init files add at startup: a batch Emacs starts without that `load-path` and would compile each macro the vendored packages provide into a plain function call, and a shared session lets one package redefine what the next compiles against. Before the walk it deletes every `.elc` that is older than its `.el` or whose `.el` is gone, since `require` would otherwise hand the compiler the stale one.

   `init.el` itself is left uncompiled. It sets `load-prefer-newer`, so an edit under `init/` takes effect at the next start whether or not `make compile` has run since.

## Updating

```bash
cd ~/.emacs.d
make update
```

`make update` pulls with `--ff-only`, syncs and updates every submodule recursively, and then runs `make compile`. It also removes two kinds of leftovers:

- The work tree of a submodule that upstream removed. `git pull` cannot remove it (`warning: unable to rmdir`) and `git submodule update` ignores it, so otherwise it sits in `package/` forever. A directory that holds a git repository git did not create as a submodule work tree is reported and kept.
- `package/helm/helm-autoloads.el`, which `make compile` regenerates. `loaddefs-generate` rewrites the file only when a helm source is newer, and helm's `autoloads` target has no prerequisites to force the rebuild, so upgrading Emacs alone leaves the file in an older format that Emacs 30 and later warn about at startup.

`make update` does not touch the tree-sitter grammars. Run `make grammars` when `init/init-treesit-grammars.el` changes.

## Keymaps

| Mode | Key | Action |
| --- | --- | --- |
| Corfu | `M-n`, `M-j` | corfu-next (move to the next candidate; `C-n`, `C-p` and `C-a` keep their global meaning while the popup is open) |
| Corfu | `M-p`, `M-k` | corfu-previous (move to the previous candidate) |
| Corfu | `M-1` … `M-9`, `M-0` | Insert the first through ninth visible candidate, and with `M-0` the tenth; a lambda over init-corfu--quick-select, with no named command of its own |
| gfm-mode | `M-;` | my/gfm-comment-dwim (comment with the syntax of the code block's language inside a fence and with HTML comments outside; shadows the global comment-dwim-line) |
| Global | `<up>`, `<down>`, `<left>`, `<right>` | windmove-up, windmove-down, windmove-left and windmove-right (move point to the window in that direction). This takes the arrow keys away from plain cursor movement, which stays on `C-p`, `C-n`, `C-b` and `C-f` |
| Global | `M-0` … `M-9` | select-window-0 through select-window-9 (select the window carrying that number, from window-numbering) |
| Global | `C-x 2`, `C-x 3` | split-window-vertically-and-focus and split-window-horizontally-and-focus (split the window and move point into the new one, which the stock commands do not) |
| Global | `C-x C-b` | ibuffer (list buffers, in place of the stock list-buffers) |
| Global | `C-x g` | my/magit-status-follow-symlink (open Magit status, resolving a symlinked working tree to its real path first) |
| Global | `C-x u` | undo-tree-visualize (open the undo history as a tree) |
| Global | `C-_`, `M-_` | undo-tree-undo and undo-tree-redo (step back and forward along the current branch of that tree) |
| Global | `M-w` | kill-ring-save-line-or-region (copy the region, or the whole line when there is no region) |
| Global | `M-;` | comment-dwim-line (comment or uncomment the region, or the line at point) |
| Global | `M-i` | delete-indentation (join the line at point to the one above) |
| Global | `M-#` | query-replace-regexp (replace by regexp, asking at each match) |
| Global | `M-]` | scroll-lock-mode (keep point in place within the window while scrolling) |
| Global | `M-<up>`, `M-<down>` | move-line-up and move-line-down (move the line, or the region, one line up or down) |
| Global | ``M-` ``, `ESC M-x` | lacarte-execute-command (run a menu bar command from the minibuffer) |
| Global | `C-j` | end-of-line-and-indent-new-line (break at the end of the line and indent the new one) |
| Global | `M-x slime`, `C-u M-x slime` | slime (start a REPL with `inferior-lisp-program`, or, with a prefix argument, prompt for the lisp to run) |
| Global | `f8`, `f9` | highlight-symbol-at-point (highlight every occurrence of the symbol at point) and highlight-symbol-remove-all (drop every such highlight) |
| Global | `f12` | Open a shell buffer; a lambda around `shell`, with no named command of its own |
| Global | `C-<f12>` | whitespace-mode (show tabs, trailing space and the rest as visible glyphs) |
| Global | `C-c o` | occur (list every line in the buffer matching a regexp) |
| Global | `C-c t` | toggle-truncate-lines (switch between truncating a long line and wrapping it) |
| Global | `C-c r` | redraw-display (repaint the frame after something else has corrupted it) |
| Global | `C-c p`, `C-c n` | previous-buffer and next-buffer (walk this window's buffer history) |
| Global | `C-c [`, `C-c ]` | xref-go-back and xref-go-forward (walk the stack of definition lookups) |
| Global | `C-c i` | imenu-list-smart-toggle (open or close the imenu side window) |
| Global | `C-c :` | mc/edit-lines (put a cursor on every line of the region) |
| Global | `C-c >`, `C-c <` | mc/mark-next-like-this and mc/mark-previous-like-this (add a cursor at the next or previous occurrence of the symbol at point) |
| Global | `C-c ;` | mc/mark-all-like-this-dwim (add a cursor at every occurrence of the symbol at point) |
| Global | `C-s-<left>`, `C-s-<right>` | buffer-order-prev-mark and buffer-order-next-mark (walk this buffer's mark ring) |
| ibuffer | `C-c g`, `C-c C-g` | ibuffer-vc-set-filter-groups-by-vc-root (group the buffer list by version control root) |
| lisp-mode | `C-c C-k` | slime-compile-and-load-file (compile the buffer's file and load the result) |
| lisp-mode | `C-c C-c` | slime-compile-defun (compile the top-level form at point) |
| markdown-mode | `RET` | my/markdown-insert-list-item-on-enter (continue the list at point and renumber it; shadows the default markdown-enter-key) |
| markdown-mode | `DEL` | my/markdown-delete-marker-on-backspace (replace a list item's marker with spaces when point sits right after it and renumber the list, or unindent a line that holds nothing but whitespace before point to the previous column it can nest at; shadows markdown-outdent-or-delete, which unindents through the columns of markdown-calc-indents instead) |
| markdown-mode | `TAB` | markdown-cycle (cycle the line at point through the columns it can nest at under the list above, then renumber the list; the stock binding, with the columns from my/markdown-indent-line and the renumbering from advice) |
| markdown-mode | `<backtab>` | markdown-promote (move the list item at point out one level, nested items included, then renumber the list; shadows markdown-shifttab, whose global heading cycling stays on `C-u TAB`) |
| markdown-mode | `C-c C-=` | markdown-demote (move the list item at point in one level, nested items included, then renumber the list; the stock binding, with both behaviours added by advice) |
| markdown-mode | `C-c C-c n` | my/markdown-renumber-list-at-point (renumber the list at point, restarting each nested level at 1 and leaving code blocks and the first item of the outermost level alone; shadows markdown-cleanup-list-numbers, which stays available through `M-x`) |
| markdown-mode | `C-c TAB` | my/markdown-table-compress (compress the table at point to its narrowest padding) |
| markdown-mode | `C-c \|` | my/markdown-table-compress-buffer (compress every table in the buffer) |
| markdown-mode | `C-c C-x i` | markdown-insert-image (relocated from `C-c C-i`, which `C-c TAB` shadows in a terminal) |
| markdown-mode | `C-c q` | my/markdown-toggle-blockquote (quote or unquote the region, or the line at point; the built-in `C-c C-s q` and `C-c C-s Q` only ever add a marker) |
| SLIME REPL | `, q` | slime-handle-repl-shortcut, which `,` dispatches; `q` is the shortcut that quits SLIME |
| SLIME REPL | `C-<up>`, `C-<down>` | slime-repl-backward-input and slime-repl-forward-input (walk the REPL input history) |
| sql-mode | `C-c C-f` | sqlformat-buffer (reformat the buffer with sql-formatter) |
| Vertico | `RET` | vertico-directory-enter (descend into the directory at point instead of accepting the candidate) |
| Vertico | `DEL`, `M-DEL` | vertico-directory-delete-char and vertico-directory-delete-word (delete back through a path one character or one component at a time) |
| web-mode | `C-c /` | web-mode-element-close (insert the closing tag for the element at point) |

[SLIME REPL documentation](https://slime.common-lisp.dev/doc/html/REPL.html#REPL)
