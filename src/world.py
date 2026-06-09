import pygame
import random
from src.settings import *

TERRAIN = {
    0: (30, 70, 30),    # grass
    1: (60, 45, 25),    # dirt
    2: (50, 50, 55),    # stone
    3: (20, 40, 80),    # water (impassable visual)
    4: (80, 50, 20),    # sand
}

class WorldMap:
    def __init__(self):
        random.seed(42)
        self.tiles = self._generate()
        self.rect  = pygame.Rect(0, 0, WORLD_WIDTH, WORLD_HEIGHT)

    def _generate(self):
        tiles = []
        for r in range(WORLD_ROWS):
            row = []
            for c in range(WORLD_COLS):
                # Border = stone
                if r == 0 or r == WORLD_ROWS-1 or c == 0 or c == WORLD_COLS-1:
                    row.append(2)
                else:
                    row.append(random.choices([0, 1, 2, 4], weights=[60, 20, 15, 5])[0])
            tiles.append(row)
        return tiles

    def draw(self, surface, camera):
        start_col = max(0, camera.offset_x // TILE_SIZE)
        end_col   = min(WORLD_COLS, start_col + SCREEN_WIDTH  // TILE_SIZE + 2)
        start_row = max(0, camera.offset_y // TILE_SIZE)
        end_row   = min(WORLD_ROWS, start_row + SCREEN_HEIGHT // TILE_SIZE + 2)

        for r in range(start_row, end_row):
            for c in range(start_col, end_col):
                t = self.tiles[r][c]
                x = c * TILE_SIZE - camera.offset_x
                y = r * TILE_SIZE - camera.offset_y
                color = TERRAIN[t]
                pygame.draw.rect(surface, color, (x, y, TILE_SIZE, TILE_SIZE))
                # Grid lines
                pygame.draw.rect(surface, (color[0]-10, color[1]-10, color[2]-10), (x, y, TILE_SIZE, TILE_SIZE), 1)

        # Decorations: random rocks/trees
        random.seed(99)
        for r in range(start_row, end_row):
            for c in range(start_col, end_col):
                if self.tiles[r][c] == 2:
                    x = c * TILE_SIZE - camera.offset_x
                    y = r * TILE_SIZE - camera.offset_y
                    pygame.draw.circle(surface, (70, 60, 65), (x + 32, y + 32), 18)
                elif self.tiles[r][c] == 0 and random.random() < 0.15:
                    x = c * TILE_SIZE - camera.offset_x
                    y = r * TILE_SIZE - camera.offset_y
                    pygame.draw.circle(surface, (20, 50, 15), (x + 20, y + 20), 14)
                    pygame.draw.rect(surface, (80, 50, 20), (x + 17, y + 30, 6, 12))
