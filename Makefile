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
	docker exec -it devenv-ide-1 bash

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
