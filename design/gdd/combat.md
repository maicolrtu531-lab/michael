# Combat System

> **Status**: Designed (pending /design-review in fresh session)
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-06-10
> **Implements Pillar**: Visceral Melee

## Overview

El sistema de combate de Wrath of the Gods es el núcleo de la interacción jugador-enemigo. El jugador dispone de dos tipos de ataque cuerpo a cuerpo (ligero y pesado), un sistema de combo de 3 golpes que amplifica el daño en el tercer hit, un dodge roll con ventana de invencibilidad, y lock-on de objetivo. La detección de golpes usa distancia euclidiana directa con arco frontal de ~100° — no se usan physics layers. El daño se calcula aplicando multiplicadores de combo, tipo de ataque y Furia Espartana sobre `base_damage`. Los enemigos responden con knockback proporcional a la dirección del impacto.

*→ ADR pendiente: hit detection por distancia directa sin physics queries.*

## Player Fantasy

El jugador debe sentir que cada golpe fue **merecido**. No se trata de machacar botones — se trata de leer el momento correcto: el dodge en el último fotograma, el heavy que encuentra la apertura, el combo que remata al enemigo antes de que se recupere. La violencia es precisa y contundente. Un golpe bien ejecutado se siente en el flash, en el knockback, en el grunt del enemigo — la pantalla reacciona a tu decisión. El combate recompensa la presión sostenida sobre el enemigo (combo ×3) y castiga la precipitación (ataque deja al jugador inmóvil 0.35s).

## Detailed Design

### Core Rules

1. Attack input is consumed only when `attack_cd <= 0` AND `is_dodging == false`. Any input while either condition is true is silently discarded (no queuing).
2. Light attack sets `attack_cd = 0.35s`; heavy attack sets `attack_cd = 0.60s`. `is_attacking` is `true` for the full duration of `attack_cd`.
3. Player velocity is forced to `0` (via lerp rate 10.0) during `is_attacking`. The player cannot steer mid-swing.
4. **Combo tracking.** Each attack that fires while `combo_timer > 0` increments `combo_count` by 1 modulo 3 (`0→1→2→0→…`). If `combo_timer <= 0`, `combo_count` resets to `0` first. Every attack (re)sets `combo_timer = 0.55s`.
5. **Hit detection.** For each node in group `"enemy"`: compute `diff = enemy.position - player.position` (Y zeroed). Hit registers if `diff.length() <= 2.5` AND (`diff.length() <= 0.5` OR `forward.dot(diff.normalized()) >= -0.3`). Arc ≈ ±100° in front.
6. **Damage formula.** `dmg = int(base_damage × dmg_mult)`. `dmg_mult` starts at 1.0, ×2.0 for heavy, ×1.5 if `combo_count == 2`, ×1.5 if `rage_active > 0`. Multipliers stack multiplicatively.
7. **Knockback.** On hit: `kb = diff.normalized() × 7.0` applied to enemy velocity. Zero knockback if diff length is 0.
8. **Dodge.** Sets `is_dodging=true`, `dodge_timer=0.32s`, `invincible=0.38s`. Velocity locked to `dodge_dir × 15.0 m/s`. `is_dodging` clears when `dodge_timer` reaches 0; invincibility persists extra 0.06s.
9. **Invincibility.** While `invincible > 0`, `take_damage` returns immediately with no effect. Post-hit I-frame of 0.5s applied after any successful hit on the player.
10. **Damage taken.** `effective_dmg = max(1, incoming − defense)`. Minimum 1 damage always dealt. After hit: `hp -= effective_dmg`, `invincible = 0.5s`.
11. **Lock-on.** Toggles on `lock_target` press. Enables: closest enemy within 14.0m is selected; camera auto-rotates toward target; player facing snaps to target. Clears if target becomes invalid.
12. **Rage.** Costs 30 MP, 12s cooldown, active 6s. During rage: movement uses `sprint_speed (10.0)`, melee `dmg_mult` ×1.5. Does not interrupt active attack or dodge.

### States and Transitions

