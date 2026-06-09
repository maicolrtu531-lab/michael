import pygame
from src.settings import *

class HUD:
    def __init__(self):
        self.font = pygame.font.SysFont("Arial", 18)
        self.font_big = pygame.font.SysFont("Arial", 22, bold=True)

    def draw(self, surface, player):
        self._bar(surface, 20, 20, player.hp, player.max_hp, RED, "HP")
        self._bar(surface, 20, 50, player.mana, player.max_mana, BLUE, "MP")
        level_text = self.font_big.render(f"Nivel {player.level}  EXP: {player.exp}/{player.level*100}", True, YELLOW)
        surface.blit(level_text, (20, 80))

    def _bar(self, surface, x, y, current, maximum, color, label):
        bar_w = 200
        ratio = max(0, current / maximum)
        pygame.draw.rect(surface, GRAY, (x, y, bar_w, 18))
        pygame.draw.rect(surface, color, (x, y, int(bar_w * ratio), 18))
        pygame.draw.rect(surface, WHITE, (x, y, bar_w, 18), 2)
        text = self.font.render(f"{label}: {current}/{maximum}", True, WHITE)
        surface.blit(text, (x + 4, y + 1))
