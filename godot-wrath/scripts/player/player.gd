extends CharacterBody3D

# ── Stats ──────────────────────────────────────────────────────────────────
@export var move_speed    : float = 6.0
@export var sprint_speed  : float = 10.0
@export var jump_force    : float = 8.0
@export var gravity       : float = 20.0
@export var max_hp        : int   = 150
@export var max_mana      : int   = 80
@export var base_damage   : int   = 25
@export var defense       : int   = 5

var hp      : int
var mana    : float
var level   : int = 1
var exp     : int = 0
var gold    : int = 0
var kills   : int = 0
var potions : int = 3
var stat_points : int = 0

# ── Combat ─────────────────────────────────────────────────────────────────
var combo_count    : int   = 0
var combo_timer    : float = 0.0
var attack_cd      : float = 0.0
var is_attacking   : bool  = false
var is_dodging     : bool  = false
var dodge_timer    : float = 0.0
var dodge_dir      : Vector3 = Vector3.ZERO
var invincible     : float = 0.0
var rage_active    : float = 0.0
var rage_cd        : float = 0.0
var axe_cd         : float = 0.0
var mana_regen     : float = 2.0  # per second

# ── Lock-on ────────────────────────────────────────────────────────────────
var locked_target  : Node3D = null
var lock_range     : float  = 12.0

# ── Signals ────────────────────────────────────────────────────────────────
signal health_changed(current, maximum)
signal mana_changed(current, maximum)
signal level_up(new_level)
signal died
signal enemy_killed

# ── Nodes ──────────────────────────────────────────────────────────────────
@onready var camera_arm   : SpringArm3D  = $CameraArm
@onready var camera       : Camera3D     = $CameraArm/Camera3D
@onready var mesh         : MeshInstance3D = $Body
@onready var hit_area     : Area3D       = $HitArea
@onready var anim         : AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

const AXE_SCENE = preload("res://scenes/player/axe_projectile.tscn")

func _ready() -> void:
	hp   = max_hp
	mana = max_mana
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not locked_target:
		camera_arm.rotation.y -= event.relative.x * 0.003
		camera_arm.rotation.x -= event.relative.y * 0.003
		camera_arm.rotation.x  = clamp(camera_arm.rotation.x, deg_to_rad(-60), deg_to_rad(10))

	if event.is_action_pressed("lock_target"):
		_toggle_lock()

func _physics_process(delta: float) -> void:
	_handle_gravity(delta)
	_handle_movement(delta)
	_handle_combat(delta)
	_handle_timers(delta)
	_handle_lock_on(delta)
	_regen_mana(delta)
	move_and_slide()

# ── Gravity ────────────────────────────────────────────────────────────────
func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

# ── Movement ───────────────────────────────────────────────────────────────
func _handle_movement(delta: float) -> void:
	if is_attacking or is_dodging:
		if is_dodging:
			velocity.x = dodge_dir.x * sprint_speed * 1.4
			velocity.z = dodge_dir.z * sprint_speed * 1.4
		return

	var input_dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_forward", "move_backward")
	)

	var cam_basis = camera_arm.global_transform.basis
	var move_dir  = (cam_basis.z * input_dir.y + cam_basis.x * input_dir.x).normalized()
	move_dir.y    = 0

	var spd = sprint_speed if rage_active > 0 else move_speed
	if move_dir.length() > 0.1:
		velocity.x = move_dir.x * spd
		velocity.z = move_dir.z * spd
		# Face movement or locked target
		var target_rot : Vector3
		if locked_target:
			var to_target = locked_target.global_position - global_position
			to_target.y = 0
			if to_target.length() > 0.1:
				target_rot = to_target.normalized()
		else:
			target_rot = move_dir
		if target_rot.length() > 0.1:
			var angle = atan2(target_rot.x, target_rot.z)
			rotation.y = lerp_angle(rotation.y, angle, 12.0 * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, 12.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 12.0 * delta)

	# Dodge
	if Input.is_action_just_pressed("dodge") and not is_dodging and attack_cd <= 0:
		_start_dodge(move_dir)

# ── Dodge ──────────────────────────────────────────────────────────────────
func _start_dodge(dir: Vector3) -> void:
	is_dodging  = true
	dodge_timer = 0.35
	invincible  = 0.4
	dodge_dir   = dir if dir.length() > 0.1 else -global_transform.basis.z

# ── Combat ─────────────────────────────────────────────────────────────────
func _handle_combat(_delta: float) -> void:
	if attack_cd > 0 or is_dodging:
		return

	if Input.is_action_just_pressed("attack_light"):
		_melee_attack(false)
	elif Input.is_action_just_pressed("attack_heavy"):
		_melee_attack(true)
	elif Input.is_action_just_pressed("use_ability"):
		_throw_axe()
	elif Input.is_action_just_pressed("use_potion"):
		use_potion()

