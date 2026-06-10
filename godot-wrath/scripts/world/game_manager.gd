extends Node

var current_wave   : int   = 0
var current_world  : int   = 1
var enemies_alive  : int   = 0
var wave_timer     : float = 0.0
var wave_timeout   : float = 0.0
var between_waves  : bool  = false
var total_gold     : int   = 0

var player         : Node3D = null
var hud            : CanvasLayer = null
var stats_menu     : CanvasLayer = null
var shop_menu      : CanvasLayer = null
var inventory_menu : CanvasLayer = null
var spawn_points   : Node3D = null

signal wave_started(wave_number)
signal wave_cleared(wave_number)
signal game_over
signal victory

const DRAUGR    = preload("res://scenes/enemies/draugr.tscn")
const BERSERKER = preload("res://scenes/enemies/berserker.tscn")
const BALDUR    = preload("res://scenes/enemies/baldur_boss.tscn")

# Base wave definitions — each world re-uses these with scaled stats
const WAVE_TEMPLATES : Array = [
	[{"type": "Draugr",    "count": 2}],
	[{"type": "Draugr",    "count": 4}],
	[{"type": "Draugr",    "count": 3}, {"type": "Berserker", "count": 2}],
	[{"type": "Draugr",    "count": 4}, {"type": "Berserker", "count": 3}],
	[{"type": "Berserker", "count": 4}, {"type": "Draugr",    "count": 4}],
	[{"type": "Draugr",    "count": 5}, {"type": "Berserker", "count": 5}],
	[{"type": "Berserker", "count": 6}, {"type": "Draugr",    "count": 5}],
	[{"type": "Draugr",    "count": 6}, {"type": "Berserker", "count": 6}],
	[{"type": "Berserker", "count": 8}, {"type": "Draugr",    "count": 8}],
	[{"type": "Draugr",    "count": 5}, {"type": "Berserker", "count": 5}, {"type": "Baldur", "count": 1}],
]

func _world_multiplier() -> float:
	return 1.0 + (current_world - 1) * 0.4

func _ready() -> void:
	player         = get_node_or_null("Player")
	hud            = get_node_or_null("HUD")
	stats_menu     = get_node_or_null("StatsMenu")
	shop_menu      = get_node_or_null("Shop")
	inventory_menu = get_node_or_null("InventoryMenu")
	spawn_points   = get_node_or_null("SpawnPoints")

	if player:
		if player.has_signal("died"):
			player.died.connect(_on_player_died)
		if player.has_signal("enemy_killed"):
			player.enemy_killed.connect(_on_enemy_kill_gold)

	if hud and player:
		hud.connect_player(player)

	if stats_menu and player:
		stats_menu.connect_player(player)
	if shop_menu and player:
		shop_menu.connect_player(player)
	if inventory_menu and player:
		inventory_menu.connect_player(player)

	await get_tree().create_timer(0.5).timeout
	_start_wave(0)

func _process(delta: float) -> void:
	# Wave timeout: if enemies get stuck, force-advance after 90s
	if not between_waves and enemies_alive > 0:
		wave_timeout -= delta
		if wave_timeout <= 0:
			print("Wave timeout — forcing wave clear")
			enemies_alive = 0
			_on_enemy_died(null)

	if between_waves:
		wave_timer -= delta
		# Show countdown
		if hud and wave_timer > 0:
			var next = current_wave + 1
			if next < WAVE_TEMPLATES.size():
				hud.show_countdown("Próxima oleada: %d" % ceili(wave_timer))
			else:
				hud.show_countdown("Próximo mundo: %d" % ceili(wave_timer))
		if wave_timer <= 0:
			between_waves = false
			if hud:
				hud.clear_countdown()
			current_wave += 1
			if current_wave >= WAVE_TEMPLATES.size():
				_next_world()
			else:
				_start_wave(current_wave)

func _next_world() -> void:
	current_world += 1
	current_wave   = 0
	var mult = _world_multiplier()
	if hud:
		hud.update_wave_label("MUNDO %d — Oleada 1" % current_world)
		hud.show_message("MUNDO %d  (x%.1f)" % [current_world, mult], Color(1.0, 0.6, 0.0, 1))
	await get_tree().create_timer(3.0).timeout
	_start_wave(0)

