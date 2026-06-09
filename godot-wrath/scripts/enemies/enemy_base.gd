extends CharacterBody3D

@export var max_hp       : int   = 60
@export var move_speed   : float = 3.5
@export var attack_dmg   : int   = 12
@export var attack_range : float = 1.8
@export var detect_range : float = 14.0
@export var exp_reward   : int   = 40
@export var gold_reward  : int   = 8
@export var enemy_name   : String = "Enemy"

var hp           : int
var is_dead      : bool  = false
var attack_cd    : float = 0.0
var frozen_timer : float = 0.0
var knockback    : Vector3 = Vector3.ZERO
var gravity_vel  : float = 0.0

enum State { IDLE, CHASE, ATTACK, DEAD }
var state  : State = State.IDLE
var player : Node3D = null

signal died(enemy)

@onready var mesh : MeshInstance3D = $Mesh

func _ready() -> void:
	hp = max_hp
	add_to_group("enemy")
	# Find player after scene is ready
	call_deferred("_find_player")
	_on_ready_extra()

func _find_player() -> void:
	player = get_tree().get_first_node_in_group("player")

func _on_ready_extra() -> void:
	pass

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Gravity
	if not is_on_floor():
		gravity_vel -= 20.0 * delta
	else:
		gravity_vel = -2.0
	velocity.y = gravity_vel

	# Frozen
	if frozen_timer > 0:
		frozen_timer -= delta
		move_and_slide()
		return

	# Cooldowns
	if attack_cd > 0:
		attack_cd -= delta

	# Knockback
	if knockback.length() > 0.5:
		velocity.x = knockback.x
		velocity.z = knockback.z
		knockback  = knockback.lerp(Vector3.ZERO, 10.0 * delta)
		move_and_slide()
		return

	if not player or not is_instance_valid(player):
		_find_player()
		move_and_slide()
		return

	var dist = global_position.distance_to(player.global_position)

	match state:
		State.IDLE:
			velocity.x = 0
			velocity.z = 0
			if dist < detect_range:
				state = State.CHASE

		State.CHASE:
			_move_toward_player(delta, dist)
			if dist <= attack_range:
				state = State.ATTACK
			elif dist > detect_range + 5:
				state = State.IDLE

		State.ATTACK:
			# Stop and face player
			velocity.x = lerp(velocity.x, 0.0, 12.0 * delta)
			velocity.z = lerp(velocity.z, 0.0, 12.0 * delta)
			_face_player(delta)

			if dist > attack_range + 0.5:
				state = State.CHASE
			elif attack_cd <= 0:
				attack_cd = 1.4
				if player.has_method("take_damage"):
					player.take_damage(attack_dmg)
				_flash(Color(1.0, 0.3, 0.0, 1))

	move_and_slide()

func _move_toward_player(delta: float, dist: float) -> void:
	var dir = (player.global_position - global_position)
	dir.y = 0
	dir = dir.normalized()
	var spd = _get_speed(delta, dist)
	velocity.x = dir.x * spd
	velocity.z = dir.z * spd
	_face_player(delta)

func _get_speed(_delta: float, _dist: float) -> float:
	return move_speed

func _face_player(delta: float) -> void:
	var to = player.global_position - global_position
	to.y = 0
	if to.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 10.0 * delta)

func take_damage(amount: int, knockback_vel: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
	hp -= amount
	if knockback_vel.length() > 0:
		knockback = knockback_vel
	state = State.CHASE
	_flash(Color(1.0, 1.0, 1.0, 1))
	if hp <= 0:
		_die()

func _flash(col: Color) -> void:
	if mesh:
		var mat = mesh.get_surface_override_material(0)
		if mat:
			var orig = _get_color()
			mat.albedo_color = col
			await get_tree().create_timer(0.12).timeout
			if mat and is_instance_valid(self):
				mat.albedo_color = orig

func freeze(duration: float = 2.0) -> void:
	frozen_timer = duration
	if mesh:
		var mat = mesh.get_surface_override_material(0)
		if mat:
			mat.albedo_color = Color(0.6, 0.9, 1.0, 1)

func _die() -> void:
	is_dead = true
	state   = State.DEAD
	velocity = Vector3.ZERO
	emit_signal("died", self)
	if player and player.has_method("on_enemy_killed"):
		player.on_enemy_killed(exp_reward, gold_reward)
	await get_tree().create_timer(0.6).timeout
	queue_free()

func _get_color() -> Color:
	return Color(0.7, 0.2, 0.8, 1)

func _update_timers(_delta: float) -> void:
	pass
