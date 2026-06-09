import pygame
from src.settings import *

NPC_DEFINITIONS = {
    "Odin": {
        "color":   (50, 100, 220),   # blue
        "ability": "Rayo de Odin",
        "key":     "T",
        "desc":    "Desbloquea: Rayo de Odin (T)",
        "attr":    "has_odin_ray",
    },
    "Freya": {
        "color":   (50, 180, 80),    # green
        "ability": "Escudo Divino",
        "key":     "Y",
        "desc":    "Desbloquea: Escudo Divino (Y)",
        "attr":    "has_divine_shield",
    },
    "Thor": {
        "color":   (240, 200, 0),    # yellow
        "ability": "Tormenta de Truenos",
        "key":     "U",
        "desc":    "Desbloquea: Tormenta de Truenos (U)",
        "attr":    "has_thunder_storm",
    },
}

TALK_RADIUS = 90


class NPC(pygame.sprite.Sprite):
    def __init__(self, name, x, y):
        super().__init__()
        self.name     = name
        self.defn     = NPC_DEFINITIONS[name]
        self.color    = self.defn["color"]
        self.rect     = pygame.Rect(x, y, 40, 48)
        self.talked   = False          # has given the ability
        self.bob_t    = 0
        self.font     = pygame.font.SysFont("Arial", 13, bold=True)
        self.font_sm  = pygame.font.SysFont("Arial", 11)

    def near(self, player):
        dx = player.rect.centerx - self.rect.centerx
        dy = player.rect.centery - self.rect.centery
        return (dx * dx + dy * dy) ** 0.5 < TALK_RADIUS

    def interact(self, player):
        """Grant ability if not already granted."""
        attr = self.defn["attr"]
        if not getattr(player, attr):
            setattr(player, attr, True)
            self.talked = True
            return f"¡{self.name} te otorga: {self.defn['ability']}!"
        return f"Ya tienes: {self.defn['ability']}"

    def update(self):
        self.bob_t += 0.05

    def draw(self, surface, camera):
        import math
        bob = int(math.sin(self.bob_t) * 4)
        draw_rect = pygame.Rect(
            self.rect.x, self.rect.y + bob,
            self.rect.width, self.rect.height
        )
        pos = camera.apply(draw_rect)

        # Body
        pygame.draw.rect(surface, self.color, pos, border_radius=6)
        # Glow outline
        outline_color = tuple(min(255, c + 80) for c in self.color)
        pygame.draw.rect(surface, outline_color, pos, 2, border_radius=6)

        # Head (slightly lighter circle)
        hx = pos.x + pos.width // 2
        hy = pos.y - 10
        head_color = tuple(min(255, c + 40) for c in self.color)
        pygame.draw.circle(surface, head_color, (hx, hy), 12)
        pygame.draw.circle(surface, outline_color, (hx, hy), 12, 2)

        # Name label above head
        name_surf = self.font.render(self.name, True, WHITE)
        surface.blit(name_surf, (hx - name_surf.get_width() // 2, hy - 28))

    def draw_prompt(self, surface, camera):
        """Draw talk prompt when player is nearby."""
        pos = camera.apply(self.rect)
        import math
        bob = int(math.sin(self.bob_t) * 4)
        cx = pos.x + pos.width // 2
        cy = pos.y + bob - 48

        prompt = self.font_sm.render("F: Hablar", True, GOLD)
        desc   = self.font_sm.render(self.defn["desc"] if not self.talked else "Habilidad otorgada", True, WHITE)

        bg_w = max(prompt.get_width(), desc.get_width()) + 14
        bg_h = prompt.get_height() + desc.get_height() + 10
        bg = pygame.Surface((bg_w, bg_h), pygame.SRCALPHA)
        bg.fill((0, 0, 0, 180))
        surface.blit(bg, (cx - bg_w // 2, cy - bg_h))
        surface.blit(prompt, (cx - prompt.get_width() // 2, cy - bg_h + 4))
        surface.blit(desc,   (cx - desc.get_width()   // 2, cy - bg_h + 4 + prompt.get_height() + 2))
