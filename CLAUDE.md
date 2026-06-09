# Wrath of the Gods — RPG de Acción

Motor: Python 3 + Pygame  
Inspirado en God of War. Estructura modular.

## Estructura
- `main.py` — punto de entrada
- `src/settings.py` — constantes globales (colores, tamaños, escenas)
- `src/game.py` — loop principal + gestor de escenas
- `src/camera.py` — cámara scrolling
- `src/world.py` — mapa procedural con tiles
- `src/scenes/` — menu_scene, game_scene, gameover_scene
- `src/entities/` — player, enemy (Draugr/Berserker/Revenant/Ancient/Baldur), projectile
- `src/ui/` — hud, inventory (tienda)

## Controles
| Tecla | Acción |
|-------|--------|
| WASD / Flechas | Mover |
| ESPACIO | Ataque cuerpo a cuerpo (combo x3) |
| E | Lanzar hacha (15 mana) |
| R | Blizzard en área (25 mana) |
| Q | Furia Espartana (30 mana, daño +50%) |
| F / H | Usar poción |
| I | Abrir tienda |
| ESC | Salir |

## Enemigos
- **Draugr** — básico
- **Berserker** — rápido y agresivo
- **Revenant** — se teletransporta
- **Ancient** — tanque lento con núcleo naranja
- **Baldur** — BOSS con 2 fases y carga

## Para correr
```bash
pip install pygame
python main.py
```

## Responde siempre de forma concisa y sin relleno.
