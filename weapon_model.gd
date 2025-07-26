extends Node3D
class_name WeaponModel

@export var weapon_name: String = "Default Weapon"
@export var weapon_color: Color = Color.GRAY
@export var muzzle_offset: Vector3 = Vector3(0, 0, -0.5)  # Offset from weapon center to muzzle

var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D
var muzzle_point: Node3D

func _ready():
	create_weapon_mesh()
	create_muzzle_point()

func create_weapon_mesh():
	# Create a simple weapon mesh (you can replace this with actual weapon models)
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.1, 0.1, 0.5)  # Long, thin weapon
	
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	add_child(mesh_instance)
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = weapon_color
	mesh_instance.material_override = material
	
	# Position the weapon in front of the camera
	position = Vector3(0.3, -0.2, -0.5)  # Offset from camera center

func create_muzzle_point():
	# Create a muzzle point for firing effects
	muzzle_point = Node3D.new()
	muzzle_point.name = "MuzzlePoint"
	muzzle_point.position = muzzle_offset
	add_child(muzzle_point)
	
	# Optional: Add a visual marker for the muzzle point (for debugging)
	var marker = CSGBox3D.new()
	marker.size = Vector3(0.02, 0.02, 0.02)
	marker.material = StandardMaterial3D.new()
	marker.material.albedo_color = Color.RED
	marker.material.emission_enabled = true
	marker.material.emission = Color.RED
	marker.material.emission_energy = 2.0
	muzzle_point.add_child(marker)

func get_muzzle_global_position() -> Vector3:
	if muzzle_point:
		return muzzle_point.global_position
	else:
		# Fallback to weapon position + offset
		return global_position + muzzle_offset

func get_muzzle_global_transform() -> Transform3D:
	if muzzle_point:
		return muzzle_point.global_transform
	else:
		# Fallback to weapon transform with offset
		return global_transform.translated(muzzle_offset)

func set_weapon_color(color: Color):
	weapon_color = color
	if mesh_instance and mesh_instance.material_override:
		mesh_instance.material_override.albedo_color = color 
