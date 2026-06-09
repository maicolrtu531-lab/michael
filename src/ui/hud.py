import pygame
from src.settings import *

class HUD:
    def __init__(self):
        self.font      = pygame.font.SysFont("Arial", 17)
        self.font_big  = pygame.font.SysFont("Arial", 20, bold=True)
        self.font_sm   = pygame.font.SysFont("Arial", 14)

    def draw(self, surface, player, boss=None):
        self._panel(surface, player)
        self._abilities(surface, player)
        self._minimap_hint(surface, player)
        if boss:
            self._boss_bar(surface, boss)
        if player.level_up_flash > 0:
            self._level_up(surface, player)
        if player.rage_active > 0:
            self._rage_overlay(surface)

    # ── Bottom-left stat panel ─────────────────────────────────────────────
    def _panel(self, surface, p):
        panel = pygame.Surface((280, 100), pygame.SRCALPHA)
        panel.fill((0, 0, 0, 140))
        surface.blit(panel, (10, SCREEN_HEIGHT - 110))

        self._bar(surface, 18, SCREEN_HEIGHT - 105, p.hp,   p.max_hp,   RED,        f"HP  {p.hp}/{p.max_hp}")
        self._bar(surface, 18, SCREEN_HEIGHT - 80,  p.mana, p.max_mana, LIGHT_BLUE, f"MP  {int(p.mana)}/{p.max_mana}")

        exp_ratio = p.exp / p.exp_needed
        self._bar(surface, 18, SCREEN_HEIGHT - 55, p.exp, p.exp_needed, GOLD, f"EXP  {p.exp}/{p.exp_needed}")

        info = self.font_sm.render(f"Nv.{p.level}  ☠ {p.kills}  🪙 {p.gold}  🧪 {p.potions}", True, WHITE)
        surface.blit(info, (18, SCREEN_HEIGHT - 32))

    def _bar(self, surface, x, y, cur, mx, color, label):
        bw = 256
        ratio = max(0, cur / mx)
        pygame.draw.rect(surface, DARK_GRAY, (x, y, bw, 16))
        pygame.draw.rect(surface, color,     (x, y, int(bw * ratio), 16))
        pygame.draw.rect(surface, WHITE,     (x, y, bw, 16), 1)
        t = self.font_sm.render(label, True, WHITE)
        surface.blit(t, (x + 4, y + 1))

    # ── Ability cooldown icons ─────────────────────────────────────────────
    def _abilities(self, surface, p):
        panel = pygame.Surface((220, 54), pygame.SRCALPHA)
        panel.fill((0, 0, 0, 140))
        surface.blit(panel, (SCREEN_WIDTH - 230, SCREEN_HEIGHT - 64))

        abilities = [
            ("ATK", pygame.K_SPACE, p.attack_cooldown,  20, ICE_BLUE),
            ("AXE", pygame.K_e,     p.axe_throw_cd,     90, CYAN),
            ("ICE", pygame.K_r,     p.blizzard_cd,      180, LIGHT_BLUE),
            ("RAGE",pygame.K_q,     p.rage_cd,          600, ORANGE),
        ]
        for i, (name, key, cd, max_cd, color) in enumerate(abilities):
            x = SCREEN_WIDTH - 225 + i * 54
            y = SCREEN_HEIGHT - 58
            ready = cd == 0
            pygame.draw.rect(surface, color if ready else DARK_GRAY, (x, y, 48, 44), border_radius=4)
            pygame.draw.rect(surface, WHITE, (x, y, 48, 44), 1, border_radius=4)
            lbl = self.font_sm.render(name, True, BLACK if ready else GRAY)
            surface.blit(lbl, (x + 24 - lbl.get_width()//2, y + 4))
            key_lbl = self.font_sm.render(pygame.key.name(key).upper(), True, BLACK if ready else GRAY)
            surface.blit(key_lbl, (x + 24 - key_lbl.get_width()//2, y + 26))
            if not ready:
                ratio = cd / max_cd
                pygame.draw.rect(surface, (0,0,0,160), (x, y + int(44*(1-ratio)), 48, int(44*ratio)))

    # ── Boss health bar ─────────────────────────────────────────────────────
    def _boss_bar(self, surface, boss):
        bw = 500
        bx = SCREEN_WIDTH//2 - bw//2
        by = 16
        panel = pygame.Surface((bw + 20, 50), pygame.SRCALPHA)
        panel.fill((0, 0, 0, 180))
        surface.blit(panel, (bx - 10, by - 8))
        ratio = max(0, boss.hp / boss.max_hp)
        phase_color = ORANGE if boss.phase == 2 else PURPLE
        pygame.draw.rect(surface, DARK_RED,   (bx, by + 20, bw, 18))
        pygame.draw.rect(surface, phase_color,(bx, by + 20, int(bw * ratio), 18))
        pygame.draw.rect(surface, GOLD,       (bx, by + 20, bw, 18), 2)
        name_lbl = self.font_big.render(f"⚔  {boss.name}  —  {boss.hp} / {boss.max_hp}", True, GOLD)
        surface.blit(name_lbl, (SCREEN_WIDTH//2 - name_lbl.get_width()//2, by))

    # ── Level up banner ─────────────────────────────────────────────────────
    def _level_up(self, surface, p):
        alpha = min(255, p.level_up_flash * 5)
        txt = self.font_big.render(f"¡NIVEL {p.level}!", True, GOLD)
        txt.set_alpha(alpha)
        surface.blit(txt, (SCREEN_WIDTH//2 - txt.get_width()//2, SCREEN_HEIGHT//2 - 60))

    def _rage_overlay(self, surface):
        overlay = pygame.Surface((SCREEN_WIDTH, SCREEN_HEIGHT), pygame.SRCALPHA)
        pygame.draw.rect(overlay, (255, 60, 0, 25), (0, 0, SCREEN_WIDTH, SCREEN_HEIGHT))
        surface.blit(overlay, (0, 0))

    def _minimap_hint(self, surface, p):
        pass
