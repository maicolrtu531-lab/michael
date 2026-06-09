extends Node3D

var velocity  : Vector3 = Vector3.ZERO
var damage    : int     = 50
var speed     : float   = 20.0
var lifetime  : float   = 2.0
var hit_set   : Array   = []

@onready var mesh : MeshInstance3D = $Mesh

func launch(direction: Vector3, dmg: int) -> void:
	velocity = direction.normalized() * speed
	damage   = dmg

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return

	global_position += velocity * delta
	rotate_object_local(Vector3.RIGHT, delta * 10.0)

	# Hit detection
	for body in $Area3D.get_overlapping_bodies():
		if body.is_in_group("enemy") and body not in hit_set:
			hit_set.append(body)
			var kb = velocity.normalized() * 5.0
			body.take_damage(damage, kb)
			queue_free()
			return
