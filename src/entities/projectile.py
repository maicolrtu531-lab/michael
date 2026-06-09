import pygame
import math
from src.settings import *

class AxeProjectile(pygame.sprite.Sprite):
    def __init__(self, x, y, dx, dy, damage):
        super().__init__()
        self.rect    = pygame.Rect(x - 8, y - 8, 16, 16)
        self.vel     = pygame.math.Vector2(dx, dy).normalize() * 14
        self.damage  = damage
        self.lifetime = 50
        self.angle   = 0
        self.hit_enemies = []

    def update(self, world_rect):
        self.rect.x += int(self.vel.x)
        self.rect.y += int(self.vel.y)
        self.angle += 20
        self.lifetime -= 1
        if not world_rect.contains(self.rect) or self.lifetime <= 0:
            self.kill()

    def draw(self, surface, camera):
        pos = camera.apply(self.rect)
        surf = pygame.Surface((20, 20), pygame.SRCALPHA)
        pygame.draw.polygon(surf, ICE_BLUE, [(10, 0), (20, 10), (10, 20), (0, 10)])
        rotated = pygame.transform.rotate(surf, self.angle)
        surface.blit(rotated, (pos.x - 2, pos.y - 2))


class BlizzardEffect:
    def __init__(self, x, y, radius, damage):
        self.x       = x
        self.y       = y
        self.radius  = radius
        self.damage  = damage
        self.timer   = 60
        self.hit_set = set()

    @property
    def alive(self):
        return self.timer > 0

    def update(self):
        self.timer -= 1

    def draw(self, surface, camera):
        cx = self.x - camera.offset_x
        cy = self.y - camera.offset_y
        alpha = int(180 * (self.timer / 60))
        surf = pygame.Surface((self.radius * 2, self.radius * 2), pygame.SRCALPHA)
        pygame.draw.circle(surf, (160, 220, 255, alpha), (self.radius, self.radius), self.radius)
        pygame.draw.circle(surf, (200, 240, 255, min(255, alpha + 40)), (self.radius, self.radius), self.radius, 3)
        surface.blit(surf, (cx - self.radius, cy - self.radius))


class FloatingText:
    def __init__(self, x, y, text, color=WHITE):
        self.x     = float(x)
        self.y     = float(y)
        self.text  = text
        self.color = color
        self.timer = 50
        self.font  = pygame.font.SysFont("Arial", 18, bold=True)

    @property
    def alive(self):
        return self.timer > 0

    def update(self):
        self.y  -= 1.2
        self.timer -= 1

    def draw(self, surface, camera):
        alpha = int(255 * (self.timer / 50))
        surf = self.font.render(self.text, True, self.color)
        surf.set_alpha(alpha)
        surface.blit(surf, (self.x - camera.offset_x - surf.get_width()//2, self.y - camera.offset_y))
