#!/usr/bin/env bash
#
# Create a new Architecture Decision Record (ADR)
#
# Usage: ./new-adr.sh "Short Title for Decision"
#
# This script:
# 1. Finds the next ADR number
# 2. Creates a new ADR from template
# 3. Opens it in your editor

set -euo pipefail

# Configuration
ADR_DIR="${ADR_DIR:-docs/architecture/decisions}"
TEMPLATE="${ADR_DIR}/template.md"
EDITOR="${EDITOR:-code}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 \"Short Title for Decision\""
    echo ""
    echo "Creates a new Architecture Decision Record."
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo "  -d, --dir     ADR directory (default: docs/architecture/decisions)"
    echo "  -n, --no-edit Don't open editor after creation"
    echo ""
    echo "Examples:"
    echo "  $0 \"Use PostgreSQL for primary database\""
    echo "  $0 \"Adopt microservices architecture\""
    exit 1
}

# Parse arguments
TITLE=""
NO_EDIT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -d|--dir)
            ADR_DIR="$2"
            shift 2
            ;;
        -n|--no-edit)
            NO_EDIT=true
            shift
            ;;
        *)
            TITLE="$1"
            shift
            ;;
    esac
done

if [[ -z "$TITLE" ]]; then
    echo -e "${RED}Error: Title is required${NC}"
    usage
fi

# Ensure ADR directory exists
mkdir -p "$ADR_DIR"

# Find next ADR number
get_next_number() {
    local max_num=0
    for file in "$ADR_DIR"/[0-9][0-9][0-9]-*.md; do
        if [[ -f "$file" ]]; then
            num=$(basename "$file" | cut -d'-' -f1)
            num=$((10#$num)) # Remove leading zeros
            if [[ $num -gt $max_num ]]; then
                max_num=$num
            fi
        fi
    done
    printf "%03d" $((max_num + 1))
}

# Convert title to filename slug
slugify() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-'
}

NEXT_NUM=$(get_next_number)
SLUG=$(slugify "$TITLE")
FILENAME="${NEXT_NUM}-${SLUG}.md"
FILEPATH="${ADR_DIR}/${FILENAME}"

# Check if file already exists
if [[ -f "$FILEPATH" ]]; then
    echo -e "${RED}Error: ADR already exists: ${FILEPATH}${NC}"
    exit 1
fi

# Get current date
DATE=$(date +%Y-%m-%d)

# Get git user for author
AUTHOR=$(git config user.name 2>/dev/null || echo "Author")

# Create ADR content
cat > "$FILEPATH" << EOF
# ADR-${NEXT_NUM}: ${TITLE}

<!--
AI Agent Instructions:
- This ADR documents a significant technical decision
- Read the Context to understand WHY this decision was needed
- Read Decision to understand WHAT was chosen
- Read Consequences to understand TRADE-OFFS
- Check Alternatives to avoid re-proposing rejected options
-->

## Metadata

| Field | Value |
|-------|-------|
| Status | Proposed |
| Date | ${DATE} |
| Decision Makers | @${AUTHOR} |
| Tags | architecture |

## Context

<!-- What is the issue that we're seeing that is motivating this decision? -->

[Describe the situation, constraints, and forces at play]

## Decision

<!-- What is the change that we're proposing and/or doing? -->

We will [decision statement].

### Implementation Details

1. [Step or component 1]
2. [Step or component 2]

## Consequences

### Positive

- [Benefit 1]
- [Benefit 2]

### Negative

- [Drawback 1]
- [Mitigation strategy]

## Alternatives Considered

### Alternative 1: [Name]

**Description**: [Brief description]

**Pros**:
- [Pro]

**Cons**:
- [Con]

**Why Rejected**: [Reason]

## References

- [Link to relevant resource]
EOF

echo -e "${GREEN}Created ADR: ${FILEPATH}${NC}"

# Open in editor unless --no-edit flag
if [[ "$NO_EDIT" == "false" ]]; then
    echo -e "${YELLOW}Opening in ${EDITOR}...${NC}"
    $EDITOR "$FILEPATH"
fi
