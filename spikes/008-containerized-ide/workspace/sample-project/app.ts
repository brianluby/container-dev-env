/**
 * Sample TypeScript file for IDE feature testing.
 */

interface User {
  id: number;
  name: string;
  email: string;
  createdAt: Date;
}

interface ApiResponse<T> {
  data: T;
  status: number;
  message: string;
}

function createUser(name: string, email: string): User {
  return {
    id: Math.floor(Math.random() * 10000),
    name,
    email,
    createdAt: new Date(),
  };
}

async function fetchUser(id: number): Promise<ApiResponse<User | null>> {
  // Simulated async operation
  return new Promise((resolve) => {
    setTimeout(() => {
      if (id > 0) {
        resolve({
          data: createUser(`User${id}`, `user${id}@example.com`),
          status: 200,
          message: "Success",
        });
      } else {
        resolve({
          data: null,
          status: 404,
          message: "User not found",
        });
      }
    }, 100);
  });
}

class UserService {
  private users: Map<number, User> = new Map();

  addUser(user: User): void {
    this.users.set(user.id, user);
  }

  getUser(id: number): User | undefined {
    return this.users.get(id);
  }

  getAllUsers(): User[] {
    return Array.from(this.users.values());
  }

  deleteUser(id: number): boolean {
    return this.users.delete(id);
  }
}

// Main execution
const service = new UserService();
const user = createUser("Test User", "test@example.com");
service.addUser(user);

console.log("Created user:", user);
console.log("All users:", service.getAllUsers());
