/**
 * Sample TypeScript file for testing AI code completions.
 *
 * Test scenarios:
 * 1. Interface completion - add properties to interfaces
 * 2. Generic type completion - implement generic functions
 * 3. Async/await patterns - complete async functions
 * 4. Error handling - add try/catch blocks
 */

interface User {
  id: number;
  name: string;
  email: string;
  createdAt: Date;
  // Test: Ask AI to add more fields
}

interface ApiResponse<T> {
  data: T;
  status: number;
  message: string;
}

// Test: Ask AI to complete this function with proper error handling
async function fetchUser(userId: number): Promise<ApiResponse<User>> {
  // TODO: Implement fetch with error handling
  // TODO: Add retry logic
  // TODO: Add timeout
  throw new Error("Not implemented");
}

// Test: Ask AI to complete this validation function
function validateEmail(email: string): boolean {
  // Let AI complete the regex and validation logic
  return false;
}

// Test: Ask AI to implement this caching decorator
function memoize<T extends (...args: unknown[]) => unknown>(fn: T): T {
  // Let AI implement memoization
  return fn;
}

// Test: Ask AI to generate a React component from this interface
interface ButtonProps {
  label: string;
  onClick: () => void;
  variant?: "primary" | "secondary" | "danger";
  disabled?: boolean;
}

// Test: Ask AI to complete this class
class UserService {
  private users: Map<number, User> = new Map();

  // Let AI implement CRUD operations
}

// Test: Ask AI to add JSDoc comments to all functions above
// Test: Ask AI to convert UserService to functional approach
// Test: Ask AI to add zod schema validation for User interface
