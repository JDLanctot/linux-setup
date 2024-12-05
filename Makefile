.PHONY: test test-unit test-integration test-e2e lint clean coverage

test: lint test-unit test-integration test-e2e

test-unit:
	@echo "Running unit tests..."
	./tests/run_tests.sh unit/*.sh

test-integration:
	@echo "Running integration tests..."
	./tests/run_tests.sh integration/*.sh

test-e2e:
	@echo "Running end-to-end tests..."
	./tests/run_tests.sh e2e/*.sh

test-simulate:
	@echo "Running installation simulation..."
	./install.sh --simulate --profile minimal
	./install.sh --simulate --profile standard
	./install.sh --simulate --profile full

lint:
	@echo "Running shellcheck..."
	shellcheck install.sh
	find lib tests -type f -name "*.sh" -exec shellcheck {} +

coverage:
	@echo "Generating test coverage report..."
	kcov --include-pattern=lib/ coverage/ ./tests/run_tests.sh

clean:
	rm -rf tmp/
	rm -f *.log
	rm -rf coverage/
	rm -f test-results/*.xml

.PHONY: install
install:
	./install.sh

.PHONY: check
check: lint test
