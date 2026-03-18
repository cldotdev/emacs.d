(require 'visual-fill-column)

(add-to-list 'auto-mode-alist
             '("\\.\\(?:md\\|markdown\\|mkd\\|mdown\\|mkdn\\|mdwn\\)\\'" . gfm-mode))

(defun my/markdown-ensure-syntax-propertize (&rest _args)
  "Ensure syntax properties are up-to-date before imenu scans.
tree-sitter-hl-mode bypasses syntax-propertize, causing
markdown-code-block-at-point-p to miss fenced code blocks."
  (syntax-propertize (point-max)))

;; Bind S-Tab to decrease indentation (promote) in list items
(with-eval-after-load 'markdown-mode
  ;; Disable electric backquote prompt when typing ```
  (setq markdown-gfm-use-electric-backquote nil)
  (define-key markdown-mode-map (kbd "<backtab>") 'markdown-promote)
  (define-key markdown-mode-map (kbd "RET") #'my/markdown-insert-list-item-on-enter)
  ;; Ensure syntax-propertize runs before imenu scans, so that
  ;; markdown-code-block-at-point-p correctly detects fenced code blocks.
  (advice-add 'markdown-imenu-create-nested-index
              :before #'my/markdown-ensure-syntax-propertize)
  (advice-add 'markdown-imenu-create-flat-index
              :before #'my/markdown-ensure-syntax-propertize))

(defun my/markdown-insert-list-item-on-enter ()
  "Insert a new list item with appropriate marker when pressing RET in a list.
Supports unordered lists (-, *, +), ordered lists (1., 2., etc.), and
GitHub-style task lists (- [ ], * [ ], etc.).
When the current list item is empty, removes the marker but keeps indentation.
Text after cursor is moved to the new line."
  (interactive)
  (let ((line-content (buffer-substring-no-properties
                       (line-beginning-position)
                       (line-end-position)))
        (text-after-cursor (buffer-substring-no-properties
                            (point)
                            (line-end-position))))
    (cond
     ;; Match task list: indentation + marker + [ ] or [x] + optional content
     ((string-match "^\\([ \t]*\\)\\([-*+]\\)\\s-+\\(\\[[ xX]\\]\\)\\s-*\\(.*\\)$" line-content)
      (let* ((indent (match-string 1 line-content))
             (marker (match-string 2 line-content))
             (content (match-string 4 line-content)))
        (if (string-empty-p content)
            ;; Empty task list item: remove marker, keep indent
            (progn
              (delete-region (line-beginning-position) (line-end-position))
              (insert indent)
              (newline-and-indent))
          ;; Non-empty: insert new task list item, move text after cursor
          (delete-region (point) (line-end-position))
          (newline)
          (insert indent marker " [ ] ")
          (save-excursion
            (insert (string-trim-left text-after-cursor))))))

     ;; Match ordered list: indentation + number + . or ) + optional content
     ((string-match "^\\([ \t]*\\)\\([0-9]+\\)\\([.)]\\)\\s-*\\(.*\\)$" line-content)
      (let* ((indent (match-string 1 line-content))
             (num (string-to-number (match-string 2 line-content)))
             (delim (match-string 3 line-content))
             (content (match-string 4 line-content)))
        (if (string-empty-p content)
            ;; Empty ordered list item: remove marker, keep indent
            (progn
              (delete-region (line-beginning-position) (line-end-position))
              (insert indent)
              (newline-and-indent))
          ;; Non-empty: insert new ordered list item, move text after cursor
          (delete-region (point) (line-end-position))
          (newline)
          (insert indent (number-to-string (1+ num)) delim " ")
          (save-excursion
            (insert (string-trim-left text-after-cursor))))))

     ;; Match unordered list: indentation + marker (-, *, +) + space + optional content
     ((string-match "^\\([ \t]*\\)\\([-*+]\\)\\s-+\\(.*\\)$" line-content)
      (let* ((indent (match-string 1 line-content))
             (marker (match-string 2 line-content))
             (content (match-string 3 line-content)))
        (if (string-empty-p content)
            ;; Empty unordered list item: remove marker, keep indent
            (progn
              (delete-region (line-beginning-position) (line-end-position))
              (insert indent)
              (newline-and-indent))
          ;; Non-empty: insert new unordered list item, move text after cursor
          (delete-region (point) (line-end-position))
          (newline)
          (insert indent marker " ")
          (save-excursion
            (insert (string-trim-left text-after-cursor))))))

     ;; Not a list item: just do normal newline
     (t
      (newline-and-indent)))))

(defun my/markdown-fill-paragraph-single-item (&optional justify)
  "Fill only the current sub-paragraph within a list item.
In list items, treats the first line separately from indented continuations.
When point is on a list marker line, fill only that line.
When point is on an indented continuation line, fill only the block of
indented continuations, preserving proper indentation."
  (interactive)
  (save-excursion
    (let ((orig-point (point))
          start end)
      (beginning-of-line)
      (cond
       ;; Case 1: We're on a list marker line
       ((looking-at markdown-regex-list)
        (let ((marker-length (length (match-string 0))))
          (setq start (point))
          ;; Find the end of the first paragraph (before indented continuation or next list item)
          (forward-line 1)
          (while (and (not (eobp))
                      (not (looking-at markdown-regex-list))        ; Not another list item
                      (not (looking-at "^[ \t]+[^ \t\n]"))          ; Not an indented line
                      (not (looking-at "^[ \t]*$")))                ; Not a blank line
            (forward-line 1))
          (setq end (point))
          ;; Fill with proper indentation for continuation lines
          (let ((fill-prefix (make-string marker-length ?\s)))
            (fill-region start end justify nil))))

       ;; Case 2: We're on an indented continuation line within a list item
       ((and (looking-at "^[ \t]+[^ \t\n]")
             (save-excursion
               ;; Check if there's a list marker above
               (let ((found-marker nil))
                 (while (and (not (bobp))
                             (not found-marker))
                   (forward-line -1)
                   (when (looking-at markdown-regex-list)
                     (setq found-marker t)))
                 found-marker)))
        ;; Find the extent of indented continuation lines
        (let ((base-indent (current-indentation)))
          ;; Start from current line (don't search backwards)
          (setq start (point))

          ;; Find end of indented block with same or greater indentation
          (while (and (not (eobp))
                      (looking-at "^[ \t]+[^ \t\n]")
                      (>= (current-indentation) base-indent))
            (forward-line 1))
          (setq end (point))

          ;; Fill the indented region with proper hanging indent
          (let ((fill-prefix (make-string base-indent ?\s)))
            (fill-region start end justify nil))))

       ;; Case 3: Not in a list, use default markdown fill
       (t
        (markdown-fill-paragraph justify))))))

;; Language-specific comment syntax for code blocks
(defvar my/code-block-comment-alist
  '(;; Shell variants
    ("shell" . ("#" . ""))
    ("bash" . ("#" . ""))
    ("sh" . ("#" . ""))
    ("zsh" . ("#" . ""))
    ("fish" . ("#" . ""))
    ("ksh" . ("#" . ""))
    ("csh" . ("#" . ""))
    ("tcsh" . ("#" . ""))
    ;; Python variants
    ("python" . ("#" . ""))
    ("py" . ("#" . ""))
    ("python3" . ("#" . ""))
    ("python2" . ("#" . ""))
    ;; Ruby variants
    ("ruby" . ("#" . ""))
    ("rb" . ("#" . ""))
    ;; Go variants
    ("go" . ("//" . ""))
    ("golang" . ("//" . ""))
    ;; Rust variants
    ("rust" . ("//" . ""))
    ("rs" . ("//" . ""))
    ;; Markdown variants (uses HTML comments)
    ("markdown" . ("<!--" . "-->"))
    ("md" . ("<!--" . "-->"))
    ("mkd" . ("<!--" . "-->"))
    ("mdown" . ("<!--" . "-->"))
    ;; Other # comment languages
    ("perl" . ("#" . ""))
    ("r" . ("#" . ""))
    ("yaml" . ("#" . ""))
    ("yml" . ("#" . ""))
    ("toml" . ("#" . ""))
    ("dockerfile" . ("#" . ""))
    ("makefile" . ("#" . ""))
    ("make" . ("#" . ""))
    ;; Lisp family
    ("elisp" . (";" . ""))
    ("emacs-lisp" . (";" . ""))
    ("lisp" . (";" . ""))
    ("scheme" . (";" . ""))
    ("clojure" . (";" . ""))
    ("clj" . (";" . ""))
    ;; C-style // comments
    ("javascript" . ("//" . ""))
    ("js" . ("//" . ""))
    ("typescript" . ("//" . ""))
    ("ts" . ("//" . ""))
    ("c" . ("//" . ""))
    ("cpp" . ("//" . ""))
    ("c++" . ("//" . ""))
    ("java" . ("//" . ""))
    ("swift" . ("//" . ""))
    ("kotlin" . ("//" . ""))
    ("kt" . ("//" . ""))
    ("scala" . ("//" . ""))
    ("php" . ("//" . ""))
    ("groovy" . ("//" . ""))
    ("dart" . ("//" . ""))
    ;; -- comment languages
    ("sql" . ("--" . ""))
    ("lua" . ("--" . ""))
    ("haskell" . ("--" . ""))
    ("hs" . ("--" . ""))
    ;; Block comment languages
    ("css" . ("/*" . "*/"))
    ("html" . ("<!--" . "-->"))
    ("xml" . ("<!--" . "-->")))
  "Mapping of code block languages to comment syntax (start . end).")

(defun my/gfm-get-code-block-lang ()
  "Get the language of the code block at point by parsing buffer text.
Returns the language string if inside a fenced code block, nil otherwise."
  (save-excursion
    (let ((current-pos (point))
          (fence-regexp "^[ \t]*\\(```\\|~~~\\)\\s-*\\([^`\n]*\\)$")
          open-fence-pos open-fence-lang close-fence-pos)
      ;; Search backward for opening fence
      (when (re-search-backward fence-regexp nil t)
        (setq open-fence-pos (point))
        (setq open-fence-lang (string-trim (match-string 2)))
        ;; Check if this is an opening fence (has language or is first of pair)
        ;; by looking for a closing fence after it
        (goto-char (match-end 0))
        (forward-line 1)
        (when (re-search-forward "^[ \t]*\\(```\\|~~~\\)[ \t]*$" nil t)
          (setq close-fence-pos (match-beginning 0))
          ;; We're inside if current-pos is between open and close
          (when (and (> current-pos open-fence-pos)
                     (< current-pos close-fence-pos)
                     (not (string-empty-p open-fence-lang)))
            open-fence-lang))))))

