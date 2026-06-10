extends Node3D

var item         : Dictionary = {}
var elapsed      : float      = 0.0
var player       : Node3D     = null
const LIFETIME   : float      = 20.0
const PICK_RANGE : float      = 1.8

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	rotation.y += delta * 2.2
	position.y  = position.y + sin(elapsed * 3.0) * delta * 0.12

	elapsed += delta
	if elapsed > LIFETIME:
		queue_free()
		return

	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	if global_position.distance_to(player.global_position) < PICK_RANGE:
		if player.has_method("receive_item_drop"):
			player.receive_item_drop(item)
		queue_free()
