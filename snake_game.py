import pygame
import random
import sys

pygame.init()

WINDOW_WIDTH = 640
WINDOW_HEIGHT = 640
GRID_SIZE = 20
CELL_SIZE = WINDOW_WIDTH // GRID_SIZE
SNAKE_COLOR = (0, 255, 0)
FOOD_COLOR = (255, 0, 0)
BACKGROUND_COLOR = (0, 0, 0)
TEXT_COLOR = (255, 255, 255)

screen = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
pygame.display.set_caption("Snake Game")
clock = pygame.time.Clock()
font = pygame.font.Font(None, 36)

class Snake:
    def __init__(self):
        self.positions = [(GRID_SIZE // 2, GRID_SIZE // 2)]
        self.direction = (1, 0)
        self.grow = False
    
    def move(self):
        head = self.positions[0]
        new_head = ((head[0] + self.direction[0]) % GRID_SIZE, 
                   (head[1] + self.direction[1]) % GRID_SIZE)
        
        if new_head in self.positions:
            return False
        
        self.positions.insert(0, new_head)
        if not self.grow:
            self.positions.pop()
        else:
            self.grow = False
        return True
    
    def change_direction(self, new_dir):
        if (new_dir[0] * -1, new_dir[1] * -1) != self.direction:
            self.direction = new_dir
    
    def grow_snake(self):
        self.grow = True
    
    def draw(self, screen):
        for pos in self.positions:
            rect = pygame.Rect(pos[0] * CELL_SIZE, pos[1] * CELL_SIZE, CELL_SIZE, CELL_SIZE)
            pygame.draw.rect(screen, SNAKE_COLOR, rect)
            pygame.draw.rect(screen, (0, 200, 0), rect, 2)

class Food:
    def __init__(self, snake_positions):
        self.position = self.generate_position(snake_positions)
    
    def generate_position(self, snake_positions):
        while True:
            pos = (random.randint(0, GRID_SIZE - 1), random.randint(0, GRID_SIZE - 1))
            if pos not in snake_positions:
                return pos
    
    def respawn(self, snake_positions):
        self.position = self.generate_position(snake_positions)
    
    def draw(self, screen):
        rect = pygame.Rect(self.position[0] * CELL_SIZE, self.position[1] * CELL_SIZE, CELL_SIZE, CELL_SIZE)
        pygame.draw.rect(screen, FOOD_COLOR, rect)

class Game:
    def __init__(self):
        self.snake = Snake()
        self.food = Food(self.snake.positions)
        self.score = 0
        self.game_over = False
        self.speed = 10
    
    def handle_events(self):
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_UP:
                    self.snake.change_direction((0, -1))
                elif event.key == pygame.K_DOWN:
                    self.snake.change_direction((0, 1))
                elif event.key == pygame.K_LEFT:
                    self.snake.change_direction((-1, 0))
                elif event.key == pygame.K_RIGHT:
                    self.snake.change_direction((1, 0))
                elif event.key == pygame.K_SPACE and self.game_over:
                    self.__init__()
        return True
    
    def update(self):
        if not self.game_over:
            if not self.snake.move():
                self.game_over = True
            
            if self.snake.positions[0] == self.food.position:
                self.snake.grow_snake()
                self.food.respawn(self.snake.positions)
                self.score += 1
                if self.score % 5 == 0:
                    self.speed = min(self.speed + 2, 20)
    
    def draw(self, screen):
        screen.fill(BACKGROUND_COLOR)
        
        for i in range(0, WINDOW_WIDTH, CELL_SIZE):
            pygame.draw.line(screen, (40, 40, 40), (i, 0), (i, WINDOW_HEIGHT))
            pygame.draw.line(screen, (40, 40, 40), (0, i), (WINDOW_WIDTH, i))
        
        self.snake.draw(screen)
        self.food.draw(screen)
        
        score_text = font.render(f"Score: {self.score}", True, TEXT_COLOR)
        screen.blit(score_text, (10, 10))
        
        if self.game_over:
            game_over_text = font.render("GAME OVER! Press SPACE to restart", True, TEXT_COLOR)
            text_rect = game_over_text.get_rect(center=(WINDOW_WIDTH // 2, WINDOW_HEIGHT // 2))
            screen.blit(game_over_text, text_rect)
    
    def run(self):
        running = True
        while running:
            running = self.handle_events()
            self.update()
            self.draw(screen)
            pygame.display.flip()
            clock.tick(self.speed)
        
        pygame.quit()
        sys.exit()

if __name__ == "__main__":
    game = Game()
    game.run()