extends Node3D
class_name BeamEffect

@export var line_width: float = 0.3
@export var beam_color: Color = Color.CYAN
@export var duration: float = 0.2

var line_renderer: Node3D
var is_persistent: bool = false

func _ready():
	# Create line renderer for the beam effect
	create_line_renderer()

func _physics_process(_delta):
	# Force update the line renderer in physics process for better sync
	if line_renderer and is_persistent:
		# This ensures the line renderer updates in sync with physics
		line_renderer.force_update_transform()

func create_line_renderer():
	# Create the LineRenderer node using the plugin script
	var LineRendererScript = preload("res://addons/LineRenderer/line_renderer.gd")
	line_renderer = LineRendererScript.new()
	add_child(line_renderer)
	
	# Set up line renderer properties
	line_renderer.start_thickness = line_width
	line_renderer.end_thickness = line_width
	line_renderer.use_global_coords = true
	line_renderer.draw_caps = true
	line_renderer.draw_crners = false  # No corners for simple beam
	
	# Set material properties
	if not line_renderer.material_override:
		var material = StandardMaterial3D.new()
		material.albedo_color = beam_color
		material.emission_enabled = true
		material.emission = beam_color
		material.emission_energy = 3.0
		line_renderer.material_override = material

func setup_beam(from: Vector3, to: Vector3):
	print("Setting up beam effect from ", from, " to ", to)
	
	# Check if this is a persistent beam (duration < 0)
	is_persistent = duration < 0
	
	# Set the points array directly (this is how the LineRenderer3D works)
	var points_array: Array[Vector3] = [from, to]
	line_renderer.points = points_array
	
	print("Beam points set: ", from, " -> ", to)
	
	# Only auto-destroy if not persistent
	if not is_persistent:
		await get_tree().create_timer(duration).timeout
		queue_free()

func update_beam_points(points: Array):
	if not line_renderer:
		return
	
	# Convert to typed array
	var points_array: Array[Vector3] = []
	for point in points:
		points_array.append(point)
	
	# Update the beam points
	line_renderer.points = points_array

func destroy_beam():
	if is_persistent:
		queue_free() 
