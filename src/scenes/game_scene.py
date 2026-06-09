import pygame
import random
from src.settings import *
from src.entities.player     import Player
from src.entities.enemy      import Draugr, Berserker, Revenant, Ancient, Baldur
from src.entities.projectile import AxeProjectile, BlizzardEffect, FloatingText
from src.ui.hud              import HUD
from src.ui.inventory        import ShopMenu
from src.camera              import Camera
from src.world               import WorldMap

WAVE_TEMPLATES = [
    # (type, count)
    [(Draugr, 4)],
    [(Draugr, 4), (Berserker, 2)],
    [(Berserker, 3), (Revenant, 2)],
    [(Draugr, 3), (Berserker, 2), (Revenant, 2)],
    [(Ancient, 2), (Berserker, 3)],
    [(Draugr, 5), (Revenant, 3), (Ancient, 1)],
    [(Baldur, 1)],  # Boss wave
]

class GameScene:
    def __init__(self):
        self.world    = WorldMap()
        self.camera   = Camera()
        self.player   = Player(WORLD_WIDTH // 2, WORLD_HEIGHT // 2)
        self.hud      = HUD()
        self.shop     = ShopMenu()

        self.enemies    = []
        self.projectiles= []
        self.effects    = []
        self.texts      = []

        self.wave       = 0
        self.wave_timer = 0
        self.boss       = None
        self.next_scene = None

        self._spawn_wave()

    # ── Spawning ──────────────────────────────────────────────────────────────
    def _spawn_wave(self):
        if self.wave >= len(WAVE_TEMPLATES):
            return
        template = WAVE_TEMPLATES[self.wave]
        for cls, count in template:
            for _ in range(count):
                x, y = self._rand_pos()
                e = cls(x, y)
                self.enemies.append(e)
                if isinstance(e, Baldur):
                    self.boss = e

    def _rand_pos(self):
        px, py = self.player.rect.center
        while True:
            x = random.randint(TILE_SIZE, WORLD_WIDTH  - TILE_SIZE)
            y = random.randint(TILE_SIZE, WORLD_HEIGHT - TILE_SIZE)
            if abs(x - px) > 300 or abs(y - py) > 300:
                return x, y

    # ── Events ────────────────────────────────────────────────────────────────
    def handle_event(self, event):
        self.shop.handle_event(event, self.player)
        if self.shop.visible:
            return

        if event.type == pygame.KEYDOWN:
            p = self.player
            if event.key == pygame.K_SPACE:
                atk = p.melee_attack()
                if atk:
                    self._apply_melee(atk)

            elif event.key == pygame.K_e:
                proj = p.axe_throw()
                if proj:
                    self.projectiles.append(AxeProjectile(proj["x"], proj["y"], proj["dx"], proj["dy"], proj["damage"]))
                elif p.axe_throw_cd > 0:
                    self.texts.append(FloatingText(p.rect.centerx, p.rect.top, "En recarga!", GRAY))
                else:
                    self.texts.append(FloatingText(p.rect.centerx, p.rect.top, "Mana insuf.", LIGHT_BLUE))

            elif event.key == pygame.K_r:
                bliz = p.blizzard()
                if bliz:
                    self.effects.append(BlizzardEffect(bliz["x"], bliz["y"], bliz["radius"], bliz["damage"]))
                else:
                    self.texts.append(FloatingText(p.rect.centerx, p.rect.top, "Mana insuf.", LIGHT_BLUE))

            elif event.key == pygame.K_q:
                ok = p.spartan_rage()
                if ok:
                    self.texts.append(FloatingText(p.rect.centerx, p.rect.top - 20, "¡FURIA ESPARTANA!", ORANGE))

            elif event.key in (pygame.K_f, pygame.K_h):
                p.use_potion()

            elif event.key == pygame.K_i:
                self.shop.toggle()

    # ── Melee hit ─────────────────────────────────────────────────────────────
    def _apply_melee(self, atk):
        for enemy in self.enemies:
            if not enemy.dead and atk["rect"].colliderect(enemy.rect):
                enemy.take_damage(atk["damage"], atk.get("knockback"))
                self.texts.append(FloatingText(enemy.rect.centerx, enemy.rect.top, f"-{atk['damage']}", RED))

    # ── Update ────────────────────────────────────────────────────────────────
    def update(self):
        keys = pygame.key.get_pressed()
        self.player.update(keys, self.world.rect)
        self.camera.update(self.player)

        # Enemies
        for e in self.enemies:
            e.update(self.player, self.world.rect)
            e.try_attack(self.player)

        # Projectiles
        for p in list(self.projectiles):
            p.update(self.world.rect)
            for e in self.enemies:
                if not e.dead and e not in p.hit_enemies and p.rect.colliderect(e.rect):
                    e.take_damage(p.damage)
                    self.texts.append(FloatingText(e.rect.centerx, e.rect.top, f"-{p.damage}", CYAN))
                    p.hit_enemies.append(e)
                    p.kill()
                    break

        self.projectiles = [p for p in self.projectiles if p.alive]

        # Blizzard effects
        for b in self.effects:
            b.update()
            for e in self.enemies:
                if not e.dead and id(e) not in b.hit_set:
                    ex, ey = e.rect.center
                    if ((ex - b.x)**2 + (ey - b.y)**2) ** 0.5 < b.radius:
                        e.take_damage(b.damage)
                        e.freeze(150)
                        b.hit_set.add(id(e))
                        self.texts.append(FloatingText(e.rect.centerx, e.rect.top, f"❄ -{b.damage}", ICE_BLUE))

        self.effects = [b for b in self.effects if b.alive]

        # Floating texts
        for t in self.texts:
            t.update()
        self.texts = [t for t in self.texts if t.alive]

        # Collect dead enemies
        for e in list(self.enemies):
            if e.dead:
                self.player.kills  += 1
                self.player.gold   += e.gold_reward
                self.player.gain_exp(e.exp_reward)
                self.texts.append(FloatingText(e.rect.centerx, e.rect.top - 10, f"+{e.exp_reward}xp", YELLOW))
                self.enemies.remove(e)
                if e is self.boss:
                    self.boss = None

        # Wave progression
        if len(self.enemies) == 0:
            self.wave_timer += 1
            if self.wave_timer > 120:
                self.wave_timer = 0
                self.wave += 1
                if self.wave >= len(WAVE_TEMPLATES):
                    self.next_scene = SCENE_WIN
                else:
                    self._spawn_wave()

        # Death check
        if self.player.hp <= 0:
            self.next_scene = SCENE_GAMEOVER

    # ── Draw ──────────────────────────────────────────────────────────────────
    def draw(self, surface):
        self.world.draw(surface, self.camera)

        for e in self.enemies:
            e.draw(surface, self.camera)

        for p in self.projectiles:
            p.draw(surface, self.camera)

        for b in self.effects:
            b.draw(surface, self.camera)

        for t in self.texts:
            t.draw(surface, self.camera)

        self.player.draw(surface, self.camera)
        self.hud.draw(surface, self.player, self.boss)
        self.shop.draw(surface, self.player)

        # Wave info
        if len(self.enemies) == 0 and self.wave_timer > 0 and self.wave < len(WAVE_TEMPLATES):
            font = pygame.font.SysFont("Arial", 26, bold=True)
            msg = font.render(f"Oleada {self.wave + 1} en {(120 - self.wave_timer)//60 + 1}...", True, YELLOW)
            surface.blit(msg, (SCREEN_WIDTH//2 - msg.get_width()//2, 60))
        elif len(self.enemies) > 0:
            font = pygame.font.SysFont("Arial", 20)
            msg  = font.render(f"Oleada {self.wave + 1} / {len(WAVE_TEMPLATES)}  —  {len(self.enemies)} enemigos", True, WHITE)
            surface.blit(msg, (SCREEN_WIDTH//2 - msg.get_width()//2, 12))
