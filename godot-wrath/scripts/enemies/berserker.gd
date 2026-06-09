extends "res://scripts/enemies/enemy_base.gd"

func _on_ready_extra() -> void:
	enemy_name  = "Berserker"
	max_hp      = 40
	hp          = max_hp
	move_speed  = 6.5
	attack_dmg  = 20
	attack_range = 2.2
	exp_reward  = 60
	gold_reward = randi_range(6, 14)

func _get_color() -> Color:
	return Color(1.0, 0.5, 0.0)

# Berserker charges at player when far
func _chase(delta: float) -> void:
	if not nav_agent:
		return
	var dist = global_position.distance_to(player.global_position)
	var spd  = move_speed * (1.8 if dist > 5.0 else 1.0)
	nav_agent.target_position = player.global_position
	var next = nav_agent.get_next_path_position()
	var dir  = (next - global_position).normalized()
	dir.y    = 0
	velocity.x = dir.x * spd
	velocity.z = dir.z * spd
	var to_player = player.global_position - global_position
	to_player.y = 0
	if to_player.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(to_player.x, to_player.z), 10.0 * delta)
