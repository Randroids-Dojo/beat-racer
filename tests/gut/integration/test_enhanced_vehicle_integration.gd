# Integration tests for enhanced vehicle with track and other systems
extends GutTest

var vehicle = null
var track_system = null
var beat_manager = null
var test_scene: Node2D = null


func before_each():
	# Create test scene
	test_scene = Node2D.new()
	test_scene.name = "TestScene"
	add_child(test_scene)
	
	# Setup BeatManager if not already loaded
	beat_manager = get_node("/root/BeatManager")
	if not beat_manager:
		var BeatManager = preload("res://scripts/autoloads/beat_manager.gd")
		beat_manager = BeatManager.new()
		beat_manager.name = "BeatManager"
		get_tree().root.add_child(beat_manager)
		beat_manager.set_bpm(120)
		beat_manager.start()
	
	# Create track
	var TrackSystem = preload("res://scripts/components/track/track_system.gd")
	track_system = TrackSystem.new()
	track_system.name = "TestTrackSystem"
	test_scene.add_child(track_system)
	
	# Create vehicle
	var EnhancedVehicle = preload("res://scripts/components/vehicle/enhanced_vehicle.gd")
	vehicle = EnhancedVehicle.new()
	vehicle.name = "TestEnhancedVehicle"
	test_scene.add_child(vehicle)
	
	await wait_frames(2)


func after_each():
	if test_scene:
		test_scene.queue_free()
		test_scene = null
	vehicle = null
	track_system = null


func test_vehicle_on_track():
	# Position vehicle at track start
	var start_pos = track_system.get_start_position()
	vehicle.reset_position(start_pos, 0)
	
	assert_eq(vehicle.global_position, start_pos, "Vehicle should be at start position")
	assert_eq(vehicle.current_speed, 0.0, "Speed should be reset")
	assert_eq(vehicle.velocity, Vector2.ZERO, "Velocity should be reset")


func test_vehicle_trail_with_movement():
	# Ensure trail exists
	assert_not_null(vehicle.trail_effect, "Should have trail effect")
	
	# Move vehicle
	vehicle.global_position = Vector2(100, 100)
	vehicle.current_speed = 200.0
	vehicle.velocity = Vector2(200, 0)
	
	# Simulate some frames
	for i in range(10):
		vehicle.global_position += Vector2(10, 0)
		vehicle._process(0.1)
		await wait_frames(1)
	
	# Trail should have points
	assert_gt(vehicle.trail_effect.get_trail_length(), 0, "Trail should have points after movement")


func test_particle_activation_with_speed():
	vehicle.enable_speed_particles = true
	vehicle.speed_particle_threshold = 0.5
	
	# Set high speed
	vehicle.current_speed = vehicle.max_speed * 0.6
	vehicle.update_particle_effects()
	
	assert_true(vehicle.speed_particles.emitting, "Speed particles should emit at high speed")
	
	# Set low speed
	vehicle.current_speed = vehicle.max_speed * 0.3
	vehicle.update_particle_effects()
	
	assert_false(vehicle.speed_particles.emitting, "Speed particles should not emit at low speed")


func test_tire_smoke_when_drifting():
	vehicle.enable_tire_smoke = true
	
	# Setup drift conditions
	vehicle.is_drifting = true
	vehicle.slip_angle = 30.0
	vehicle.update_particle_effects()
	
	for particles in vehicle.tire_smoke_particles:
		assert_true(particles.emitting, "Tire smoke should emit when drifting")
	
	# Stop drifting
	vehicle.is_drifting = false
	vehicle.slip_angle = 5.0
	vehicle.update_particle_effects()
	
	for particles in vehicle.tire_smoke_particles:
		assert_false(particles.emitting, "Tire smoke should stop when not drifting")


func test_camera_shake_integration():
	# Create a test camera
	var camera = Camera2D.new()
	camera.name = "TestCamera"
	test_scene.add_child(camera)
	vehicle.camera = camera
	
	# Add trauma method to camera
	camera.set_script(load("res://tests/gut/unit/mock_camera.gd") if FileAccess.file_exists("res://tests/gut/unit/mock_camera.gd") else null)
	
	vehicle.enable_screen_shake = true
	
	# Test acceleration shake
	vehicle.current_state = vehicle.VehicleState.ACCELERATING
	vehicle.acceleration_factor = 1.0
	vehicle.apply_screen_shake()
	
	# Would need camera mock to properly test shake amount


