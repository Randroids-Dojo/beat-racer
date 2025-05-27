extends GutTest

# Unit tests for LaneAudioController
# Tests lane-to-sound mapping functionality

var lane_audio_controller: LaneAudioController
var mock_lane_detection: LaneDetectionSystem
var mock_lane_sound: LaneSoundSystem
var test_scene_helpers


func before_all():
	test_scene_helpers = load("res://scenes/test/test_scene_helpers.gd").new()


func before_each():
	# Create controller
	lane_audio_controller = LaneAudioController.new()
	add_child(lane_audio_controller)
	
	# Create mock systems
	mock_lane_detection = LaneDetectionSystem.new()
	mock_lane_sound = LaneSoundSystem.new()
	add_child(mock_lane_detection)
	add_child(mock_lane_sound)
	
	# Wait for ready
	await wait_frames(1)


func after_each():
	if lane_audio_controller:
		lane_audio_controller.queue_free()
	if mock_lane_detection:
		mock_lane_detection.queue_free()
	if mock_lane_sound:
		mock_lane_sound.queue_free()
	
	await wait_frames(1)


func test_initialization():
	assert_not_null(lane_audio_controller)
	assert_eq(lane_audio_controller.current_lane, -1)
	assert_eq(lane_audio_controller.previous_lane, -1)
	assert_false(lane_audio_controller.is_transitioning)
	assert_true(lane_audio_controller.center_lane_silent)
	assert_true(lane_audio_controller.enable_transitions)


func test_setup_connections():
	# Setup the controller
	lane_audio_controller.setup(mock_lane_detection, mock_lane_sound)
	
	# Verify connections were made
	assert_true(mock_lane_detection.lane_changed.is_connected(lane_audio_controller._on_lane_changed))
	assert_true(mock_lane_detection.lane_position_updated.is_connected(lane_audio_controller._on_lane_position_updated))


func test_start_stop_audio():
	lane_audio_controller.setup(mock_lane_detection, mock_lane_sound)
	
	# Test start
	lane_audio_controller.start_audio()
	assert_true(mock_lane_sound.is_playing())
	
	# Test stop
	lane_audio_controller.stop_audio()
	assert_false(mock_lane_sound.is_playing())
	
	# Verify volumes reset
	for lane in range(3):
		assert_eq(lane_audio_controller.get_lane_volume(lane), 0.0)


func test_lane_change_instant():
	lane_audio_controller.setup(mock_lane_detection, mock_lane_sound)
	lane_audio_controller.enable_transitions = false
	lane_audio_controller.start_audio()
	
	# Watch for signals
	watch_signals(lane_audio_controller)
	
	# Simulate lane change
	mock_lane_detection.emit_signal("lane_changed", -1, 0)
	
	# Verify immediate change
	assert_eq(lane_audio_controller.get_active_lane(), 0)
	assert_signal_emitted(lane_audio_controller, "lane_sound_started", [0])
	assert_false(lane_audio_controller.is_transitioning)


func test_lane_change_with_transition():
	lane_audio_controller.setup(mock_lane_detection, mock_lane_sound)
	lane_audio_controller.enable_transitions = true
	lane_audio_controller.transition_time = 0.2
	lane_audio_controller.start_audio()
	
	# Watch for signals
	watch_signals(lane_audio_controller)
	
	# Simulate lane change
	mock_lane_detection.emit_signal("lane_changed", 0, 2)
	
	# Verify transition started
	assert_true(lane_audio_controller.is_transitioning)
	assert_signal_emitted(lane_audio_controller, "sound_transition_started", [0, 2])
	
	# Wait for transition to complete
	await wait_for_signal(lane_audio_controller.sound_transition_completed, 0.5)
	
	# Verify transition completed
	assert_false(lane_audio_controller.is_transitioning)
	assert_eq(lane_audio_controller.get_active_lane(), 2)


