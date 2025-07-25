extends Node
class_name Health

@export var health: float = 100.0

func take_damage(amount: float, source = null):
	health -= amount
	if health <= 0:
		die()

func die():
	queue_free() 