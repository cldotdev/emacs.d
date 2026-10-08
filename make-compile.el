;;; make-compile.el --- Byte- and native-compile the configuration  -*- lexical-binding: t -*-

;;; Commentary:

;; Run from the Makefile as `emacs --batch -l make-compile.el'.
;;
;; `--batch' implies `-q', so `load-path' starts out holding nothing but the
;; directories Emacs ships.  Compiling against that path would turn every
;; macro the vendored packages provide -- dash, compat, llama, cond-let and
;; the rest -- into a plain function call in the `.elc', so collect the same
;; directories `init.el' and the modules under `init/' add at startup.
;; Reading the forms out of the sources beats loading the configuration,
;; which would start the server and set up a whole session.
;;
;; Every package is compiled in an Emacs of its own, because one package can
;; redefine what the next compiles against: `slime.el' defines a `when-let'
;; of its own, and in a shared session each package the walk reaches after it
;; compiles against that definition rather than the one in `subr-x'.
;;
;; A `.elc' that `byte-recompile-directory' has not reached yet is still what
;; `require' hands the compiler, so every stale or orphaned one goes first.
;;
;; Every `.elc' outside `make-compile-native-skip' then gets its `.eln' in
;; `eln-cache/'.  `load' swaps a `.elc' for its `.eln' only when the `.eln'
;; is not older than the `.elc'; otherwise it loads the `.elc' and queues a
;; native compile in the background, which warns about every dependency it
;; cannot see.  The
;; makefiles for magit and helm rebuild their `.elc' without touching the
;; `.eln', so a rebuild leaves the `.eln' older, and only the timestamps
;; tell.  `native-compile-prune-cache' then drops the directories of every
;; other Emacs build.
;;
;; `init.el' itself stays uncompiled.  It is a list of `require' forms, so
;; there is nothing to gain, and `load' reads it before the
;; `load-prefer-newer' it sets can take effect.

;;; Code:

(require 'cl-lib)

(defvar make-compile-root
  (file-name-directory (or load-file-name buffer-file-name))
  "The configuration this run compiles.")

(defun make-compile-load-path ()
  "Return the `load-path' entries the configuration adds at startup."
  (let ((init-dir (expand-file-name "init" make-compile-root))
        dirs)
    (dolist (file (cons (expand-file-name "init.el" make-compile-root)
                        (directory-files init-dir t "\\.el\\'")))
      (with-temp-buffer
        (insert-file-contents file)
        (goto-char (point-min))
        (while (re-search-forward "(add-to-list 'load-path \"\\([^\"]+\\)\")" nil t)
          (cl-pushnew (expand-file-name (match-string 1)) dirs :test #'equal))))
    ;; `slime-setup' adds this one at run time, too late for a batch compile.
    (cl-pushnew (expand-file-name "package/slime/contrib" make-compile-root)
                dirs :test #'equal)
    (nreverse dirs)))

(defun make-compile-prune (dir)
  "Delete every `.elc' under DIR that no longer stands for its source.
One older than its `.el' is what `require' loads while the rest of the tree
compiles against it, and one whose `.el' upstream removed is loaded for good."
  (dolist (elc (directory-files-recursively dir "\\.elc\\'"))
    (let ((el (substring elc 0 -1)))
      (unless (and (file-exists-p el) (file-newer-than-file-p elc el))
        (message "Pruning %s" elc)
        (delete-file elc)))))

(defun make-compile-target (form args)
  "Evaluate FORM in an Emacs of its own, started with ARGS, and echo its output."
  (with-temp-buffer
    (apply #'call-process
           (expand-file-name invocation-name invocation-directory) nil t nil
           (append args (list "--eval" (format "%S" form))))
    (princ (buffer-string))))

(defconst make-compile-native-skip
  "/\\(?:tests?\\|dev\\|features\\)/\\|-tests?\\.el\\'"
  "Regexp for the sources the native step skips, matched relative to the root.
They are tests, development scripts and cucumber step definitions that no
session loads, so native-compiling them only costs build time and `eln-cache/'
space.  `native-compile' also fails on dash's examples with
`invalid-read-syntax' \"#<\" while loading the file it writes.")

(defun make-compile-native-stale (entry)
  "Return the sources under ENTRY whose `.eln' is missing or out of date.
ENTRY is a directory or a single `.el'.  Only a source with a `.elc' counts,
so files that opt out of compiling stay out."
  (let ((elcs (cond ((file-directory-p entry)
                     (directory-files-recursively entry "\\.elc\\'"))
                    ((and (string-suffix-p ".el" entry)
                          (file-exists-p (concat entry "c")))
                     (list (concat entry "c"))))))
    (cl-loop for elc in elcs
             for el = (substring elc 0 -1)
             unless (string-match-p make-compile-native-skip
                                    (file-relative-name el make-compile-root))
             when (file-newer-than-file-p elc (comp-el-to-eln-filename el))
             collect el)))

(let* ((args (append '("-Q" "--batch")
                     (mapcan (lambda (dir) (list "-L" dir))
                             (make-compile-load-path))))
       (init-dir (expand-file-name "init" make-compile-root))
       (package-dir (expand-file-name "package" make-compile-root))
       (entries (cons init-dir (directory-files package-dir t "\\`[^.]"))))
  (make-compile-prune init-dir)
  (make-compile-prune package-dir)
  (dolist (entry entries)
    (cond ((file-directory-p entry)
           (make-compile-target `(byte-recompile-directory ,entry 0) args))
          ((string-suffix-p ".el" entry)
           ;; `byte-recompile-file' is not autoloaded, unlike its directory
           ;; counterpart.
           (make-compile-target
            `(progn (require 'bytecomp) (byte-recompile-file ,entry nil 0))
            args))))
  (when (native-comp-available-p)
    ;; Checking in this Emacs means a package with nothing stale starts no
    ;; Emacs of its own.
    (dolist (entry entries)
      (when-let* ((els (make-compile-native-stale entry)))
        (make-compile-target
         `(dolist (el ',els)
            (message "Native-compiling %s" el)
            (condition-case err
                (native-compile el)
              (error (message "Native compile of %s failed: %S" el err))))
         args)))
    (native-compile-prune-cache)))

;;; make-compile.el ends here
