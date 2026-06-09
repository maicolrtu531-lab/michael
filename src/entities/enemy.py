import pygame
import math
import random
from src.settings import *

# ── Base ──────────────────────────────────────────────────────────────────────
class Enemy(pygame.sprite.Sprite):
    def __init__(self, x, y):
        super().__init__()
        self.rect        = pygame.Rect(x, y, 40, 40)
        self.hp          = 40
        self.max_hp      = 40
        self.speed       = 1.8
        self.damage      = 12
        self.exp_reward  = 30
        self.gold_reward = random.randint(2, 8)
        self.atk_cd      = 0
        self.hit_flash   = 0
        self.frozen      = 0
        self.knockback   = pygame.math.Vector2(0, 0)
        self.color       = RED
        self.name        = "Draugr"
        self.dead        = False

    def _dist(self, player):
        dx = player.rect.centerx - self.rect.centerx
        dy = player.rect.centery - self.rect.centery
        return math.hypot(dx, dy), dx, dy

    def update(self, player, world_rect):
        if self.dead:
            return
        if self.frozen > 0:
            self.frozen -= 1
        if self.atk_cd > 0:
            self.atk_cd -= 1
        if self.hit_flash > 0:
            self.hit_flash -= 1

        # Knockback decay
        if self.knockback.length() > 0:
            self.rect.x += int(self.knockback.x)
            self.rect.y += int(self.knockback.y)
            self.rect.clamp_ip(world_rect)
            self.knockback *= 0.7
            if self.knockback.length() < 0.5:
                self.knockback = pygame.math.Vector2(0, 0)

        if self.frozen == 0:
            self._ai(player, world_rect)

        if self.hp <= 0:
            self.dead = True

    def _ai(self, player, world_rect):
        dist, dx, dy = self._dist(player)
        if dist < 350 and dist > 0:
            spd = self.speed
            self.rect.x += int((dx / dist) * spd)
            self.rect.y += int((dy / dist) * spd)
            self.rect.clamp_ip(world_rect)

    def try_attack(self, player):
        if self.dead or self.frozen > 0:
            return
        if self.rect.colliderect(player.rect) and self.atk_cd == 0:
            player.take_damage(self.damage)
            self.atk_cd = 70

    def take_damage(self, amount, knockback=None):
        self.hp -= amount
        self.hit_flash = 8
        if knockback:
            self.knockback = pygame.math.Vector2(knockback)

    def freeze(self, duration=120):
        self.frozen = duration

    def draw(self, surface, camera):
        if self.dead:
            return
        pos = camera.apply(self.rect)
        color = ICE_BLUE if self.frozen > 0 else (WHITE if self.hit_flash % 4 < 2 and self.hit_flash > 0 else self.color)
        pygame.draw.rect(surface, color, pos)
        self._draw_hp_bar(surface, pos)

    def _draw_hp_bar(self, surface, pos):
        ratio = max(0, self.hp / self.max_hp)
        bar_w = self.rect.width
        pygame.draw.rect(surface, DARK_RED,  (pos.x, pos.y - 8, bar_w, 5))
        pygame.draw.rect(surface, GREEN,     (pos.x, pos.y - 8, int(bar_w * ratio), 5))


# ── Draugr (básico) ───────────────────────────────────────────────────────────
class Draugr(Enemy):
    def __init__(self, x, y):
        super().__init__(x, y)
        self.color  = (140, 60, 200)
        self.name   = "Draugr"
        self.hp = self.max_hp = 40
        self.image  = pygame.Surface((40, 40), pygame.SRCALPHA)
        self._draw()

    def _draw(self):
        s = self.image
        s.fill((0,0,0,0))
        pygame.draw.rect(s, (100, 40, 160), (8, 12, 24, 20))
        pygame.draw.circle(s, (160, 100, 200), (20, 8), 8)
        pygame.draw.line(s, GRAY, (28, 14), (38, 8), 3)

    def draw(self, surface, camera):
        if self.dead: return
        pos = camera.apply(self.rect)
        if self.hit_flash % 4 < 2 and self.hit_flash > 0:
            pygame.draw.rect(surface, WHITE, pos)
        elif self.frozen > 0:
            pygame.draw.rect(surface, ICE_BLUE, pos)
        else:
            surface.blit(self.image, pos)
        self._draw_hp_bar(surface, pos)


# ── Berserker (rápido y agresivo) ────────────────────────────────────────────
class Berserker(Enemy):
    def __init__(self, x, y):
        super().__init__(x, y)
        self.rect   = pygame.Rect(x, y, 36, 36)
        self.hp = self.max_hp = 30
        self.speed  = 3.5
        self.damage = 18
        self.exp_reward  = 50
        self.gold_reward = random.randint(5, 12)
        self.color  = ORANGE
        self.name   = "Berserker"

    def draw(self, surface, camera):
        if self.dead: return
        pos = camera.apply(self.rect)
        color = ICE_BLUE if self.frozen > 0 else (WHITE if self.hit_flash % 4 < 2 and self.hit_flash > 0 else ORANGE)
        # Triangle shape for Berserker
        pts = [(pos.x + 18, pos.y), (pos.x, pos.y + 36), (pos.x + 36, pos.y + 36)]
        pygame.draw.polygon(surface, color, pts)
        self._draw_hp_bar(surface, pos)