| State | Entry Condition | Blocked Actions | Exit Condition |
|-------|----------------|-----------------|----------------|
| **IDLE** | Default | — | Any input |
| **MOVING** | Move input length > 0.1 | — | Input released or ATTACKING |
| **ATTACKING** | Attack input, `attack_cd<=0`, not DODGING | Movement (zeroed), new attacks, dodge | `attack_cd` reaches 0 |
| **DODGING** | Dodge input, not already dodging | All attacks | `dodge_timer` reaches 0 |
| **INVINCIBLE** | Post-hit OR dodge active OR Divine Shield | Damage reception | `invincible` timer reaches 0 |
| **RAGE** | Spartan Fury cast, `mana>=30`, `rage_cd<=0` | — | `rage_active` timer reaches 0 |
| **DEAD** | `hp <= 0` | All actions | — |

Concurrent: MOVING+RAGE, ATTACKING+RAGE, DODGING+INVINCIBLE. Mutually exclusive: ATTACKING↔DODGING.

### Interactions with Other Systems

| System | Data FROM combat | Data TO combat | Interface |
|--------|-----------------|----------------|-----------|
| **player-stats** | `base_damage`, `defense`, `max_hp` | `hp`, `mana` mutated | `health_changed`, `mana_changed` signals |
| **spell-system** | `mana` gates casts; `rage_active` propagates to melee ×1.5 | Mana consumed; `invincible` timer set | Same-object mutation (player.gd) |
| **enemy-ai** | `take_damage(amount, kb)` called on enemy | `attack_dmg`, `attack_range`, `attack_cd` from enemy | Direct method call both directions |
| **HUD** | Emits `health_changed`, `mana_changed`, `level_up`, `enemy_killed` | No data HUD→combat | Signal bus (pure consumer) |
| **progression** | `on_enemy_killed(exp, gold, mana_r)` on enemy death | `base_damage+5`, `defense+1`, `max_hp+20` per level | `gain_exp()` → `_level_up()` |

## Formulas

### 1. Melee Damage (Player → Enemy)

`melee_dmg = (base_dmg + level × 5) × dmg_mult`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Base damage | `base_dmg` | int | 25 | Player export var |
| Level | `level` | int | 1–∞ | Player level |
| Damage multiplier | `dmg_mult` | float | 1.0–4.5 | Product: heavy ×2.0, combo_count==2 ×1.5, rage ×1.5 (multiplicative) |
| **Output** | `melee_dmg` | float | 30–∞ | Final damage; no enemy defense stat |

**Output Range:** minimum ~30 (L1, no multipliers); unclamped above.
**Example:** Level 3, heavy + combo_count==2: `(25+15) × 3.0 = 120`

---

### 2. Damage Taken (Enemy → Player)

`dmg_taken = max(1, incoming − defense)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Incoming damage | `incoming` | float | 1–∞ | Raw enemy hit |
| Defense | `defense` | int | 5 + (level−1) | Starts 5, +1/level |
| **Output** | `dmg_taken` | int | 1–∞ | Floor of 1; full negation impossible |

**Output Range:** minimum 1.
**Example:** L1, incoming 12: `max(1, 12−5) = 7`

---

### 3. Mana Regeneration

`mana_new = min(max_mana, mana + regen_rate × delta)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Regen rate | `regen_rate` | float | 3.0 | MP/second (fixed) |
| Max mana | `max_mana` | int | 80+(level−1)×10 | +10/level |
| **Output** | `mana_new` | float | 0–max_mana | Clamped to cap |

**Example:** L1, mana=60, delta=0.016: `min(80, 60.048) = 60.048`

---

### 4. EXP Threshold per Level

`exp_needed(L) = L × 120 + L² × 20`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Target level | `L` | int | 1–∞ | Level player is trying to reach |
| **Output** | `exp_needed` | int | 140–∞ | Quadratic growth |

| L | exp_needed |
|---|-----------|
| 1 | 140 |
| 3 | 540 |
| 5 | 1,100 |
| 7 | 1,820 |
| 10 | 3,200 |

## Edge Cases

