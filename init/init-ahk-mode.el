;;; -*- lexical-binding: t; -*-
;; Tree-sitter major mode for AutoHotkey v2 scripts.  The grammar is
;; pinned in init-treesit-grammars.  AutoHotkey v1 is not supported.
(require 'treesit)

(defcustom ahk-ts-mode-indent-offset 4
  "Number of spaces for each indentation step in `ahk-ts-mode'."
  :type 'natnum
  :safe 'natnump
  :group 'languages)

(defvar ahk-ts-mode--syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_  "_"  table)
    (modify-syntax-entry ?`  "\\" table)
    (modify-syntax-entry ?\" "\"" table)
    (modify-syntax-entry ?\' "\"" table)
    ;; `;' is style b and /* */ style a, so a newline ends only the former.
    (modify-syntax-entry ?\; "< b" table)
    (modify-syntax-entry ?\n "> b" table)
    (modify-syntax-entry ?/  ". 14" table)
    (modify-syntax-entry ?*  ". 23" table)
    table)
  "Syntax table for `ahk-ts-mode'.")

(defvar ahk-ts-mode--keywords
  '("if" "else" "while" "for" "loop" "until" "return" "break" "continue"
    "goto" "try" "catch" "finally" "throw" "switch" "case" "default"
    "class" "extends" "get" "set" "as" "is" "in" "unset" "and" "or" "not"
    "export" "struct" "global")
  "AutoHotkey keywords, which the grammar exposes as named nodes.
The query therefore matches (if) rather than \"if\".")

