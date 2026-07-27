;;; -*- lexical-binding: t; -*-
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
  ;; DEL takes the marker off a list item before touching its
  ;; indentation.  The stock markdown-outdent-or-delete never removes a
  ;; marker, and unindents through the columns of markdown-calc-indents
  ;; rather than the ones TAB cycles through.
  (define-key markdown-mode-map (kbd "DEL")
              #'my/markdown-delete-marker-on-backspace)
  ;; Compress table padding for narrow-screen reading.  In a terminal
  ;; C-c TAB is read as C-c C-i, which shadows the default
  ;; markdown-insert-image, so rebind that to C-c C-x i (next to the
  ;; existing C-c C-x C-i image toggle) to keep it available.
  (define-key markdown-mode-map (kbd "C-c TAB") #'my/markdown-table-compress)
  (define-key markdown-mode-map (kbd "C-c |") #'my/markdown-table-compress-buffer)
  (define-key markdown-mode-map (kbd "C-c C-x i") #'markdown-insert-image)
  ;; markdown-mode only ever adds a blockquote marker, through
  ;; markdown-insert-blockquote and markdown-blockquote-region; nothing
  ;; takes one away.
  (define-key markdown-mode-map (kbd "C-c q") #'my/markdown-toggle-blockquote)
  ;; C-c C-c n renumbers only the list at point.  It shadows the built-in
  ;; markdown-cleanup-list-numbers, which walks the whole buffer, restarts
  ;; every level at 1, ignores `1)' markers, and rewrites numbered lines
  ;; inside code blocks; that command stays reachable through M-x.
  (define-key markdown-mode-command-map
              (kbd "n") #'my/markdown-renumber-list-at-point)
  ;; Renumber after either way an item can change level: Tab, which
  ;; cycles the indentation of the line at point, and the promote and
  ;; demote commands, which move an item with its children.  Advising
  ;; the list-item helpers rather than markdown-promote and
  ;; markdown-demote covers every key those two are bound to and leaves
  ;; their heading and table branches alone.
  ;;
  ;; The same helpers indent by a fixed markdown-list-indent-width,
  ;; which lines an item up with the content of the item above only
  ;; when that item's marker happens to be as wide, so the overrides
  ;; below move through the columns Tab cycles through instead.  They
  ;; renumber the list themselves rather than through a separate :after
  ;; advice, which would fire even when the item had nowhere to go.
  (advice-add 'markdown-cycle :after #'my/markdown-renumber-after-cycle)
  (advice-add 'markdown-promote-list-item
              :override #'my/markdown-promote-list-item)
  (advice-add 'markdown-demote-list-item
              :override #'my/markdown-demote-list-item)
  ;; Ensure syntax-propertize runs before imenu scans, so that
  ;; markdown-code-block-at-point-p correctly detects fenced code blocks.
  (advice-add 'markdown-imenu-create-nested-index
              :before #'my/markdown-ensure-syntax-propertize)
  (advice-add 'markdown-imenu-create-flat-index
              :before #'my/markdown-ensure-syntax-propertize))

(defconst my/markdown-list-item-regexp
  "^[ \t]*\\(?:[0-9]+[.)]\\|[-*+]\\)[ \t]"
  "Regexp matching the marker of an ordered or unordered list item.")

(defconst my/markdown-ordered-list-item-regexp
  "^[ \t]*\\([0-9]+\\)[.)][ \t]"
  "Regexp matching an ordered list item marker.
The item number is group 1.")

(defconst my/markdown-list-item-content-regexp
  (concat my/markdown-list-item-regexp "[ \t]*")
  "Regexp matching a list item marker and the whitespace after it.
The match ends at the column the item's own content starts at, which
is where anything nested under the item has to line up.")

(defconst my/markdown-code-fence-regexp
  "^[ \t]*\\(?:```\\|~~~\\)"
  "Regexp matching a fenced code block delimiter.")

(defun my/markdown-insert-list-item-on-enter ()
  "Insert a new list item with appropriate marker when pressing RET in a list.
Supports unordered lists (-, *, +), ordered lists (1., 2., etc.), and
GitHub-style task lists (- [ ], * [ ], etc.).
When the current list item is empty, removes the marker but keeps indentation.
Text after cursor is moved to the new line.
With point still in the indentation before the marker, opens a line
above and leaves the list alone.
After inserting an item, renumbers the list so that the items below the
new one get the right numbers; see `my/markdown-renumber-list-at-point'."
  (interactive)
  (let* ((line-content (buffer-substring-no-properties
                        (line-beginning-position)
                        (line-end-position)))
         (text-after-cursor (buffer-substring-no-properties
                             (point)
                             (line-end-position)))
         ;; Point has not reached the marker yet, so the text carried
         ;; over to a new item would be the marker itself.
         (before-marker (and (string-match-p my/markdown-list-item-regexp
                                             line-content)
                             (<= (current-column) (current-indentation)))))
    (cond
     ;; Open a line above, leaving the item's own line untouched.  A plain
     ;; newline would split its indentation across the two lines, changing
     ;; the item's nesting level.
     (before-marker
      (let ((column (current-column)))
        (beginning-of-line)
        (insert "\n")
        (move-to-column column)))

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
      (newline-and-indent)))
    ;; Only a new item can throw the numbering off.  Keep a renumbering
    ;; bug from breaking RET itself.
    (unless before-marker
      (with-demoted-errors "Error renumbering list: %S"
        (my/markdown-renumber-list-at-point)))))

(defun my/markdown-list-item-line-p ()
  "Return non-nil when the current line starts a list item.
Point must be at the beginning of the line."
  (and (looking-at-p my/markdown-list-item-regexp)
       (not (looking-at-p markdown-regex-hr))))

(defun my/markdown-scan-list-items-backward (function)
  "Call FUNCTION on each list item line above point, nearest first.
Point is at the beginning of the line for each call.  The scan stops
where the list does: at a code fence, at an unindented line that is not
a list item, and at two consecutive blank lines.  FUNCTION returning
nil stops it early."
  (save-excursion
    (beginning-of-line)
    (let ((blanks 0)
          (scanning t))
      (while (and scanning (= 0 (forward-line -1)))
        (cond
         ((looking-at-p my/markdown-code-fence-regexp)
          (setq scanning nil))
         ((looking-at-p markdown-regex-blank-line)
          (setq blanks (1+ blanks))
          (when (> blanks 1) (setq scanning nil)))
         ((my/markdown-list-item-line-p)
          (setq blanks 0)
          (unless (funcall function) (setq scanning nil)))
         ;; Indented text continues the item above.
         ((> (current-indentation) 0)
          (setq blanks 0))
         (t (setq scanning nil)))))))

(defun my/markdown-list-bounds ()
  "Return the bounds of the list around point as (BEGIN . END).
Return nil unless point is on a list item line.  The list stops where
`my/markdown-scan-list-items-backward' stops scanning, so a list
interrupted by a code block or a paragraph counts as two separate
lists."
  (save-excursion
    (beginning-of-line)
    (when (my/markdown-list-item-line-p)
      (let ((begin (point))
            (end (line-end-position)))
        (my/markdown-scan-list-items-backward
         (lambda () (setq begin (point)) t))
        (save-excursion
          (let ((blanks 0)
                (scanning t))
            (while (and scanning (= 0 (forward-line 1)))
              (cond
               ((looking-at-p my/markdown-code-fence-regexp)
                (setq scanning nil))
               ((looking-at-p markdown-regex-blank-line)
                (setq blanks (1+ blanks))
                (when (> blanks 1) (setq scanning nil)))
               ((or (my/markdown-list-item-line-p)
                    (> (current-indentation) 0))
                (setq end (line-end-position)
                      blanks 0))
               (t (setq scanning nil))))))
        (cons begin end)))))

(defun my/markdown-list-item-content-column ()
  "Return the column the content of the item at point starts at.
Point must be at the beginning of a list item line."
  (save-excursion
    (looking-at my/markdown-list-item-content-regexp)
    (goto-char (match-end 0))
    (current-column)))

(defun my/markdown-list-indent-positions ()
  "Return the columns the line at point can be indented to, or nil.
The columns are 0 and the content column of each list item that could
hold the line: the nearest one above it, then each item that in turn
encloses that one.

Return nil when no list item precedes the line, leaving it no level to
move into."
  (let ((positions nil)
        (nearest nil))
    (my/markdown-scan-list-items-backward
     (lambda ()
       (let ((indent (current-indentation)))
         ;; Only items shallower than the ones already seen enclose the
         ;; line; siblings of those add no level of their own.
         (when (or (null nearest) (< indent nearest))
           (setq nearest indent)
           (push (my/markdown-list-item-content-column) positions))
         ;; Nothing above an unindented item can enclose the line.
         (> indent 0))))
    (when positions
      (sort (delete-dups (cons 0 positions)) #'<))))

(defun my/markdown-deeper-indent-position (cur positions)
  "Return the first of POSITIONS deeper than column CUR, or nil.
The counterpart of `markdown-outdent-find-next-position', which picks
the nearest shallower column."
  (seq-find (lambda (position) (> position cur)) positions))

(defun my/markdown-list-base-indent (begin end)
  "Return the smallest indentation of the list items between BEGIN and END.
Items at that indentation make up the outermost level of the list."
  (save-excursion
    (goto-char begin)
    (beginning-of-line)
    (let ((base most-positive-fixnum))
      (while (< (point) end)
        (when (my/markdown-list-item-line-p)
          (setq base (min base (current-indentation))))
        (forward-line 1))
      base)))

(defun my/markdown-renumber-list-at-point (&optional restart)
  "Renumber the ordered items of the list around point.
The outermost level starts at the number of its own first item, so a
list that deliberately picks up at `4.' keeps its offset; changing that
item is the way to renumber the whole list.  Nested levels always
restart at 1, because their first item usually carries a number that
`RET' gave it while it still belonged to the level above.

With RESTART non-nil, the item at point starts its own level at 1 even
at the outermost level.  The reindenting commands pass it once they
have moved an item.

Items that already carry the right number are left untouched, so a list
in good shape triggers no buffer modification, no undo entry, and no
modified flag.  Does nothing outside a list or inside a fenced code
block, where a line such as a shell `case' label looks exactly like an
ordered item."
  (interactive)
  (let ((bounds (and (save-excursion
                       (beginning-of-line)
                       (my/markdown-list-item-line-p))
                     ;; tree-sitter-hl-mode bypasses syntax-propertize,
                     ;; so make sure markdown-code-block-at-point-p can
                     ;; see the fences above point.  RET runs this
                     ;; command on every line, and propertizing is the
                     ;; expensive step, so do it only from a list item.
                     (progn (syntax-propertize (line-end-position))
                            (not (markdown-code-block-at-point-p)))
                     (my/markdown-list-bounds))))
    (when bounds
      (save-excursion
        (let ((end (copy-marker (cdr bounds)))
              (base (my/markdown-list-base-indent (car bounds) (cdr bounds)))
              ;; A marker, since renumbering a line above it can change
              ;; the width of that line's number.
              (restart-line (and restart
                                 (copy-marker (line-beginning-position))))
              ;; Alist of (INDENT . LAST-NUMBER), deepest level first.
              (levels nil))
          (goto-char (car bounds))
          (beginning-of-line)
          (while (< (point) end)
            (let ((indent (current-indentation)))
              (cond
               ((looking-at my/markdown-ordered-list-item-regexp)
                (while (and levels (> (caar levels) indent))
                  (pop levels))
                (let* ((seed (if (or (> indent base)
                                     (and restart-line
                                          (= restart-line (point))))
                                 1
                               (string-to-number (match-string 1))))
                       (number (if (and levels (= (caar levels) indent))
                                   (setcdr (car levels) (1+ (cdar levels)))
                                 (cdar (push (cons indent seed) levels))))
                       (new (number-to-string number)))
                  (unless (string= (match-string 1) new)
                    (replace-match new t t nil 1))))
               ;; An unordered item still closes any deeper levels, so a
               ;; nested ordered list under the next bullet restarts.
               ((my/markdown-list-item-line-p)
                (while (and levels (> (caar levels) indent))
                  (pop levels)))))
            (forward-line 1))
          (set-marker end nil)
          (when restart-line (set-marker restart-line nil)))))))

(defun my/markdown-list-item-line-position ()
  "Return the start of the list item line holding point, or nil.
A continuation line belongs to the item it is indented under; the
reindenting commands can leave point on such a line."
  (save-excursion
    (beginning-of-line)
    (while (and (not (my/markdown-list-item-line-p))
                (> (current-indentation) 0)
                (= 0 (forward-line -1))))
    (and (my/markdown-list-item-line-p) (point))))

(defun my/markdown-renumber-after-cycle (&optional arg)
  "Renumber the list at point after `markdown-cycle' indented an item.
ARG is the command's own argument, which makes the command cycle global
visibility instead of indenting.  The command reindents the line at
point and nothing else, so a line that is not itself a list item, such
as a table row or a continuation line, leaves every number as it is."
  (unless arg
    ;; Keep a renumbering bug from breaking Tab itself.
    (with-demoted-errors "Error renumbering list: %S"
      (save-excursion
        (beginning-of-line)
        (when (my/markdown-list-item-line-p)
          (my/markdown-renumber-list-at-point t))))))

(defun my/markdown-list-item-content-start-p ()
  "Return non-nil when point sits where a list item's content starts.
Everything before point on the line is then the indentation of the
item, its marker, and the whitespace after the marker.  A line inside a
fenced code block does not count, since a shell `case' label there
looks exactly like an ordered item."
  (let ((position (point)))
    (and (save-excursion
           (beginning-of-line)
           (and (my/markdown-list-item-line-p)
                (looking-at my/markdown-list-item-content-regexp)
                (= (match-end 0) position)))
         ;; tree-sitter-hl-mode bypasses syntax-propertize, so make
         ;; sure markdown-code-block-at-point-p can see the fences
         ;; above point.
         (progn (syntax-propertize (line-end-position))
                (not (markdown-code-block-at-point-p))))))

(defun my/markdown-strip-list-item-marker ()
  "Replace the marker of the list item at point with spaces.
Point must sit where the content of the item starts, and stays in that
column, which is where text nested under the item above belongs.
Renumber the list afterwards, since the items below the line have moved
up a number."
  (let* ((marker (save-excursion (back-to-indentation) (point)))
         (width (- (current-column)
                   (save-excursion (goto-char marker) (current-column)))))
    (delete-region marker (point))
    (insert (make-string width ?\s)))
  ;; The line no longer carries a marker of its own, so renumber from
  ;; the item it continues.
  (let ((item (my/markdown-list-item-line-position)))
    (when item
      ;; Keep a renumbering bug from breaking DEL itself.
      (with-demoted-errors "Error renumbering list: %S"
        (save-excursion
          (goto-char item)
          (my/markdown-renumber-list-at-point))))))

(defun my/markdown-delete-marker-on-backspace (arg)
  "Strip a list marker, unindent the line, or delete ARG characters back.
With point right after the marker of a list item, ordered or
unordered, replace that marker with spaces: the line turns into a
continuation of the item above it, and point keeps its column.  See
`my/markdown-strip-list-item-marker'.  An ARG of more than one skips
this step, since a numeric argument asks for that many characters
rather than for a marker.

With nothing but whitespace before point, unindent the line to the
column `my/markdown-previous-indent-position' returns.  The two steps
together walk a nested item back out to column 0, one press at a time.

Anywhere else, delete ARG characters backwards.  Replaces
`markdown-outdent-or-delete', which unindents through the columns of
`markdown-calc-indents' rather than the ones `TAB' cycles through."
  (interactive "*p")
  (let ((column (current-column)))
    (cond
     ((use-region-p)
      (backward-delete-char-untabify arg))
     ((and (= arg 1) (my/markdown-list-item-content-start-p))
      (my/markdown-strip-list-item-marker))
     ((and (> column 0)
           (= column (save-excursion (back-to-indentation) (current-column))))
      (indent-line-to (my/markdown-previous-indent-position column)))
     (t
      (backward-delete-char-untabify arg)))))

(defconst my/markdown-blockquote-regexp
  "^[ \t]*\\(> ?\\)"
  "Regexp matching one blockquote marker at the start of a line.
The marker, with the space that usually follows it, is group 1.
The stock `markdown-regex-blockquote' instead takes in every space
after the marker, which would flatten the indentation of quoted text.")

(defun my/markdown-clear-blank-line ()
  "Empty the current line when it holds nothing but whitespace.
Point must be at the beginning of the line.  Whitespace left on such a
line would trail the blockquote marker, either the one about to be
inserted or the one just removed."
  (when (looking-at-p markdown-regex-blank-line)
    (delete-region (point) (line-end-position))))

(defun my/markdown-toggle-blockquote (begin end)
  "Toggle the blockquote marker on every line between BEGIN and END.
Interactively, act on the region when it is active and on the line at
point otherwise; since Markdown buffers here run `visual-line-mode'
without `auto-fill-mode', that line is usually a whole paragraph.

Strip one level of quoting when every non-blank line already carries a
marker, and add one otherwise, so a partly quoted region ends up fully
quoted.  The marker goes at the common indentation of the non-blank
lines, which keeps a quote inside the list item it belongs to and
leaves the lines indented relative to each other as they were.  Blank
lines get a bare `>' at that same column, so that the paragraphs
around them stay in a single blockquote."
  (interactive
   (if (use-region-p)
       (list (region-beginning) (region-end))
     ;; Take in the line break: a blank line ends where it begins, so
     ;; without it the loops below would get an empty range.
     (list (line-beginning-position) (line-beginning-position 2))))
  (save-excursion
    ;; A range of nothing but blank lines leaves `indent' unset, which
    ;; doubles as the flag for having no marker to strip.
    (let ((end (copy-marker end))
          (quoted t)
          (indent nil))
      (goto-char begin)
      (beginning-of-line)
      (while (< (point) end)
        (unless (looking-at-p markdown-regex-blank-line)
          (setq indent (if indent
                           (min indent (current-indentation))
                         (current-indentation)))
          (unless (looking-at-p my/markdown-blockquote-regexp)
            (setq quoted nil)))
        (forward-line 1))
      (goto-char begin)
      (beginning-of-line)
      (while (< (point) end)
        (if (and quoted indent)
            (when (looking-at my/markdown-blockquote-regexp)
              (replace-match "" t t nil 1)
              (beginning-of-line)
              (my/markdown-clear-blank-line))
          (my/markdown-clear-blank-line)
          (move-to-column (or indent 0) t)
          (insert (if (eolp) ">" "> ")))
        (forward-line 1))
      (set-marker end nil)))
  ;; Keep the region alive so that a second press toggles it back.
  (setq deactivate-mark nil))

(defun my/markdown-fill-paragraph-single-item (&optional justify)
  "Fill only the current sub-paragraph within a list item.
In list items, treats the first line separately from indented continuations.
When point is on a list marker line, fill only that line.
When point is on an indented continuation line, fill only the block of
indented continuations, preserving proper indentation."
  (interactive)
  (save-excursion
    (let (start end)
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
                      (not (looking-at markdown-regex-blank-line))) ; Not a blank line
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
           (comment-regexp (concat "^\\([ \t]*\\)" (regexp-quote comment-str) " ?")))
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

(defun my/markdown-next-indent-position (cur)
  "Return the column to cycle to from column CUR.
A line that a list item precedes moves through the columns of
`my/markdown-list-indent-positions', so that it lands under the item
that holds it; past the deepest one it wraps around to 0.  This covers
the continuation lines of an item as much as the items themselves,
since text nested under an item has to line up with that item's content
just the same.  Every other line, the first item of a list included,
moves in `tab-width' increments up to four times that width."
  (let ((positions (my/markdown-list-indent-positions)))
    (cond
     (positions (or (my/markdown-deeper-indent-position cur positions) 0))
     ((>= cur (* 4 tab-width)) 0)
     (t (+ cur tab-width)))))

(defun my/markdown-previous-indent-position (cur)
  "Return the column to unindent to from column CUR.
The counterpart of `my/markdown-next-indent-position': a line that a
list item precedes moves back through the columns of
`my/markdown-list-indent-positions', and every other line moves in
`tab-width' decrements down to 0.  Both directions therefore walk the
same columns, so that unindenting a line and cycling it back with
`TAB' leaves it where it started."
  (let ((positions (my/markdown-list-indent-positions)))
    (if positions
        (markdown-outdent-find-next-position cur positions)
      (max 0 (- cur tab-width)))))

(defun my/markdown-indent-line ()
  "Cycle the indentation of the line at point.
When invoked via `markdown-cycle' (Tab key), move to the column
`my/markdown-next-indent-position' returns.  Otherwise, match the
previous line's indentation for auto-indent."
  (let* ((cur (current-indentation))
         (next (if (eq this-command 'markdown-cycle)
                   (my/markdown-next-indent-position cur)
                 (or (markdown-prev-line-indent) 0))))
    (if (<= (current-column) cur)
        (progn (indent-line-to next)
               (back-to-indentation))
      (save-excursion (indent-line-to next)))))

(defun my/markdown-list-item-subtree-end ()
  "Return the end of the list item at point, nested items included.
Point must be at the beginning of a list item line.  Anything indented
deeper than the item belongs to it, blank lines between them included."
  (save-excursion
    (let ((indent (current-indentation))
          (end (line-beginning-position 2))
          (blanks 0)
          (scanning t))
      (while (and scanning (= 0 (forward-line 1)))
        (cond
         ((looking-at-p markdown-regex-blank-line)
          (setq blanks (1+ blanks))
          (when (> blanks 1) (setq scanning nil)))
         ((> (current-indentation) indent)
          (setq end (line-beginning-position 2)
                blanks 0))
         (t (setq scanning nil))))
      end)))

(defun my/markdown-shift-list-item (target)
  "Move the list item at point to column TARGET, nested items included.
Point must be at the beginning of a list item line.  Return non-nil
when the item actually moved."
  (let ((delta (- target (current-indentation))))
    (unless (zerop delta)
      (indent-rigidly (line-beginning-position)
                      (my/markdown-list-item-subtree-end)
                      delta)
      t)))

(defun my/markdown-reindent-list-item (target-function)
  "Move the list item at point to the column TARGET-FUNCTION picks.
TARGET-FUNCTION receives the item's current indentation and the columns
from `my/markdown-list-indent-positions', and returns nil to leave the
item where it is.  Renumber the list only once the item has moved, so
that an item with nowhere to go leaves the number the list opens on
alone."
  (save-excursion
    (let ((item (my/markdown-list-item-line-position)))
      (when item
        (goto-char item)
        (let ((target (funcall target-function
                               (current-indentation)
                               (my/markdown-list-indent-positions))))
          (when (and target (my/markdown-shift-list-item target))
            ;; Keep a renumbering bug from breaking the command itself.
            (with-demoted-errors "Error renumbering list: %S"
              (my/markdown-renumber-list-at-point t))))))))

(defun my/markdown-demote-list-item (&optional _bounds)
  "Indent the list item at point to the next column it can sit at.
Nested items move with it.  Does nothing when no item above can hold
it."
  (interactive)
  (my/markdown-reindent-list-item #'my/markdown-deeper-indent-position))

(defun my/markdown-promote-list-item (&optional _bounds)
  "Unindent the list item at point to the previous column it can sit at.
Nested items move with it.  An item that no other item encloses goes
back to column 0."
  (interactive)
  (my/markdown-reindent-list-item #'markdown-outdent-find-next-position))

(defun my/markdown-mode-setup ()
  "Setup for markdown-mode buffers."
  (auto-fill-mode -1)
  (visual-line-mode 1)
  (setq-local tab-width 2)
  (setq-local indent-line-function #'my/markdown-indent-line)
  (setq-local indent-bars-starting-column 0)
  (setq-local indent-bars-spacing-override 2)
  ;; Use custom fill function for better list item handling
  (setq-local fill-paragraph-function #'my/markdown-fill-paragraph-single-item)
  ;; Clear stale buffer-local overrides from previous config
  ;; versions so the global electric-pair-inhibit-predicate
  ;; takes effect.
  (kill-local-variable 'electric-pair-inhibit-predicate)
  (kill-local-variable 'electric-pair-skip-self)
  (kill-local-variable 'electric-pair-pairs))

(add-hook 'markdown-mode-hook #'my/markdown-mode-setup)

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
            ;; (add-hook 'post-self-insert-hook #'my/gfm-electric-backtick 'append t)
            ))

(defun my/markdown-table-compress ()
  "Compress the table at point by stripping alignment padding.
Each non-empty cell keeps a single space on each side, while an empty
cell becomes a single space.  The delimiter row is reduced to a
minimal form, and column alignment markers (`:') are preserved.  This
makes wide aligned tables more compact for reading on narrow screens.

Note: cells are not padded to a common column width, so each row is
only as wide as its own content.  Pressing Tab inside the table
re-aligns it unless `markdown-table-align-p' is nil."
  (interactive)
  (unless (markdown-table-at-point-p)
    (user-error "Not at a table"))
  (let ((begin (markdown-table-begin))
        (end (copy-marker (markdown-table-end))))
    (markdown-table-save-cell
     (goto-char begin)
     (let* ((indent (progn (looking-at "[ \t]*") (match-string 0)))
            fmtspec
            (lines (mapcar (lambda (line)
                             (if (markdown--is-delimiter-row line)
                                 (progn (setq fmtspec (or fmtspec line)) nil)
                               line))
                           (markdown--split-string
                            (buffer-substring begin end) "\n")))
            (cells (mapcar #'markdown--table-line-to-columns (remq nil lines)))
            (maxcells (if cells
                          (apply #'max (mapcar #'length cells))
                        (user-error "Empty table")))
            (emptycells (make-list maxcells ""))
            (fmts (markdown-table-colfmt fmtspec))
            ;; Minimal delimiter row, keeping each column's alignment.
            (hline (concat
                    indent "|"
                    (mapconcat
                     (lambda (i)
                       (let ((f (nth i fmts)))
                         (cond ((eq f 'l) ":--")
                               ((eq f 'r) "--:")
                               ((eq f 'c) ":-:")
                               (t "---"))))
                     (number-sequence 0 (1- maxcells))
                     "|")
                    "|")))
       (dolist (line lines)
         (let ((new (if line
                        (let ((row (seq-take
                                    (append (pop cells) emptycells)
                                    maxcells)))
                          (concat indent "|"
                                  (mapconcat
                                   (lambda (c)
                                     (let ((c (string-trim c)))
                                       (if (string-empty-p c)
                                           " "
                                         (concat " " c " "))))
                                   row "|")
                                  "|"))
                      hline))
               (previous (buffer-substring-no-properties (point) (line-end-position))))
           (if (equal previous new)
               (forward-line)
             (insert new "\n")
             (delete-region (point) (line-beginning-position 2)))))
       (set-marker end nil)))))

(defun my/markdown-table-compress-buffer ()
  "Compress every Markdown table in the current buffer.
See `my/markdown-table-compress'."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((count 0))
      (while (not (eobp))
        (when (markdown-table-at-point-p)
          (my/markdown-table-compress)
          (setq count (1+ count))
          (goto-char (markdown-table-end)))
        (forward-line 1))
      (message "Compressed %d table(s)" count))))

(provide 'init-markdown-mode)
