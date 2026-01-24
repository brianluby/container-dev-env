# container-dev-env
Containerized development environment

## Features

- **Containerized Development**: Reproducible development environments using Docker
- **Dotfile Management**: Personal configuration via Chezmoi
- **Secret Injection**: Secure handling of API keys, tokens, and credentials

## Documentation

- Getting started: [docs/getting-started.md](docs/getting-started.md)
- Advanced guide: [docs/advanced-guide.md](docs/advanced-guide.md)

## Secret Injection

Securely manage secrets (API keys, tokens, credentials) using age-encrypted dotfiles:

```bash
# First-time setup (5 minutes)
./scripts/secrets-setup.sh

# Edit secrets
chezmoi edit ~/.secrets.env

# Apply and restart container
chezmoi apply
```

Secrets are:
- Encrypted at rest with your personal age key
- Automatically loaded as environment variables at container startup
- Invisible to `docker inspect` (loaded at runtime, not baked into images)
- Available offline after initial setup

See [docs/secrets-guide.md](docs/secrets-guide.md) for complete documentation.

## Quick Start

1. Build the container:
   ```bash
    docker compose -f docker/docker-compose.yml build
    ```

2. Start the container:
   ```bash
    docker compose -f docker/docker-compose.yml up -d
    ```

3. Attach to the container:
   ```bash
    docker compose -f docker/docker-compose.yml exec dev bash
    ```

4. Set up secrets (first time only):
   ```bash
   ./scripts/secrets-setup.sh
   ```