- **If attack input fires while `is_dodging == true`**: input is discarded silently. No queuing; the player must re-press after dodge ends.
- **If attack input fires while `is_attacking == true`**: input is discarded. Combos advance only on successful attack fires, not on input during lockout.
- **If `combo_timer` expires between two inputs**: `combo_count` resets to 0 before the next attack fires; the combo chain breaks regardless of visual feedback.
- **If two enemies are equidistant within melee range**: both receive full damage independently. No hit-count cap per swing.
- **If an enemy dies during the hit-registration loop**: `is_instance_valid(e)` check prevents calling `take_damage` on a freed node; hit is skipped silently.
- **If `diff.length() == 0` (enemy exactly on player position)**: `diff.normalized()` returns `Vector3.ZERO`; knockback applied is 0. Damage still applies.
- **If player has `invincible > 0` when enemy attacks**: `take_damage` returns immediately. No HP loss, no I-frame reset; `invincible` timer continues from its current value.
- **If `defense >= incoming`**: `max(1, 0)` = 1 — player always takes minimum 1 damage. Defense cannot fully negate an attack.
- **If `rage_active` expires mid-swing**: the multiplier applies to the attack that was already initiated (dmg_mult captured at attack start); next attack uses baseline.
- **If `locked_target` is freed (enemy dies while locked)**: `is_instance_valid(locked_target)` check in `_apply_camera` and `_handle_movement` clears the reference safely; camera reverts to mouse control.

## Dependencies

| System | Direction | Type | Interface |
|--------|-----------|------|-----------|
| **player-stats** | Upstream (hard) | Data source | `base_damage`, `defense`, `max_hp`, `max_mana` read every attack; `hp`/`mana` written |
| **enemy-ai** | Upstream (hard) | Mutual | Enemies call `player.take_damage()`; player calls `enemy.take_damage(dmg, kb)` |
| **spell-system** | Downstream (soft) | Data consumer | Reads `mana`, `rage_active` from player; shares player.gd state space |
| **progression** | Downstream (soft) | Event consumer | `on_enemy_killed()` called by enemy on death signal; level-up mutates player stats |
| **HUD** | Downstream (soft) | Signal consumer | `health_changed`, `mana_changed`, `enemy_killed` signals |
| **wave-manager** | Downstream (soft) | Event consumer | `player.died` signal triggers game-over; enemy `died` signal triggers wave tracking |

## Tuning Knobs

| Knob | Current | Safe Range | Effect if Too Low | Effect if Too High |
|------|---------|-----------|------------------|--------------------|
| `base_damage` | 25 | 15–40 | Fights feel slow, enemies unkillable | One-shots trivialize waves |
| `melee_range` | 2.5 m | 1.5–3.5 | Players feel they miss when they shouldn't | Free damage outside visual contact |
| `attack_cd` (light) | 0.35s | 0.2–0.5 | Spam removes decision-making | Attacks feel unresponsive |
| `attack_cd` (heavy) | 0.6s | 0.4–0.9 | Heavy is too good relative to light | Heavy never worth using |
| `combo_timer` | 0.55s | 0.4–0.8 | Combo breaks too easily mid-fight | Combo maintained without intent |
| `dodge_timer` | 0.32s | 0.2–0.5 | Dodge feels instantaneous, reads as jitter | Dodge displacement too large |
| `invincible` (dodge) | 0.38s | 0.25–0.5 | I-frame too short to dodge fast attacks | Dodge trivializes all damage |
| `invincible` (hit) | 0.5s | 0.3–0.7 | Enemy can chain hits instantly | Player cannot be pressured |
| `knockback` strength | 7.0 | 4–12 | No visual confirmation of hit | Enemies fly out of melee range constantly |
| `lock_range` | 14.0 m | 8–20 | Can't lock targets until they're already attacking | Lock activates on off-screen targets |
| `defense` (L1) | 5 | 3–10 | Player melts to any hit | Defense makes early game trivial |

## Visual/Audio Requirements

