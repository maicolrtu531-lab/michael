# Wrath of the Gods 3D — Godot 4

RPG de acción 3D estilo God of War hecho en Godot 4.

## Cómo abrir el proyecto

1. Abre **Godot 4**
2. Click en **"Importar"**
3. Navega a esta carpeta y selecciona `project.godot`
4. Click **"Importar y Editar"**

## Crear las escenas manualmente en el editor

El proyecto incluye todos los scripts GDScript. Necesitas crear las escenas en el editor de Godot:

### Escena del Jugador (scenes/player/player.tscn)
```
CharacterBody3D  [script: scripts/player/player.gd]
├── CameraArm (SpringArm3D)
│   └── Camera3D
├── Mesh (MeshInstance3D) — CapsuleMesh
├── CollisionShape3D — CapsuleShape3D
└── HitArea (Area3D) — SphereShape3D, radio 2.0
```

### Escena Enemigo Base (scenes/enemies/draugr.tscn)
```
CharacterBody3D  [script: scripts/enemies/draugr.gd]
├── Mesh (MeshInstance3D) — CapsuleMesh, color morado
├── CollisionShape3D — CapsuleShape3D
├── NavigationAgent3D
└── HPBar (Node3D) — opcional
```

### Escena Principal (scenes/world/main.tscn)
```
Node  [script: scripts/world/game_manager.gd]
├── Player (instancia de player.tscn)
├── HUD (instancia de hud.tscn)
├── StatsMenu (instancia de stats_menu.tscn)
├── WorldEnvironment
├── DirectionalLight3D
├── SpawnPoints (Node3D)
│   ├── SpawnPoint1..8 (Marker3D, posiciones alrededor del mapa)
└── NavigationRegion3D (mapa con NavMesh)
```

## Controles

| Tecla | Acción |
|-------|--------|
| WASD | Mover |
| Clic izquierdo | Ataque ligero |
| Clic derecho | Ataque pesado |
| ESPACIO | Esquivar |
| E | Lanzar hacha |
| F | Usar poción |
| T | Bloquear objetivo |
| M | Estadísticas |
| ESC | Salir |

## Enemigos
- **Draugr** — básico
- **Berserker** — rápido, carga
- **Baldur** — BOSS, 2 fases, carga y golpe en área

## Sistema de estadísticas (M)
- Cada nivel otorga 3 puntos
- Stats: Fuerza, Vitalidad, Agilidad, Inteligencia
- Costo escala con el nivel actual de cada stat
