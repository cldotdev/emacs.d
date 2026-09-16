;;; make-compile.el --- Byte-compile the configuration  -*- lexical-binding: t -*-

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

(let* ((args (append '("-Q" "--batch")
                     (mapcan (lambda (dir) (list "-L" dir))
                             (make-compile-load-path))))
       (package-dir (expand-file-name "package" make-compile-root)))
  (make-compile-prune (expand-file-name "init" make-compile-root))
  (make-compile-prune package-dir)
  (make-compile-target
   `(byte-recompile-directory ,(expand-file-name "init" make-compile-root) 0)
   args)
  (dolist (entry (directory-files package-dir t "\\`[^.]"))
    (cond ((file-directory-p entry)
           (make-compile-target `(byte-recompile-directory ,entry 0) args))
          ((string-suffix-p ".el" entry)
           ;; `byte-recompile-file' is not autoloaded, unlike its directory
           ;; counterpart.
           (make-compile-target
            `(progn (require 'bytecomp) (byte-recompile-file ,entry nil 0))
            args)))))

;;; make-compile.el ends here
