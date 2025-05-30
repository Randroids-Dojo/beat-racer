extends GutTest

## Unit tests for CameraController

var camera: Node
var mock_target: Node2D
var scene_root: Node2D

func before_each():
	# Create scene structure
	scene_root = Node2D.new()
	add_child_autofree(scene_root)
	
	# Create camera
	var camera_script = preload("res://scripts/components/camera/camera_controller.gd")
	camera = Camera2D.new()
	camera.set_script(camera_script)
	scene_root.add_child(camera)
	
	# Create mock target
	mock_target = Node2D.new()
	mock_target.global_position = Vector2(100, 50)
	scene_root.add_child(mock_target)

func after_each():
	if is_instance_valid(camera):
		camera.queue_free()
	if is_instance_valid(mock_target):
		mock_target.queue_free()

func test_camera_initialization():
	assert_not_null(camera, "Camera should be created")
	assert_eq(camera.current_mode, 0, "Should start in FOLLOW mode")
	assert_eq(camera.zoom, camera.base_zoom, "Should start with base zoom")

func test_follow_mode():
	# Set target
	camera.set_follow_mode(mock_target)
	
	assert_eq(camera.current_mode, 0, "Should be in FOLLOW mode")
	assert_eq(camera.follow_target, mock_target, "Should have correct target")

func test_overview_mode():
	camera.set_overview_mode()
	
	assert_eq(camera.current_mode, 1, "Should be in OVERVIEW mode")

func test_snap_to_target():
	var target_pos = Vector2(200, 100)
	mock_target.global_position = target_pos
	
	camera.snap_to_target(mock_target)
	
	assert_eq(camera.global_position, target_pos + camera.position_offset, "Should snap to target position")
	assert_eq(camera.follow_target, mock_target, "Should set follow target")
	assert_eq(camera.current_mode, 0, "Should be in FOLLOW mode")

func test_configure_overview():
	var center = Vector2(500, 300)
	var zoom_level = Vector2(0.5, 0.5)
	
	camera.configure_overview(center, zoom_level)
	
	assert_eq(camera.overview_position, center, "Should set overview position")
	assert_eq(camera.overview_zoom, zoom_level, "Should set overview zoom")

func test_camera_mode_signal():
	var signal_watcher = watch_signals(camera)
	
	camera.set_overview_mode()
	
	assert_signal_emitted(camera, "camera_mode_changed", "Should emit mode changed signal")
	var signal_params = signal_watcher.get_signal_parameters(camera, "camera_mode_changed", 0)
	assert_eq(signal_params[0], 1, "Should emit correct mode")

func test_target_changed_signal():
	var signal_watcher = watch_signals(camera)
	
	camera.follow_target = mock_target
	
	assert_signal_emitted(camera, "target_changed", "Should emit target changed signal")
	var signal_params = signal_watcher.get_signal_parameters(camera, "target_changed", 0)
	assert_eq(signal_params[0], mock_target, "Should emit correct target")

func test_zoom_percentage():
	# Test minimum zoom
	camera.zoom = camera.min_zoom
	assert_almost_eq(camera.get_zoom_percentage(), 0.0, 0.01, "Min zoom should be 0%")
	
	# Test maximum zoom
	camera.zoom = camera.max_zoom
	assert_almost_eq(camera.get_zoom_percentage(), 1.0, 0.01, "Max zoom should be 100%")
	
	# Test base zoom (should be somewhere in middle)
	camera.zoom = camera.base_zoom
	var expected_percentage = ((camera.base_zoom.x + camera.base_zoom.y) / 2.0 - 
		(camera.min_zoom.x + camera.min_zoom.y) / 2.0) / \
		((camera.max_zoom.x + camera.max_zoom.y) / 2.0 - 
		(camera.min_zoom.x + camera.min_zoom.y) / 2.0)
	assert_almost_eq(camera.get_zoom_percentage(), expected_percentage, 0.01, 
		"Base zoom should have correct percentage")

func test_follow_smoothing_values():
	# Test valid values
	camera.follow_smoothing = 0.5
	assert_eq(camera.follow_smoothing, 0.5, "Should accept valid smoothing value")
	
	camera.follow_smoothing = 0.01
	assert_eq(camera.follow_smoothing, 0.01, "Should accept small smoothing value")

func test_speed_zoom_configuration():
	# Test configuration values
	camera.speed_zoom_factor = 0.002
	assert_eq(camera.speed_zoom_factor, 0.002, "Should set speed zoom factor")
	
	camera.max_speed_for_zoom = 500.0
	assert_eq(camera.max_speed_for_zoom, 500.0, "Should set max speed for zoom")

func test_position_offset():
	var offset = Vector2(50, -30)
	camera.position_offset = offset
	camera.snap_to_target(mock_target)
	
	assert_eq(camera.global_position, mock_target.global_position + offset, 
		"Should apply position offset")

func test_look_ahead_factor():
	camera.look_ahead_factor = 0.5
	assert_eq(camera.look_ahead_factor, 0.5, "Should set look ahead factor")

func test_zoom_smoothing():
	camera.zoom_smoothing = 0.2
	assert_eq(camera.zoom_smoothing, 0.2, "Should set zoom smoothing")

func test_transition_settings():
	var duration = 2.0
	camera.transition_duration = duration
	assert_eq(camera.transition_duration, duration, "Should set transition duration")

func test_mode_enum_values():
	# Test that enum values are accessible and correct
	assert_true(camera.has_method("set_follow_mode"), "Should have follow mode method")
	assert_true(camera.has_method("set_overview_mode"), "Should have overview mode method")

func test_camera_inheritance():
	assert_true(camera is Camera2D, "CameraController should extend Camera2D")
	assert_true(camera.has_method("get_zoom_percentage"), "Should have custom methods")

func test_signal_definitions():
	# Test that all expected signals exist
	assert_true(camera.has_signal("camera_mode_changed"), "Should have camera_mode_changed signal")
	assert_true(camera.has_signal("target_changed"), "Should have target_changed signal")
	assert_true(camera.has_signal("transition_started"), "Should have transition_started signal")
	assert_true(camera.has_signal("transition_completed"), "Should have transition_completed signal")