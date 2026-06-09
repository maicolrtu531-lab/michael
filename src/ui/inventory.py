import pygame
from src.settings import *

ITEMS = {
    "Hacha de Leviatán":  {"color": ICE_BLUE, "desc": "+15 daño",  "cost": 80,  "effect": "damage", "value": 15},
    "Armadura Guardiana": {"color": GRAY,      "desc": "+10 defensa","cost": 60, "effect": "defense","value": 10},
    "Corazón de Piedra":  {"color": RED,       "desc": "+50 HP max", "cost": 50, "effect": "hp",     "value": 50},
    "Poción":             {"color": GREEN,      "desc": "+1 poción",  "cost": 20, "effect": "potion", "value": 1},
    "Runa de Velocidad":  {"color": YELLOW,    "desc": "+2 velocidad","cost":70,  "effect": "speed",  "value": 2},
}

class ShopMenu:
    def __init__(self):
        self.visible = False
        self.font    = pygame.font.SysFont("Arial", 18)
        self.font_big= pygame.font.SysFont("Arial", 22, bold=True)
        self.items   = list(ITEMS.keys())
        self.selected= 0

    def toggle(self):
        self.visible = not self.visible

    def handle_event(self, event, player):
        if not self.visible:
            return
        if event.type == pygame.KEYDOWN:
            if event.key in (pygame.K_UP, pygame.K_w):
                self.selected = (self.selected - 1) % len(self.items)
            elif event.key in (pygame.K_DOWN, pygame.K_s):
                self.selected = (self.selected + 1) % len(self.items)
            elif event.key == pygame.K_RETURN:
                self._buy(player)
            elif event.key in (pygame.K_ESCAPE, pygame.K_i):
                self.visible = False

    def _buy(self, player):
        name = self.items[self.selected]
        item = ITEMS[name]
        if player.gold >= item["cost"]:
            player.gold -= item["cost"]
            fx = item["effect"]
            if fx == "damage":  player.damage   += item["value"]
            elif fx == "defense": player.defense += item["value"]
            elif fx == "hp":
                player.max_hp += item["value"]
                player.hp = min(player.max_hp, player.hp + item["value"])
            elif fx == "potion": player.potions  += item["value"]
            elif fx == "speed":  player.speed    += item["value"]
            player.inventory.append(name)

    def draw(self, surface, player):
        if not self.visible:
            return
        panel = pygame.Surface((440, 360), pygame.SRCALPHA)
        panel.fill((10, 10, 20, 220))
        sx = SCREEN_WIDTH//2 - 220
        sy = SCREEN_HEIGHT//2 - 180
        surface.blit(panel, (sx, sy))
        pygame.draw.rect(surface, GOLD, (sx, sy, 440, 360), 2)

        title = self.font_big.render("⚔  TIENDA  ⚔", True, GOLD)
        surface.blit(title, (sx + 220 - title.get_width()//2, sy + 12))

        gold_lbl = self.font.render(f"🪙 Oro: {player.gold}", True, YELLOW)
        surface.blit(gold_lbl, (sx + 16, sy + 44))

        for i, name in enumerate(self.items):
            item   = ITEMS[name]
            y      = sy + 80 + i * 48
            color  = GOLD if i == self.selected else WHITE
            bg     = (40, 40, 80, 180) if i == self.selected else (0, 0, 0, 0)
            bg_s   = pygame.Surface((408, 44), pygame.SRCALPHA)
            bg_s.fill(bg)
            surface.blit(bg_s, (sx + 16, y))
            pygame.draw.circle(surface, item["color"], (sx + 36, y + 22), 14)
            lbl = self.font.render(f"{name}  —  {item['desc']}  [{item['cost']}🪙]", True, color)
            surface.blit(lbl, (sx + 58, y + 12))

        hint = self.font.render("↑↓ Mover  |  ENTER Comprar  |  I/ESC Cerrar", True, GRAY)
        surface.blit(hint, (sx + 220 - hint.get_width()//2, sy + 330))