func _melee_attack(heavy: bool) -> void:
	if combo_timer > 0:
		combo_count = (combo_count + 1) % 3
	else:
		combo_count = 0
	combo_timer  = 0.5
	attack_cd    = 0.35 if not heavy else 0.6
	is_attacking = true

	var dmg_mult = 1.0
	if heavy:          dmg_mult = 2.0
	if combo_count == 2: dmg_mult *= 1.5
	if rage_active > 0:  dmg_mult *= 1.5

	var dmg = int(base_damage * dmg_mult)

	# Hit enemies in front
	for body in hit_area.get_overlapping_bodies():
		if body.is_in_group("enemy"):
			var kb = (body.global_position - global_position).normalized() * 6.0
			body.take_damage(dmg, kb)
			# Spawn floating damage text
			_spawn_damage_text(body.global_position, dmg, Color.RED)

func _throw_axe() -> void:
	if axe_cd > 0 or mana < 15:
		return
	axe_cd  = 1.5
	mana   -= 15
	emit_signal("mana_changed", int(mana), max_mana)

	var axe = AXE_SCENE.instantiate()
	get_parent().add_child(axe)
	axe.global_position = global_position + Vector3(0, 1, 0)
	var fwd = -global_transform.basis.z
	if locked_target:
		fwd = (locked_target.global_position - global_position).normalized()
	axe.launch(fwd, int(base_damage * 2.5))

# ── Timers ─────────────────────────────────────────────────────────────────
func _handle_timers(delta: float) -> void:
	if attack_cd    > 0: attack_cd    -= delta
	if combo_timer  > 0:
		combo_timer -= delta
	else:
		combo_count = 0
	if invincible   > 0: invincible   -= delta
	if rage_active  > 0: rage_active  -= delta
	if rage_cd      > 0: rage_cd      -= delta
	if axe_cd       > 0: axe_cd       -= delta
	if dodge_timer  > 0:
		dodge_timer -= delta
		if dodge_timer <= 0:
			is_dodging = false
	if attack_cd    <= 0: is_attacking = false

# ── Mana regen ─────────────────────────────────────────────────────────────
func _regen_mana(delta: float) -> void:
	if mana < max_mana:
		mana = min(max_mana, mana + mana_regen * delta)
		emit_signal("mana_changed", int(mana), max_mana)

# ── Lock-on ────────────────────────────────────────────────────────────────
func _toggle_lock() -> void:
	if locked_target:
		locked_target = null
		return
	var enemies = get_tree().get_nodes_in_group("enemy")
	var closest : Node3D = null
	var closest_dist : float = lock_range
	for e in enemies:
		var d = global_position.distance_to(e.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = e
	locked_target = closest

func _handle_lock_on(delta: float) -> void:
	if not locked_target:
		return
	if not is_instance_valid(locked_target) or locked_target.global_position.distance_to(global_position) > lock_range + 3:
		locked_target = null
		return
	# Rotate camera toward target
	var to = locked_target.global_position - camera_arm.global_position
	var angle_y = atan2(to.x, to.z)
	camera_arm.rotation.y = lerp_angle(camera_arm.rotation.y, angle_y, 5.0 * delta)

# ── Damage / Death ─────────────────────────────────────────────────────────
func take_damage(amount: int) -> void:
	if invincible > 0:
		return
	var reduced = max(1, amount - defense)
	hp -= reduced
	invincible = 0.5
	emit_signal("health_changed", hp, max_hp)
	if hp <= 0:
		_die()

func _die() -> void:
	emit_signal("died")
	# Respawn or game over handled by GameManager

# ── Potion ────────────────────────────────────────────────────────────────
func use_potion() -> void:
	if potions <= 0 or hp >= max_hp:
		return
	potions -= 1
	hp = min(max_hp, hp + 60)
	emit_signal("health_changed", hp, max_hp)

# ── EXP / Level ───────────────────────────────────────────────────────────
func gain_exp(amount: int) -> void:
	exp += amount
	while exp >= exp_needed():
		exp -= exp_needed()
		_level_up()

func exp_needed() -> int:
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

# ── Kill reward ────────────────────────────────────────────────────────────
func on_enemy_killed(exp_reward: int, gold_reward: int, mana_reward: float = 8.0) -> void:
	kills += 1
	gold  += gold_reward
	gain_exp(exp_reward)
	mana = min(max_mana, mana + mana_reward)
	emit_signal("mana_changed", int(mana), max_mana)
	emit_signal("enemy_killed")

# ── Spartan Rage ──────────────────────────────────────────────────────────
func spartan_rage() -> bool:
	if rage_cd > 0 or mana < 30:
		return false
	rage_cd    = 10.0
	rage_active = 5.0
	mana       -= 30
	emit_signal("mana_changed", int(mana), max_mana)
	return true

func _spawn_damage_text(_pos: Vector3, _dmg: int, _color: Color) -> void:
	pass  # Implementado en GameManager via señal
