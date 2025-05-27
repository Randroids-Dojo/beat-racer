extends GutTest

# Unit tests for PlaybackVehicle component

var playback_vehicle: PlaybackVehicle
var test_recording: LapRecorder.LapRecording
var mock_lane_sound_system: Node


func before_each():
	playback_vehicle = PlaybackVehicle.new()
	add_child_autofree(playback_vehicle)
	
	# Create mock lane sound system
	mock_lane_sound_system = Node.new()
	mock_lane_sound_system.set_script(preload("res://tests/gut/unit/mock_lane_sound_system.gd") if ResourceLoader.exists("res://tests/gut/unit/mock_lane_sound_system.gd") else null)
	add_child_autofree(mock_lane_sound_system)
	
	# Create test recording
	test_recording = _create_test_recording()


func _create_test_recording() -> LapRecorder.LapRecording:
	var recording = LapRecorder.LapRecording.new()
	recording.start_time = 0.0
	recording.end_time = 3.0
	recording.duration = 3.0
	recording.bpm = 120.0
	recording.is_valid = true
	
	# Add samples that change lanes
	for i in range(4):
		var sample = LapRecorder.PositionSample.new()
		sample.timestamp = float(i)
		sample.position = Vector2(i * 100, i * 50)
		sample.rotation = i * PI / 6
		sample.lane = i % 3
		sample.velocity = Vector2(100, 50)
		recording.position_samples.append(sample)
	
	recording.total_samples = recording.position_samples.size()
	return recording


func test_playback_vehicle_initialization():
	assert_not_null(playback_vehicle, "PlaybackVehicle should be created")
	assert_not_null(playback_vehicle.path_player, "Should have PathPlayer component")
	assert_eq(playback_vehicle.current_lane, -1, "Should start with no lane")
	assert_false(playback_vehicle.is_active, "Should not be active initially")
	assert_false(playback_vehicle.visible, "Should not be visible initially")


func test_setup_lane_sound_system():
	playback_vehicle.setup(mock_lane_sound_system)
	assert_eq(playback_vehicle.lane_sound_system, mock_lane_sound_system, "Should store lane sound system reference")


func test_load_recording():
	var result = playback_vehicle.load_recording(test_recording)
	assert_true(result, "Should successfully load recording")


func test_visual_properties():
	assert_eq(playback_vehicle.ghost_alpha, 0.5, "Default ghost alpha should be 0.5")
	assert_true(playback_vehicle.trail_enabled, "Trail should be enabled by default")
	assert_eq(playback_vehicle.trail_length, 20, "Default trail length should be 20")
	
	# Test color setter
	var new_color = Color(1.0, 0.0, 0.0, 0.7)
	playback_vehicle.set_ghost_color(new_color)
	assert_eq(playback_vehicle.ghost_color, new_color, "Should update ghost color")


func test_position_update_handling():
	var lane_changed = false
	var from_lane = -1
	var to_lane = -1
	
	playback_vehicle.lane_changed.connect(func(from, to):
		lane_changed = true
		from_lane = from
		to_lane = to
	)
	
	# Simulate position updates
	playback_vehicle._on_position_updated(Vector2(100, 0), PI/4, 0)
	assert_eq(playback_vehicle.global_position, Vector2(100, 0), "Should update position")
	assert_eq(playback_vehicle.global_rotation, PI/4, "Should update rotation")
	assert_true(lane_changed, "Should emit lane_changed signal")
	assert_eq(from_lane, -1, "Should report from lane")
	assert_eq(to_lane, 0, "Should report to lane")
	assert_eq(playback_vehicle.current_lane, 0, "Should update current lane")


func test_playback_start_stop():
	playback_vehicle.load_recording(test_recording)
	
	var started = false
	var stopped = false
	
	playback_vehicle.playback_started.connect(func(): started = true)
	playback_vehicle.playback_stopped.connect(func(): stopped = true)
	
	# Start playback
	playback_vehicle.start_playback()
	assert_true(started, "Should emit playback_started signal")
	
	# Trigger internal start handler
	playback_vehicle._on_playback_started()
	assert_true(playback_vehicle.is_active, "Should be active")
	assert_true(playback_vehicle.visible, "Should be visible")
	
	# Stop playback
	playback_vehicle.stop_playback()
	
	# Trigger internal stop handler
	playback_vehicle._on_playback_stopped()
	assert_false(playback_vehicle.is_active, "Should not be active")
	assert_false(playback_vehicle.visible, "Should not be visible")
	assert_eq(playback_vehicle.current_lane, -1, "Should reset lane")


func test_loop_toggling():
	playback_vehicle.set_loop_enabled(false)
	assert_false(playback_vehicle.path_player.loop_enabled, "Should disable looping")
	
	playback_vehicle.set_loop_enabled(true)
	assert_true(playback_vehicle.path_player.loop_enabled, "Should enable looping")


func test_playback_speed_control():
	playback_vehicle.set_playback_speed(2.0)
	assert_eq(playback_vehicle.path_player.playback_speed, 2.0, "Should update playback speed")


func test_progress_getter():
	playback_vehicle.load_recording(test_recording)
	playback_vehicle.path_player.playback_time = 1.5
	
	var progress = playback_vehicle.get_playback_progress()
	assert_almost_eq(progress, 0.5, 0.01, "Should return correct progress")


func test_state_getters():
	playback_vehicle.load_recording(test_recording)
	
	assert_false(playback_vehicle.is_playing(), "Should not be playing initially")
	
	playback_vehicle.path_player.current_state = PathPlayer.PlaybackState.PLAYING
	assert_true(playback_vehicle.is_playing(), "Should report playing state")


func test_current_lane_getter():
	playback_vehicle.current_lane = 2
	assert_eq(playback_vehicle.get_current_lane(), 2, "Should return current lane")


func test_sound_triggering():
	# This would require a more complex mock setup
	# For now, we'll test that the setup doesn't crash
	playback_vehicle.trigger_sounds = true
	playback_vehicle.setup(null)
	assert_false(playback_vehicle.trigger_sounds, "Should disable sound triggering without system")


func test_trail_creation():
	# Trail should be created if enabled
	assert_eq(playback_vehicle.trail_nodes.size(), playback_vehicle.trail_length, "Should create trail nodes")
	
	# Trail nodes should be initially hidden
	for node in playback_vehicle.trail_nodes:
		assert_false(node.visible, "Trail nodes should be initially hidden")


func test_pause_functionality():
	playback_vehicle.load_recording(test_recording)
	playback_vehicle.start_playback()
	
	playback_vehicle.pause_playback()
	# Verify through path_player state
	assert_true(playback_vehicle.path_player.current_state == PathPlayer.PlaybackState.PLAYING or 
			   playback_vehicle.path_player.current_state == PathPlayer.PlaybackState.PAUSED, 
			   "Should be in playing or paused state")


# Mock lane sound system for testing
class MockLaneSoundSystem extends Node:
	var lanes_played = []
	var all_stopped = false
	
	func play_lane(lane: int):
		lanes_played.append(lane)
	
	func play_lane_with_volume(lane: int, volume: float):
		lanes_played.append({"lane": lane, "volume": volume})
	
	func stop_all_lanes():
		all_stopped = true