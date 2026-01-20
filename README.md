# Container Development Environment

A containerized development environment that allows you to run all development tools within containers. This provides a consistent, portable, and reproducible development setup across different machines.

## Features

- **Portability**: Spin up your development environment on any machine with Docker installed
- **Consistency**: Same tools and versions across all machines
- **Flexibility**: Multiple pre-configured environments (base, Python, Node.js)
- **Experimentation**: Try new tools without affecting your host system
- **Easy Rollback**: Rebuild or switch environments quickly
- **Isolation**: Each project can have its own environment configuration

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (version 20.10 or higher)
- [Docker Compose](https://docs.docker.com/compose/install/) (version 1.29 or higher)

## Quick Start

### 1. Start the Base Development Environment

```bash
./scripts/start.sh
```

This will:
- Build the Docker image if it doesn't exist
- Start the container
- Drop you into a bash shell inside the container

### 2. Start a Language-Specific Environment

For Python development:
```bash
./scripts/start.sh python-dev
```

For Node.js development:
```bash
./scripts/start.sh node-dev
```

### 3. Stop the Environment

```bash
./scripts/stop.sh
```

To stop a specific environment:
```bash
./scripts/stop.sh python-dev
```

## Available Environments

### Base Development Environment (`dev`)
- Ubuntu 22.04 base
- Git, Vim, Nano
- Python 3, Node.js, npm
- Docker CLI (for Docker-in-Docker scenarios)
- Build tools (gcc, make, etc.)

**Usage:**
```bash
docker-compose up -d dev
docker-compose exec dev /bin/bash
```

### Python Development Environment (`python-dev`)
- All base tools
- Python 3 with pip
- Popular Python tools: black, flake8, pylint, pytest, poetry
- Virtual environment support

**Usage:**
```bash
docker-compose up -d python-dev
docker-compose exec python-dev /bin/bash
```

### Node.js Development Environment (`node-dev`)
- All base tools
- Node.js 18.x with npm
- Yarn package manager
- Common tools: ESLint, Prettier, TypeScript, nodemon

**Usage:**
```bash
docker-compose up -d node-dev
docker-compose exec node-dev /bin/bash
```

## Helper Scripts

Located in the `scripts/` directory:

- **`start.sh [service]`**: Build (if needed) and start a development environment
- **`stop.sh [service]`**: Stop and remove containers
- **`rebuild.sh [service]`**: Rebuild an environment from scratch
- **`clean.sh`**: Remove all containers, images, and volumes (use with caution)

## Customization

### Adding New Tools to an Existing Environment

Edit the corresponding `Dockerfile` and rebuild:

```bash
./scripts/rebuild.sh dev
```

### Creating a New Environment

1. Create a new `Dockerfile.<name>` (e.g., `Dockerfile.go`)
2. Add a new service in `docker-compose.yml`
3. Build and start:
   ```bash
   docker-compose build <name>-dev
   docker-compose up -d <name>-dev
   ```

### Persisting Data

The docker-compose configuration includes volumes for:
- Bash history
- Language-specific package caches
- Your workspace (mounted from the current directory)

## Docker-in-Docker

The base environment includes Docker CLI and mounts the Docker socket, allowing you to run Docker commands from within the container. This is useful for:
- Building Docker images
- Running containerized services
- Testing Docker-based workflows

## Troubleshooting

### Permission Issues

If you encounter permission issues, ensure your user ID matches the container user (default: 1000):

```bash
id -u  # Check your user ID
```

### Docker Socket Permission Denied

Add your user to the Docker group:
```bash
sudo usermod -aG docker $USER
```
Then log out and back in.

### Container Won't Start

Check Docker logs:
```bash
docker-compose logs <service>
```

### Rebuilding Everything

If things get messy, clean up and rebuild:
```bash
./scripts/clean.sh
./scripts/start.sh
```

## Examples

### Python Project Development

```bash
# Start Python environment
./scripts/start.sh python-dev

# Inside the container
pip install -r requirements.txt
python -m pytest tests/
black .
```

### Node.js Project Development

```bash
# Start Node environment
./scripts/start.sh node-dev

# Inside the container
npm install
npm run test
npm run dev
```

### Working with Multiple Projects

You can run multiple environments simultaneously:

```bash
# Terminal 1: Python project
cd ~/projects/python-app
./scripts/start.sh python-dev

# Terminal 2: Node.js project
cd ~/projects/node-app
./scripts/start.sh node-dev
```

## Contributing

To add new environments or improve existing ones:
1. Create or modify the appropriate Dockerfile
2. Update docker-compose.yml if adding a new service
3. Test your changes
4. Update this README with documentation

## License

This project is open source and available under the MIT License.
