extends Node2D

# Vehicle spawning system for Beat Racer

@export var vehicle_scenes: Array[PackedScene] = []
@export var spawn_position: Vector2 = Vector2(0, 0)
@export var spawn_rotation: float = 0.0
@export var debug_mode: bool = false

var vehicle_container: Node2D
var current_vehicle: CharacterBody2D = null

func _ready() -> void:
	vehicle_container = $VehicleContainer
	load_vehicle_scenes()

func load_vehicle_scenes() -> void:
	# Load all vehicle scenes if not provided
	if vehicle_scenes.is_empty():
		vehicle_scenes = [
			preload("res://scenes/vehicles/sedan.tscn"),
			preload("res://scenes/vehicles/sports_car.tscn"),
			preload("res://scenes/vehicles/van.tscn"),
			preload("res://scenes/vehicles/motorcycle.tscn"),
			preload("res://scenes/vehicles/truck.tscn")
		]

func spawn_vehicle(vehicle_type: int, custom_position: Vector2 = Vector2.ZERO, custom_rotation: float = 0.0) -> CharacterBody2D:
	# Remove current vehicle if exists
	if current_vehicle:
		current_vehicle.queue_free()
	
	# Validate vehicle type
	if vehicle_type < 0 or vehicle_type >= vehicle_scenes.size():
		push_error("Invalid vehicle type: " + str(vehicle_type))
		return null
	
	# Instantiate new vehicle
	var vehicle_scene = vehicle_scenes[vehicle_type]
	current_vehicle = vehicle_scene.instantiate()
	
	# Set spawn position and rotation
	var actual_position = custom_position if custom_position != Vector2.ZERO else spawn_position
	var actual_rotation = custom_rotation if custom_rotation != 0.0 else spawn_rotation
	
	# Add to scene
	vehicle_container.add_child(current_vehicle)
	
	# Call spawn function on vehicle
	if current_vehicle.has_method("spawn_at_position"):
		current_vehicle.spawn_at_position(actual_position, actual_rotation)
	else:
		current_vehicle.position = actual_position
		current_vehicle.rotation = actual_rotation
	
	# Set debug mode
	if debug_mode:
		current_vehicle.show_debug_collision = true
	
	return current_vehicle

func spawn_random_vehicle(custom_position: Vector2 = Vector2.ZERO, custom_rotation: float = 0.0) -> CharacterBody2D:
	var random_type = randi() % vehicle_scenes.size()
	return spawn_vehicle(random_type, custom_position, custom_rotation)

func get_current_vehicle() -> CharacterBody2D:
	return current_vehicle

func set_spawn_point(position: Vector2, rotation: float) -> void:
	spawn_position = position
	spawn_rotation = rotation

func remove_all_vehicles() -> void:
	for child in vehicle_container.get_children():
		child.queue_free()
	current_vehicle = null