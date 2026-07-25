;;; -*- lexical-binding: t; -*-
(when (fboundp 'native-compile-async)
  (if (yes-or-no-p "async compile? ")
      (progn
        (setq package-native-compile t)
        (native-compile-async "~/.emacs.d/package" 'recursively)
        ;; Block until native compilation has finished.
        (while (or comp-files-queue
                   (> (comp-async-runnings) 0))
          (sleep-for 1)))))

(when (boundp 'native-comp-async-report-warnings-errors)
  (setq native-comp-async-report-warnings-errors 'silent))

(provide 'init-native-comp)
