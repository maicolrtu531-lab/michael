import pygame
import random
from src.settings import *
from src.entities.player     import Player
from src.entities.enemy      import Draugr, Berserker, Revenant, Ancient, Baldur
from src.entities.projectile import AxeProjectile, BlizzardEffect, FloatingText
from src.entities.npc        import NPC, NPC_DEFINITIONS
from src.ui.hud              import HUD
from src.ui.inventory        import ShopMenu
from src.ui.stats_menu       import StatsMenu
from src.camera              import Camera
from src.world               import WorldMap, NPC_SPAWN_POSITIONS

WAVE_TEMPLATES = [
    [(Draugr, 4)],
    [(Draugr, 4), (Berserker, 2)],
    [(Berserker, 3), (Revenant, 2)],
    [(Draugr, 3), (Berserker, 2), (Revenant, 2)],
    [(Ancient, 2), (Berserker, 3)],
    [(Draugr, 5), (Revenant, 3), (Ancient, 1)],
    [(Baldur, 1)],
]

class GameScene:
    def __init__(self):
        self.world  = WorldMap()
        self.camera = Camera()
        self.player = Player(WORLD_WIDTH // 2, WORLD_HEIGHT // 2)
        self.hud    = HUD()
        self.shop   = ShopMenu()
        self.stats  = StatsMenu()
        self.enemies     = []
        self.projectiles = []
        self.effects     = []
        self.texts       = []
        self.wave        = 0
        self.wave_timer  = 0
        self.boss        = None
        self.next_scene  = None
        self.npcs = [NPC(name, pos[0], pos[1]) for name, pos in NPC_SPAWN_POSITIONS.items()]
        self.npc_message       = ""
        self.npc_message_timer = 0
        self._spawn_wave()

    def _spawn_wave(self):
        if self.wave >= len(WAVE_TEMPLATES):
            return
        for cls, count in WAVE_TEMPLATES[self.wave]:
            for _ in range(count):
                x, y = self._rand_pos()
                e = cls(x, y)
                self.enemies.append(e)
                if isinstance(e, Baldur):
                    self.boss = e

    def _rand_pos(self):
        px, py = self.player.rect.center
        while True:
            x = random.randint(TILE_SIZE * 2, WORLD_WIDTH  - TILE_SIZE * 2)
            y = random.randint(TILE_SIZE * 2, WORLD_HEIGHT - TILE_SIZE * 2)
            if abs(x - px) > 300 or abs(y - py) > 300:
                return x, y

    def handle_event(self, event):
        if self.stats.visible:
            self.stats.handle_event(event, self.player)
            return
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
                else:
                    self.texts.append(FloatingText(p.rect.centerx, p.rect.top, "En recarga!" if p.axe_throw_cd > 0 else "Mana insuf.", GRAY))
            elif event.key == pygame.K_r:
                bliz = p.blizzard()
                if bliz:
                    self.effects.append(BlizzardEffect(bliz["x"], bliz["y"], bliz["radius"], bliz["damage"]))
                else:
                    self.texts.append(FloatingText(p.rect.centerx, p.rect.top, "Mana insuf.", LIGHT_BLUE))
            elif event.key == pygame.K_q:
                if p.spartan_rage():
                    self.texts.append(FloatingText(p.rect.centerx, p.rect.top - 20, "FURIA ESPARTANA!", ORANGE))
            elif event.key == pygame.K_t:
                proj = p.odin_ray()
                if proj:
                    self.projectiles.append(AxeProjectile(proj["x"], proj["y"], proj["dx"], proj["dy"], proj["damage"]))
                elif p.has_odin_ray:
                    self.texts.append(FloatingText(p.rect.centerx, p.rect.top, "En recarga!" if p.odin_ray_cd > 0 else "Mana insuf.", GOLD))
            elif event.key == pygame.K_y:
                if p.divine_shield():
                    self.texts.append(FloatingText(p.rect.centerx, p.rect.top - 20, "ESCUDO DIVINO!", GREEN))
                elif p.has_divine_shield:
                    self.texts.append(FloatingText(p.rect.centerx, p.rect.top, "En recarga!" if p.divine_shield_cd > 0 else "Mana insuf.", GREEN))
            elif event.key == pygame.K_u:
                storm = p.thunder_storm()
                if storm:
                    self.effects.append(BlizzardEffect(storm["x"], storm["y"], storm["radius"], storm["damage"]))
                    self.texts.append(FloatingText(p.rect.centerx, p.rect.top - 20, "TORMENTA DE TRUENOS!", YELLOW))
                elif p.has_thunder_storm:
                    self.texts.append(FloatingText(p.rect.centerx, p.rect.top, "En recarga!" if p.thunder_storm_cd > 0 else "Mana insuf.", YELLOW))
            elif event.key in (pygame.K_f, pygame.K_h):
                talked = False
                for npc in self.npcs:
                    if npc.near(self.player):
                        msg = npc.interact(self.player)
                        self.npc_message = msg
                        self.npc_message_timer = 180
                        talked = True
                        break
                if not talked:
                    p.use_potion()
            elif event.key == pygame.K_i:
                self.shop.toggle()
            elif event.key == pygame.K_m:
                self.stats.toggle()

    def _apply_melee(self, atk):
        for enemy in self.enemies:
            if not enemy.dead and atk["rect"].colliderect(enemy.rect):
                enemy.take_damage(atk["damage"], atk.get("knockback"))
                self.texts.append(FloatingText(enemy.rect.centerx, enemy.rect.top, f"-{atk['damage']}", RED))

    def update(self):
        keys = pygame.key.get_pressed()
        self.player.update(keys, self.world.rect)
        self.camera.update(self.player)
        for npc in self.npcs:
            npc.update()
        if self.npc_message_timer > 0:
            self.npc_message_timer -= 1
        for e in self.enemies:
            e.update(self.player, self.world.rect)
            e.try_attack(self.player)
        for proj in list(self.projectiles):
            proj.update(self.world.rect)
            for e in self.enemies:
                if not e.dead and e not in proj.hit_enemies and proj.rect.colliderect(e.rect):
                    e.take_damage(proj.damage)
                    self.texts.append(FloatingText(e.rect.centerx, e.rect.top, f"-{proj.damage}", CYAN))
                    proj.hit_enemies.append(e)
                    proj.lifetime = 0
                    break
        self.projectiles = [p for p in self.projectiles if p.alive]
        for b in self.effects:
            b.update()
            for e in self.enemies:
                if not e.dead and id(e) not in b.hit_set:
                    ex, ey = e.rect.center
                    if ((ex - b.x)**2 + (ey - b.y)**2) ** 0.5 < b.radius:
                        e.take_damage(b.damage)
                        e.freeze(150)
                        b.hit_set.add(id(e))
                        self.texts.append(FloatingText(e.rect.centerx, e.rect.top, f"- {b.damage}", ICE_BLUE))
        self.effects = [b for b in self.effects if b.alive]
        for t in self.texts:
            t.update()
        self.texts = [t for t in self.texts if t.alive]
        for e in list(self.enemies):
            if e.dead:
                self.player.kills += 1
                self.player.gold  += e.gold_reward
                self.player.gain_exp(e.exp_reward)
                self.player.mana = min(self.player.max_mana, self.player.mana + 8)
                self.texts.append(FloatingText(e.rect.centerx, e.rect.top - 10, f"+{e.exp_reward}xp", YELLOW))
                self.texts.append(FloatingText(e.rect.centerx, e.rect.top - 28, "+8 MP", LIGHT_BLUE))
                self.enemies.remove(e)
                if e is self.boss:
                    self.boss = None
        if len(self.enemies) == 0:
            self.wave_timer += 1
            if self.wave_timer > 120:
                self.wave_timer = 0
                self.wave += 1
                if self.wave >= len(WAVE_TEMPLATES):
                    self.next_scene = SCENE_WIN
                else:
                    self._spawn_wave()
        if self.player.hp <= 0:
            self.next_scene = SCENE_GAMEOVER

    def draw(self, surface):
        self.world.draw(surface, self.camera)
        for npc in self.npcs:
            npc.draw(surface, self.camera)
            if npc.near(self.player):
                npc.draw_prompt(surface, self.camera)
        for e in self.enemies:
            e.draw(surface, self.camera)
        for proj in self.projectiles:
            proj.draw(surface, self.camera)
        for b in self.effects:
            b.draw(surface, self.camera)
        for t in self.texts:
            t.draw(surface, self.camera)
        self.player.draw(surface, self.camera)
        self.hud.draw(surface, self.player, self.boss)
        self.shop.draw(surface, self.player)
        self.stats.draw(surface, self.player)
        if self.npc_message_timer > 0:
            font = pygame.font.SysFont("Arial", 22, bold=True)
            msg = font.render(self.npc_message, True, GOLD)
            msg.set_alpha(min(255, self.npc_message_timer * 4))
            surface.blit(msg, (SCREEN_WIDTH//2 - msg.get_width()//2, SCREEN_HEIGHT//2 - 120))
        font = pygame.font.SysFont("Arial", 20)
        if len(self.enemies) == 0 and self.wave_timer > 0 and self.wave < len(WAVE_TEMPLATES):
            msg = font.render(f"Oleada {self.wave + 1} en breve...", True, YELLOW)
            surface.blit(msg, (SCREEN_WIDTH//2 - msg.get_width()//2, 60))
        elif len(self.enemies) > 0:
            msg = font.render(f"Oleada {self.wave + 1}/{len(WAVE_TEMPLATES)}  -  {len(self.enemies)} enemigos", True, WHITE)
            surface.blit(msg, (SCREEN_WIDTH//2 - msg.get_width()//2, 12))
