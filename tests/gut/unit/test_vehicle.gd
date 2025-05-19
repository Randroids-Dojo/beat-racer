# GUT unit test for Vehicle class
extends GutTest

const Vehicle = preload("res://scripts/components/vehicle/vehicle.gd")

var vehicle: Vehicle


func before_each() -> void:
	vehicle = autofree(Vehicle.new())
	add_child(vehicle)
	await wait_frames(1)


func test_vehicle_initialization() -> void:
	assert_not_null(vehicle)
	assert_eq(vehicle.current_speed, 0.0)
	assert_eq(vehicle.velocity, Vector2.ZERO)
	assert_eq(vehicle.collision_layer, 2)  # Vehicle layer
	assert_eq(vehicle.collision_mask, 5)   # Collide with walls and vehicles


func test_vehicle_properties() -> void:
	assert_eq(vehicle.max_speed, 600.0)
	assert_eq(vehicle.acceleration, 800.0)
	assert_eq(vehicle.deceleration, 1200.0)
	assert_eq(vehicle.turn_speed, 3.0)
	assert_eq(vehicle.friction, 600.0)
	assert_eq(vehicle.drift_factor, 0.95)
	assert_eq(vehicle.vehicle_color, Color(0.2, 0.6, 1.0))


func test_vehicle_collision_shape() -> void:
	# Verify collision shape was created
	var collision_shape = null
	for child in vehicle.get_children():
		if child is CollisionShape2D:
			collision_shape = child
			break
	
	assert_not_null(collision_shape, "Vehicle should have a CollisionShape2D")
	assert_true(collision_shape.shape is RectangleShape2D)
	
	var rect_shape = collision_shape.shape as RectangleShape2D
	assert_eq(rect_shape.size, Vector2(vehicle.vehicle_length, vehicle.vehicle_width))


func test_acceleration() -> void:
	# Simulate forward acceleration
	vehicle.throttle_input = 1.0
	var initial_speed = vehicle.current_speed
	
	# Process one physics frame
	vehicle.apply_physics(0.1)
	
	assert_gt(vehicle.current_speed, initial_speed, "Speed should increase with positive throttle")
	assert_true(vehicle.current_speed <= vehicle.max_speed, "Speed should not exceed max speed")


func test_deceleration() -> void:
	# Set initial speed
	vehicle.current_speed = 300.0
	vehicle.throttle_input = -1.0
	
	# Process one physics frame
	vehicle.apply_physics(0.1)
	
	assert_lt(vehicle.current_speed, 300.0, "Speed should decrease with negative throttle")
	assert_true(vehicle.current_speed >= -vehicle.max_speed * 0.5, "Reverse speed should be limited")


func test_friction() -> void:
	# Set initial speed with no input
	vehicle.current_speed = 200.0
	vehicle.throttle_input = 0.0
	
	# Process one physics frame
	vehicle.apply_physics(0.1)
	
	assert_lt(vehicle.current_speed, 200.0, "Speed should decrease due to friction")
	assert_true(vehicle.current_speed >= 0.0, "Speed should not go negative from friction alone")


func test_steering() -> void:
	# Need speed to steer
	vehicle.current_speed = 100.0
	vehicle.steering_input = 1.0
	
	var initial_rotation = vehicle.rotation
	
	# Process one physics frame
	vehicle.apply_physics(0.1)
	
	assert_ne(vehicle.rotation, initial_rotation, "Rotation should change when steering")


func test_no_steering_when_stationary() -> void:
	# No speed, try to steer
	vehicle.current_speed = 0.0
	vehicle.steering_input = 1.0
	
	var initial_rotation = vehicle.rotation
	
	# Process one physics frame
	vehicle.apply_physics(0.1)
	
	assert_eq(vehicle.rotation, initial_rotation, "Should not rotate when stationary")


func test_reset_position() -> void:
	# Set vehicle in motion
	vehicle.current_speed = 300.0
	vehicle.velocity = Vector2(100, 100)
	vehicle.drift_velocity = Vector2(50, 50)
	vehicle.global_position = Vector2(500, 500)
	vehicle.rotation = PI / 2
	
	# Reset
	vehicle.reset_position(Vector2(100, 100), 0.0)
	
	assert_eq(vehicle.global_position, Vector2(100, 100))
	assert_eq(vehicle.rotation, 0.0)
	assert_eq(vehicle.current_speed, 0.0)
	assert_eq(vehicle.drift_velocity, Vector2.ZERO)
	assert_eq(vehicle.velocity, Vector2.ZERO)


func test_speed_percentage() -> void:
	vehicle.current_speed = 0.0
	assert_eq(vehicle.get_speed_percentage(), 0.0)
	
	vehicle.current_speed = vehicle.max_speed / 2
	assert_almost_eq(vehicle.get_speed_percentage(), 0.5, 0.001)
	
	vehicle.current_speed = vehicle.max_speed
	assert_eq(vehicle.get_speed_percentage(), 1.0)
	
	# Test with negative speed
	vehicle.current_speed = -vehicle.max_speed / 2
	assert_almost_eq(vehicle.get_speed_percentage(), 0.5, 0.001)


func test_is_vehicle_method() -> void:
	assert_true(vehicle.is_vehicle(), "Vehicle should identify itself")


func test_signals() -> void:
	watch_signals(vehicle)
	
	# Trigger speed change
	vehicle.current_speed = 150.0
	vehicle.emit_status_signals()
	
	assert_signal_emitted(vehicle, "speed_changed")
	var speed_params = get_signal_parameters(vehicle, "speed_changed", 0)
	assert_eq(speed_params[0], 150.0)
	
	# Trigger direction change - reset signals first
	vehicle.rotation = PI / 4
	vehicle.emit_status_signals()
	
	assert_signal_emitted(vehicle, "direction_changed")
	var dir_params = get_signal_parameters(vehicle, "direction_changed", 1)  # Get second emission
	assert_almost_eq(dir_params[0], PI / 4, 0.001)