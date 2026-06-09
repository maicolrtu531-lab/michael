extends "res://scripts/enemies/enemy_base.gd"

var phase       : int   = 1
var charge_cd   : float = 0.0
var is_charging : bool  = false
var charge_vel  : Vector3 = Vector3.ZERO
var slam_cd     : float = 0.0

func _on_ready_extra() -> void:
	enemy_name   = "Baldur"
	max_hp       = 800
	hp           = max_hp
	move_speed   = 4.0
	attack_dmg   = 45
	attack_range = 3.5
	detect_range = 30.0
	exp_reward   = 500
	gold_reward  = 100

func _get_color() -> Color:
	return Color(0.86, 0.71, 1.0, 1) if phase == 1 else Color(1.0, 0.31, 0.12, 1)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if charge_cd > 0: charge_cd -= delta
	if slam_cd   > 0: slam_cd   -= delta
	if hp < max_hp * 0.5 and phase == 1:
		phase      = 2
		move_speed = 6.0
		attack_dmg = 60
		_phase_flash()
	super(delta)

func _phase_flash() -> void:
	if mesh:
		var mat = mesh.get_surface_override_material(0)
		if mat:
			mat.albedo_color = Color(1.0, 0.31, 0.12, 1)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.2, 0.0, 1)
			mat.emission_energy_multiplier = 2.5

func _move_toward_player(delta: float, dist: float) -> void:
	if dist < 12.0 and charge_cd <= 0 and not is_charging:
		is_charging = true
		charge_cd   = 4.0
		var dir = (player.global_position - global_position).normalized()
		charge_vel  = dir * 20.0
	if is_charging:
		velocity.x = charge_vel.x
		velocity.z = charge_vel.z
		charge_vel = charge_vel.lerp(Vector3.ZERO, 5.0 * delta)
		if charge_vel.length() < 0.5:
			is_charging = false
		if global_position.distance_to(player.global_position) < 2.5:
			if player.has_method("take_damage"):
				player.take_damage(attack_dmg)
			is_charging = false
	else:
		super(delta, dist)
	if phase == 2 and dist < 4.0 and slam_cd <= 0:
		slam_cd = 2.5
		if player.has_method("take_damage"):
			player.take_damage(int(attack_dmg * 0.6))