(defvar ahk-ts-mode--font-lock-settings
  ;; Rules follow the order of the grammar's highlights.scm, where later
  ;; patterns win, so they use `:override t'.  Operator, bracket and
  ;; delimiter come last without it so that they only fill what is left;
  ;; among them the earlier rule wins, so operator goes first to claim the
  ;; ternary `:'.
  (treesit-font-lock-rules
   :language 'autohotkey
   :feature 'directive
   :override t
   '([(directive_name) (include_ignore_failure) (directive_comment)]
     @font-lock-preprocessor-face)

   :language 'autohotkey
   :feature 'string
   :override t
   '([(file_or_dir_name) (lib_name) (requirement) (version_requirement)
      (warning_type) (warning_mode) (single_instance_mode) (bitness)]
     @font-lock-string-face
     (directive_comment arguments: (directive_arguments)
                        @font-lock-string-face))

   :language 'autohotkey
   :feature 'type
   :override t
   `((import_directive module: (identifier) @font-lock-type-face)
     (import_directive alias: (identifier) @font-lock-type-face)
     (import_directive (export_name export: (identifier)
                                    @font-lock-type-face))
     (import_directive (export_name alias: (identifier)
                                    @font-lock-type-face))
     (module_directive name: (identifier) @font-lock-type-face)
     (class_declaration name: (identifier) @font-lock-type-face)
     (class_declaration superclass: (identifier) @font-lock-type-face)
     (class_declaration superclass: (member_access
                                     member: (identifier)
                                     @font-lock-type-face))
     (struct_declaration name: (identifier) @font-lock-type-face)
     (struct_declaration superclass: (identifier) @font-lock-type-face)
     ((identifier) @font-lock-type-face
      (:match ,(rx bos (or "Int8" "Int16" "Int32" "Int64" "UInt8" "UInt16"
                           "UInt32" "IntPtr" "Float32" "Float64")
                   eos)
              @font-lock-type-face)))

   :language 'autohotkey
   :feature 'keyword
   :override t
   `([,@(mapcar (lambda (k) (list (intern k))) ahk-ts-mode--keywords)
      (scope_identifier)]
     @font-lock-keyword-face)

   :language 'autohotkey
   :feature 'constant
   :override t
   '((label name: (identifier) @font-lock-constant-face)
     (goto_statement label: (identifier) @font-lock-constant-face)
     (boolean_literal) @font-lock-constant-face)

   :language 'autohotkey
   :feature 'definition
   :override t
   '((param_sequence (identifier) @font-lock-variable-name-face)
     (default_param name: (identifier) @font-lock-variable-name-face)
     (optional_param name: (identifier) @font-lock-variable-name-face)
     (variadic_param name: (identifier) @font-lock-variable-name-face)
     (property_declaration name: (identifier) @font-lock-property-name-face)
     (property_declarator name: (identifier) @font-lock-property-name-face)
     (typed_property_declaration name: (identifier)
                                 @font-lock-property-name-face)
     (function_declaration name: (identifier) @font-lock-function-name-face)
     (function_expression name: (identifier) @font-lock-function-name-face)
     (fat_arrow_function name: (identifier) @font-lock-function-name-face)
     (method_declaration name: (identifier) @font-lock-function-name-face))

   :language 'autohotkey
   :feature 'property
   :override t
   '((member_access member: (identifier) @font-lock-property-use-face))

   :language 'autohotkey
   :feature 'function
   :override t
   '((function_call function: (identifier) @font-lock-function-call-face)
     (call_statement function: (identifier) @font-lock-function-call-face)
     (function_call function: (member_access
                               member: (identifier)
                               @font-lock-function-call-face)))

   :language 'autohotkey
   :feature 'assignment
   :override t
   '((assignment_operation left: (identifier) @font-lock-variable-name-face)
     (variable_declarator name: (identifier) @font-lock-variable-name-face))

   :language 'autohotkey
   :feature 'builtin
   :override t
   '(((identifier) @font-lock-builtin-face
      (:match "\\`[Aa]_" @font-lock-builtin-face))
     ((identifier) @font-lock-builtin-face
      (:equal "this" @font-lock-builtin-face)))

   :language 'autohotkey
   :feature 'number
   :override t
   '([(integer_literal) (float_literal) (hex_literal)]
     @font-lock-number-face)

   :language 'autohotkey
   :feature 'string
   :override t
   '([(string_literal) (multiline_string_literal)] @font-lock-string-face)

   ;; Continuation options sit inside a multiline string but are not its
   ;; text, so this follows `string' to override it.
   :language 'autohotkey
   :feature 'directive
   :override t
   '([(continuation_join) (continuation_ltrim) (continuation_ltrim_off)
      (continuation_rtrim_off) (continuation_allow_comments)
      (continuation_no_escape)]
     @font-lock-preprocessor-face)

   :language 'autohotkey
   :feature 'hotkey
   :override t
   '((hotkey_trigger) @font-lock-constant-face
     (hotstring_trigger) @font-lock-constant-face
     (hotstring_replacement) @font-lock-string-face)

   :language 'autohotkey
   :feature 'comment
   :override t
   '([(line_comment) (block_comment)] @font-lock-comment-face)

   :language 'autohotkey
   :feature 'operator
   '((_ operator: _ @font-lock-operator-face)
     (ternary_expression ["?" ":"] @font-lock-operator-face)
     ["=>"] @font-lock-operator-face
     (arrow) @font-lock-operator-face)

   :language 'autohotkey
   :feature 'bracket
   '(["(" ")" "[" "]" "{" "}"] @font-lock-bracket-face)

   :language 'autohotkey
   :feature 'delimiter
   '(["," ":" "::" "."] @font-lock-delimiter-face)

   :language 'autohotkey
   :feature 'error
   :override t
   '((ERROR) @font-lock-warning-face))
  "Font-lock settings for `ahk-ts-mode'.")

