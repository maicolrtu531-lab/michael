import pygame
from src.settings import *

STAT_KEYS   = ["Fuerza", "Vitalidad", "Agilidad", "Inteligencia"]
STAT_COLORS = {
    "Fuerza":       RED,
    "Vitalidad":    (100, 220, 100),
    "Agilidad":     CYAN,
    "Inteligencia": LIGHT_BLUE,
}
STAT_DESC = {
    "Fuerza":       "Daño +5 por nivel",
    "Vitalidad":    "HP máx +25 por nivel",
    "Agilidad":     "Velocidad +0.4 por nivel",
    "Inteligencia": "Mana máx +15 por nivel",
}


class StatsMenu:
    def __init__(self):
        self.visible    = False
        self.selected   = 0
        self.font_title = pygame.font.SysFont("Arial", 26, bold=True)
        self.font_main  = pygame.font.SysFont("Arial", 20)
        self.font_sm    = pygame.font.SysFont("Arial", 15)

    def toggle(self):
        self.visible = not self.visible
        self.selected = 0

    def handle_event(self, event, player):
        if not self.visible:
            return
        if event.type == pygame.KEYDOWN:
            if event.key in (pygame.K_m, pygame.K_ESCAPE):
                self.visible = False
            elif event.key == pygame.K_UP:
                self.selected = (self.selected - 1) % len(STAT_KEYS)
            elif event.key == pygame.K_DOWN:
                self.selected = (self.selected + 1) % len(STAT_KEYS)
            elif event.key == pygame.K_RETURN:
                self._upgrade(player)

    def _cost(self, player, stat):
        return player.stats[stat]   # cost = current level of that stat

    def _upgrade(self, player):
        stat = STAT_KEYS[self.selected]
        cost = self._cost(player, stat)
        if player.stat_points >= cost:
            player.stat_points -= cost
            player.stats[stat] += 1
            self._apply(player, stat)

    def _apply(self, player, stat):
        if stat == "Fuerza":
            player.damage += 5
        elif stat == "Vitalidad":
            player.max_hp += 25
            player.hp = min(player.hp + 25, player.max_hp)
        elif stat == "Agilidad":
            player.speed += 0.4
        elif stat == "Inteligencia":
            player.max_mana += 15

    def draw(self, surface, player):
        if not self.visible:
            return

        W, H = 460, 380
        x = SCREEN_WIDTH  // 2 - W // 2
        y = SCREEN_HEIGHT // 2 - H // 2

        # Background
        bg = pygame.Surface((W, H), pygame.SRCALPHA)
        bg.fill((10, 10, 30, 220))
        pygame.draw.rect(bg, GOLD, (0, 0, W, H), 2, border_radius=10)
        surface.blit(bg, (x, y))

        # Title
        title = self.font_title.render("Estadísticas", True, GOLD)
        surface.blit(title, (x + W // 2 - title.get_width() // 2, y + 14))

        # Stat points available
        pts_color = GOLD if player.stat_points > 0 else GRAY
        pts_lbl = self.font_main.render(f"Puntos disponibles: {player.stat_points}", True, pts_color)
        surface.blit(pts_lbl, (x + W // 2 - pts_lbl.get_width() // 2, y + 50))

        # Stats list
        row_h = 62
        for i, stat in enumerate(STAT_KEYS):
            ry = y + 90 + i * row_h
            selected = (i == self.selected)
            row_color = (40, 40, 80, 200) if not selected else (80, 60, 120, 230)
            row_surf = pygame.Surface((W - 30, row_h - 6), pygame.SRCALPHA)
            row_surf.fill(row_color)
            if selected:
                pygame.draw.rect(row_surf, GOLD, (0, 0, W - 30, row_h - 6), 2, border_radius=4)
            surface.blit(row_surf, (x + 15, ry))

            color = STAT_COLORS[stat]
            level = player.stats[stat]
            cost  = self._cost(player, stat)
            can_afford = player.stat_points >= cost

            # Stat name & level
            name_lbl = self.font_main.render(f"{stat}  Nv.{level}", True, color)
            surface.blit(name_lbl, (x + 26, ry + 6))

            # Description
            desc_lbl = self.font_sm.render(STAT_DESC[stat], True, (180, 180, 200))
            surface.blit(desc_lbl, (x + 26, ry + 32))

            # Cost
            cost_color = GOLD if can_afford else (120, 120, 120)
            cost_lbl = self.font_sm.render(f"Costo: {cost} pt{'s' if cost != 1 else ''}", True, cost_color)
            surface.blit(cost_lbl, (x + W - 30 - cost_lbl.get_width() - 10, ry + 18))

        # Controls hint
        hint = self.font_sm.render("↑↓ Seleccionar   ENTER Subir   M/ESC Cerrar", True, (150, 150, 180))
        surface.blit(hint, (x + W // 2 - hint.get_width() // 2, y + H - 26))
