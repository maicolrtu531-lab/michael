import pygame
import random
from src.settings import *
from src.entities.player import Player
from src.entities.enemy import Enemy
from src.ui.hud import HUD

class GameScene:
    def __init__(self):
        self.player  = Player(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2)
        self.enemies = pygame.sprite.Group()
        self.hud     = HUD()
        self._spawn_enemies(5)

        self.spawn_timer = 0

    def _spawn_enemies(self, count):
        for _ in range(count):
            x = random.randint(100, SCREEN_WIDTH - 100)
            y = random.randint(100, SCREEN_HEIGHT - 100)
            self.enemies.add(Enemy(x, y))

    def handle_event(self, event):
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_SPACE:
                self._player_attack()

    def _player_attack(self):
        attack_range = 80
        for enemy in list(self.enemies):
            dx = enemy.rect.centerx - self.player.rect.centerx
            dy = enemy.rect.centery - self.player.rect.centery
            if (dx**2 + dy**2) ** 0.5 < attack_range:
                enemy.hp -= 20
                if enemy.hp <= 0:
                    self.player.gain_exp(enemy.exp_reward)
                    enemy.kill()

    def update(self):
        self.player.update()
        for enemy in self.enemies:
            enemy.update(self.player)
            enemy.try_attack(self.player)

        self.spawn_timer += 1
        if self.spawn_timer >= 300 and len(self.enemies) < 10:
            self._spawn_enemies(2)
            self.spawn_timer = 0

    def draw(self, surface):
        surface.fill((30, 80, 30))  # green world background
        self._draw_grid(surface)
        self.enemies.draw(surface)
        surface.blit(self.player.image, self.player.rect)
        self.hud.draw(surface, self.player)
        self._draw_controls(surface)

    def _draw_grid(self, surface):
        for x in range(0, SCREEN_WIDTH, TILE_SIZE):
            pygame.draw.line(surface, (40, 90, 40), (x, 0), (x, SCREEN_HEIGHT))
        for y in range(0, SCREEN_HEIGHT, TILE_SIZE):
            pygame.draw.line(surface, (40, 90, 40), (0, y), (SCREEN_WIDTH, y))

    def _draw_controls(self, surface):
        font = pygame.font.SysFont("Arial", 16)
        controls = ["WASD / Flechas: Mover", "ESPACIO: Atacar"]
        for i, text in enumerate(controls):
            surface.blit(font.render(text, True, WHITE), (SCREEN_WIDTH - 200, 20 + i * 22))
