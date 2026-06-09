extends "res://scripts/enemies/enemy_base.gd"

func _on_ready_extra() -> void:
	enemy_name  = "Draugr"
	max_hp      = 60
	hp          = max_hp
	move_speed  = 3.5
	attack_dmg  = 12
	exp_reward  = 40
	gold_reward = randi_range(3, 10)

func _get_color() -> Color:
	return Color(0.55, 0.23, 0.78)
