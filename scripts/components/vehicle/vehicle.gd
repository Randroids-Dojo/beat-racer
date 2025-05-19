# Basic vehicle implementation with top-down physics
extends CharacterBody2D
class_name Vehicle

@export_group("Physics")
@export var max_speed := 600.0
@export var acceleration := 800.0
@export var deceleration := 1200.0
@export var turn_speed := 3.0
@export var friction := 600.0
@export var drift_factor := 0.95

@export_group("Visual")
@export var vehicle_color := Color(0.2, 0.6, 1.0)
@export var vehicle_length := 30.0
@export var vehicle_width := 15.0

signal speed_changed(speed: float)
signal direction_changed(direction: float)

var current_speed := 0.0
var steering_input := 0.0
var throttle_input := 0.0
var drift_velocity := Vector2.ZERO


func _ready() -> void:
	collision_layer = 2  # Vehicle layer
	collision_mask = 5   # Collide with walls (1) and vehicles (4)
	
	# Create collision shape
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(vehicle_length, vehicle_width)
	collision_shape.shape = shape
	add_child(collision_shape)
	
	queue_redraw()


func _physics_process(delta: float) -> void:
	process_input()
	apply_physics(delta)
	move_and_slide()
	emit_status_signals()


func _draw() -> void:
	# Draw simple vehicle rectangle
	var rect := Rect2(
		-vehicle_length / 2.0,
		-vehicle_width / 2.0,
		vehicle_length,
		vehicle_width
	)
	draw_rect(rect, vehicle_color)
	
	# Draw direction indicator (front of vehicle)
	var front_indicator := Vector2(vehicle_length / 2.0 - 5.0, 0.0)
	draw_circle(front_indicator, 3.0, Color.WHITE)


func process_input() -> void:
	"""Get input from player"""
	steering_input = Input.get_axis("ui_left", "ui_right")
	throttle_input = Input.get_axis("ui_down", "ui_up")


func apply_physics(delta: float) -> void:
	"""Apply top-down car physics"""
	# Handle acceleration/deceleration
	if throttle_input > 0:
		current_speed = min(current_speed + acceleration * delta, max_speed)
	elif throttle_input < 0:
		current_speed = max(current_speed - deceleration * delta, -max_speed * 0.5)
	else:
		# Apply friction when not accelerating
		var friction_force = friction * delta
		if current_speed > 0:
			current_speed = max(current_speed - friction_force, 0)
		else:
			current_speed = min(current_speed + friction_force, 0)
	
	# Handle steering
	if abs(current_speed) > 10.0:  # Only steer when moving
		rotation += steering_input * turn_speed * delta * sign(current_speed)
	
	# Calculate movement
	var forward_velocity = transform.x * current_speed
	
	# Apply drift (realistic top-down car physics)
	drift_velocity = drift_velocity.lerp(forward_velocity, drift_factor)
	velocity = drift_velocity


func emit_status_signals() -> void:
	"""Emit signals for UI updates"""
	speed_changed.emit(abs(current_speed))
	direction_changed.emit(rotation)


func reset_position(new_position: Vector2, new_rotation: float = 0.0) -> void:
	"""Reset vehicle to a specific position and rotation"""
	global_position = new_position
	rotation = new_rotation
	current_speed = 0.0
	drift_velocity = Vector2.ZERO
	velocity = Vector2.ZERO


func get_speed_percentage() -> float:
	"""Get current speed as percentage of max speed"""
	return abs(current_speed) / max_speed


func is_vehicle() -> bool:
	"""Identify this node as a vehicle for collision detection"""
	return true