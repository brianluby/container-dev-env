#!/usr/bin/env python3
"""Sample Python file for IDE feature testing."""

from typing import List, Optional


def greet(name: str) -> str:
    """Return a greeting message."""
    return f"Hello, {name}!"


def calculate_sum(numbers: List[int]) -> int:
    """Calculate the sum of a list of numbers."""
    return sum(numbers)


def find_max(numbers: List[int]) -> Optional[int]:
    """Find the maximum value in a list, or None if empty."""
    if not numbers:
        return None
    return max(numbers)


class Calculator:
    """A simple calculator class for testing IntelliSense."""

    def __init__(self, initial_value: int = 0):
        self.value = initial_value

    def add(self, x: int) -> "Calculator":
        """Add a value."""
        self.value += x
        return self

    def subtract(self, x: int) -> "Calculator":
        """Subtract a value."""
        self.value -= x
        return self

    def multiply(self, x: int) -> "Calculator":
        """Multiply by a value."""
        self.value *= x
        return self

    def get_result(self) -> int:
        """Get the current value."""
        return self.value


if __name__ == "__main__":
    print(greet("World"))
    print(f"Sum: {calculate_sum([1, 2, 3, 4, 5])}")

    calc = Calculator(10)
    result = calc.add(5).multiply(2).subtract(10).get_result()
    print(f"Calculator result: {result}")
