extends "res://scripts/enemies/enemy_base.gd"

var phase        : int   = 1
var charge_cd    : float = 0.0
var is_charging  : bool  = false
var charge_vel   : Vector3 = Vector3.ZERO
var slam_cd      : float = 0.0

func _on_ready_extra() -> void:
	enemy_name   = "Baldur"
	max_hp       = 800
	hp           = max_hp
	move_speed   = 4.0
	attack_dmg   = 45
	attack_range = 3.0
	detect_range = 30.0
	exp_reward   = 500
	gold_reward  = 100

func _get_color() -> Color:
	return Color(0.86, 0.71, 1.0) if phase == 1 else Color(1.0, 0.31, 0.12)

func _update_timers(delta: float) -> void:
	super(delta)
	if charge_cd > 0: charge_cd -= delta
	if slam_cd   > 0: slam_cd   -= delta

	# Phase 2 at 50% HP
	if hp < max_hp * 0.5 and phase == 1:
		phase      = 2
		move_speed = 6.0
		attack_dmg = 60
		_phase_two_flash()

func _phase_two_flash() -> void:
	if mesh:
		var mat = mesh.get_surface_override_material(0)
		if mat:
			mat.albedo_color = Color(1.0, 0.31, 0.12)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.2, 0.0)
			mat.emission_energy_multiplier = 2.0

func _update_ai(delta: float) -> void:
	if not player:
		return
	var dist = global_position.distance_to(player.global_position)

	# Charge attack
	if dist < 12.0 and charge_cd <= 0 and not is_charging:
		_start_charge()

	if is_charging:
		_do_charge(delta)
		return

	# Normal AI
	if dist > attack_range:
		_chase(delta)
	else:
		_attack_player(delta)

	# Slam attack at close range phase 2
	if phase == 2 and dist < 4.0 and slam_cd <= 0:
		_slam_attack()

func _start_charge() -> void:
	is_charging = true
	charge_cd   = 3.0
	var dir = (player.global_position - global_position).normalized()
	charge_vel  = dir * 18.0

func _do_charge(delta: float) -> void:
	velocity = charge_vel
	charge_vel = charge_vel.lerp(Vector3.ZERO, 4.0 * delta)
	if charge_vel.length() < 0.5:
		is_charging = false

	# Hit player during charge
	var dist = global_position.distance_to(player.global_position)
	if dist < 2.5:
		player.take_damage(attack_dmg)
		is_charging = false

func _slam_attack() -> void:
	slam_cd = 2.5
	# AoE damage around Baldur
	var dist = global_position.distance_to(player.global_position)
	if dist < 5.0:
		player.take_damage(int(attack_dmg * 0.7))
