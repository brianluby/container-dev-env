# Examples Directory

This directory contains example configurations for additional development environments that you can use as templates.

## Available Examples

### Go Development Environment
- **File**: `Dockerfile.go`
- **Tools**: Go compiler, gopls, delve debugger, staticcheck
- See `docker-compose-examples.yml` for the corresponding docker-compose service configuration

### Rust Development Environment
- **File**: `Dockerfile.rust`
- **Tools**: Rust toolchain (rustc, cargo), rustfmt, clippy, rust-analyzer
- See `docker-compose-examples.yml` for the corresponding docker-compose service configuration

### Environment Variables
- **File**: `.env.example`
- Copy to `.env` in the project root and customize as needed

## How to Use These Examples

1. Copy the desired Dockerfile to the project root:
   ```bash
   cp examples/Dockerfile.go ../Dockerfile.go
   ```

2. Add the corresponding service from `docker-compose-examples.yml` to your `docker-compose.yml`

3. Build and start the environment:
   ```bash
   docker-compose build go-dev
   docker-compose up -d go-dev
   docker-compose exec go-dev /bin/bash
   ```

## Creating Your Own Environment

Use these examples as templates to create environments for other languages or tools:
1. Copy an existing Dockerfile and modify it for your needs
2. Update the base image, installed packages, and tools
3. Add a corresponding service in docker-compose.yml
4. Document your environment in the README
