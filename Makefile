PYTHON_VERSION ?= 3.10.4
CMD := poetry run
SRC_DIR := src
TESTS_DIR := tests

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
.PHONY: help

format: ## rewrites code with black and isort
	$(CMD) black $(SRC_DIR) $(TESTS_DIR)
	$(CMD) isort $(SRC_DIR) $(TESTS_DIR)
.PHONY: format

lint-black: ## checks src and tests with mypy
	$(CMD) black --check --fast $(SRC_DIR) $(TESTS_DIR)
.PHONY: lint-black

lint-flake: ## checks src and tests with mypy
	$(CMD) flakeheaven lint $(SRC_DIR) $(TESTS_DIR)
.PHONY: lint-flake

lint-mypy: ## checks type annotation
	$(CMD) mypy $(SRC_DIR)
.PHONY: lint-mypy

lint: lint-black lint-flake lint-mypy ## runs all static analysis tools
.PHONY: lint

test: ## runs tests
	$(CMD) pytest --cov=src --cov-report html:tests/.coverage $(TESTS_DIR)
.PHONY: test

safety: ## tests third part packages against a database of known compromised ones
	poetry export --with dev --format=requirements.txt --without-hashes | poetry run safety check --stdin

qa: safety lint test ## for CI/CD. Runs all code quality tools
.PHONY: qa

qa-local: format qa ## for local development (before checking in). Formats code and runs qa
.PHONY: qa-local

# # # # add and import a project.Makefile ?

scripts-all: scripts-clean Biosample-exhasutive-FoF-sorted-exhaustion_report.yaml

scripts-clean:
	rm -rf Biosample-exhasutive-FoF.yaml
	rm -rf Biosample-exhasutive-FoF-sorted.yaml
	rm -rf Biosample-exhasutive-FoF-sorted-exhaustion_report.yaml
	rm -rf Database-biosample-exhasutive.yaml

# or use curl ?
# or bundle something? would need to bundle data and schema to eliminate network traffic
Database-biosample-exhasutive.yaml:
	wget -O $@ "https://raw.githubusercontent.com/microbiomedata/nmdc-schema/main/src/data/valid/Database-biosample-exhasutive.yaml"

Biosample-exhasutive-FoF.yaml: Database-biosample-exhasutive.yaml
	poetry run get-first-of-first \
		--input_data $< \
		--output_data $@ \

Biosample-exhasutive-FoF-sorted.yaml: Biosample-exhasutive-FoF.yaml
	poetry run pretty-sort-yaml \
		-i $< \
		-o $@

Biosample-exhasutive-FoF-sorted-exhaustion_report.yaml: Biosample-exhasutive-FoF-sorted.yaml
	poetry run exhaustion-check \
		--class-name "Biosample" \
		--instance-yaml-file $< \
		--output-yaml-file $@ \
		--schema-path https://raw.githubusercontent.com/microbiomedata/nmdc-schema/main/src/schema/nmdc.yaml


