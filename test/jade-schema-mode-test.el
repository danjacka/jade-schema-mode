;;; -*- lexical-binding: t; -*-
(require 'ert)
(require 'imenu)
(require 'jade-schema-mode)

(setq ert-batch-print-length 10)
(setq ert-batch-print-level 10)

(ert-deftest jade-schema-mode-imenu-only-types-test ()
  (with-temp-buffer
    (insert "
typeDefinitions
	Red completeDefinition
	(
	)
	Orange completeDefinition
	(
	)
	Yellow completeDefinition
	(
	)
memberKeyDefinitions
	Blue completeDefinition
	(
		number;
	)
	Purple completeDefinition
	(
		number;
	)
	Green completeDefinition
	(
		number;
	)")
    (jade-schema-mode)
    (should (equal
             (imenu--make-index-alist)
             '(("*Rescan*" . -99)
               ("Orange" . 48)
               ("Red" . 18)
               ("Yellow" . 81))))))

(ert-deftest jade-schema-mode-imenu-type-components-test ()
  (with-temp-buffer
    (insert "
typeHeaders
	Red subclassOf Colour;
	Orange subclassOf Colour;
	Yellow subclassOf Colour;
	Blue subclassOf Colour;
typeDefinitions
	Red completeDefinition
	(
	)
	Orange completeDefinition
	(
	)
	Yellow completeDefinition
	(
	)
	Blue completeDefinition
	(
	)
typeSources
	Red (
	jadeMethodSources
	)
	Orange (
	jadeMethodSources
	)
	Yellow (
	jadeMethodSources
	)
	Purple (
	jadeMethodSources
	)")
    (jade-schema-mode)
    (should (equal
             (imenu--make-index-alist)
             '(("*Rescan*" . -99)
               ("Blue" . (("typeHeaders" . 92)
                          ("typeDefinitions" . 229)))
               ("Orange" . (("typeHeaders" . 38)
                            ("typeDefinitions" . 163)
                            ("typeSources" . 301)))
               ("Purple" . 365)
               ("Red" . (("typeHeaders" . 14)
                         ("typeDefinitions" . 133)
                         ("typeSources" . 272)))
               ("Yellow" . (("typeHeaders" . 65)
                            ("typeDefinitions" . 196)
                            ("typeSources" . 333))))))))
