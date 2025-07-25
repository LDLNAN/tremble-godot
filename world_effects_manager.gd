extends Node
class_name WorldEffectsManager

# Singleton for managing world effects
static var instance: WorldEffectsManager

func _ready():
	# Set up singleton
	instance = self

# Spawn a beam effect in world space
static func spawn_beam_effect(from: Vector3, to: Vector3, effect_scene: PackedScene = null):
	print("WorldEffectsManager.spawn_beam_effect called")
	if not instance:
		print("ERROR: WorldEffectsManager not found!")
		return
	
	if effect_scene:
		var effect = effect_scene.instantiate()
		instance.add_child(effect)
		effect.setup_beam(from, to)
	else:
		# Create simple debug effect
		var effect = BeamEffect.new()
		instance.add_child(effect)
		effect.setup_beam(from, to)

# Spawn any effect in world space
static func spawn_effect(effect_scene: PackedScene, position: Vector3, rotation: Vector3 = Vector3.ZERO):
	if not instance:
		print("ERROR: WorldEffectsManager not found!")
		return
	
	var effect = effect_scene.instantiate()
	instance.add_child(effect)
	effect.global_position = position
	effect.global_rotation = rotation 