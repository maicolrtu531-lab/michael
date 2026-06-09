import pygame
import math
from src.settings import *

class Player(pygame.sprite.Sprite):
    def __init__(self, x, y):
        super().__init__()
        self.image = pygame.Surface((44, 44), pygame.SRCALPHA)
        self._draw_sprite()
        self.rect = self.image.get_rect(center=(x, y))

        # Stats
        self.hp          = PLAYER_HP
        self.max_hp      = PLAYER_HP
        self.mana        = PLAYER_MANA
        self.max_mana    = PLAYER_MANA
        self.level       = 1
        self.exp         = 0
        self.damage      = PLAYER_DAMAGE
        self.defense     = PLAYER_DEFENSE
        self.speed       = PLAYER_SPEED
        self.kills       = 0

        # Movement
        self.vel = pygame.math.Vector2(0, 0)
        self.facing = pygame.math.Vector2(1, 0)

        # Combat
        self.attack_timer     = 0
        self.attack_duration  = 20
        self.attack_cooldown  = 0
        self.is_attacking     = False
        self.combo_count      = 0
        self.combo_timer      = 0
        self.invincible       = 0

        # Abilities
        self.axe_throw_cd    = 0
        self.rage_cd         = 0
        self.rage_active     = 0
        self.blizzard_cd     = 0

        # Inventory
        self.gold            = 0
        self.potions         = 3
        self.inventory       = []

        # Visual feedback
        self.hit_flash       = 0
        self.level_up_flash  = 0

    def _draw_sprite(self):
        s = self.image
        s.fill((0, 0, 0, 0))
        # Body
        pygame.draw.rect(s, (180, 80, 40), (10, 14, 24, 22))
        # Head
        pygame.draw.circle(s, (210, 160, 100), (22, 10), 9)
        # Beard (red)
        pygame.draw.rect(s, RED, (14, 14, 16, 6))
        # Arms
        pygame.draw.rect(s, (180, 80, 40), (2, 16, 10, 8))
        pygame.draw.rect(s, (180, 80, 40), (32, 16, 10, 8))
        # Axe
        pygame.draw.rect(s, GRAY, (34, 10, 6, 16))
        pygame.draw.polygon(s, ICE_BLUE, [(38, 8), (44, 14), (38, 20)])
        # Legs
        pygame.draw.rect(s, DARK_RED, (10, 36, 10, 8))
        pygame.draw.rect(s, DARK_RED, (24, 36, 10, 8))

    def handle_input(self, keys):
        self.vel.x = 0
        self.vel.y = 0
        spd = self.speed * (1.5 if self.rage_active > 0 else 1)

        if keys[pygame.K_w] or keys[pygame.K_UP]:    self.vel.y = -spd
        if keys[pygame.K_s] or keys[pygame.K_DOWN]:  self.vel.y =  spd
        if keys[pygame.K_a] or keys[pygame.K_LEFT]:  self.vel.x = -spd
        if keys[pygame.K_d] or keys[pygame.K_RIGHT]: self.vel.x =  spd

        if self.vel.length() > 0:
            self.vel = self.vel.normalize() * spd
            self.facing = self.vel.normalize()

    def use_potion(self):
        if self.potions > 0 and self.hp < self.max_hp:
            self.potions -= 1
            self.hp = min(self.max_hp, self.hp + 60)

    def update(self, keys, world_rect):
        self.handle_input(keys)
        self.rect.x += int(self.vel.x)
        self.rect.y += int(self.vel.y)
        self.rect.clamp_ip(world_rect)

        # Timers
        if self.attack_timer > 0:     self.attack_timer -= 1
        if self.attack_cooldown > 0:  self.attack_cooldown -= 1
        if self.invincible > 0:       self.invincible -= 1
        if self.combo_timer > 0:      self.combo_timer -= 1
        else:                         self.combo_count = 0
        if self.axe_throw_cd > 0:     self.axe_throw_cd -= 1
        if self.rage_cd > 0:          self.rage_cd -= 1
        if self.rage_active > 0:      self.rage_active -= 1
        if self.blizzard_cd > 0:      self.blizzard_cd -= 1
        if self.hit_flash > 0:        self.hit_flash -= 1
        if self.level_up_flash > 0:   self.level_up_flash -= 1
        if self.mana < self.max_mana: self.mana = min(self.max_mana, self.mana + 0.02)

    def melee_attack(self):
        if self.attack_cooldown > 0:
            return None
        self.combo_count = (self.combo_count + 1) % 3
        self.combo_timer = 40
        self.attack_timer = self.attack_duration
        self.attack_cooldown = 18

        bonus = 1.8 if self.combo_count == 2 else 1.0
        dmg = int(self.damage * bonus * (1.5 if self.rage_active > 0 else 1))

        offset = self.facing * 55
        cx = self.rect.centerx + offset.x
        cy = self.rect.centery + offset.y
        return {"type": "melee", "rect": pygame.Rect(cx - 35, cy - 35, 70, 70), "damage": dmg, "knockback": self.facing * 8}

    def axe_throw(self):
        if self.axe_throw_cd > 0 or self.mana < 15:
            return None
        self.axe_throw_cd = 90
        self.mana -= 15
        return {"type": "axe", "x": self.rect.centerx, "y": self.rect.centery,
                "dx": self.facing.x, "dy": self.facing.y, "damage": self.damage * 2}

    def spartan_rage(self):
        if self.rage_cd > 0 or self.mana < 30:
            return False
        self.rage_cd = 600
        self.rage_active = 300
        self.mana -= 30
        return True

    def blizzard(self):
        if self.blizzard_cd > 0 or self.mana < 25:
            return None
        self.blizzard_cd = 180
        self.mana -= 25
        return {"type": "blizzard", "x": self.rect.centerx, "y": self.rect.centery, "radius": 160, "damage": self.damage}

    def take_damage(self, amount):
        if self.invincible > 0:
            return
        reduced = max(1, amount - self.defense)
        self.hp -= reduced
        self.invincible = 30
        self.hit_flash = 10

    def gain_exp(self, amount):
        self.exp += amount
        needed = self.level * 120
        if self.exp >= needed:
            self.exp -= needed
            self.level += 1
            self.max_hp   += 20
            self.hp        = self.max_hp
            self.max_mana += 10
            self.damage   += 5
            self.defense  += 1
            self.level_up_flash = 60

    def draw(self, surface, camera):
        if self.hit_flash % 4 < 2 and self.hit_flash > 0:
            return
        pos = camera.apply(self.rect)

        # Rage aura
        if self.rage_active > 0:
            aura = pygame.Surface((60, 60), pygame.SRCALPHA)
            pygame.draw.circle(aura, (255, 80, 0, 80), (30, 30), 30)
            surface.blit(aura, (pos.x - 8, pos.y - 8))

        surface.blit(self.image, pos)

        # Attack arc
        if self.attack_timer > 0:
            offset = self.facing * 55
            cx = pos.x + 22 + int(offset.x)
            cy = pos.y + 22 + int(offset.y)
            arc_surf = pygame.Surface((80, 80), pygame.SRCALPHA)
            pygame.draw.circle(arc_surf, (ICE_BLUE[0], ICE_BLUE[1], ICE_BLUE[2], 120), (40, 40), 36)
            surface.blit(arc_surf, (cx - 40, cy - 40))

    @property
    def exp_needed(self):
        return self.level * 120