(defun my/gfm-toggle-comment-line (comment-str)
  "Toggle comment on current line using COMMENT-STR as the comment marker."
  (save-excursion
    (beginning-of-line)
    (let* ((line-start (point))
           (line-end (line-end-position))
           (line-content (buffer-substring-no-properties line-start line-end))
           (comment-regexp (concat "^\\([ \t]*\\)" (regexp-quote comment-str) " ?"))
           (indent ""))
      (if (string-match comment-regexp line-content)
          ;; Line is commented - uncomment it
          (let ((indent (match-string 1 line-content))
                (rest (substring line-content (match-end 0))))
            (delete-region line-start line-end)
            (insert indent rest))
        ;; Line is not commented - comment it
        (if (string-match "^\\([ \t]*\\)\\(.*\\)$" line-content)
            (let ((indent (match-string 1 line-content))
                  (code (match-string 2 line-content)))
              (delete-region line-start line-end)
              (insert indent comment-str " " code))
          ;; Fallback: just prepend comment
          (insert comment-str " "))))))

(defun my/gfm-comment-dwim ()
  "Comment command that respects code block language in gfm-mode.
When point is inside a fenced code block, use the comment syntax
appropriate for the specified language instead of HTML comments."
  (interactive)
  (let* ((lang (my/gfm-get-code-block-lang))
         (comment-syntax (when lang
                          (cdr (assoc (string-trim (downcase lang)) my/code-block-comment-alist)))))
    (if comment-syntax
        ;; Inside code block with known language
        (let ((comment-str (car comment-syntax)))
          (if (region-active-p)
              ;; Handle region
              (save-excursion
                (let ((start (region-beginning))
                      (end (region-end)))
                  (goto-char start)
                  (beginning-of-line)
                  (while (< (point) end)
                    (my/gfm-toggle-comment-line comment-str)
                    (forward-line 1)
                    ;; Adjust end position if lines changed length
                    (setq end (+ end (- (line-end-position) (line-end-position)))))))
            ;; Handle single line
            (my/gfm-toggle-comment-line comment-str)))
      ;; Outside code block or unknown language
      (comment-dwim-line))))

