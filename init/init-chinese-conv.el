;;; -*- lexical-binding: t; -*-
(require 'chinese-conv)
(setq chinese-conv-opencc-data "/usr/local/share/opencc/")
(defalias 'opencc 'chinese-conv-replace)
(provide 'init-chinese-conv)