func test_center_lane_silent():
	lane_audio_controller.setup(mock_lane_detection, mock_lane_sound)
	lane_audio_controller.center_lane_silent = true
	lane_audio_controller.enable_transitions = false
	lane_audio_controller.start_audio()
	
	# Change to center lane
	mock_lane_detection.emit_signal("lane_changed", 0, 1)
	
	# Verify center lane has zero volume
	assert_eq(lane_audio_controller.get_lane_volume(1), 0.0)
	assert_eq(lane_audio_controller.get_active_lane(), 1)
	
	# Change to side lane
	mock_lane_detection.emit_signal("lane_changed", 1, 2)
	
	# Verify side lane has volume
	assert_gt(lane_audio_controller.get_lane_volume(2), 0.0)


func test_center_lane_not_silent():
	lane_audio_controller.setup(mock_lane_detection, mock_lane_sound)
	lane_audio_controller.center_lane_silent = false
	lane_audio_controller.enable_transitions = false
	lane_audio_controller.start_audio()
	
	# Change to center lane
	mock_lane_detection.emit_signal("lane_changed", 0, 1)
	
	# Verify center lane has volume
	assert_gt(lane_audio_controller.get_lane_volume(1), 0.0)


func test_volume_control():
	lane_audio_controller.setup(mock_lane_detection, mock_lane_sound)
	lane_audio_controller.enable_transitions = false
	lane_audio_controller.start_audio()
	
	# Set custom volume
	lane_audio_controller.set_active_lane_volume(0.5)
	
	# Change lane
	mock_lane_detection.emit_signal("lane_changed", -1, 0)
	
	# Verify volume applied
	assert_almost_eq(lane_audio_controller.get_lane_volume(0), 0.5, 0.01)


func test_force_lane():
	lane_audio_controller.setup(mock_lane_detection, mock_lane_sound)
	lane_audio_controller.enable_transitions = false
	lane_audio_controller.start_audio()
	
	# Force to specific lane
	lane_audio_controller.force_lane(2)
	
	# Verify lane changed
	assert_eq(lane_audio_controller.get_active_lane(), 2)


func test_transition_time_configuration():
	lane_audio_controller.setup(mock_lane_detection, mock_lane_sound)
	
	# Test setting transition time
	lane_audio_controller.set_transition_time(0.5)
	assert_eq(lane_audio_controller.transition_time, 0.5)
	
	# Test minimum clamp
	lane_audio_controller.set_transition_time(-1.0)
	assert_eq(lane_audio_controller.transition_time, 0.01)


func test_is_lane_active():
	lane_audio_controller.setup(mock_lane_detection, mock_lane_sound)
	lane_audio_controller.enable_transitions = false
	lane_audio_controller.start_audio()
	
	# Initially no lanes active
	for lane in range(3):
		assert_false(lane_audio_controller.is_lane_active(lane))
	
	# Activate lane 0
	mock_lane_detection.emit_signal("lane_changed", -1, 0)
	await wait_frames(2)
	
	assert_true(lane_audio_controller.is_lane_active(0))
	assert_false(lane_audio_controller.is_lane_active(1))
	assert_false(lane_audio_controller.is_lane_active(2))


func test_multiple_transitions():
	lane_audio_controller.setup(mock_lane_detection, mock_lane_sound)
	lane_audio_controller.enable_transitions = true
	lane_audio_controller.transition_time = 0.1
	lane_audio_controller.start_audio()
	
	# Rapid lane changes
	mock_lane_detection.emit_signal("lane_changed", -1, 0)
	await wait_frames(2)
	mock_lane_detection.emit_signal("lane_changed", 0, 1)
	await wait_frames(2)
	mock_lane_detection.emit_signal("lane_changed", 1, 2)
	
	# Wait for all transitions
	await wait_for_signal(lane_audio_controller.sound_transition_completed, 0.5)
	
	# Verify final state
	assert_eq(lane_audio_controller.get_active_lane(), 2)
	assert_false(lane_audio_controller.is_transitioning)