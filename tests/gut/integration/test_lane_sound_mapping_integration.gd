extends GutTest

# Integration tests for lane position to sound mapping
# Tests the complete flow from vehicle movement to sound generation

var test_scene_helpers
var track_system: TrackSystem
var vehicle: RhythmVehicleWithLanes
var lane_detection: LaneDetectionSystem
var lane_sound_system: LaneSoundSystem
var lane_audio_controller: LaneAudioController


func before_all():
	test_scene_helpers = load("res://scenes/test/test_scene_helpers.gd").new()
	
	# Initialize autoloads for testing
	if not has_node("/root/AudioManager"):
		var audio_manager = load("res://scripts/autoloads/audio_manager.gd").new()
		audio_manager.name = "AudioManager"
		get_tree().root.add_child(audio_manager)
	
	if not has_node("/root/BeatManager"):
		var beat_manager = load("res://scripts/autoloads/beat_manager.gd").new()
		beat_manager.name = "BeatManager"
		get_tree().root.add_child(beat_manager)


func before_each():
	# Create track
	track_system = test_scene_helpers.create_track_system()
	add_child(track_system)
	
	# Create vehicle
	vehicle = test_scene_helpers.create_rhythm_vehicle_with_lanes()
	add_child(vehicle)
	vehicle.position = track_system.get_start_position()
	
	# Create lane detection
	lane_detection = LaneDetectionSystem.new()
	lane_detection.track_reference = track_system
	lane_detection.vehicle_reference = vehicle
	add_child(lane_detection)
	
	# Create sound systems
	lane_sound_system = LaneSoundSystem.new()
	add_child(lane_sound_system)
	
	lane_audio_controller = LaneAudioController.new()
	add_child(lane_audio_controller)
	
	# Wait for ready
	await wait_frames(2)
	
	# Setup connections
	lane_audio_controller.setup(lane_detection, lane_sound_system)
	
	# Configure lane sounds
	_setup_test_sounds()


func after_each():
	if lane_audio_controller:
		lane_audio_controller.stop_audio()
		lane_audio_controller.queue_free()
	if lane_sound_system:
		lane_sound_system.queue_free()
	if lane_detection:
		lane_detection.queue_free()
	if vehicle:
		vehicle.queue_free()
	if track_system:
		track_system.queue_free()
	
	await wait_frames(2)


func _setup_test_sounds():
	"""Configure distinct sounds for each lane"""
	var configs = [
		_create_test_config("Sine", 0, 1),
		_create_test_config("Square", 1, 3),
		_create_test_config("Triangle", 2, 5)
	]
	
	for i in range(3):
		lane_sound_system.load_lane_configuration(configs[i], i)


func _create_test_config(waveform: String, octave: int, scale_degree: int) -> LaneSoundConfig:
	var config = LaneSoundConfig.new()
	config.config_name = "Test %s" % waveform
	config.waveform = waveform
	config.octave = octave
	config.scale_degree = scale_degree
	config.volume = 0.7
	config.audio_bus = "Melody"
	return config


func test_vehicle_movement_triggers_sound_changes():
	gut.p("Testing vehicle movement triggers appropriate sound changes")
	
	# Start audio
	lane_audio_controller.enable_transitions = false
	lane_audio_controller.start_audio()
	
	# Watch for signals
	watch_signals(lane_audio_controller)
	
	# Get initial lane info
	var initial_info = lane_detection.get_lane_info()
	gut.p("Initial lane: %d" % initial_info.current_lane)
	
	# Move vehicle to different lane
	vehicle.position.x += 100  # Move right
	await wait_frames(5)
	
	# Check lane changed
	var new_info = lane_detection.get_lane_info()
	assert_ne(new_info.current_lane, initial_info.current_lane, "Vehicle should have changed lanes")
	
	# Verify sound changed
	assert_signal_emitted(lane_audio_controller, "lane_sound_started")
	assert_eq(lane_audio_controller.get_active_lane(), new_info.current_lane)


func test_center_lane_silence_integration():
	gut.p("Testing center lane silence during vehicle movement")
	
	# Configure center lane as silent
	lane_audio_controller.center_lane_silent = true
	lane_audio_controller.enable_transitions = false
	lane_audio_controller.start_audio()
	
	# Move vehicle to center lane
	var center_pos = track_system.get_lane_center_position(1)
	vehicle.position = center_pos
	await wait_frames(5)
	
	# Verify in center lane
	var info = lane_detection.get_lane_info()
	assert_eq(info.current_lane, 1, "Vehicle should be in center lane")
	
	# Verify volume is zero
	assert_eq(lane_audio_controller.get_lane_volume(1), 0.0, "Center lane should be silent")
	
	# Move to side lane
	vehicle.position.x += 100
	await wait_frames(5)
	
	# Verify sound restored
	info = lane_detection.get_lane_info()
	assert_ne(info.current_lane, 1, "Vehicle should have left center lane")
	assert_gt(lane_audio_controller.get_lane_volume(info.current_lane), 0.0, "Side lane should have sound")


