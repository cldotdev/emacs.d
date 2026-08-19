;;; -*- lexical-binding: t; -*-
(add-to-list 'load-path "~/.emacs.d/package/compat")
(add-to-list 'load-path "~/.emacs.d/package/orderless")
(add-to-list 'load-path "~/.emacs.d/package/vertico")
(add-to-list 'load-path "~/.emacs.d/package/vertico/extensions")

(require 'cl-lib)

(require 'vertico)
(vertico-mode 1)

(require 'vertico-multiform)
(vertico-multiform-mode)

;; Enable vertico-grid for multi-column display
(require 'vertico-grid)
;; Allow grid to fall back to a single column on narrow frames.
(setq vertico-grid-min-columns 1)

;; The grid arrangement of vertico-grid.el 2.4, with the column count measured
;; by `string-width' where upstream uses `length'.  A CJK character counts as
;; one character but occupies two columns, so `length' under-measures a CJK
;; candidate: the grid lays out more columns than the window can hold, and
;; `truncate-string-to-width' then cuts the candidates.  This method replaces
;; the one `vertico-grid' installs, so it has to stay after the `require'
;; above; a later `require' of `vertico-grid' would silently reinstate the
;; upstream method.  Re-check the body against upstream when the submodule is
;; updated.
(cl-defmethod vertico--arrange-candidates (&context (vertico-grid-mode (eql t)))
  (when (<= vertico--index 0)
    (let ((w 1))
      (cl-loop repeat vertico-grid-lookahead for cand in vertico--candidates do
               (setq w (max w (+ vertico-grid-annotate (string-width cand)))))
      (setq vertico-grid--columns
            (max vertico-grid-min-columns
                 (min vertico-grid-max-columns
                      (floor (vertico--window-width) (+ w (length vertico-grid-separator))))))))
  (let* ((sep (length vertico-grid-separator))
         (count (* vertico-count vertico-grid--columns))
         (start (* count (floor (max 0 vertico--index) count)))
         (width (- (/ (vertico--window-width) vertico-grid--columns) sep))
         (cands (funcall (if (> vertico-grid-annotate 0) #'vertico--affixate #'identity)
                         (cl-loop repeat count for c in (nthcdr start vertico--candidates)
                                  collect (vertico--hilit c))))
         (cands (cl-loop
                 for cand in cands for index from 0 collect
                 (let (prefix suffix)
                   (when (consp cand)
                     (setq prefix (cadr cand) suffix (caddr cand) cand (car cand)))
                   (when (string-search "\n" cand)
                     (setq cand (vertico--truncate-multiline cand width)))
                   (truncate-string-to-width
                    (string-trim
                     (replace-regexp-in-string
                      "[ \t]+"
                      (lambda (x) (apply #'propertize " " (text-properties-at 0 x)))
                      (vertico--format-candidate cand prefix suffix (+ index start) start)))
                    width))))
         (width (make-vector vertico-grid--columns 0)))
    (dotimes (col vertico-grid--columns)
      (dotimes (row vertico-count)
        (aset width col (max
                         (aref width col)
                         (string-width (or (nth (+ row (* col vertico-count)) cands) ""))))))
    (dotimes (col (1- vertico-grid--columns))
      (cl-incf (aref width (1+ col)) (+ (aref width col) sep)))
    (cl-loop for row from 0 to (1- (min vertico-count vertico--total)) collect
             (let ((line (list "\n")))
               (cl-loop for col from (1- vertico-grid--columns) downto 0 do
                        (when-let ((cand (nth (+ row (* col vertico-count)) cands)))
                          (push cand line)
                          (when (> col 0)
                            (push vertico-grid-separator line)
                            (push (propertize " " 'display
                                              `(space :align-to (+ left ,(aref width (1- col))))) line))))
               (string-join line)))))

(vertico-grid-mode 1)

;; Ido-like directory navigation for Vertico
(require 'vertico-directory)
(with-eval-after-load 'vertico
  (keymap-set vertico-map "RET" #'vertico-directory-enter)
  (keymap-set vertico-map "DEL" #'vertico-directory-delete-char)
  (keymap-set vertico-map "M-DEL" #'vertico-directory-delete-word))

(require 'vertico-sort)
(setq vertico-multiform-categories
      '((file (vertico-sort-function . vertico-sort-history-alpha))))

(require 'orderless)
(setq completion-styles '(orderless basic)
      completion-category-overrides '((file (styles basic partial-completion))))

(provide 'init-vertico)
