;;; jade-schema-mode.el --- A major-mode for navigating Jade Platform schema files -*- lexical-binding: t -*-

;; Copyright (C) 2025 Dan Jacka

;; Author: Dan Jacka <danjacka@gmail.com>
;; URL: https://github.com/danjacka/jade-schema-mode
;; Version: 0.0.1
;; Package-Requires: ((emacs "26.3"))
;; Keywords: languages, tools

;;; Commentary:

;; Font-lock and navigation support for Jade Platform schema files in Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(require 'rx)

(defconst jade-schema-jade-reserved-words
  '("abortTransaction" "abortTransientTransaction" "and" "app" "Any"
    "appContext" "as" "attributeDefinitions" "begin" "beginLoad" "beginLock"
    "beginTransaction" "beginTransientTransaction" "Binary" "Boolean" "break"
    "Byte" "call" "categoryDefinition" "Character" "classMapDefinitions"
    "_cloneOf" "commitTransaction" "commitTransientTransaction"
    "constantDefinitions" "constants" "continue" "create" "currentSchema"
    "currentSession" "databaseDefinitions" "databaseFileDefinitions" "Date"
    "dbServerDefinitions" "Decimal" "defaultFileDefinition" "delete" "div" "do"
    "documentationText" "else" "elseif" "_encryptedSource" "_endEncryptedSource"
    "end" "endExecuteWhen" "endforeach" "endif" "endLoad" "endLock" "endswitch"
    "endwhile" "epilog" "eventMethodMappings" "executeWhen" "exception"
    "exportedClassDefinitions" "exportedConstantDefinitions"
    "exportedInterfaceDefinitions" "exportedMethodDefinitions"
    "exportedPackageDefinitions" "exportedPropertyDefinitions"
    "_exposedConstantDefinitions" "_exposedJavaFeatures"
    "_exposedListDefinitions" "_exposedMethodDefinitions"
    "_exposedPropertyDefinitions" "externalFunctionDefinitions"
    "externalFunctionSources" "externalKeyDefinitions"
    "externalMethodDefinitions" "externalMethodSources" "false" "_for" "foreach"
    "global" "if" "implementInterfaces" "importMethod"
    "importedClassDefinitions" "importedInterfaceDefinitions"
    "importedPackageDefinitions" "in" "Integer" "Integer64"
    "interfaceDefinitions" "interfaceDefs" "inverseDefinitions" "is"
    "JadeFiletypeVersiontag" "jadeMethodDefinitions" "jadeMethodSources"
    "jadePatchRelease" "jadeVersionNumber" "libraryDefinitions"
    "localeDefinitions" "localeFormatDefinitions" "memberKeyDefinitions"
    "membershipDefinitions" "MemoryAddress" "methodImplementations" "method"
    "mod" "node" "not" "null" "of" "on" "or" "Point" "parentOf"
    "partitionMethod" "peerOf" "primitive" "process" "raise" "read" "Real"
    "referenceDefinitions" "_remapTableDefinitions" "return" "reversed"
    "rootSchema" "schemaDefaultLocale" "schemaDefinition"
    "schemaViewDefinitions" "self" "selfType" "setModifiedTimeStamp" "step"
    "String" "StringUtf8" "subInterfaceOf" "subclassOf" "subschemaOf" "system"
    "terminate" "then" "Time" "TimeStamp" "TimeStampInterval" "TimeStampOffset"
    "to" "translatableStringDefinitions" "true" "typeDefinitions" "typeHeaders"
    "typeSources" "vars" "webServicesClassProperties"
    "webServicesMethodDefinitions" "webServicesMethodProperties"
    "webServicesMethodSources" "where" "while" "write" "xor"))

(defconst jade-schema-jade-syntax-words
  '("discreteLock"
    "inheritCreate" "inheritMethod"
    "internal" "precondition"
    "persistent" "transient" "sharedTransient"
    "setPatchVersion"
    "switch" "case" "default"))

