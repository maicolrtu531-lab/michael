extends Node

var current_wave : int  = 0
var enemies_alive: int  = 0
var wave_timer   : float = 0.0
var between_waves: bool  = false

var player    : Node3D = null
var spawn_points : Node3D = null

signal wave_started(wave_number)
signal wave_cleared(wave_number)
signal game_over
signal victory

const DRAUGR    = preload("res://scenes/enemies/draugr.tscn")
const BERSERKER = preload("res://scenes/enemies/berserker.tscn")
const BALDUR    = preload("res://scenes/enemies/baldur_boss.tscn")

var WAVES : Array = [
	[{"type": "Draugr",    "count": 4}],
	[{"type": "Draugr",    "count": 4}, {"type": "Berserker", "count": 2}],
	[{"type": "Berserker", "count": 3}, {"type": "Draugr",    "count": 3}],
	[{"type": "Draugr",    "count": 5}, {"type": "Berserker", "count": 3}],
	[{"type": "Baldur",    "count": 1}],
]

func _ready() -> void:
	player       = get_node_or_null("Player")
	spawn_points = get_node_or_null("SpawnPoints")
	if player and player.has_signal("died"):
		player.died.connect(_on_player_died)
	_start_wave(0)

func _process(delta: float) -> void:
	if between_waves:
		wave_timer -= delta
		if wave_timer <= 0:
			between_waves = false
			current_wave += 1
			if current_wave >= WAVES.size():
				emit_signal("victory")
			else:
				_start_wave(current_wave)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()

func _start_wave(wave_idx: int) -> void:
	emit_signal("wave_started", wave_idx + 1)
	var wave = WAVES[wave_idx]
	enemies_alive = 0
	for group in wave:
		for i in range(group["count"]):
			var enemy = _spawn_enemy(group["type"])
			if enemy:
				enemies_alive += 1
				enemy.died.connect(_on_enemy_died)

func _spawn_enemy(type: String) -> Node:
	var scene = null
	match type:
		"Draugr":    scene = DRAUGR
		"Berserker": scene = BERSERKER
		"Baldur":    scene = BALDUR
	if not scene:
		return null

	var enemy = scene.instantiate()
	add_child(enemy)
	enemy.global_position = _get_spawn_point()
	return enemy

func _get_spawn_point() -> Vector3:
	if spawn_points:
		var points = spawn_points.get_children()
		if points.size() > 0:
			return points[randi() % points.size()].global_position
	return Vector3(randf_range(-20, 20), 1, randf_range(-20, 20))

func _on_enemy_died(_enemy: Node) -> void:
	enemies_alive -= 1
	if enemies_alive <= 0:
		emit_signal("wave_cleared", current_wave + 1)
		between_waves = true
		wave_timer    = 3.0

func _on_player_died() -> void:
	emit_signal("game_over")
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