- **Hit flash**: Enemy mesh flashes white (0.12s) on any damage received; orange flash on player attack retaliation.
- **Freeze flash**: Enemy mesh turns ice-blue on Blizzard freeze (duration of frozen_timer).
- **Death squash**: Enemy mesh tweens to scale `(1.3, 0.1, 1.3)` over 0.5s then fades modulate alpha to 0 over 0.3s.
- **Sword swing**: Sword node tweens position/rotation on every attack (already implemented via Tween).
- **Body bob**: Player body oscillates on Y axis while moving (bob_timer × sin wave).
- **Dodge lean**: Body node rotation_degrees.x tweens to 25° then back to 0° on dodge.
- **Rage glow**: Player Body material emission enabled (orange, energy 1.5) while `rage_active > 0`.
- **HP bar color shift**: HP bar foreground color lerps green→yellow→red based on `hp/max_hp` ratio.

📌 **Asset Spec** — Visual/Audio requirements defined. After art bible is approved, run `/asset-spec system:combat` to produce per-asset descriptions and generation prompts.

## UI Requirements

- **HP bar**: ProgressBar bottom-left, color red, label "HP: X / Y". Updates on `health_changed` signal.
- **Mana bar**: ProgressBar below HP, color blue, label "MANA: X / Y". Updates on `mana_changed` signal.
- **Spell cooldown bar**: Bottom-center HUD shows 6 spell slots with name, MP cost, and live countdown. Green = ready, red = on cooldown with seconds remaining.
- **Wave label**: Top-center "Oleada N" displayed on wave start.
- **Center message**: Full-screen flash messages for LEVEL UP (yellow), OLEADA COMPLETADA (green), HAS MUERTO (red), VICTORIA (gold).

📌 **UX Flag — combat**: This system has UI requirements. Run `/ux-design` to create a UX spec for the HUD before writing epics.

## Acceptance Criteria

**Melee hit detection:**
- GIVEN player is within 2.5m of an enemy and facing within ±100°, WHEN light attack fires, THEN `take_damage` is called on that enemy.
- GIVEN player is 3.0m from an enemy, WHEN light attack fires, THEN no damage is dealt (enemy HP unchanged).
- GIVEN player faces away (>100° arc miss), WHEN light attack fires, THEN no damage to enemy directly behind player.

**Combo system:**
- GIVEN player fires 3 consecutive light attacks within combo_timer windows, WHEN the third attack lands, THEN damage = `base_damage × 1.5` (combo multiplier applied).
- GIVEN combo_timer expires between attacks, WHEN next attack fires, THEN combo_count resets to 0 and no ×1.5 multiplier applies.

**Heavy attack:**
- GIVEN player fires a heavy attack, WHEN it lands, THEN damage = `base_damage × 2.0`.
- GIVEN player fires a heavy attack, WHEN `attack_cd` is active (0.6s window), THEN no new attack input is accepted.

**Dodge:**
- GIVEN player presses dodge, WHEN dodge is active (0.32s), THEN player position changes in dodge direction.
- GIVEN player is in dodge (invincible=0.38s), WHEN enemy attack lands, THEN player HP is unchanged.

**Damage taken:**
- GIVEN enemy hits player for 12, player defense=5 (L1), THEN player HP decreases by 7.
- GIVEN player defense >= incoming, THEN player HP decreases by minimum 1 (never 0).

**Invincibility:**
- GIVEN player took damage (invincible=0.5s), WHEN another hit arrives within 0.5s, THEN no additional HP loss.

**Lock-on:**
- GIVEN enemy within 14m, WHEN lock_target pressed, THEN `locked_target` is set to that enemy and camera rotates toward it.
- GIVEN locked enemy dies, THEN `locked_target` is cleared and camera reverts to mouse control.

**Death:**
- GIVEN player HP reaches 0, THEN `died` signal is emitted and scene reloads within 2.5s.

## Open Questions

- **Attack queuing**: Should the last input before `attack_cd` expires be queued and auto-fired? Currently discarded. Decision affects combo fluidity.
- **Enemy defense stat**: Enemies currently have no defense. Should future enemy types (e.g., armored Draugr) reduce damage? Would require formula update.
- **Parry / counter**: Should the player have a parry window that counters for bonus damage? Not in current design — would be a new mechanic.
- **ADR pending**: Hit detection via direct distance (no physics layers) — formalize this decision so architecture review can validate it.
