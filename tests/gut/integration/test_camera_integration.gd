extends GutTest

## Integration tests for Camera System with Vehicles

var camera: Node
var screen_shake: Node
var vehicle: EnhancedVehicle
var track_system: TrackSystem
var scene_root: Node2D

func before_each():
	# Create scene structure
	scene_root = Node2D.new()
	add_child_autofree(scene_root)
	
	# Create and configure track system
	track_system = preload("res://scenes/systems/track_system.tscn").instantiate()
	scene_root.add_child(track_system)
	
	# Create vehicle
	vehicle = EnhancedVehicle.new()
	vehicle.position = Vector2.ZERO
	scene_root.add_child(vehicle)
	
	# Create camera
	var camera_script = preload("res://scripts/components/camera/camera_controller.gd")
	camera = Camera2D.new()
	camera.set_script(camera_script)
	scene_root.add_child(camera)
	
	# Create screen shake system
	var shake_script = preload("res://scripts/components/camera/screen_shake_system.gd")
	screen_shake = Node.new()
	screen_shake.set_script(shake_script)
	screen_shake.camera = camera
	scene_root.add_child(screen_shake)

func after_each():
	# Clean up
	if is_instance_valid(scene_root):
		scene_root.queue_free()

func test_camera_follows_vehicle():
	# Set camera to follow vehicle
	camera.set_follow_mode(vehicle)
	
	# Move vehicle
	var target_position = Vector2(200, 100)
	vehicle.position = target_position
	
	# Process a few frames for smooth following
	await wait_frames(10)
	
	# Camera should be near vehicle position
	var distance = camera.global_position.distance_to(target_position)
	assert_lt(distance, 50.0, "Camera should follow vehicle closely")

func test_speed_based_zoom():
	camera.set_follow_mode(vehicle)
	camera.speed_zoom_factor = 0.001
	camera.max_speed_for_zoom = 500.0
	
	# Create a mock velocity method for testing
	vehicle.set_script(preload("res://scripts/components/vehicle/enhanced_vehicle.gd"))
	
	# Set high velocity
	vehicle.linear_velocity = Vector2(400, 0)  # High speed
	
	# Process frames to update zoom
	await wait_frames(5)
	
	# Zoom should be affected by speed
	var zoom_percentage = camera.get_zoom_percentage()
	assert_true(zoom_percentage > 0.1, "High speed should affect zoom")

func test_camera_overview_mode():
	# Set overview configuration
	var overview_center = Vector2(0, 0)
	var overview_zoom = Vector2(0.3, 0.3)
	camera.configure_overview(overview_center, overview_zoom)
	
	# Switch to overview mode
	camera.set_overview_mode()
	
	# Process frames for transition
	await wait_frames(10)
	
	assert_eq(camera.current_mode, 1, # OVERVIEW mode
		"Should be in overview mode")
	
	# Camera should move toward overview position
	var distance = camera.global_position.distance_to(overview_center)
	assert_lt(distance, 100.0, "Camera should move toward overview center")

func test_vehicle_transition():
	# Create second vehicle
	var vehicle2 = EnhancedVehicle.new()
	vehicle2.position = Vector2(300, 200)
	scene_root.add_child(vehicle2)
	
	# Start following first vehicle
	camera.set_follow_mode(vehicle)
	await wait_frames(5)
	
	# Switch to second vehicle
	camera.follow_target = vehicle2
	
	# Should trigger transition mode
	assert_eq(camera.current_mode, 2, # TRANSITION mode
		"Should enter transition mode")
	
	# Clean up
	vehicle2.queue_free()

func test_camera_signals_with_vehicles():
	var signal_watcher = watch_signals(camera)
	
	# Test mode change signal
	camera.set_overview_mode()
	assert_signal_emitted(camera, "camera_mode_changed", "Should emit mode changed")
	
	# Test target change signal
	camera.follow_target = vehicle
	assert_signal_emitted(camera, "target_changed", "Should emit target changed")

func test_screen_shake_integration():
	var signal_watcher = watch_signals(screen_shake)
	
	# Apply shake
	screen_shake.shake_impact(0.5)
	
	# Process frame to start shake
	await wait_frames(1)
	
	assert_signal_emitted(screen_shake, "shake_started", "Should start shake")
	assert_gt(screen_shake.get_shake_intensity(), 0.0, "Should have active shake")