(defvar ahk-ts-mode--indent-rules
  `((autohotkey
     ;; Also matches the `)"' that closes a continuation section.
     ((node-is ,(rx bos (any "})]"))) parent-bol 0)
     ;; The rest of a block comment or continuation section is verbatim.
     ((parent-is ,(rx bos (or "block_comment" "multiline_string")))
      no-indent 0)
     ;; An Allman brace lines up with the line that owns the block.
     ((and (node-is ,(rx bos (or "block" "function_body") eos))
           (not (parent-is ,(rx bos "block" eos))))
      standalone-parent 0)
     ((node-is ,(rx bos (or "else_statement" "catch_clause" "finally_clause"
                            "until_statement")
                    eos))
      parent-bol 0)
     ((parent-is ,(rx bos "source_file" eos)) column-0 0)
     ((parent-is ,(rx bos (or "arg_sequence" "param_sequence") eos))
      first-sibling 0)
     ((parent-is ,(rx bos (or "block" "class_body" "switch_body"
                              "object_literal" "array_literal"
                              "property_declaration_block" "function_call"
                              "function_head" "parenthesized_expression"
                              "case_clause" "default_clause" "if_statement"
                              "else_statement" "while_statement"
                              "for_statement" "loop_statement" "try_statement"
                              "catch_clause" "finally_clause"
                              "until_statement" "function_body" "hotkey"
                              "hotstring" "getter" "setter"
                              "ternary_expression" "object_literal_member")
                      eos))
      parent-bol ahk-ts-mode-indent-offset)
     ((parent-is ,(rx "operation" eos)) parent-bol ahk-ts-mode-indent-offset))))

(defun ahk-ts-mode--defun-name (node)
  "Return the defun name of NODE, or nil if NODE is not a defun node."
  (pcase (treesit-node-type node)
    ((or "class_declaration" "function_declaration" "method_declaration")
     (treesit-node-text (treesit-node-child-by-field-name node "name") t))
    ((or "hotkey" "hotstring")
     (treesit-node-text (treesit-node-child-by-field-name node "trigger") t))))

(define-derived-mode ahk-ts-mode prog-mode "AHK"
  "Major mode for editing AutoHotkey v2 scripts, powered by tree-sitter."
  :syntax-table ahk-ts-mode--syntax-table
  (setq-local comment-start "; ")
  (setq-local comment-end "")
  (setq-local comment-start-skip ";+[ \t]*")
  (setq-local indent-tabs-mode nil)

  (when (treesit-ready-p 'autohotkey)
    (setq treesit-primary-parser (treesit-parser-create 'autohotkey))

    (setq-local treesit-simple-indent-rules ahk-ts-mode--indent-rules)

    (setq-local treesit-defun-type-regexp
                (rx bos (or "class_declaration" "function_declaration"
                            "method_declaration" "hotkey" "hotstring")
                    eos))
    (setq-local treesit-defun-name-function #'ahk-ts-mode--defun-name)
    (setq-local treesit-thing-settings
                `((autohotkey
                   (list ,(rx bos (or "block" "class_body" "switch_body"
                                      "object_literal" "array_literal"
                                      "parenthesized_expression"
                                      "property_declaration_block")
                              eos))
                   (text ,(rx bos (or "line_comment" "block_comment") eos)))))

    (setq-local treesit-simple-imenu-settings
                `(("Class" ,(rx bos "class_declaration" eos) nil nil)
                  ("Function" ,(rx bos "function_declaration" eos) nil nil)
                  ("Method" ,(rx bos "method_declaration" eos) nil nil)
                  ("Hotkey" ,(rx bos "hotkey" eos) nil nil)
                  ("Hotstring" ,(rx bos "hotstring" eos) nil nil)))

    (setq-local treesit-font-lock-settings ahk-ts-mode--font-lock-settings)
    (setq-local treesit-font-lock-feature-list
                '((comment definition)
                  (keyword string type directive)
                  (builtin constant number property assignment function
                           hotkey)
                  (bracket delimiter operator error)))

    (treesit-major-mode-setup)))

(add-to-list 'auto-mode-alist '("\\.ah[k2]\\'" . ahk-ts-mode))

(provide 'init-ahk-mode)
