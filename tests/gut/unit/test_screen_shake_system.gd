extends GutTest

## Unit tests for ScreenShakeSystem

var shake_system: Node
var mock_camera: Camera2D
var scene_root: Node2D

func before_each():
	# Create scene structure
	scene_root = Node2D.new()
	add_child_autofree(scene_root)
	
	# Create camera
	mock_camera = Camera2D.new()
	scene_root.add_child(mock_camera)
	
	# Create shake system
	var shake_script = preload("res://scripts/components/camera/screen_shake_system.gd")
	shake_system = Node.new()
	shake_system.set_script(shake_script)
	shake_system.camera = mock_camera
	scene_root.add_child(shake_system)

func after_each():
	if is_instance_valid(shake_system):
		shake_system.queue_free()
	if is_instance_valid(mock_camera):
		mock_camera.queue_free()

func test_shake_system_initialization():
	assert_not_null(shake_system, "Shake system should be created")
	assert_eq(shake_system.camera, mock_camera, "Should reference mock camera")
	assert_eq(shake_system.get_shake_intensity(), 0.0, "Should start with no shake")

func test_basic_shake():
	var intensity = 0.5
	var duration = 0.2
	
	shake_system.shake(intensity, duration)
	
	assert_gt(shake_system.get_shake_intensity(), 0.0, "Should have active shake")

func test_shake_intensity_clamping():
	# Test intensity values outside range
	shake_system.shake(1.5, 0.1)  # Should clamp to 1.0
	assert_le(shake_system.get_shake_intensity(), 1.0, "Should clamp max intensity to 1.0")
	
	shake_system.stop_all_shakes()
	shake_system.shake(-0.5, 0.1)  # Should clamp to 0.0
	assert_eq(shake_system.get_shake_intensity(), 0.0, "Should clamp negative intensity to 0.0")

func test_shake_presets():
	# Test impact shake
	shake_system.shake_impact(0.5)
	assert_gt(shake_system.get_shake_intensity(), 0.0, "Impact shake should be active")
	
	shake_system.stop_all_shakes()
	
	# Test rumble shake
	shake_system.shake_rumble(0.3, 1.0)
	assert_gt(shake_system.get_shake_intensity(), 0.0, "Rumble shake should be active")
	
	shake_system.stop_all_shakes()
	
	# Test explosion shake
	shake_system.shake_explosion(0.8)
	assert_gt(shake_system.get_shake_intensity(), 0.0, "Explosion shake should be active")

func test_directional_shake():
	var direction = Vector2(1, 0)  # Right direction
	
	shake_system.shake_directional(0.5, 0.2, direction)
	
	assert_gt(shake_system.get_shake_intensity(), 0.0, "Directional shake should be active")

func test_stop_all_shakes():
	# Add multiple shakes
	shake_system.shake(0.5, 1.0)
	shake_system.shake_rumble(0.3, 2.0)
	
	assert_gt(shake_system.get_shake_intensity(), 0.0, "Should have active shakes")
	
	shake_system.stop_all_shakes()
	
	assert_eq(shake_system.get_shake_intensity(), 0.0, "Should have no active shakes")

func test_shake_signals():
	var signal_watcher = watch_signals(shake_system)
	
	# Start shake
	shake_system.shake(0.5, 0.1)
	
	# Process one frame to trigger shake start
	await wait_frames(1)
	
	assert_signal_emitted(shake_system, "shake_started", "Should emit shake started signal")

func test_advanced_shake():
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	
	shake_system.shake_advanced(0.6, 0.3, 80.0, curve)
	
	assert_gt(shake_system.get_shake_intensity(), 0.0, "Advanced shake should be active")

func test_max_offset_configuration():
	var max_offset = 100.0
	shake_system.max_offset = max_offset
	
	assert_eq(shake_system.max_offset, max_offset, "Should set max offset")

func test_default_frequency_configuration():
	var frequency = 45.0
	shake_system.default_frequency = frequency
	
	assert_eq(shake_system.default_frequency, frequency, "Should set default frequency")

func test_rotation_enabled():
	shake_system.rotation_enabled = false
	assert_false(shake_system.rotation_enabled, "Should disable rotation")
	
	shake_system.rotation_enabled = true
	assert_true(shake_system.rotation_enabled, "Should enable rotation")

func test_max_rotation_configuration():
	var max_rotation = 0.2
	shake_system.max_rotation = max_rotation
	
	assert_eq(shake_system.max_rotation, max_rotation, "Should set max rotation")

func test_camera_assignment():
	var new_camera = Camera2D.new()
	scene_root.add_child(new_camera)
	
	shake_system.camera = new_camera
	
	assert_eq(shake_system.camera, new_camera, "Should assign new camera")
	
	new_camera.queue_free()

func test_shake_intensity_decay():
	shake_system.shake(1.0, 0.1)
	
	var initial_intensity = shake_system.get_shake_intensity()
	assert_gt(initial_intensity, 0.0, "Should have initial intensity")
	
	# Wait a bit and check that intensity decreases
	await wait_seconds(0.05)
	
	var later_intensity = shake_system.get_shake_intensity()
	assert_lt(later_intensity, initial_intensity, "Intensity should decay over time")

func test_multiple_simultaneous_shakes():
	# Add multiple shakes
	shake_system.shake(0.3, 0.5)
	shake_system.shake(0.4, 0.3)
	shake_system.shake(0.2, 0.2)
	
	# Combined intensity should be higher than individual shakes
	var combined_intensity = shake_system.get_shake_intensity()
	assert_gt(combined_intensity, 0.4, "Combined shake should be stronger")

func test_shake_system_inheritance():
	assert_true(shake_system is Node, "ScreenShakeSystem should extend Node")
	assert_true(shake_system.has_method("shake"), "Should have shake methods")

func test_signal_definitions():
	assert_true(shake_system.has_signal("shake_started"), "Should have shake_started signal")
	assert_true(shake_system.has_signal("shake_ended"), "Should have shake_ended signal")

func test_default_curves_creation():
	# The curves should be created automatically if not set
	assert_not_null(shake_system.impact_curve, "Should have default impact curve")
	assert_not_null(shake_system.rumble_curve, "Should have default rumble curve")
	assert_not_null(shake_system.explosion_curve, "Should have default explosion curve")