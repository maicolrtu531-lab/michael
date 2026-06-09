import pygame
import random
import math
from src.settings import *

# Biome definitions: (base_color, accent_color)
BIOMES = {
    "snow":   {"base": (200, 220, 240), "accent": (220, 235, 255), "dec": "snow"},
    "lava":   {"base": (80,  30,  10),  "accent": (160, 50,  10),  "dec": "lava"},
    "forest": {"base": (25,  70,  25),  "accent": (35,  90,  35),  "dec": "tree"},
    "ruins":  {"base": (70,  65,  55),  "accent": (90,  80,  65),  "dec": "ruin"},
    "grass":  {"base": (40,  85,  40),  "accent": (50, 100,  50),  "dec": "none"},
    "dirt":   {"base": (70,  50,  30),  "accent": (85,  60,  35),  "dec": "rock"},
    "path":   {"base": (110, 90,  60),  "accent": (120, 100, 70),  "dec": "none"},
}

def _biome_at(col, row):
    # Snow — top-left quadrant
    if col < WORLD_COLS // 3 and row < WORLD_ROWS // 3:
        return "snow"
    # Ruins — top-right quadrant
    if col > WORLD_COLS * 2 // 3 and row < WORLD_ROWS // 3:
        return "ruins"
    # Lava — bottom-right quadrant
    if col > WORLD_COLS * 2 // 3 and row > WORLD_ROWS * 2 // 3:
        return "lava"
    # Forest — center band
    cx = abs(col - WORLD_COLS // 2)
    cy = abs(row - WORLD_ROWS // 2)
    if cx < WORLD_COLS // 5 and cy < WORLD_ROWS // 5:
        return "forest"
    # Paths (cross pattern)
    if abs(col - WORLD_COLS // 2) < 2 or abs(row - WORLD_ROWS // 2) < 2:
        return "path"
    # Dirt patches (noise-based)
    random.seed(col * 1000 + row)
    if random.random() < 0.2:
        return "dirt"
    return "grass"


class WorldMap:
    def __init__(self):
        self.biome_map = [[_biome_at(c, r) for c in range(WORLD_COLS)] for r in range(WORLD_ROWS)]
        self.rect = pygame.Rect(0, 0, WORLD_WIDTH, WORLD_HEIGHT)
        # Pre-generate decoration positions per tile (seeded for consistency)
        self._dec_cache = {}

    def _dec(self, r, c):
        if (r, c) in self._dec_cache:
            return self._dec_cache[(r, c)]
        rng = random.Random(r * 10007 + c * 97)
        val = (rng.random(), rng.randint(0, 3), rng.randint(4, 18), rng.randint(4, 18))
        self._dec_cache[(r, c)] = val
        return val

    def draw(self, surface, camera):
        sc = max(0, camera.offset_x // TILE_SIZE)
        ec = min(WORLD_COLS, sc + SCREEN_WIDTH  // TILE_SIZE + 2)
        sr = max(0, camera.offset_y // TILE_SIZE)
        er = min(WORLD_ROWS, sr + SCREEN_HEIGHT // TILE_SIZE + 2)

        for r in range(sr, er):
            for c in range(sc, ec):
                biome = self.biome_map[r][c]
                B = BIOMES[biome]
                x = c * TILE_SIZE - camera.offset_x
                y = r * TILE_SIZE - camera.offset_y

                # Base tile with slight checkerboard shade
                shade = 8 if (r + c) % 2 == 0 else 0
                base = tuple(max(0, v - shade) for v in B["base"])
                pygame.draw.rect(surface, base, (x, y, TILE_SIZE, TILE_SIZE))

                # Border
                pygame.draw.rect(surface, B["accent"], (x, y, TILE_SIZE, TILE_SIZE), 1)

                # Decorations
                prob, variant, dx, dy = self._dec(r, c)
                dec = B["dec"]

                if r == 0 or r == WORLD_ROWS-1 or c == 0 or c == WORLD_COLS-1:
                    # Border wall
                    pygame.draw.rect(surface, (55, 50, 45), (x, y, TILE_SIZE, TILE_SIZE))
                    pygame.draw.rect(surface, (80, 70, 60), (x+2, y+2, TILE_SIZE-4, TILE_SIZE-4), 2)
                    continue

                if dec == "tree" and prob < 0.18:
                    # Tree
                    pygame.draw.rect(surface, (80, 50, 20), (x+dx, y+dy+12, 6, 14))
                    pygame.draw.circle(surface, (20, 100, 20), (x+dx+3, y+dy+8), 14)
                    pygame.draw.circle(surface, (30, 130, 30), (x+dx+3, y+dy+4), 9)

                elif dec == "snow" and prob < 0.12:
                    # Snowman / snow pile
                    pygame.draw.circle(surface, (230, 240, 255), (x+dx, y+dy), 10)
                    pygame.draw.circle(surface, (210, 225, 245), (x+dx, y+dy-14), 7)
                    # Eyes
                    pygame.draw.circle(surface, (50, 50, 80), (x+dx-3, y+dy-15), 1)
                    pygame.draw.circle(surface, (50, 50, 80), (x+dx+3, y+dy-15), 1)

                elif dec == "lava" and prob < 0.25:
                    # Lava bubble
                    alpha = 160 + int(40 * math.sin(pygame.time.get_ticks() * 0.003 + c))
                    bubble = pygame.Surface((20, 12), pygame.SRCALPHA)
                    pygame.draw.ellipse(bubble, (255, 100, 0, alpha), (0, 0, 20, 12))
                    surface.blit(bubble, (x+dx-4, y+dy-4))

                elif dec == "ruin" and prob < 0.20:
                    # Broken column
                    col_h = 16 + variant * 4
                    pygame.draw.rect(surface, (100, 90, 75), (x+dx-4, y+dy, 10, col_h))
                    pygame.draw.rect(surface, (130, 115, 95), (x+dx-6, y+dy-4, 14, 6))

                elif dec == "rock" and prob < 0.15:
                    # Rock
                    pygame.draw.ellipse(surface, (90, 85, 80), (x+dx-6, y+dy-4, 14, 10))
                    pygame.draw.ellipse(surface, (110, 105, 95), (x+dx-5, y+dy-5, 12, 8), 1)

        # NPC spawn markers (visible as glowing circles on the ground)
        npc_positions = _npc_spawn_positions()
        for name, (wx, wy) in npc_positions.items():
            sx = wx - camera.offset_x
            sy = wy - camera.offset_y
            if -60 < sx < SCREEN_WIDTH + 60 and -60 < sy < SCREEN_HEIGHT + 60:
                glow = pygame.Surface((60, 60), pygame.SRCALPHA)
                c = {"Odin": BLUE, "Freya": GREEN, "Thor": YELLOW}[name]
                alpha = 60 + int(30 * math.sin(pygame.time.get_ticks() * 0.003))
                pygame.draw.circle(glow, (*c, alpha), (30, 30), 28)
                surface.blit(glow, (sx - 30, sy - 30))


def _npc_spawn_positions():
    return {
        "Odin":  (WORLD_WIDTH  // 6,     WORLD_HEIGHT // 6),
        "Freya": (WORLD_WIDTH  // 2,     WORLD_HEIGHT // 2 - 120),
        "Thor":  (WORLD_WIDTH  * 5 // 6, WORLD_HEIGHT * 5 // 6),
    }

NPC_SPAWN_POSITIONS = _npc_spawn_positions()