# ── Revenant (se teletransporta) ──────────────────────────────────────────────
class Revenant(Enemy):
    def __init__(self, x, y):
        super().__init__(x, y)
        self.rect   = pygame.Rect(x, y, 38, 38)
        self.hp = self.max_hp = 55
        self.speed  = 2.0
        self.damage = 20
        self.exp_reward  = 70
        self.gold_reward = random.randint(8, 18)
        self.color  = CYAN
        self.name   = "Revenant"
        self.teleport_cd = 0

    def _ai(self, player, world_rect):
        self.teleport_cd -= 1
        dist, dx, dy = self._dist(player)
        if dist < 80 and self.teleport_cd <= 0:
            # Teleport away
            angle = random.uniform(0, math.pi * 2)
            self.rect.x = max(0, min(world_rect.width  - 38, self.rect.x + int(math.cos(angle) * 200)))
            self.rect.y = max(0, min(world_rect.height - 38, self.rect.y + int(math.sin(angle) * 200)))
            self.teleport_cd = 120
        elif dist < 400 and dist > 0:
            self.rect.x += int((dx / dist) * self.speed)
            self.rect.y += int((dy / dist) * self.speed)
            self.rect.clamp_ip(world_rect)

    def draw(self, surface, camera):
        if self.dead: return
        pos = camera.apply(self.rect)
        color = ICE_BLUE if self.frozen > 0 else (WHITE if self.hit_flash % 4 < 2 and self.hit_flash > 0 else CYAN)
        pygame.draw.ellipse(surface, color, pos)
        self._draw_hp_bar(surface, pos)


# ── Ancient (tanque lento) ─────────────────────────────────────────────────────
class Ancient(Enemy):
    def __init__(self, x, y):
        super().__init__(x, y)
        self.rect   = pygame.Rect(x, y, 60, 60)
        self.hp = self.max_hp = 200
        self.speed  = 0.9
        self.damage = 35
        self.exp_reward  = 150
        self.gold_reward = random.randint(20, 40)
        self.color  = GRAY
        self.name   = "Ancient"

    def draw(self, surface, camera):
        if self.dead: return
        pos = camera.apply(self.rect)
        color = ICE_BLUE if self.frozen > 0 else (WHITE if self.hit_flash % 4 < 2 and self.hit_flash > 0 else GRAY)
        pygame.draw.rect(surface, color, pos, border_radius=8)
        # Glowing core
        cx, cy = pos.x + 30, pos.y + 30
        pygame.draw.circle(surface, ORANGE, (cx, cy), 10)
        self._draw_hp_bar(surface, pos)


# ── BOSS: Baldur ───────────────────────────────────────────────────────────────
class Baldur(Enemy):
    def __init__(self, x, y):
        super().__init__(x, y)
        self.rect   = pygame.Rect(x, y, 80, 80)
        self.hp = self.max_hp = 800
        self.speed  = 2.2
        self.damage = 45
        self.exp_reward  = 500
        self.gold_reward = 100
        self.name   = "Baldur"
        self.phase  = 1
        self.charge_cd   = 0
        self.slam_cd     = 0
        self.charge_vel  = pygame.math.Vector2(0, 0)
        self.is_charging = False

    def _ai(self, player, world_rect):
        if self.hp < self.max_hp * 0.5 and self.phase == 1:
            self.phase = 2
            self.speed = 3.2

        dist, dx, dy = self._dist(player)

        # Charge attack
        self.charge_cd -= 1
        if dist < 500 and self.charge_cd <= 0 and not self.is_charging:
            self.is_charging = True
            self.charge_cd = 180
            if dist > 0:
                self.charge_vel = pygame.math.Vector2(dx, dy).normalize() * 12

        if self.is_charging:
            self.rect.x += int(self.charge_vel.x)
            self.rect.y += int(self.charge_vel.y)
            self.rect.clamp_ip(world_rect)
            self.charge_vel *= 0.92
            if self.charge_vel.length() < 1:
                self.is_charging = False
        elif dist < 600 and dist > 0:
            self.rect.x += int((dx / dist) * self.speed)
            self.rect.y += int((dy / dist) * self.speed)
            self.rect.clamp_ip(world_rect)

    def draw(self, surface, camera):
        if self.dead: return
        pos = camera.apply(self.rect)
        base = (220, 180, 255) if self.phase == 1 else (255, 80, 30)
        color = ICE_BLUE if self.frozen > 0 else (WHITE if self.hit_flash % 4 < 2 and self.hit_flash > 0 else base)
        pygame.draw.rect(surface, DARK_GRAY, pos, border_radius=6)
        # Inner body
        inner = pygame.Rect(pos.x + 6, pos.y + 6, 68, 68)
        pygame.draw.rect(surface, color, inner, border_radius=6)
        # Boss name
        font = pygame.font.SysFont("Arial", 14, bold=True)
        lbl = font.render("BALDUR", True, GOLD)
        surface.blit(lbl, (pos.x + 80//2 - lbl.get_width()//2, pos.y - 18))
        # Charge glow
        if self.is_charging:
            glow = pygame.Surface((100, 100), pygame.SRCALPHA)
            pygame.draw.circle(glow, (255, 150, 0, 100), (50, 50), 50)
            surface.blit(glow, (pos.x - 10, pos.y - 10))
        self._draw_hp_bar(surface, pos)
