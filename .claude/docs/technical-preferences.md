<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->

# Technical Preferences

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Rendering**: Godot Forward+ renderer
- **Physics**: Godot Physics (GodotPhysics3D)

## Input & Platform

- **Target Platforms**: PC (Steam / itch.io) — Windows, macOS, Linux
- **Input Methods**: Keyboard/Mouse, Gamepad (optional)
- **Primary Input**: Keyboard/Mouse
- **Gamepad Support**: Partial
- **Touch Support**: None
- **Platform Notes**: PC-only release. Mouse-relative camera (SpringArm3D).

## Naming Conventions

- **Classes**: PascalCase (e.g., `PlayerController`)
- **Variables/functions**: snake_case (e.g., `move_speed`, `take_damage()`)
- **Signals/Events**: snake_case past tense (e.g., `health_changed`, `enemy_killed`)
- **Files**: snake_case matching class (e.g., `player_controller.gd`)
- **Scenes/Prefabs**: PascalCase matching root node (e.g., `PlayerController.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`)

## Performance Budgets

- **Target Framerate**: 60 fps
- **Frame Budget**: 16.6 ms
- **Draw Calls**: ≤ 200 per frame (Godot Forward+ on mid-range PC)
- **Memory Ceiling**: 512 MB RAM

## Testing

- **Framework**: GUT (Godot Unit Testing) — `addons/gut/`
- **Minimum Coverage**: Core gameplay formulas, state machines, damage calculations
- **Required Tests**: Combat formulas (damage, cooldowns), wave spawning logic, player stat progression

## Forbidden Patterns

- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist (all .gd files)
- **Shader Specialist**: godot-shader-specialist (.gdshader files, VisualShader resources)
- **UI Specialist**: godot-specialist (no dedicated UI specialist — primary covers all UI)
- **Additional Specialists**: godot-gdextension-specialist (GDExtension / native C++ bindings only)
- **Routing Notes**: Invoke primary for architecture decisions, ADR validation, and cross-cutting code review. Invoke GDScript specialist for code quality, signal architecture, static typing enforcement, and GDScript idioms. Invoke shader specialist for material design and shader code. Invoke GDExtension specialist only when native extensions are involved.

### File Extension Routing

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |
