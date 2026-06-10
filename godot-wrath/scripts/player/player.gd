extends CharacterBody3D

@export var move_speed  : float = 6.0
@export var sprint_speed: float = 10.0
@export var gravity_str : float = 20.0
@export var max_hp      : int   = 150
@export var max_mana    : int   = 80
@export var base_damage : int   = 25
@export var defense     : int   = 5

var hp          : int
var mana        : float
var level       : int   = 1
var exp         : int   = 0
var gold        : int   = 0
var kills       : int   = 0
var potions     : int   = 3
var stat_points : int   = 0

var owned_abilities : Array = ["axe", "blizzard"]
var active_slots    : Array = ["axe", "blizzard", "", "", "", ""]

var combo_count  : int   = 0
var combo_timer  : float = 0.0
var attack_cd    : float = 0.0
var is_attacking : bool  = false
var is_dodging   : bool  = false
var dodge_timer  : float = 0.0
var dodge_dir    : Vector3 = Vector3.ZERO
var invincible   : float = 0.0
var rage_active  : float = 0.0
var rage_cd      : float = 0.0
var axe_cd       : float = 0.0
var blizzard_cd  : float = 0.0
var lightning_cd : float = 0.0
var shield_cd    : float = 0.0
var shield_active: float = 0.0
var slam_cd      : float = 0.0
var meteor_cd    : float = 0.0
var heal_cd      : float = 0.0
var howl_cd      : float = 0.0
var mana_regen   : float = 3.0

# Camera stored as world-space angles so player body rotation doesn't affect it
var cam_yaw   : float = 0.0
var cam_pitch : float = -0.35

var locked_target : Node3D = null
var lock_range    : float  = 14.0
var melee_range   : float  = 2.5

var menu_open   : bool  = false

var _tween      : Tween = null
var _sword_node : MeshInstance3D = null
var _body_node  : MeshInstance3D = null
var _shield_mesh: MeshInstance3D = null
var _bob_timer  : float = 0.0
var _is_moving  : bool  = false
var _shield_vfx : MeshInstance3D = null

signal health_changed(current, maximum)
signal mana_changed(current, maximum)
signal level_up(new_level)
signal died
signal enemy_killed

@onready var camera_arm : SpringArm3D    = $CameraArm
@onready var cam3d      : Camera3D       = $CameraArm/Camera3D
@onready var mesh       : MeshInstance3D = $Body

const AXE_SCENE = preload("res://scenes/player/axe_projectile.tscn")

func _ready() -> void:
	hp   = max_hp
	mana = max_mana
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	_sword_node  = get_node_or_null("Sword")
	_body_node   = get_node_or_null("Body")
	_shield_mesh = get_node_or_null("Shield")

func _animate(delta: float) -> void:
	var moving = velocity.length() > 1.0 and is_on_floor()
	if moving:
		_bob_timer += delta * 8.0
		if _body_node:
			_body_node.position.y = 0.75 + sin(_bob_timer) * 0.04
		if _sword_node:
			_sword_node.position.y = 0.9 + sin(_bob_timer * 0.5) * 0.03
	elif _body_node:
		_body_node.position.y = lerp(_body_node.position.y, 0.75, 8.0 * delta)

	# Rage glow on body
	if _body_node and rage_active > 0:
		var mat = _body_node.get_surface_override_material(0)
		if mat:
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.3, 0.0, 1)
			mat.emission_energy_multiplier = 1.5
	elif _body_node:
		var mat = _body_node.get_surface_override_material(0)
		if mat and mat.emission_enabled:
			mat.emission_energy_multiplier = 0.0
			mat.emission_enabled = false

	# Shield bubble pulse
	if _shield_vfx and is_instance_valid(_shield_vfx):
		_shield_vfx.scale = Vector3.ONE * (1.0 + sin(_bob_timer * 3.0) * 0.05)

func _input(event: InputEvent) -> void:
	if menu_open:
		return
	if event is InputEventMouseMotion and not locked_target:
		cam_yaw   -= event.relative.x * 0.003
		cam_pitch  = clamp(cam_pitch - event.relative.y * 0.003,
						   deg_to_rad(-70), deg_to_rad(15))

	if event.is_action_pressed("lock_target"):
		_toggle_lock()

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_apply_camera(delta)
	_handle_movement(delta)
	_handle_timers(delta)
	_handle_combat()
	_handle_spells()
	_regen_mana(delta)
	_animate(delta)
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity_str * delta
	else:
		if velocity.y < 0:
			velocity.y = -2.0

func _apply_camera(delta: float) -> void:
	if locked_target and is_instance_valid(locked_target):
		var to = locked_target.global_position - global_position
		to.y = 0
		if to.length() > 0.1:
			cam_yaw = lerp_angle(cam_yaw, atan2(to.x, to.z) + PI, 6.0 * delta)
	camera_arm.rotation.y = cam_yaw - rotation.y
	camera_arm.rotation.x = cam_pitch

func _handle_movement(delta: float) -> void:
	if is_dodging:
		velocity.x = dodge_dir.x * sprint_speed * 1.5
		velocity.z = dodge_dir.z * sprint_speed * 1.5
		return
	if is_attacking:
		velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 10.0 * delta)
		return

	var ix = Input.get_axis("move_left", "move_right")
	var iz = Input.get_axis("move_forward", "move_backward")
	var input_dir = Vector2(ix, iz)

	var cy = cos(cam_yaw)
	var sy = sin(cam_yaw)
	var move_dir = Vector3(
		sy * input_dir.y + cy * input_dir.x,
		0,
		cy * input_dir.y - sy * input_dir.x
	).normalized()

	var spd = sprint_speed if rage_active > 0 else move_speed

	if move_dir.length() > 0.1:
		velocity.x = move_dir.x * spd
		velocity.z = move_dir.z * spd
		var face_dir = move_dir
		if locked_target and is_instance_valid(locked_target):
			var to = locked_target.global_position - global_position
			to.y = 0
			if to.length() > 0.1:
				face_dir = to.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(face_dir.x, face_dir.z), 14.0 * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, 14.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 14.0 * delta)

	if Input.is_action_just_pressed("dodge") and not is_dodging:
		var dir = move_dir if move_dir.length() > 0.1 else -Vector3(sin(rotation.y), 0, cos(rotation.y))
		_start_dodge(dir)

func _start_dodge(dir: Vector3) -> void:
	is_dodging  = true
	dodge_timer = 0.32
	invincible  = 0.38
	dodge_dir   = dir
	if _body_node and (_tween == null or not _tween.is_running()):
		var lean = create_tween()
		lean.tween_property(_body_node, "rotation_degrees", Vector3(25, 0, 0), 0.15)
		lean.tween_property(_body_node, "rotation_degrees", Vector3(0, 0, 0), 0.2)

func _handle_combat() -> void:
	if attack_cd > 0 or is_dodging:
		return
	var light = Input.is_action_just_pressed("attack_light") or Input.is_key_label_pressed(KEY_Z)
	var heavy = Input.is_action_just_pressed("attack_heavy") or Input.is_key_label_pressed(KEY_X)
	if light:
		_melee_attack(false)
	elif heavy:
		_melee_attack(true)
	elif Input.is_action_just_pressed("use_ability"):
		_cast_slot(0)
	elif Input.is_action_just_pressed("use_potion"):
		use_potion()

func _handle_spells() -> void:
	if Input.is_action_just_pressed("blizzard"):
		_cast_slot(1)
	if Input.is_action_just_pressed("spartan_rage"):
		_cast_slot(2)
	if Input.is_key_label_pressed(KEY_1):
		_cast_slot(3)
	if Input.is_key_label_pressed(KEY_2):
		_cast_slot(4)
	if Input.is_key_label_pressed(KEY_3):
		_cast_slot(5)

func _cast_slot(idx: int) -> void:
	if idx >= active_slots.size():
		return
	match active_slots[idx]:
		"axe":       _throw_axe()
		"blizzard":  _blizzard()
		"rage":      _spartan_rage()
		"lightning": _lightning_strike()
		"shield":    _divine_shield()
		"slam":      _ground_slam()
		"meteor":    _meteor()
		"heal":      _heal_spell()
		"howl":      _berserker_howl()

func get_ability_cd(key: String) -> float:
	match key:
		"axe":       return axe_cd
		"blizzard":  return blizzard_cd
		"rage":      return rage_cd
		"lightning": return lightning_cd
		"shield":    return shield_cd
		"slam":      return slam_cd
		"meteor":    return meteor_cd
		"heal":      return heal_cd
		"howl":      return howl_cd
	return 0.0

func _melee_attack(heavy: bool) -> void:
	if combo_timer > 0:
		combo_count = (combo_count + 1) % 3
	else:
		combo_count = 0
	combo_timer  = 0.55
	attack_cd    = 0.35 if not heavy else 0.6
	is_attacking = true
	_swing_sword()

	var dmg_mult = 2.0 if heavy else 1.0
	if combo_count == 2:
		dmg_mult *= 1.5
	if rage_active > 0:
		dmg_mult *= 1.5
	var dmg = int(base_damage * dmg_mult)

	var forward = Vector3(sin(rotation.y), 0, cos(rotation.y))
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e):
			continue
		var diff = e.global_position - global_position
		diff.y = 0
		var dist = diff.length()
		if dist > melee_range:
			continue
		if dist > 0.5 and forward.dot(diff.normalized()) < -0.3:
			continue
		var kb = diff.normalized() * 7.0
		e.take_damage(dmg, kb)

func _swing_sword() -> void:
	if not _sword_node:
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_sword_node, "position", Vector3(0.45, 1.2, -0.3), 0.12)
	_tween.tween_property(_sword_node, "rotation_degrees", Vector3(-60, 0, 0), 0.12)
	_tween.tween_property(_sword_node, "position", Vector3(0.45, 0.9, 0.1), 0.15)
	_tween.tween_property(_sword_node, "rotation_degrees", Vector3(0, 0, 0), 0.15)

func _throw_axe() -> void:
	if axe_cd > 0 or mana < 15:
		return
	axe_cd = 1.5
	mana  -= 15
	emit_signal("mana_changed", int(mana), max_mana)
	var axe = AXE_SCENE.instantiate()
	get_parent().add_child(axe)
	axe.global_position = global_position + Vector3(0, 1.2, 0)
	var fwd = Vector3(sin(rotation.y), 0, cos(rotation.y))
	if locked_target and is_instance_valid(locked_target):
		fwd = (locked_target.global_position - global_position).normalized()
		fwd.y = 0
		fwd = fwd.normalized()
	axe.launch(fwd, int(base_damage * 2.5))

func _blizzard() -> void:
	if blizzard_cd > 0 or mana < 25:
		return
	blizzard_cd = 5.0
	mana -= 25
	emit_signal("mana_changed", int(mana), max_mana)
	_spawn_vfx_sphere(global_position + Vector3(0, 0.5, 0), 9.0, Color(0.4, 0.8, 1.0, 1), 0.6)
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e):
			continue
		if global_position.distance_to(e.global_position) < 9.0:
			e.take_damage(int(base_damage * 1.8), Vector3.ZERO)
			if e.has_method("freeze"):
				e.freeze(1.8)

func _spartan_rage() -> void:
	if rage_cd > 0 or mana < 30:
		return
	rage_cd     = 12.0
	rage_active = 6.0
	mana       -= 30
	emit_signal("mana_changed", int(mana), max_mana)
	_spawn_vfx_sphere(global_position + Vector3(0, 1.0, 0), 2.5, Color(1.0, 0.4, 0.0, 1), 0.4)

# --- New spells ---

func _lightning_strike() -> void:
	if lightning_cd > 0 or mana < 20:
		return
	lightning_cd = 4.0
	mana -= 20
	emit_signal("mana_changed", int(mana), max_mana)

	# Hit closest enemy in front
	var best_enemy : Node3D = null
	var best_dist  : float  = 18.0
	var forward = Vector3(sin(rotation.y), 0, cos(rotation.y))
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e):
			continue
		var diff = e.global_position - global_position
		diff.y = 0
		var d = diff.length()
		if d < best_dist and forward.dot(diff.normalized()) > 0.4:
			best_dist  = d
			best_enemy = e

	if best_enemy:
		best_enemy.take_damage(int(base_damage * 3.0), Vector3.ZERO)
		_spawn_lightning_vfx(best_enemy.global_position)
	else:
		_spawn_lightning_vfx(global_position + forward * 5.0)

func _spawn_lightning_vfx(pos: Vector3) -> void:
	# Bright yellow-white flash cylinder
	var vfx = MeshInstance3D.new()
	var m   = CylinderMesh.new()
	m.top_radius    = 0.08
	m.bottom_radius = 0.08
	m.height        = 6.0
	vfx.mesh        = m
	var mat = StandardMaterial3D.new()
	mat.albedo_color            = Color(1.0, 1.0, 0.3, 1)
	mat.emission_enabled        = true
	mat.emission                = Color(1.0, 1.0, 0.2, 1)
	mat.emission_energy_multiplier = 6.0
	vfx.set_surface_override_material(0, mat)
	get_parent().add_child(vfx)
	vfx.global_position = pos + Vector3(0, 3.0, 0)

	var t = vfx.create_tween()
	t.tween_property(vfx, "scale", Vector3(3.0, 1.0, 3.0), 0.08)
	t.tween_property(vfx, "scale", Vector3(0.1, 1.2, 0.1), 0.12)
	t.tween_property(mat, "albedo_color", Color(1, 1, 1, 0), 0.2)
	await get_tree().create_timer(0.4).timeout
	if is_instance_valid(vfx):
		vfx.queue_free()

func _divine_shield() -> void:
	if shield_cd > 0 or mana < 20:
		return
	shield_cd    = 8.0
	shield_active = 4.0
	mana -= 20
	emit_signal("mana_changed", int(mana), max_mana)
	invincible = 4.0

	# Spawn shield bubble
	if _shield_vfx and is_instance_valid(_shield_vfx):
		_shield_vfx.queue_free()
	_shield_vfx = MeshInstance3D.new()
	var m = SphereMesh.new()
	m.radius = 1.2
	m.height = 2.4
	_shield_vfx.mesh = m
	var mat = StandardMaterial3D.new()
	mat.albedo_color   = Color(0.3, 0.6, 1.0, 0.25)
	mat.emission_enabled = true
	mat.emission       = Color(0.2, 0.5, 1.0, 1)
	mat.emission_energy_multiplier = 1.5
	mat.transparency   = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shield_vfx.set_surface_override_material(0, mat)
	_shield_vfx.position = Vector3(0, 1.0, 0)
	add_child(_shield_vfx)
	_despawn_shield_later()

func _despawn_shield_later() -> void:
	await get_tree().create_timer(4.0).timeout
	if _shield_vfx and is_instance_valid(_shield_vfx):
		var t = create_tween()
		t.tween_property(_shield_vfx, "scale", Vector3.ZERO, 0.3)
		await get_tree().create_timer(0.3).timeout
		if _shield_vfx and is_instance_valid(_shield_vfx):
			_shield_vfx.queue_free()

func _ground_slam() -> void:
	if slam_cd > 0 or mana < 30:
		return
	slam_cd = 6.0
	mana   -= 30
	emit_signal("mana_changed", int(mana), max_mana)

	# Shockwave ring visual
	var ring = MeshInstance3D.new()
	var m = TorusMesh.new()
	m.inner_radius = 0.3
	m.outer_radius = 0.5
	ring.mesh = m
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.6, 0.1, 1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.0, 1)
	mat.emission_energy_multiplier = 4.0
	ring.set_surface_override_material(0, mat)
	get_parent().add_child(ring)
	ring.global_position = global_position + Vector3(0, 0.1, 0)

	var t = ring.create_tween()
	t.tween_property(ring, "scale", Vector3(10.0, 0.5, 10.0), 0.4)
	t.tween_property(mat, "albedo_color", Color(1.0, 0.5, 0.0, 0), 0.3)

	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e):
			continue
		var diff = e.global_position - global_position
		var d    = diff.length()
		if d < 6.0:
			var kb = diff.normalized() * 12.0
			e.take_damage(int(base_damage * 2.2), kb)

	await get_tree().create_timer(0.7).timeout
	if is_instance_valid(ring):
		ring.queue_free()

func _meteor() -> void:
	if meteor_cd > 0 or mana < 50:
		return
	meteor_cd = 20.0
	mana -= 50
	emit_signal("mana_changed", int(mana), max_mana)
	var target_pos = global_position
	if locked_target and is_instance_valid(locked_target):
		target_pos = locked_target.global_position
	else:
		target_pos = global_position + Vector3(sin(rotation.y), 0, cos(rotation.y)) * 8.0
	_spawn_meteor_vfx(target_pos)
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e):
			continue
		if target_pos.distance_to(e.global_position) < 7.0:
			var kb = (e.global_position - target_pos).normalized() * 15.0
			e.take_damage(int(base_damage * 4.5), kb)

func _spawn_meteor_vfx(pos: Vector3) -> void:
	# Falling rock effect then explosion ring
	var core = MeshInstance3D.new()
	core.mesh = SphereMesh.new()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.4, 0.0, 1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.2, 0.0, 1)
	mat.emission_energy_multiplier = 8.0
	core.set_surface_override_material(0, mat)
	get_parent().add_child(core)
	core.global_position = pos + Vector3(0, 12.0, 0)
	core.scale = Vector3(2.0, 2.0, 2.0)
	var t = core.create_tween()
	t.tween_property(core, "global_position", pos + Vector3(0, 0.5, 0), 0.4)
	t.tween_property(core, "scale", Vector3(0.3, 0.3, 0.3), 0.1)
	_spawn_vfx_sphere(pos + Vector3(0, 0.5, 0), 7.0, Color(1.0, 0.5, 0.0, 1), 0.5)
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(core):
		core.queue_free()

func _heal_spell() -> void:
	if heal_cd > 0 or mana < 25:
		return
	heal_cd = 15.0
	mana -= 25
	emit_signal("mana_changed", int(mana), max_mana)
	hp = min(max_hp, hp + 80)
	emit_signal("health_changed", hp, max_hp)
	_spawn_vfx_sphere(global_position + Vector3(0, 1.0, 0), 1.5, Color(0.3, 1.0, 0.5, 1), 0.6)

func _berserker_howl() -> void:
	if howl_cd > 0 or mana < 60:
		return
	howl_cd = 25.0
	mana -= 60
	emit_signal("mana_changed", int(mana), max_mana)
	_spawn_vfx_sphere(global_position + Vector3(0, 1.0, 0), 8.0, Color(0.8, 0.0, 1.0, 1), 0.8)
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e):
			continue
		var dist = global_position.distance_to(e.global_position)
		if dist < 8.0:
			e.take_damage(int(base_damage * 2.0), Vector3.ZERO)
			if e.has_method("freeze"):
				e.freeze(2.5)

func _spawn_vfx_sphere(pos: Vector3, radius: float, col: Color, duration: float) -> void:
	var vfx = MeshInstance3D.new()
	var m = SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	vfx.mesh = m
	var mat = StandardMaterial3D.new()
	mat.albedo_color   = Color(col.r, col.g, col.b, 0.3)
	mat.emission_enabled = true
	mat.emission       = col
	mat.emission_energy_multiplier = 2.0
	mat.transparency   = BaseMaterial3D.TRANSPARENCY_ALPHA
	vfx.set_surface_override_material(0, mat)
	get_parent().add_child(vfx)
	vfx.global_position = pos
	var t = vfx.create_tween()
	t.tween_property(vfx, "scale", Vector3(1.0, 1.0, 1.0), 0.05)
	t.tween_property(mat, "albedo_color", Color(col.r, col.g, col.b, 0), duration)
	await get_tree().create_timer(duration + 0.1).timeout
	if is_instance_valid(vfx):
		vfx.queue_free()

func _handle_timers(delta: float) -> void:
	if attack_cd   > 0: attack_cd   -= delta
	if combo_timer > 0: combo_timer -= delta
	else:               combo_count  = 0
	if invincible  > 0: invincible  -= delta
	if rage_active > 0: rage_active -= delta
	if rage_cd     > 0: rage_cd     -= delta
	if axe_cd      > 0: axe_cd      -= delta
	if blizzard_cd > 0: blizzard_cd -= delta
	if lightning_cd > 0: lightning_cd -= delta
	if shield_cd   > 0: shield_cd   -= delta
	if shield_active > 0:
		shield_active -= delta
	if slam_cd     > 0: slam_cd     -= delta
	if meteor_cd   > 0: meteor_cd   -= delta
	if heal_cd     > 0: heal_cd     -= delta
	if howl_cd     > 0: howl_cd     -= delta
	if dodge_timer > 0:
		dodge_timer -= delta
		if dodge_timer <= 0:
			is_dodging = false
	if attack_cd <= 0:
		is_attacking = false

func _regen_mana(delta: float) -> void:
	if mana < max_mana:
		mana = min(max_mana, mana + mana_regen * delta)
		emit_signal("mana_changed", int(mana), max_mana)

func _toggle_lock() -> void:
	if locked_target:
		locked_target = null
		return
	var best  : Node3D = null
	var bdist : float  = lock_range
	for e in get_tree().get_nodes_in_group("enemy"):
		var d = global_position.distance_to(e.global_position)
		if d < bdist:
			bdist = d
			best  = e
	locked_target = best

func take_damage(amount: int) -> void:
	if invincible > 0:
		return
	hp -= max(1, amount - defense)
	invincible = 0.5
	emit_signal("health_changed", hp, max_hp)
	if hp <= 0:
		emit_signal("died")

func use_potion() -> void:
	if potions <= 0 or hp >= max_hp:
		return
	potions -= 1
	hp = min(max_hp, hp + 60)
	emit_signal("health_changed", hp, max_hp)

func gain_exp(amount: int) -> void:
	exp += amount
	while exp >= _exp_needed():
		exp -= _exp_needed()
		_level_up()

func _exp_needed() -> int:
	return level * 120 + level * level * 20

func _level_up() -> void:
	level       += 1
	max_hp      += 20
	hp           = max_hp
	max_mana    += 10
	base_damage += 5
	defense     += 1
	stat_points += 3
	emit_signal("level_up", level)
	emit_signal("health_changed", hp, max_hp)

func on_enemy_killed(exp_r: int, gold_r: int, mana_r: float = 8.0) -> void:
	kills += 1
	gold  += gold_r
	gain_exp(exp_r)
	mana = min(max_mana, mana + mana_r)
	emit_signal("mana_changed", int(mana), max_mana)
	emit_signal("enemy_killed")

func spartan_rage() -> bool:
	_spartan_rage()
	return rage_active > 0

func buy_ability(key: String) -> bool:
	if key in owned_abilities:
		return false
	return true

func add_owned_ability(key: String) -> void:
	if not key in owned_abilities:
		owned_abilities.append(key)

func buy_health_potion() -> void:
	potions += 1

func buy_strength_potion() -> void:
	base_damage += 8
