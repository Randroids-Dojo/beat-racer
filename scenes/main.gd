extends Node2D

@onready var vehicle_manager: Node2D = $VehicleManager
@onready var track: Node2D = $Track

func _ready():
	prepare_game()
	spawn_initial_vehicle()
	setup_test_ui()

func prepare_game():
	%Camera2D.position = Vector2(0, 0)
	%Camera2D.make_current()

func spawn_initial_vehicle():
	# Get spawn position from track
	var spawn_pos = Vector2(0, 0)  # Default spawn position
	var spawn_rot = 0.0  # Default spawn rotation
	
	# Try to get spawn position from track if it has one
	if track and track.has_method("get_spawn_position"):
		spawn_pos = track.get_spawn_position()
	if track and track.has_method("get_spawn_rotation"):
		spawn_rot = track.get_spawn_rotation()
	
	# Set spawn point in vehicle manager
	vehicle_manager.set_spawn_point(spawn_pos, spawn_rot)
	
	# Spawn a random vehicle for testing
	var vehicle = vehicle_manager.spawn_random_vehicle()
	
	# Enable debug mode for testing
	vehicle_manager.debug_mode = true
	
	print("Vehicle spawned at: ", spawn_pos)

func setup_test_ui():
	# Add test button for Story 002
	var TestClass = load("res://scripts/test_vehicle_spawning.gd")
	TestClass.create_test_button(self)
	
	# Add vehicle type selector
	var option_button = OptionButton.new()
	option_button.position = Vector2(220, 10)
	option_button.size = Vector2(150, 40)
	option_button.add_item("Sedan")
	option_button.add_item("Sports Car")
	option_button.add_item("Van")
	option_button.add_item("Motorcycle") 
	option_button.add_item("Truck")
	option_button.add_item("Random")
	option_button.selected = 5  # Default to random
	
	option_button.item_selected.connect(func(index):
		if index < 5:
			vehicle_manager.spawn_vehicle(index)
		else:
			vehicle_manager.spawn_random_vehicle()
	)
	
	add_child(option_button)