func test_state_machine_with_physics():
	# Start from idle
	assert_eq(vehicle.current_state, vehicle.VehicleState.IDLE)
	
	# Accelerate
	vehicle.throttle_input = 1.0
	for i in range(10):
		vehicle._physics_process(0.1)
		await wait_frames(1)
	
	assert_gt(vehicle.current_speed, 0.0, "Should have gained speed")
	assert_eq(vehicle.current_state, vehicle.VehicleState.ACCELERATING)
	
	# Release throttle
	vehicle.throttle_input = 0.0
	vehicle.update_vehicle_state()
	assert_eq(vehicle.current_state, vehicle.VehicleState.CRUISING)
	
	# Brake
	vehicle.throttle_input = -1.0
	vehicle.update_vehicle_state()
	assert_eq(vehicle.current_state, vehicle.VehicleState.BRAKING)


func test_enhanced_physics_curves():
	# Test acceleration at different speeds
	var initial_speed = vehicle.current_speed
	vehicle.throttle_input = 1.0
	
	# Low speed acceleration
	vehicle.current_speed = 50.0
	vehicle.apply_enhanced_physics(0.1)
	var low_speed_accel = vehicle.current_speed - 50.0
	
	# High speed acceleration
	vehicle.current_speed = vehicle.max_speed * 0.8
	var high_speed_start = vehicle.current_speed
	vehicle.apply_enhanced_physics(0.1)
	var high_speed_accel = vehicle.current_speed - high_speed_start
	
	assert_gt(low_speed_accel, high_speed_accel, "Should accelerate faster at low speeds")


func test_momentum_preservation():
	# Set vehicle in motion
	vehicle.current_speed = 300.0
	vehicle.actual_velocity = Vector2(300, 0)
	vehicle.velocity = vehicle.actual_velocity
	
	# Turn slightly
	vehicle.rotation = deg_to_rad(15)
	vehicle.steering_input = 0.5
	
	# Apply physics with high momentum preservation
	vehicle.momentum_preservation = 0.95
	vehicle.apply_enhanced_physics(0.1)
	
	# Check that velocity hasn't changed too drastically
	var velocity_change = vehicle.velocity.distance_to(Vector2(300, 0))
	assert_lt(velocity_change, 100.0, "Should preserve momentum")


func test_slip_angle_limits():
	# Try to create extreme slip
	vehicle.velocity = Vector2(500, 0)
	vehicle.rotation = deg_to_rad(90)  # Perpendicular to velocity
	vehicle.current_speed = 500.0
	
	vehicle.apply_enhanced_physics(0.1)
	
	assert_lte(abs(vehicle.slip_angle), vehicle.max_slip_angle, "Slip angle should be clamped")


func test_banking_visual_effect():
	vehicle.enable_banking = true
	vehicle.max_bank_angle = 10.0
	
	# Turn right at speed
	vehicle.steering_input = 1.0
	vehicle.current_speed = vehicle.max_speed * 0.8
	
	# Simulate several frames for banking to apply
	for i in range(10):
		vehicle.apply_visual_effects(0.1)
		await wait_frames(1)
	
	assert_lt(vehicle.current_bank_angle, 0.0, "Should bank into the turn")
	assert_gte(vehicle.current_bank_angle, -vehicle.max_bank_angle * 1.5, "Banking should be limited")


func test_complete_driving_loop():
	# Position at start
	var start_pos = track_system.get_start_position()
	vehicle.reset_position(start_pos, 0)
	
	# Accelerate
	vehicle.throttle_input = 1.0
	for i in range(20):
		vehicle._physics_process(0.05)
		await wait_frames(1)
	
	assert_gt(vehicle.current_speed, 100.0, "Should have gained significant speed")
	assert_ne(vehicle.global_position, start_pos, "Should have moved from start")
	
	# Turn
	vehicle.steering_input = 0.5
	for i in range(10):
		vehicle._physics_process(0.05)
		await wait_frames(1)
	
	assert_ne(vehicle.rotation, 0.0, "Should have rotated")
	
	# Check if drifting at high speed turn
	if vehicle.current_speed > 400.0 and abs(vehicle.steering_input) > 0.3:
		# Might be drifting
		assert_gt(abs(vehicle.slip_angle), 0.0, "Should have slip angle in turn")