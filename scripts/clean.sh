#!/bin/bash
# Clean up all containerized development environment resources

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}WARNING: This will remove all containers, images, and volumes created by this project.${NC}"
read -p "Are you sure you want to continue? (y/N) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Cleanup cancelled.${NC}"
    exit 0
fi

echo -e "${RED}Cleaning up...${NC}"

# Stop and remove all containers
docker compose down -v

# Remove images
docker images | grep "container-dev-env" | awk '{print $3}' | xargs -r docker rmi -f

echo -e "${GREEN}Cleanup complete!${NC}"
