#!/bin/bash
# UID/GID ownership test

echo "Container user:"
id
echo ""

echo "=== Bind Mount (/workspace) ==="
echo "Creating file..."
touch /workspace/test-uid-file.txt
ls -la /workspace/test-uid-file.txt
rm -f /workspace/test-uid-file.txt
echo ""

echo "=== Home directory (container-owned) ==="
ls -la /home/dev/ | head -10
echo ""
echo "Creating file in home..."
touch /home/dev/test-uid-file.txt
ls -la /home/dev/test-uid-file.txt
rm -f /home/dev/test-uid-file.txt
echo ""

echo "=== Named volume ownership ==="
if [ -d "/named-vol" ]; then
    ls -la / | grep named-vol
    touch /named-vol/test-uid-file.txt 2>&1 && ls -la /named-vol/test-uid-file.txt || echo "Cannot write to /named-vol (permission denied)"
fi
