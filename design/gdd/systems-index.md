# Systems Index — Wrath of the Gods 3D

> **Last Updated**: 2026-06-10
> Generated from working prototype by /design-system

## Progress Tracker

| Status | Count |
|--------|-------|
| Approved | 0 |
| Designed | 0 |
| In Design | 0 |
| Not Started | 6 |

---

## MVP Systems (must ship)

| Priority | System | Layer | Depends On | Depended On By | Status | Design Doc |
|----------|--------|-------|------------|----------------|--------|------------|
| 1 | combat | Player-Facing | player-stats, enemy-ai | spell-system, wave-manager | Designed | design/gdd/combat.md |
| 2 | spell-system | Player-Facing | combat, player-stats | — | Not Started | — |
| 3 | player-stats | Foundation | — | combat, spell-system, progression | Not Started | — |
| 4 | enemy-ai | Foundation | player-stats | combat, wave-manager | Not Started | — |
| 5 | wave-manager | Game Loop | enemy-ai | — | Not Started | — |
| 6 | progression | Player-Facing | player-stats | — | Not Started | — |

---

## System Descriptions

### combat
Core melee loop: light attack (combo ×3), heavy attack, dodge roll, hit detection, knockback, damage formula. Handles all player-to-enemy and enemy-to-player melee interactions.

### spell-system
6 player spells with distinct effects: Throw Axe, Blizzard, Spartan Rage, Lightning Strike, Divine Shield, Ground Slam. Each has mana cost, cooldown, damage formula, and VFX.

### player-stats
All numeric attributes: HP, Mana, base_damage, defense, move_speed, mana_regen. Includes leveling formula, experience thresholds, stat growth on level-up, potion system.

### enemy-ai
State machine (IDLE → CHASE → ATTACK → DEAD) with detect range, attack range, knockback, freeze status. Covers Draugr, Berserker, and Baldur phase transitions.

### wave-manager
5-wave spawning schedule, spawn point selection, between-wave timer (4s), win/lose conditions, game-over (scene reload), victory screen.

### progression
Level-up formula (exp thresholds), stat growth per level, gold accumulation, stat_points system. Post-MVP: stat allocation screen.
