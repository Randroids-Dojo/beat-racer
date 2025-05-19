# Simple test to verify RhythmVehicle works
extends Node2D

var rhythm_vehicle

func _ready() -> void:
	# Create vehicle directly
	rhythm_vehicle = preload("res://scripts/components/vehicle/rhythm_vehicle.gd").new()
	add_child(rhythm_vehicle)
	
	print("Created rhythm vehicle: ", rhythm_vehicle)
	print("Vehicle position: ", rhythm_vehicle.global_position)
	
	# Test basic movement
	rhythm_vehicle.throttle_input = 1.0
	rhythm_vehicle._physics_process(0.1)
	
	print("After physics update, speed: ", rhythm_vehicle.current_speed)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()