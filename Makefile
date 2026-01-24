# Containerized IDE convenience targets
COMPOSE_FILE := src/docker/docker-compose.ide.yml

.PHONY: ide-up ide-down ide-token ide-logs ide-shell ide-test

## Start the IDE container
ide-up:
	@if [ ! -f .env ]; then \
		echo "Generating connection token..."; \
		./src/scripts/generate-token.sh > .env; \
	fi
	docker compose -f $(COMPOSE_FILE) up -d --build

## Stop the IDE container
ide-down:
	docker compose -f $(COMPOSE_FILE) down

## Generate a new connection token
ide-token:
	./src/scripts/generate-token.sh > .env
	@echo "Token generated. Restart IDE with: make ide-down ide-up"
	@grep CONNECTION_TOKEN .env

## Show IDE container logs
ide-logs:
	docker compose -f $(COMPOSE_FILE) logs -f

## Open a shell in the IDE container
ide-shell:
	docker compose -f $(COMPOSE_FILE) exec ide bash

## Run all IDE integration tests
ide-test:
	./tests/integration/test-ide-startup.sh
	./tests/integration/test-ide-terminal.sh
	./tests/integration/test-ide-auth.sh
	./tests/integration/test-ide-extensions.sh
	./tests/integration/test-ide-git.sh
	./tests/integration/test-ide-volumes.sh
	./tests/integration/test-ide-resources.sh
	./tests/contract/test-ide-interface.sh

# ─── Notification System (016-mobile-access) ───────────────────────────

NOTIFY_SRC := src/notify.sh src/notify-sanitize.sh

## Lint notify scripts with shellcheck
notify-lint:
	shellcheck $(NOTIFY_SRC)

## Format notify scripts with shfmt
notify-format:
	shfmt -w -i 2 -ci $(NOTIFY_SRC)

## Check notify script formatting (CI mode)
notify-format-check:
	shfmt -d -i 2 -ci $(NOTIFY_SRC)

## Run all notify tests
notify-test:
	bats tests/unit/ tests/integration/

## Run notify unit tests only
notify-test-unit:
	bats tests/unit/

## Run notify integration tests only
notify-test-integration:
	bats tests/integration/
