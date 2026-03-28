(require 'ibuffer-vc)

;; Better buffer list
(global-set-key [(control x) (control b)] 'ibuffer)

;; Enable ibuffer-filter-by-filename to filter on directory names too.
(eval-after-load "ibuf-ext"
  '(define-ibuffer-filter filename
     "Toggle current view to buffers with file or directory name matching QUALIFIER."
     (:description "filename"
                   :reader (read-from-minibuffer "Filter by file/directory name (regexp): "))
     (when-let ((filename (or (buffer-local-value 'buffer-file-name buf)
                              (buffer-local-value 'dired-directory buf))))
       (string-match qualifier filename))))

;; Default grouping of ibuffer
(setq ibuffer-saved-filter-groups
      (quote (("default"
               ("org" (mode . org-mode))
               ("dirs" (mode . dired-mode))
               ("python" (mode . python-mode))
               ("php" (mode . php-mode))
               ("js" (mode . js2-mode))
               ("templates" (mode . web-mode))
               ("emacs" (or
                         (name . "^.+\\.el$")
                         (name . "^\\*.+\\*$")))))))

;; Don't show empty groups
(setq ibuffer-show-empty-filter-groups nil)

;; Loads version control groups (call on entering ibuffer)
(defun ibuffer-vc-add-vc-filter-groups ()
  "Add VC root filter groups to current Ibuffer filter groups."
  (interactive)
  (dolist (group (ibuffer-vc-generate-filter-groups-by-vc-root))
    (add-to-list 'ibuffer-filter-groups group t)))

;; Use human readable Size column instead of original one
(eval-after-load 'ibuffer
  '(progn
     (define-ibuffer-column size-h
       (:name "Size" :inline t)
       (cond
        ((> (buffer-size) 1000) (format "%7.1fk" (/ (buffer-size) 1000.0)))
        ((> (buffer-size) 1000000) (format "%7.1fM" (/ (buffer-size) 1000000.0)))
        (t (format "%8d" (buffer-size)))))

     (setq ibuffer-formats '((mark modified read-only " "
                                   (name 30 30 :left :elide)
                                   " "
                                   (size-h 9 -1 :right)
                                   " "
                                   (mode 16 16 :left :elide)
                                   " " filename-and-process)
                             (mark modified read-only vc-status-mini " "
                                   (name 30 30 :left :elide)
                                   " "
                                   (size-h 9 -1 :right)
                                   " "
                                   (mode 16 16 :left :elide)
                                   " "
                                   (vc-status 16 16 :left)
                                   " "
                                   filename-and-process)))

     ;; C-c C-g (or g) to group by version control dir (ie. projects)
     (define-key ibuffer-mode-map (kbd "C-c g") 'ibuffer-vc-set-filter-groups-by-vc-root)
     (define-key ibuffer-mode-map (kbd "C-c C-g") 'ibuffer-vc-set-filter-groups-by-vc-root)
     ))

(setq ibuffer-filter-group-name-face 'font-lock-doc-face)

(provide 'init-ibuffer)
