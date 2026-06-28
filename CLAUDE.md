# CLAUDE.md

This file guides Claude Code and other contributors working in this Emacs
configuration.

## Structure

- Configuration is modular: each feature lives in its own `init/init-*.el`
  file, loaded from `init.el`.
- Third-party packages are vendored under `package/`.

## Keeping Documentation in Sync

`README.md` documents the available features and keyboard shortcuts. Keep it
in sync with the configuration:

- When a package is added, removed, or swapped, update the **Features*- and
  **Requirements*- lists in `README.md`.
- When a keyboard shortcut is added, removed, or rebound, update the matching
  entry under **Keymaps*- in `README.md`.
- List the real command name (including any `my/` prefix) and note when a
  binding shadows or relocates a default key.
