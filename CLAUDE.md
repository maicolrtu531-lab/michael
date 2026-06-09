# Mi Videojuego — Proyecto Base

Motor: Python + Pygame  
Estructura modular para expandir fácilmente.

## Estructura
- `main.py` — punto de entrada
- `src/settings.py` — todas las constantes y configuración
- `src/game.py` — loop principal
- `src/scenes/` — escenas del juego (menú, mundo, combate...)
- `src/entities/` — jugador, enemigos, NPCs
- `src/ui/` — HUD, menús, barras
- `src/utils/` — helpers reutilizables
- `assets/` — imágenes, sonidos, fuentes
- `maps/` — mapas del mundo
- `saves/` — guardados

## Controles actuales
- WASD / Flechas: mover jugador
- ESPACIO: atacar enemigos cercanos
- ESC: salir

## Para correr
```bash
pip install pygame
python main.py
```

## Responde siempre de forma concisa y sin relleno.
