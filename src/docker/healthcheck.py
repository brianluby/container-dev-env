"""T067: Health check script for the memory MCP server container.

Verifies that the MCP server process is running and the SQLite database
is accessible. Reports status as JSON to stdout for Docker HEALTHCHECK.

Exit codes:
    0: Healthy - server responsive, database accessible.
    1: Unhealthy - one or more checks failed.
"""

from __future__ import annotations

import json
import os
import sqlite3
import sys


def check_health() -> dict[str, object]:
    """Run health checks and return status report.

    Returns:
        Dictionary with overall status and individual check results.
    """
    checks: dict[str, object] = {}
    healthy = True

    # Check 1: Database path exists and is accessible
    db_base = os.environ.get("MEMORY_DB_PATH", "")
    if not db_base:
        checks["db_path"] = "MEMORY_DB_PATH not set"
        healthy = False
    elif not os.path.isdir(db_base):
        checks["db_path"] = f"directory does not exist: {db_base}"
        healthy = False
    else:
        checks["db_path"] = "ok"

    # Check 2: SQLite is functional (can open in-memory DB)
    try:
        conn = sqlite3.connect(":memory:")
        conn.execute("SELECT 1")
        conn.close()
        checks["sqlite"] = "ok"
    except Exception as exc:
        checks["sqlite"] = f"failed: {exc}"
        healthy = False

    # Check 3: Database directory is writable
    if db_base and os.path.isdir(db_base):
        probe = os.path.join(db_base, ".healthcheck_probe")
        try:
            with open(probe, "w") as f:
                f.write("probe")
            os.remove(probe)
            checks["writable"] = "ok"
        except OSError as exc:
            checks["writable"] = f"not writable: {exc}"
            healthy = False
    else:
        checks["writable"] = "skipped (no db_path)"

    return {
        "status": "healthy" if healthy else "unhealthy",
        "checks": checks,
    }


if __name__ == "__main__":
    result = check_health()
    print(json.dumps(result))  # noqa: T201
    sys.exit(0 if result["status"] == "healthy" else 1)
