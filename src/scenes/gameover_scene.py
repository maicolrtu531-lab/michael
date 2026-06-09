import pygame
from src.settings import *

class GameOverScene:
    def __init__(self, win=False, kills=0, level=1, gold=0):
        self.win    = win
        self.kills  = kills
        self.level  = level
        self.gold   = gold
        self.font_big = pygame.font.SysFont("Arial", 64, bold=True)
        self.font     = pygame.font.SysFont("Arial", 28)
        self.font_sm  = pygame.font.SysFont("Arial", 20)
        self.tick     = 0

    def handle_event(self, event):
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_RETURN: return SCENE_MENU
            if event.key == pygame.K_ESCAPE: return "quit"
        return None

    def update(self):
        self.tick += 1

    def draw(self, surface):
        surface.fill((5, 0, 0) if not self.win else (0, 10, 5))

        if self.win:
            title_text = "¡VICTORIA!"
            color = GOLD
        else:
            title_text = "GAME OVER"
            color = RED

        title = self.font_big.render(title_text, True, color)
        surface.blit(title, (SCREEN_WIDTH//2 - title.get_width()//2, 180))

        stats = [
            f"Nivel alcanzado: {self.level}",
            f"Enemigos eliminados: {self.kills}",
            f"Oro recolectado: {self.gold}",
        ]
        for i, s in enumerate(stats):
            lbl = self.font.render(s, True, WHITE)
            surface.blit(lbl, (SCREEN_WIDTH//2 - lbl.get_width()//2, 300 + i * 44))

        hint = self.font_sm.render("ENTER — Volver al menú  |  ESC — Salir", True, GRAY)
        surface.blit(hint, (SCREEN_WIDTH//2 - hint.get_width()//2, SCREEN_HEIGHT - 60))