(with-eval-after-load 'markdown-mode
  (define-key gfm-mode-map (kbd "M-;") #'my/gfm-comment-dwim))

(add-hook  'markdown-mode-hook
           (lambda ()
             (auto-fill-mode -1)
             (visual-line-mode nil)
             (setq tab-width 2)
             ;; Use custom fill function for better list item handling
             (setq-local fill-paragraph-function #'my/markdown-fill-paragraph-single-item)
             ;; Clear stale buffer-local overrides from previous config
             ;; versions so the global electric-pair-inhibit-predicate
             ;; takes effect.
             (kill-local-variable 'electric-pair-inhibit-predicate)
             (kill-local-variable 'electric-pair-skip-self)
             (kill-local-variable 'electric-pair-pairs)))

(defun my/gfm-electric-backtick ()
  "Handle backtick auto-pairing in gfm-mode.
Backtick has punctuation syntax in markdown-mode, so electric-pair-mode
ignores it.  This function implements pairing and skipping manually,
with the rule that pairing/skipping only happens when the backtick is
NOT adjacent to another backtick (to avoid interfering with ``` code
fence syntax).  Also cleans up the trailing auto-paired backtick when
a ``` fence is formed."
  (when (and electric-pair-mode
             (eql last-command-event ?`))
    (let ((prev (char-before (1- (point))))
          (next (char-after)))
      (cond
       ;; Both sides are `: skip over closing ` to build code fence.
       ;; e.g. `|` -> type ` -> ```|
       ((and (eq prev ?`) (eq next ?`))
        (forward-char 1))
       ;; Skip over closing ` (when not preceded by `).
       ;; e.g. `hello|` -> type ` -> `hello`|
       ((and (eq next ?`)
             (not (eq prev ?`)))
        (delete-char -1)
        (forward-char 1))
       ;; Insert closing ` only when both neighbors are whitespace or absent.
       ;; e.g. |  -> type ` -> `|`
       ;; but:  |word -> type ` -> `|word  (no pairing)
       ;;       word| -> type ` -> word`|  (no pairing)
       ((and (not (eq prev ?`))
             (not (eq next ?`))
             (or (null prev) (eq (char-syntax prev) ?\s))
             (or (null next) (eq (char-syntax next) ?\s)))
        (save-excursion (insert ?`)))))))

(add-hook 'gfm-mode-hook
          (lambda ()
            (remove-hook 'post-self-insert-hook #'gfm--electric-pair-fence-code-block t)
            (add-hook 'post-self-insert-hook #'my/gfm-electric-backtick 'append t)))

(provide 'init-markdown-mode)
