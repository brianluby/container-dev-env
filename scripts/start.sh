#!/bin/bash
# Start the containerized development environment

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default service
SERVICE="${1:-dev}"

echo -e "${BLUE}Starting containerized development environment...${NC}"
echo -e "${BLUE}Service: ${SERVICE}${NC}"

# Build the image if it doesn't exist or if it needs building
echo -e "${YELLOW}Building Docker image (this may take a few minutes)...${NC}"
docker compose build ${SERVICE}

# Start the container
echo -e "${GREEN}Starting container...${NC}"
docker compose up -d ${SERVICE}

# Attach to the container
echo -e "${GREEN}Attaching to container...${NC}"
docker compose exec ${SERVICE} /bin/bash

echo -e "${GREEN}Exited from container.${NC}"
echo -e "${BLUE}Container is still running. Use './scripts/stop.sh' to stop it.${NC}"
