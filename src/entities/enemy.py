import pygame
import math
from src.settings import *

class Enemy(pygame.sprite.Sprite):
    def __init__(self, x, y):
        super().__init__()
        self.image = pygame.Surface((36, 36))
        self.image.fill(RED)
        self.rect = self.image.get_rect(topleft=(x, y))

        self.hp      = 30
        self.max_hp  = 30
        self.speed   = 1.5
        self.damage  = 10
        self.exp_reward = 40
        self.attack_cooldown = 0

    def update(self, player):
        self._move_toward(player)
        if self.attack_cooldown > 0:
            self.attack_cooldown -= 1

    def _move_toward(self, player):
        dx = player.rect.centerx - self.rect.centerx
        dy = player.rect.centery - self.rect.centery
        dist = math.hypot(dx, dy)
        if dist > 0 and dist < 400:
            self.rect.x += (dx / dist) * self.speed
            self.rect.y += (dy / dist) * self.speed

    def try_attack(self, player):
        if self.rect.colliderect(player.rect) and self.attack_cooldown == 0:
            player.hp -= self.damage
            self.attack_cooldown = 60
