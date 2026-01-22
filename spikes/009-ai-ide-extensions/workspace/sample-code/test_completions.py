"""
Sample Python file for testing AI code completions.

Test scenarios:
1. Function completion - type 'def calculate_' and see suggestions
2. Docstring generation - add docstring to existing function
3. Error handling - request try/except blocks
4. Type hints - request type annotations
"""

from dataclasses import dataclass
from pathlib import Path
from typing import Optional


@dataclass
class User:
    """Represents a user in the system."""
    id: int
    name: str
    email: str
    active: bool = True


def get_user_by_id(user_id: int, users: list[User]) -> Optional[User]:
    """Find a user by their ID."""
    for user in users:
        if user.id == user_id:
            return user
    return None


def process_user_data(filepath: Path) -> list[User]:
    """
    Load and process user data from a file.

    Test: Ask AI to add error handling and validation.
    """
    # TODO: Implement file reading
    # TODO: Add validation
    # TODO: Handle missing fields
    pass


# Test: Ask AI to complete this function
def calculate_statistics(numbers: list[float]):
    """Calculate basic statistics for a list of numbers."""
    # Let AI complete: mean, median, std_dev, min, max
    pass


# Test: Ask AI to generate tests for the User class
# Test: Ask AI to add logging to process_user_data
# Test: Ask AI to refactor get_user_by_id to use dict lookup