func _any_menu_open() -> bool:
	var sm = stats_menu and stats_menu.visible_flag
	var sh = shop_menu  and shop_menu.visible_flag
	var iv = inventory_menu and inventory_menu.visible_flag
	return sm or sh or iv

func _update_mouse_mode() -> void:
	var open = _any_menu_open()
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED if open else Input.MOUSE_MODE_CONFINED_HIDDEN
	if player:
		player.menu_open = open

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if _any_menu_open():
				if stats_menu and stats_menu.visible_flag:
					stats_menu.toggle()
				if shop_menu and shop_menu.visible_flag:
					shop_menu.toggle()
				if inventory_menu and inventory_menu.visible_flag:
					inventory_menu.toggle()
				_update_mouse_mode()
			else:
				get_tree().quit()
		elif event.keycode == KEY_TAB:
			if stats_menu:
				stats_menu.toggle()
				_update_mouse_mode()
		elif event.keycode == KEY_B:
			if shop_menu:
				shop_menu.toggle()
				_update_mouse_mode()
		elif event.keycode == KEY_I:
			if inventory_menu:
				inventory_menu.toggle()
				_update_mouse_mode()

func _start_wave(wave_idx: int) -> void:
	var wave_num = wave_idx + 1
	emit_signal("wave_started", wave_num)
	if hud:
		hud.update_wave_label("Mundo %d — Oleada %d" % [current_world, wave_num])
		hud.show_message("OLEADA %d" % wave_num, Color.ORANGE)

	var template = WAVE_TEMPLATES[wave_idx]
	enemies_alive = 0
	wave_timeout  = 90.0

	for group in template:
		for i in range(group["count"]):
			var enemy = _spawn_enemy(group["type"])
			if enemy:
				enemies_alive += 1
				enemy.died.connect(_on_enemy_died)
				# Force enemy to find and chase player immediately
				if player and is_instance_valid(player):
					enemy.player = player
					enemy.state  = 1  # State.CHASE
	print("Wave %d started — enemies_alive: %d" % [wave_num, enemies_alive])

	# Safety: if no enemies spawned, advance after a short delay
	if enemies_alive == 0:
		await get_tree().create_timer(1.0).timeout
		_on_enemy_died(null)

func _spawn_enemy(type: String) -> Node:
	var scene : PackedScene = null
	match type:
		"Draugr":    scene = DRAUGR
		"Berserker": scene = BERSERKER
		"Baldur":    scene = BALDUR
	if not scene:
		return null

	var enemy = scene.instantiate()
	add_child(enemy)
	enemy.global_position = _get_spawn_point()

	# Apply world difficulty scaling
	var mult = _world_multiplier()
	if mult > 1.0:
		enemy.max_hp      = int(enemy.max_hp      * mult)
		enemy.hp          = enemy.max_hp
		enemy.attack_dmg  = int(enemy.attack_dmg  * mult)
		enemy.move_speed  = enemy.move_speed * min(mult * 0.5 + 0.5, 2.0)
		enemy.exp_reward  = int(enemy.exp_reward   * mult)
		enemy.gold_reward = int(enemy.gold_reward  * mult)

	return enemy

func _get_spawn_point() -> Vector3:
	if spawn_points:
		var pts = spawn_points.get_children()
		if pts.size() > 0:
			return pts[randi() % pts.size()].global_position + Vector3(0, 1, 0)
	return Vector3(randf_range(-10, 10), 1, randf_range(-10, 10))

func _on_enemy_died(_enemy) -> void:
	enemies_alive -= 1
	if enemies_alive <= 0:
		emit_signal("wave_cleared", current_wave + 1)
		if hud:
			hud.show_message("OLEADA COMPLETADA!", Color.GREEN)
		between_waves = true
		wave_timer    = 3.0

func _on_enemy_kill_gold() -> void:
	if player and "gold" in player:
		total_gold = player.gold
		if hud:
			hud.update_gold(total_gold)

func _on_player_died() -> void:
	emit_signal("game_over")
	if hud:
		hud.show_message("HAS MUERTO", Color.RED)
	await get_tree().create_timer(2.5).timeout
	get_tree().reload_current_scene()

func _victory() -> void:
	emit_signal("victory")
	if hud:
		hud.show_message("VICTORIA!", Color.GOLD)
