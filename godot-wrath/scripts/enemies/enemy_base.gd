extends CharacterBody3D

# ── Stats ──────────────────────────────────────────────────────────────────
@export var max_hp       : int   = 60
@export var move_speed   : float = 3.5
@export var attack_dmg   : int   = 12
@export var attack_range : float = 1.8
@export var detect_range : float = 12.0
@export var exp_reward   : int   = 40
@export var gold_reward  : int   = 8
@export var enemy_name   : String = "Draugr"

var hp           : int
var is_dead      : bool  = false
var attack_cd    : float = 0.0
var frozen_timer : float = 0.0
var knockback    : Vector3 = Vector3.ZERO
var gravity      : float = 20.0

# ── State machine ─────────────────────────────────────────────────────────
enum State { IDLE, PATROL, CHASE, ATTACK, HIT, DEAD }
var state : State = State.IDLE
var player : Node3D = null

# ── Signals ────────────────────────────────────────────────────────────────
signal died(enemy)

@onready var mesh      : MeshInstance3D = $Mesh
@onready var hp_bar    : Node3D         = $HPBar if has_node("HPBar") else null
@onready var nav_agent : NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	hp = max_hp
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")
	_on_ready_extra()

func _on_ready_extra() -> void:
	pass  # Override in subclasses

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_handle_gravity(delta)
	_update_timers(delta)

	if frozen_timer > 0:
		frozen_timer -= delta
		move_and_slide()
		return

	if knockback.length() > 0.1:
		velocity = knockback
		knockback = knockback.lerp(Vector3.ZERO, 8.0 * delta)
	else:
		_update_ai(delta)

	move_and_slide()
	_update_hp_bar()

func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.5

func _update_timers(delta: float) -> void:
	if attack_cd > 0:
		attack_cd -= delta

func _update_ai(delta: float) -> void:
	if not player:
		return
	var dist = global_position.distance_to(player.global_position)

	match state:
		State.IDLE:
			if dist < detect_range:
				state = State.CHASE
		State.CHASE:
			_chase(delta)
			if dist <= attack_range:
				state = State.ATTACK
			elif dist > detect_range + 4:
				state = State.IDLE
		State.ATTACK:
			_attack_player(delta)
			if dist > attack_range + 0.5:
				state = State.CHASE

func _chase(delta: float) -> void:
	if not nav_agent:
		return
	nav_agent.target_position = player.global_position
	var next = nav_agent.get_next_path_position()
	var dir  = (next - global_position).normalized()
	dir.y    = 0
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	# Face player
	var to_player = player.global_position - global_position
	to_player.y   = 0
	if to_player.length() > 0.1:
		var angle = atan2(to_player.x, to_player.z)
		rotation.y = lerp_angle(rotation.y, angle, 8.0 * delta)

func _attack_player(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 10.0 * delta)
	var to_player = player.global_position - global_position
	to_player.y = 0
	if to_player.length() > 0.1:
		var angle = atan2(to_player.x, to_player.z)
		rotation.y = lerp_angle(rotation.y, angle, 10.0 * delta)

	if attack_cd <= 0:
		attack_cd = 1.2
		player.take_damage(attack_dmg)

func take_damage(amount: int, knockback_vel: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
	hp -= amount
	knockback = knockback_vel
	state = State.CHASE

	# Flash red
	if mesh:
		var mat = mesh.get_surface_override_material(0)
		if mat:
			mat.albedo_color = Color.WHITE
			await get_tree().create_timer(0.1).timeout
			mat.albedo_color = _get_color()

	if hp <= 0:
		_die()

func freeze(duration: float = 2.0) -> void:
	frozen_timer = duration
	if mesh:
		var mat = mesh.get_surface_override_material(0)
		if mat:
			mat.albedo_color = Color(0.6, 0.9, 1.0)

func _die() -> void:
	is_dead = true
	state   = State.DEAD
	emit_signal("died", self)
	# Tell player about kill
	if player and player.has_method("on_enemy_killed"):
		player.on_enemy_killed(exp_reward, gold_reward)
	# Dissolve and remove
	await get_tree().create_timer(0.8).timeout
	queue_free()

func _get_color() -> Color:
	return Color(0.7, 0.2, 0.8)

func _update_hp_bar() -> void:
	if hp_bar and hp_bar.has_method("set_value"):
		hp_bar.set_value(float(hp) / float(max_hp))
