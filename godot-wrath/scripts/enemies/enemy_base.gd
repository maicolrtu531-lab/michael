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
var _anim_timer  : float = 0.0

enum State { IDLE, CHASE, ATTACK, DEAD }
var state  : State = State.IDLE
var player : Node3D = null

signal died(enemy)

@onready var mesh : MeshInstance3D = $Mesh

# UI nodes created at runtime
var name_label  : Label3D = null
var hp_label    : Label3D = null
var hp_bar_bg   : MeshInstance3D = null
var hp_bar_fg   : MeshInstance3D = null
var hp_bar_mat  : StandardMaterial3D = null

func _ready() -> void:
	hp = max_hp
	add_to_group("enemy")
	call_deferred("_find_player")
	_on_ready_extra()
	call_deferred("_build_overhead_ui")

func _find_player() -> void:
	player = get_tree().get_first_node_in_group("player")

func _on_ready_extra() -> void:
	pass

func _build_overhead_ui() -> void:
	var bar_height = _get_bar_height()

	# Name label
	name_label = Label3D.new()
	name_label.text              = enemy_name
	name_label.font_size         = 28
	name_label.modulate          = Color(1.0, 0.9, 0.2, 1)
	name_label.outline_size      = 6
	name_label.outline_modulate  = Color(0, 0, 0, 1)
	name_label.billboard         = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.no_depth_test     = true
	name_label.position          = Vector3(0, bar_height + 0.45, 0)
	add_child(name_label)

	# HP as Label3D (reliable in Godot 4.6)
	hp_label = Label3D.new()
	hp_label.text             = "HP: %d / %d" % [hp, max_hp]
	hp_label.font_size        = 20
	hp_label.modulate         = Color(0.2, 1.0, 0.3, 1)
	hp_label.outline_size     = 4
	hp_label.outline_modulate = Color(0, 0, 0, 1)
	hp_label.billboard        = BaseMaterial3D.BILLBOARD_ENABLED
	hp_label.no_depth_test    = true
	hp_label.position         = Vector3(0, bar_height, 0)
	add_child(hp_label)

func _get_bar_height() -> float:
	return 2.0

func _update_hp_bar() -> void:
	if not hp_label:
		return
	var ratio = clamp(float(hp) / float(max_hp), 0.0, 1.0)
	hp_label.text    = "HP: %d / %d" % [hp, max_hp]
	hp_label.modulate = Color(1.0 - ratio, ratio * 0.85 + 0.1, 0.1, 1)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		gravity_vel -= 20.0 * delta
	else:
		gravity_vel = -2.0
	velocity.y = gravity_vel

	if frozen_timer > 0:
		frozen_timer -= delta
		move_and_slide()
		_update_hp_bar()
		return

	if attack_cd > 0:
		attack_cd -= delta

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

	_anim_timer += delta * (3.0 if state == State.CHASE else 1.5)
	if mesh:
		mesh.position.y = mesh.position.y + sin(_anim_timer) * 0.008
	move_and_slide()
	_update_hp_bar()

func _move_toward_player(delta: float, dist: float) -> void:
	var dir = (player.global_position - global_position)
	dir.y = 0
	dir = dir.normalized()
	velocity.x = dir.x * _get_speed(delta, dist)
	velocity.z = dir.z * _get_speed(delta, dist)
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
	if mesh:
		var mat = mesh.get_surface_override_material(0)
		var t = create_tween()
		t.tween_property(mesh, "scale", Vector3(1.3, 0.1, 1.3), 0.5)
		if mat:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var orig = mat.albedo_color
			t.tween_method(func(a: float): mat.albedo_color = Color(orig.r, orig.g, orig.b, a), 1.0, 0.0, 0.3)
	if name_label: name_label.visible = false
	if hp_label:   hp_label.visible   = false
	emit_signal("died", self)
	if player and player.has_method("on_enemy_killed"):
		player.on_enemy_killed(exp_reward, gold_reward)
	await get_tree().create_timer(0.6).timeout
	queue_free()

func _get_color() -> Color:
	return Color(0.7, 0.2, 0.8, 1)
