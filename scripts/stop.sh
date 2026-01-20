#!/bin/bash
# Stop the containerized development environment

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SERVICE="${1:-}"

echo -e "${BLUE}Stopping containerized development environment...${NC}"

if [ -z "$SERVICE" ]; then
    docker compose down
    echo -e "${GREEN}All containers stopped and removed.${NC}"
else
    docker compose stop ${SERVICE}
    docker compose rm -f ${SERVICE}
    echo -e "${GREEN}Container '${SERVICE}' stopped and removed.${NC}"
fi
