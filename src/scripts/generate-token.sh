#!/usr/bin/env bash
# Generate a cryptographically random 32-character hex connection token
# Output: CONNECTION_TOKEN=<32-hex-chars> (suitable for .env file)
set -euo pipefail

token=$(head -c 16 /dev/urandom | xxd -p)
echo "CONNECTION_TOKEN=${token}"
