import pygame
from src.settings import *

class Player(pygame.sprite.Sprite):
    def __init__(self, x, y):
        super().__init__()
        self.image = pygame.Surface((40, 40))
        self.image.fill(BLUE)
        self.rect = self.image.get_rect(topleft=(x, y))

        self.speed = PLAYER_SPEED
        self.hp    = PLAYER_HP
        self.max_hp = PLAYER_HP
        self.mana  = PLAYER_MANA
        self.max_mana = PLAYER_MANA
        self.level = 1
        self.exp   = 0

        self.vel = pygame.math.Vector2(0, 0)

    def handle_input(self):
        keys = pygame.key.get_pressed()
        self.vel.x = 0
        self.vel.y = 0
        if keys[pygame.K_w] or keys[pygame.K_UP]:    self.vel.y = -self.speed
        if keys[pygame.K_s] or keys[pygame.K_DOWN]:  self.vel.y =  self.speed
        if keys[pygame.K_a] or keys[pygame.K_LEFT]:  self.vel.x = -self.speed
        if keys[pygame.K_d] or keys[pygame.K_RIGHT]: self.vel.x =  self.speed

        if self.vel.length() > 0:
            self.vel = self.vel.normalize() * self.speed

    def update(self):
        self.handle_input()
        self.rect.x += self.vel.x
        self.rect.y += self.vel.y

        # Keep player inside screen
        self.rect.clamp_ip(pygame.display.get_surface().get_rect())

    def gain_exp(self, amount):
        self.exp += amount
        if self.exp >= self.level * 100:
            self.exp = 0
            self.level += 1
            self.max_hp += 10
            self.hp = self.max_hp
            print(f"¡Subiste al nivel {self.level}!")