func test_smooth_transitions_during_movement():
	gut.p("Testing smooth audio transitions during lane changes")
	
	# Enable transitions
	lane_audio_controller.enable_transitions = true
	lane_audio_controller.transition_time = 0.3
	lane_audio_controller.start_audio()
	
	# Watch for transition signals
	watch_signals(lane_audio_controller)
	
	# Move between lanes
	var start_pos = track_system.get_lane_center_position(0)
	vehicle.position = start_pos
	await wait_frames(5)
	
	# Move to right lane
	var target_pos = track_system.get_lane_center_position(2)
	vehicle.position = target_pos
	await wait_frames(5)
	
	# Verify transition occurred
	assert_signal_emitted(lane_audio_controller, "sound_transition_started")
	
	# Wait for transition to complete
	await wait_for_signal(lane_audio_controller.sound_transition_completed, 0.5)
	
	assert_signal_emitted(lane_audio_controller, "sound_transition_completed")
	assert_false(lane_audio_controller.is_transitioning)


func test_continuous_sound_while_in_lane():
	gut.p("Testing continuous sound generation while vehicle stays in lane")
	
	lane_audio_controller.enable_transitions = false
	lane_audio_controller.start_audio()
	
	# Position vehicle in left lane
	var lane_pos = track_system.get_lane_center_position(0)
	vehicle.position = lane_pos
	await wait_frames(5)
	
	# Verify initial state
	assert_eq(lane_audio_controller.get_active_lane(), 0)
	assert_true(lane_audio_controller.is_lane_active(0))
	
	# Keep vehicle in same lane but move along track
	for i in range(10):
		vehicle.position.y += 10
		await wait_frames(2)
	
	# Verify sound remained active
	assert_eq(lane_audio_controller.get_active_lane(), 0, "Should still be in lane 0")
	assert_true(lane_audio_controller.is_lane_active(0), "Lane 0 should still be active")


func test_rapid_lane_changes():
	gut.p("Testing system stability with rapid lane changes")
	
	lane_audio_controller.enable_transitions = true
	lane_audio_controller.transition_time = 0.2
	lane_audio_controller.start_audio()
	
	# Perform rapid lane changes
	var positions = [
		track_system.get_lane_center_position(0),
		track_system.get_lane_center_position(2),
		track_system.get_lane_center_position(1),
		track_system.get_lane_center_position(0)
	]
	
	for pos in positions:
		vehicle.position = pos
		await wait_frames(3)
	
	# Wait for system to stabilize
	await wait_frames(20)
	
	# Verify system is in valid state
	var final_lane = lane_detection.get_current_lane()
	assert_eq(lane_audio_controller.get_active_lane(), final_lane)
	assert_between(final_lane, 0, 2, "Final lane should be valid")


func test_audio_volume_modulation():
	gut.p("Testing audio volume control integration")
	
	lane_audio_controller.set_active_lane_volume(0.5)
	lane_audio_controller.enable_transitions = false
	lane_audio_controller.start_audio()
	
	# Position in lane
	vehicle.position = track_system.get_lane_center_position(0)
	await wait_frames(5)
	
	# Check volume
	assert_almost_eq(lane_audio_controller.get_lane_volume(0), 0.5, 0.01)
	
	# Change volume while playing
	lane_audio_controller.set_active_lane_volume(0.8)
	await wait_frames(2)
	
	assert_almost_eq(lane_audio_controller.get_lane_volume(0), 0.8, 0.01)


func test_beat_synchronization():
	gut.p("Testing lane sound changes stay synchronized with beat")
	
	# Start beat manager
	BeatManager.set_bpm(120)
	BeatManager.start_beat()
	
	lane_audio_controller.enable_transitions = false
	lane_audio_controller.start_audio()
	
	# Watch for beat signals
	watch_signals(BeatManager)
	
	# Change lanes on beat
	await wait_for_signal(BeatManager.beat_occurred, 2.0)
	
	vehicle.position = track_system.get_lane_center_position(2)
	await wait_frames(5)
	
	# Verify sound is playing and synchronized
	assert_true(lane_sound_system.is_playing())
	assert_eq(lane_audio_controller.get_active_lane(), 2)
	
	BeatManager.stop_beat()


func test_full_integration_flow():
	gut.p("Testing complete integration from vehicle control to sound output")
	
	# Setup complete system
	lane_audio_controller.center_lane_silent = true
	lane_audio_controller.enable_transitions = true
	lane_audio_controller.transition_time = 0.25
	lane_audio_controller.start_audio()
	
	# Start in left lane
	vehicle.position = track_system.get_lane_center_position(0)
	await wait_frames(5)
	
	assert_eq(lane_audio_controller.get_active_lane(), 0)
	assert_true(lane_audio_controller.is_lane_active(0))
	
	# Move to center (silent)
	vehicle.position = track_system.get_lane_center_position(1)
	await wait_for_signal(lane_audio_controller.sound_transition_completed, 0.5)
	
	assert_eq(lane_audio_controller.get_active_lane(), 1)
	assert_false(lane_audio_controller.is_lane_active(1))  # Silent
	
	# Move to right lane
	vehicle.position = track_system.get_lane_center_position(2)
	await wait_for_signal(lane_audio_controller.sound_transition_completed, 0.5)
	
	assert_eq(lane_audio_controller.get_active_lane(), 2)
	assert_true(lane_audio_controller.is_lane_active(2))
	
	gut.p("Full integration flow completed successfully")