(defvar jade-schema-section-pattern
  (let ((markers (seq-filter
                  (lambda (s)
                    (string-match-p (rx (or "Definition" "Definitions" "Defs"
                                            "Headers" "Sources")
                                        eol)
                                    s))
                  jade-schema-jade-reserved-words)))
    (rx-to-string `(seq bol (group (or ,@markers)) eol)))
  "Regular expression to match all sections in the schema.")

(defvar jade-schema-type-header-pattern
  (rx bol
      (1+ space)
      (group (1+ (or (syntax word) (syntax symbol))))
      (1+ space)
      "subclassOf"
      (1+ space)))

(defvar jade-schema-type-definition-pattern
  (rx bol
      (1+ space)
      (group (1+ (or (syntax word) (syntax symbol) ":")))
      (1+ space)
      "completeDefinition"
      (optional "\n")
      (1+ space)
      (syntax open-parenthesis)))

(defvar jade-schema-type-source-pattern
  (rx bol
      (1+ space)
      (group (1+ (or (syntax word) (syntax symbol))))
      (1+ space)
      (syntax open-parenthesis)
      (optional "\n")
      (1+ space)
      "jadeMethodSources"))

(defvar jade-schema-font-lock-keywords
  `((,jade-schema-type-header-pattern 1 font-lock-type-face)
    (,jade-schema-type-definition-pattern 1 font-lock-type-face)
    (,jade-schema-type-source-pattern 1 font-lock-type-face)
    (,(regexp-opt jade-schema-jade-reserved-words 'symbols) . font-lock-keyword-face)
    (,(regexp-opt jade-schema-jade-syntax-words 'symbols) . font-lock-keyword-face)))

(defvar jade-schema-imenu-indexables
  `(("typeHeaders"     . ,jade-schema-type-header-pattern)
    ("typeDefinitions" . ,jade-schema-type-definition-pattern)
    ("typeSources"     . ,jade-schema-type-source-pattern)))

(defun jade-schema-imenu-create-index ()
  "Create index for Imenu"
  (goto-char (point-min))
  (let* ((section-pattern jade-schema-section-pattern)
         (indexables (mapcar 'car jade-schema-imenu-indexables))
         (indexable-pattern (rx-to-string `(seq bol (group (or ,@indexables)) eol)))
         (positions (make-hash-table :test 'equal))
         section item-pattern)
    (while (not (eobp))
      (cond
       ((looking-at section-pattern)
        (setq section (match-string-no-properties 1))
        (setq item-pattern (if (looking-at indexable-pattern)
                               (cdr (assoc section jade-schema-imenu-indexables))
                             nil)))
       ((and item-pattern (looking-at item-pattern))
        (let* ((name (match-string-no-properties 1))
               (position (line-beginning-position))
               (existing (gethash name positions)))
          (if existing
              (puthash name (cons (cons section position) existing) positions)
            (puthash name (list (cons section position)) positions)))))
      (forward-line 1))
    (let ((index-alist '()))
      (maphash
       (lambda (name sections)
         (let ((sections (nreverse sections)))
           (if (= (length sections) 1)
               (push (cons name (cdar sections)) index-alist)
             (push (cons name sections) index-alist))))
       positions)
      (sort index-alist (lambda (a b) (string< (car a) (car b)))))))

(defvar jade-schema-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; Double quote, single quote and backtick are string delimiters.
    (modify-syntax-entry ?\" "\"" table)
    (modify-syntax-entry ?' "\"" table)
    (modify-syntax-entry ?` "\"" table)

    ;; Backslash does NOT escape the next character
    (modify-syntax-entry ?\\ "." table)

    ;; These next commands set up C++-style comments:
    ;; // to end of line ("A"-style), and
    ;; /* and */ pairs across multiple lines ("B"-style)
    ;; Make forward-slash a punctuation character,
    ;;   the first character of an "A"-style start-comment sequence,
    ;;   the second character of an "A"-style start-comment sequence,
    ;;   and the second character of a "B"-style end-comment sequence.
    (modify-syntax-entry ?/ ". 124" table)
    ;; Make star a punctuation character,
    ;;   the second character of a "B"-style start-comment sequence,
    ;;   and the first character of a "B"-style end-comment sequence.
    (modify-syntax-entry ?* ". 23b" table)
    ;; Make newline end an "A"-style comment
    (modify-syntax-entry ?\n ">" table)

    table)
  "Syntax table for `jade-schema-mode'.")

;;;###autoload
(define-derived-mode jade-schema-mode fundamental-mode "Jade schema"
  "Major mode for navigating Jade Platform schema files."
  (setq font-lock-defaults
        '(jade-schema-font-lock-keywords nil nil nil nil))
  (setq-local imenu-create-index-function #'jade-schema-imenu-create-index
              imenu-auto-rescan nil
              imenu-max-item-length nil
              imenu-use-markers t)
  (setq-local outline-regexp jade-schema-section-pattern
              outline-level (lambda () 1))
  (setq-local case-fold-search nil)
  (setq-local show-trailing-whitespace nil)
  (setq-local tab-width 4)
  (view-mode 1))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.scm\\'" . jade-schema-mode))

(provide 'jade-schema-mode)

;;; jade-schema-mode.el ends here
