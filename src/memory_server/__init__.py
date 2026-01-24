"""Persistent memory MCP server for AI coding agents."""

import logging
import sys

__version__ = "0.1.0"


class _ContextFilter(logging.Filter):
    """Injects project_id and session_id into log records for correlation."""

    def __init__(self) -> None:
        super().__init__()
        self.project_id: str = ""
        self.session_id: str = ""

    def filter(self, record: logging.LogRecord) -> bool:
        record.project_id = self.project_id
        record.session_id = self.session_id
        return True


# Structured JSON logging to stderr (stdout reserved for MCP JSON-RPC)
logger = logging.getLogger("memory_server")
_handler = logging.StreamHandler(sys.stderr)
_handler.setFormatter(
    logging.Formatter(
        '{"timestamp":"%(asctime)s","level":"%(levelname)s",'
        '"logger":"%(name)s","project_id":"%(project_id)s",'
        '"session_id":"%(session_id)s","message":"%(message)s"}'
    )
)
_context_filter = _ContextFilter()
_handler.addFilter(_context_filter)
logger.addHandler(_handler)
logger.setLevel(logging.INFO)


def set_log_context(*, project_id: str = "", session_id: str = "") -> None:
    """Set correlation IDs for structured log output.

    Args:
        project_id: The current project identifier.
        session_id: The current session identifier.
    """
    _context_filter.project_id = project_id
    _context_filter.session_id = session_id
