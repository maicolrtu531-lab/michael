# Wrath of the Gods — Game Concept

> **Status**: Approved (inferred from working prototype)
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-06-10

## Overview

Wrath of the Gods 3D is a single-player action RPG arena brawler for PC, inspired by God of War. The player controls a warrior-mage inside a walled stone arena and must survive 5 escalating waves of enemies using melee combos, dodge rolls, and 6 distinct spells. The game ends either in defeat (player death, scene reloads) or victory (Baldur boss defeated).

## Genre & Scope

- **Genre**: Action RPG — Arena Brawler
- **Scope**: Single scene, 5 waves, 1 boss — vertical slice / prototype
- **Platform**: PC (Steam / itch.io)
- **Engine**: Godot 4.6, GDScript

## Core Loop

1. Wave starts → enemies spawn at random spawn points around the arena
2. Player fights using melee combos (LMB/RMB) and 6 spells (E, R, Q, 1, 2, 3)
3. All enemies die → brief pause → next wave begins
4. Wave 5 = Baldur boss (2 phases) → kill him → Victory

## Player Fantasy

Feel like a demigod unleashing devastating divine power: chain melee combos, lock onto enemies, and detonate area spells that transform the arena. Every kill refills mana. Die and the arena resets — you always get another shot.

## Game Pillars

1. **Visceral Melee** — Combos feel weighty; knockback and screen flash sell every hit
2. **Spell Spectacle** — 6 spells with distinct VFX; casting should feel powerful
3. **Escalating Threat** — Each wave is harder; Baldur is a true test
4. **Instant Replayability** — Death reloads immediately; no menus needed

## Controls

| Key | Action |
|-----|--------|
| WASD | Move |
| Mouse | Camera |
| LMB / Z | Light attack (combo ×3) |
| RMB / X | Heavy attack |
| E | Throw Axe (15 MP) |
| R | Blizzard AoE (25 MP) |
| Q | Spartan Rage +50% dmg (30 MP) |
| 1 | Lightning Strike (20 MP) |
| 2 | Divine Shield 4s (20 MP) |
| 3 | Ground Slam (30 MP) |
| SPACE | Dodge roll |
| F | Health Potion |
| T | Lock target |

## Enemies

| Enemy | Role | HP | Dmg | Speed |
|-------|------|----|----|-------|
| Draugr | Basic melee | 60 | 12 | 3.5 |
| Berserker | Fast aggressive | 50 | 18 | 5.5 |
| Baldur (Phase 1) | Boss | 400 | 45 | 4.0 |
| Baldur (Phase 2) | Boss enraged | 400 | 60 | 6.0 |

## Waves

| Wave | Enemies |
|------|---------|
| 1 | 4× Draugr |
| 2 | 4× Draugr + 2× Berserker |
| 3 | 3× Berserker + 3× Draugr |
| 4 | 5× Draugr + 3× Berserker |
| 5 | 1× Baldur (boss) |
