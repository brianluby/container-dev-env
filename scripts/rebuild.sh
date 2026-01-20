#!/bin/bash
# Rebuild the containerized development environment

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SERVICE="${1:-dev}"

echo -e "${YELLOW}Rebuilding containerized development environment...${NC}"
echo -e "${BLUE}Service: ${SERVICE}${NC}"

# Stop and remove the existing container
docker compose stop ${SERVICE} 2>/dev/null || true
docker compose rm -f ${SERVICE} 2>/dev/null || true

# Rebuild the image
echo -e "${YELLOW}Building Docker image...${NC}"
docker compose build --no-cache ${SERVICE}

echo -e "${GREEN}Rebuild complete!${NC}"
echo -e "${BLUE}Use './scripts/start.sh ${SERVICE}' to start the environment.${NC}"
