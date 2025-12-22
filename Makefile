EMACS ?= emacs
TESTS ?= test/jade-schema-mode-test.el

test:
	$(EMACS) -Q -batch -L . -l $(TESTS) \
		-f ert-run-tests-batch-and-exit

.PHONY: test
