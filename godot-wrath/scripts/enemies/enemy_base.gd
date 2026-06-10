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
var _head_node_e : MeshInstance3D = null
var _arm_le      : MeshInstance3D = null
var _arm_re      : MeshInstance3D = null
var _leg_le      : MeshInstance3D = null
var _leg_re      : MeshInstance3D = null
var _walk_t      : float = 0.0

func _ready() -> void:
	hp = max_hp
	add_to_group("enemy")
	call_deferred("_find_player")
	_on_ready_extra()
	call_deferred("_build_limbs")
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

	# Limb animation
	if state == State.CHASE or state == State.ATTACK:
		_walk_t += delta * 6.0
	var sw = sin(_walk_t) * 0.25
	if _leg_le: _leg_le.position.z = sw
	if _leg_re: _leg_re.position.z = -sw
	if _arm_le: _arm_le.position.z = -sw * 0.6
	if _arm_re: _arm_re.position.z = sw * 0.6

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
	if _head_node_e: _head_node_e.visible = false
	if _arm_le: _arm_le.visible = false
	if _arm_re: _arm_re.visible = false
	if _leg_le: _leg_le.visible = false
	if _leg_re: _leg_re.visible = false

	# Drop item
	if player and is_instance_valid(player) and player.has_method("receive_item_drop"):
		var drop_chance = 0.35 + player.luck * 0.05
		if randf() < drop_chance:
			_drop_item()

	emit_signal("died", self)
	if player and player.has_method("on_enemy_killed"):
		player.on_enemy_killed(exp_reward, gold_reward)
	await get_tree().create_timer(0.6).timeout
	queue_free()

func _get_color() -> Color:
	return Color(0.7, 0.2, 0.8, 1)

func _build_limbs() -> void:
	var body_col = _get_color()

	_head_node_e = MeshInstance3D.new()
	var hm = SphereMesh.new()
	hm.radius = 0.25
	hm.height = 0.5
	_head_node_e.mesh = hm
	var hmat = StandardMaterial3D.new()
	hmat.albedo_color = Color(body_col.r * 1.1, body_col.g * 0.9, body_col.b * 0.9, 1)
	_head_node_e.set_surface_override_material(0, hmat)
	_head_node_e.position = Vector3(0, _get_bar_height() * 0.55, 0)
	add_child(_head_node_e)

	_arm_le = _make_enemy_limb(body_col)
	_arm_le.position = Vector3(-0.45, _get_bar_height() * 0.38, 0)
	add_child(_arm_le)

	_arm_re = _make_enemy_limb(body_col)
	_arm_re.position = Vector3(0.45, _get_bar_height() * 0.38, 0)
	add_child(_arm_re)

	_leg_le = _make_enemy_limb(body_col)
	_leg_le.position = Vector3(-0.2, _get_bar_height() * 0.12, 0)
	add_child(_leg_le)

	_leg_re = _make_enemy_limb(body_col)
	_leg_re.position = Vector3(0.2, _get_bar_height() * 0.12, 0)
	add_child(_leg_re)

func _make_enemy_limb(col: Color) -> MeshInstance3D:
	var limb = MeshInstance3D.new()
	var m = CapsuleMesh.new()
	m.radius = 0.1
	m.height = 0.5
	limb.mesh = m
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	limb.set_surface_override_material(0, mat)
	return limb

func _drop_item() -> void:
	var is_weapon = randf() < 0.5
	var tier = min(int(randf() * 6), 5)
	var item : Dictionary
	if is_weapon:
		item = player.WEAPON_DROPS[tier].duplicate()
	else:
		item = player.ARMOR_DROPS[tier].duplicate()

	# Root pickup node (carries the script)
	var pickup_root = Node3D.new()
	pickup_root.set_script(load("res://scripts/world/item_pickup.gd"))

	# Visual mesh
	var mesh_node = MeshInstance3D.new()
	var mat = StandardMaterial3D.new()

	if is_weapon:
		# Sword shape: thin tall box (blade) + wide short box (guard)
		var arr = ArrayMesh.new()
		# blade
		var blade = BoxMesh.new()
		blade.size = Vector3(0.06, 0.55, 0.04)
		var blade_node = MeshInstance3D.new()
		blade_node.mesh = blade
		blade_node.position = Vector3(0, 0.3, 0)
		var blade_mat = StandardMaterial3D.new()
		blade_mat.albedo_color = Color(0.85, 0.85, 0.95, 1)
		blade_mat.metallic = 0.9
		blade_mat.roughness = 0.15
		blade_mat.emission_enabled = true
		blade_mat.emission = Color(1.0, 0.9, 0.3, 1)
		blade_mat.emission_energy_multiplier = 1.5
		blade_node.set_surface_override_material(0, blade_mat)
		pickup_root.add_child(blade_node)
		# guard
		var guard = BoxMesh.new()
		guard.size = Vector3(0.22, 0.05, 0.06)
		var guard_node = MeshInstance3D.new()
		guard_node.mesh = guard
		guard_node.position = Vector3(0, 0.04, 0)
		var guard_mat = StandardMaterial3D.new()
		guard_mat.albedo_color = Color(0.7, 0.5, 0.1, 1)
		guard_mat.metallic = 0.8
		guard_node.set_surface_override_material(0, guard_mat)
		pickup_root.add_child(guard_node)
		# handle
		var handle = BoxMesh.new()
		handle.size = Vector3(0.055, 0.22, 0.055)
		var handle_node = MeshInstance3D.new()
		handle_node.mesh = handle
		handle_node.position = Vector3(0, -0.13, 0)
		var handle_mat = StandardMaterial3D.new()
		handle_mat.albedo_color = Color(0.35, 0.2, 0.05, 1)
		handle_node.set_surface_override_material(0, handle_mat)
		pickup_root.add_child(handle_node)
	else:
		# Armor shape: wide flat torso piece
		var chest = BoxMesh.new()
		chest.size = Vector3(0.5, 0.4, 0.12)
		var chest_node = MeshInstance3D.new()
		chest_node.mesh = chest
		chest_node.position = Vector3(0, 0.2, 0)
		var chest_mat = StandardMaterial3D.new()
		chest_mat.albedo_color = Color(0.3, 0.45, 0.7, 1)
		chest_mat.metallic = 0.7
		chest_mat.roughness = 0.3
		chest_mat.emission_enabled = true
		chest_mat.emission = Color(0.2, 0.5, 1.0, 1)
		chest_mat.emission_energy_multiplier = 1.2
		chest_node.set_surface_override_material(0, chest_mat)
		pickup_root.add_child(chest_node)
		# shoulder pads
		for side in [-1, 1]:
			var shoulder = BoxMesh.new()
			shoulder.size = Vector3(0.14, 0.14, 0.14)
			var sh_node = MeshInstance3D.new()
			sh_node.mesh = shoulder
			sh_node.position = Vector3(side * 0.32, 0.3, 0)
			var sh_mat = StandardMaterial3D.new()
			sh_mat.albedo_color = Color(0.25, 0.4, 0.65, 1)
			sh_mat.metallic = 0.8
			sh_node.set_surface_override_material(0, sh_mat)
			pickup_root.add_child(sh_node)

	# Label
	var label = Label3D.new()
	label.text = item["name"]
	label.font_size = 18
	label.modulate = Color(1.0, 0.9, 0.2, 1) if is_weapon else Color(0.4, 0.8, 1.0, 1)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = Vector3(0, 0.85, 0)
	pickup_root.add_child(label)

	get_parent().add_child(pickup_root)
	pickup_root.global_position = global_position + Vector3(0, 0.3, 0)
	pickup_root.item = item