func test_camera_with_track_boundaries():
	# Position camera at track boundary
	camera.global_position = Vector2(1000, 1000)  # Far outside track
	camera.set_follow_mode(vehicle)
	
	# Vehicle should be on track
	vehicle.position = Vector2.ZERO
	
	# Process frames for camera to follow
	await wait_frames(10)
	
	# Camera should move toward vehicle on track
	var distance = camera.global_position.distance_to(vehicle.position)
	assert_lt(distance, 200.0, "Camera should follow vehicle to track")

func test_look_ahead_functionality():
	camera.set_follow_mode(vehicle)
	camera.look_ahead_factor = 0.5
	
	# Set vehicle velocity
	vehicle.linear_velocity = Vector2(200, 0)  # Moving right
	
	# Process frames
	await wait_frames(5)
	
	# Camera should be ahead of vehicle in direction of movement
	var ahead_position = vehicle.position + Vector2(200, 0) * camera.look_ahead_factor
	var distance_to_ahead = camera.global_position.distance_to(ahead_position)
	var distance_to_vehicle = camera.global_position.distance_to(vehicle.position)
	
	# Camera should be closer to look-ahead position than just vehicle position
	assert_lt(distance_to_ahead, distance_to_vehicle + 50.0, 
		"Camera should use look-ahead")

func test_position_offset():
	var offset = Vector2(50, -30)
	camera.position_offset = offset
	camera.snap_to_target(vehicle)
	
	var expected_position = vehicle.global_position + offset
	var distance = camera.global_position.distance_to(expected_position)
	
	assert_lt(distance, 5.0, "Camera should apply position offset")

func test_zoom_limits():
	camera.set_follow_mode(vehicle)
	
	# Test minimum zoom constraint
	camera.zoom = Vector2(0.1, 0.1)  # Below minimum
	camera._target_zoom = Vector2(0.1, 0.1)
	
	await wait_frames(2)
	
	assert_true(camera.zoom.x >= camera.min_zoom.x, "Should respect minimum zoom X")
	assert_true(camera.zoom.y >= camera.min_zoom.y, "Should respect minimum zoom Y")

func test_transition_completion():
	# Create second vehicle
	var vehicle2 = EnhancedVehicle.new()
	vehicle2.position = Vector2(500, 300)
	scene_root.add_child(vehicle2)
	
	var signal_watcher = watch_signals(camera)
	
	# Start following first vehicle
	camera.set_follow_mode(vehicle)
	await wait_frames(2)
	
	# Switch to second vehicle (triggers transition)
	camera.follow_target = vehicle2
	
	# Wait for transition to complete
	await wait_seconds(camera.transition_duration + 0.1)
	
	assert_signal_emitted(camera, "transition_completed", "Should complete transition")
	assert_eq(camera.current_mode, 0, # FOLLOW mode
		"Should return to follow mode")
	
	vehicle2.queue_free()

func test_camera_with_vehicle_physics():
	# Set up realistic vehicle scenario
	camera.set_follow_mode(vehicle)
	
	# Apply physics to vehicle
	vehicle.apply_force(Vector2(1000, 0))  # Push vehicle forward
	
	# Process physics frames
	await wait_frames(10)
	
	# Camera should follow the moving vehicle
	var distance = camera.global_position.distance_to(vehicle.position)
	assert_lt(distance, 100.0, "Camera should follow physics-driven vehicle")

func test_multiple_vehicle_tracking():
	# Create multiple vehicles
	var vehicles = []
	for i in range(3):
		var v = EnhancedVehicle.new()
		v.position = Vector2(i * 200, 0)
		v.name = "Vehicle" + str(i)
		scene_root.add_child(v)
		vehicles.append(v)
	
	# Switch between vehicles
	for vehicle_target in vehicles:
		camera.set_follow_mode(vehicle_target)
		await wait_frames(5)
		
		var distance = camera.global_position.distance_to(vehicle_target.position)
		assert_lt(distance, 100.0, "Should follow each vehicle: " + vehicle_target.name)
	
	# Clean up
	for v in vehicles:
		v.queue_free()

func test_screen_shake_with_moving_camera():
	camera.set_follow_mode(vehicle)
	
	# Move vehicle
	vehicle.linear_velocity = Vector2(100, 50)
	
	# Apply shake while moving
	screen_shake.shake_impact(0.8)
	
	# Process frames
	await wait_frames(5)
	
	# Camera should still follow vehicle despite shake
	var distance = camera.global_position.distance_to(vehicle.position)
	assert_lt(distance, 150.0, "Camera should follow vehicle even with shake")
	assert_gt(screen_shake.get_shake_intensity(), 0.0, "Should maintain shake")