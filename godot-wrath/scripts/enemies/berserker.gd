extends "res://scripts/enemies/enemy_base.gd"

func _on_ready_extra() -> void:
	enemy_name   = "Berserker"
	max_hp       = 40
	hp           = max_hp
	move_speed   = 6.5
	attack_dmg   = 20
	attack_range = 2.0
	exp_reward   = 60
	gold_reward  = randi_range(6, 14)

func _get_color() -> Color:
	return Color(1.0, 0.5, 0.0, 1)

func _get_speed(_delta: float, dist: float) -> float:
	return move_speed * (2.0 if dist > 5.0 else 1.0)
