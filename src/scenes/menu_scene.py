import pygame
from src.settings import *

class MenuScene:
    def __init__(self):
        self.font_title = pygame.font.SysFont("Arial", 72, bold=True)
        self.font_sub   = pygame.font.SysFont("Arial", 28)
        self.font_sm    = pygame.font.SysFont("Arial", 20)
        self.tick       = 0
        self.options    = ["COMENZAR AVENTURA", "CONTROLES", "SALIR"]
        self.selected   = 0
        self.show_controls = False

    def handle_event(self, event):
        if event.type == pygame.KEYDOWN:
            if self.show_controls:
                self.show_controls = False
                return None
            if event.key in (pygame.K_UP, pygame.K_w):
                self.selected = (self.selected - 1) % len(self.options)
            elif event.key in (pygame.K_DOWN, pygame.K_s):
                self.selected = (self.selected + 1) % len(self.options)
            elif event.key == pygame.K_RETURN:
                choice = self.options[self.selected]
                if choice == "COMENZAR AVENTURA": return SCENE_GAME
                if choice == "CONTROLES":         self.show_controls = True
                if choice == "SALIR":             return "quit"
        return None

    def update(self):
        self.tick += 1

    def draw(self, surface):
        surface.fill((10, 5, 20))
        self._draw_stars(surface)

        title = self.font_title.render("WRATH OF THE GODS", True, GOLD)
        glow  = self.font_title.render("WRATH OF THE GODS", True, ORANGE)
        glow.set_alpha(60 + int(40 * abs(__import__('math').sin(self.tick * 0.04))))
        surface.blit(glow,  (SCREEN_WIDTH//2 - title.get_width()//2 + 3, 103))
        surface.blit(title, (SCREEN_WIDTH//2 - title.get_width()//2, 100))

        sub = self.font_sub.render("Un épico RPG de acción", True, (180, 140, 80))
        surface.blit(sub, (SCREEN_WIDTH//2 - sub.get_width()//2, 185))

        if self.show_controls:
            self._draw_controls(surface)
        else:
            for i, opt in enumerate(self.options):
                color = GOLD if i == self.selected else (160, 130, 70)
                lbl = self.font_sub.render(("▶  " if i == self.selected else "   ") + opt, True, color)
                surface.blit(lbl, (SCREEN_WIDTH//2 - lbl.get_width()//2, 300 + i * 60))

        ver = self.font_sm.render("v1.0", True, GRAY)
        surface.blit(ver, (SCREEN_WIDTH - 50, SCREEN_HEIGHT - 28))

    def _draw_stars(self, surface):
        import random
        rng = random.Random(1337)
        for _ in range(120):
            x = rng.randint(0, SCREEN_WIDTH)
            y = rng.randint(0, SCREEN_HEIGHT // 2)
            r = rng.randint(1, 2)
            alpha = 100 + rng.randint(0, 155)
            pygame.draw.circle(surface, (alpha, alpha, alpha), (x, y), r)

    def _draw_controls(self, surface):
        panel = pygame.Surface((500, 320), pygame.SRCALPHA)
        panel.fill((10, 10, 30, 220))
        px, py = SCREEN_WIDTH//2 - 250, SCREEN_HEIGHT//2 - 160
        surface.blit(panel, (px, py))
        pygame.draw.rect(surface, GOLD, (px, py, 500, 320), 2)
        title = self.font_sub.render("CONTROLES", True, GOLD)
        surface.blit(title, (SCREEN_WIDTH//2 - title.get_width()//2, py + 14))
        controls = [
            ("WASD / Flechas", "Mover"),
            ("ESPACIO",        "Ataque cuerpo a cuerpo"),
            ("E",              "Lanzar hacha (15 mana)"),
            ("R",              "Blizzard en área (25 mana)"),
            ("Q",              "Furia Espartana (30 mana)"),
            ("F / H",          "Usar poción"),
            ("I",              "Abrir tienda"),
            ("ESC",            "Menú / Salir"),
        ]
        for j, (key, desc) in enumerate(controls):
            k_lbl = self.font_sm.render(key,  True, YELLOW)
            d_lbl = self.font_sm.render(desc, True, WHITE)
            surface.blit(k_lbl, (px + 30,  py + 60 + j * 30))
            surface.blit(d_lbl, (px + 220, py + 60 + j * 30))
        hint = self.font_sm.render("Presiona cualquier tecla para volver", True, GRAY)
        surface.blit(hint, (SCREEN_WIDTH//2 - hint.get_width()//2, py + 290))
