extends GutTest

# Unit tests for PathPlayer component

var path_player: PathPlayer
var test_recording: LapRecorder.LapRecording


func before_each():
	path_player = PathPlayer.new()
	add_child_autofree(path_player)
	
	# Create a test recording with sample data
	test_recording = _create_test_recording()


func _create_test_recording() -> LapRecorder.LapRecording:
	var recording = LapRecorder.LapRecording.new()
	recording.start_time = 0.0
	recording.end_time = 5.0
	recording.duration = 5.0
	recording.bpm = 120.0
	recording.is_valid = true
	recording.is_complete_lap = true
	
	# Add position samples at 1 second intervals
	for i in range(6):
		var sample = LapRecorder.PositionSample.new()
		sample.timestamp = float(i)
		sample.position = Vector2(i * 100, 0)
		sample.rotation = i * PI / 5
		sample.lane = i % 3
		sample.velocity = Vector2(100, 0)
		sample.beat_number = i * 2
		sample.beat_progress = 0.0
		recording.position_samples.append(sample)
	
	recording.total_samples = recording.position_samples.size()
	return recording


func test_path_player_initialization():
	assert_not_null(path_player, "PathPlayer should be created")
	assert_eq(path_player.current_state, PathPlayer.PlaybackState.STOPPED, "Should start in stopped state")
	assert_eq(path_player.playback_speed, 1.0, "Default playback speed should be 1.0")
	assert_true(path_player.loop_enabled, "Loop should be enabled by default")


func test_load_recording_valid():
	var result = path_player.load_recording(test_recording)
	assert_true(result, "Should successfully load valid recording")
	assert_eq(path_player.current_recording, test_recording, "Recording should be set")
	assert_eq(path_player.playback_time, 0.0, "Playback time should reset")
	assert_eq(path_player.loop_count, 0, "Loop count should reset")


func test_load_recording_invalid():
	var empty_recording = LapRecorder.LapRecording.new()
	var result = path_player.load_recording(empty_recording)
	assert_false(result, "Should fail to load empty recording")
	
	result = path_player.load_recording(null)
	assert_false(result, "Should fail to load null recording")


func test_start_playback_without_recording():
	path_player.start_playback()
	assert_eq(path_player.current_state, PathPlayer.PlaybackState.STOPPED, "Should remain stopped without recording")


func test_start_playback_with_recording():
	# Disable beat sync for immediate start
	path_player.sync_to_beat = false
	path_player.load_recording(test_recording)
	
	var signal_emitted = false
	path_player.playback_started.connect(func(): signal_emitted = true)
	
	path_player.start_playback()
	assert_eq(path_player.current_state, PathPlayer.PlaybackState.PLAYING, "Should be in playing state")
	assert_true(signal_emitted, "Should emit playback_started signal")


func test_pause_resume_playback():
	path_player.sync_to_beat = false
	path_player.load_recording(test_recording)
	path_player.start_playback()
	
	# Test pause
	var pause_signal = false
	path_player.playback_paused.connect(func(): pause_signal = true)
	
	path_player.pause_playback()
	assert_eq(path_player.current_state, PathPlayer.PlaybackState.PAUSED, "Should be paused")
	assert_true(pause_signal, "Should emit playback_paused signal")
	
	# Test resume
	var resume_signal = false
	path_player.playback_resumed.connect(func(): resume_signal = true)
	
	path_player.start_playback()  # Resume
	assert_eq(path_player.current_state, PathPlayer.PlaybackState.PLAYING, "Should be playing again")
	assert_true(resume_signal, "Should emit playback_resumed signal")


func test_stop_playback():
	path_player.sync_to_beat = false
	path_player.load_recording(test_recording)
	path_player.start_playback()
	
	var stop_signal = false
	path_player.playback_stopped.connect(func(): stop_signal = true)
	
	path_player.stop_playback()
	assert_eq(path_player.current_state, PathPlayer.PlaybackState.STOPPED, "Should be stopped")
	assert_eq(path_player.playback_time, 0.0, "Playback time should reset")
	assert_true(stop_signal, "Should emit playback_stopped signal")


func test_interpolation_linear():
	path_player.interpolation_mode = PathPlayer.InterpolationMode.LINEAR
	path_player.load_recording(test_recording)
	
	# Test interpolation at t=2.5 (between samples at t=2 and t=3)
	var sample = path_player._get_interpolated_sample(2.5)
	assert_not_null(sample, "Should return interpolated sample")
	assert_almost_eq(sample.position.x, 250.0, 1.0, "Position should be interpolated")
	assert_eq(sample.lane, 2, "Lane should use nearest (t < 0.5)")


func test_interpolation_nearest():
	path_player.interpolation_mode = PathPlayer.InterpolationMode.NEAREST
	path_player.load_recording(test_recording)
	
	var sample = path_player._get_interpolated_sample(2.3)
	assert_eq(sample.position.x, 200.0, "Should use previous sample position")
	
	sample = path_player._get_interpolated_sample(2.7)
	assert_eq(sample.position.x, 300.0, "Should use next sample position")


func test_playback_progress():
	path_player.load_recording(test_recording)
	path_player.playback_time = 2.5
	
	var progress = path_player.get_playback_progress()
	assert_almost_eq(progress, 0.5, 0.01, "Progress should be 50% at 2.5s of 5s recording")


func test_seek_functionality():
	path_player.load_recording(test_recording)
	
	path_player.set_playback_time(3.0)
	assert_eq(path_player.playback_time, 3.0, "Should seek to specified time")
	
	path_player.set_playback_time(10.0)
	assert_eq(path_player.playback_time, 5.0, "Should clamp to recording duration")
	
	path_player.set_playback_time(-1.0)
	assert_eq(path_player.playback_time, 0.0, "Should clamp to 0")


func test_position_update_signal():
	path_player.sync_to_beat = false
	path_player.load_recording(test_recording)
	
	var position_updated = false
	var updated_position: Vector2
	var updated_rotation: float
	var updated_lane: int
	
	path_player.position_updated.connect(func(pos, rot, lane):
		position_updated = true
		updated_position = pos
		updated_rotation = rot
		updated_lane = lane
	)
	
	path_player.start_playback()
	
	# Simulate frame update
	path_player._process(0.5)
	
	assert_true(position_updated, "Should emit position_updated signal")
	assert_ne(updated_position, Vector2.ZERO, "Should have non-zero position")


func test_loop_completion():
	path_player.sync_to_beat = false
	path_player.loop_enabled = true
	path_player.load_recording(test_recording)
	
	var loop_completed = false
	var loop_count_received = 0
	
	path_player.loop_completed.connect(func(count):
		loop_completed = true
		loop_count_received = count
	)
	
	path_player.start_playback()
	path_player.playback_time = 4.9  # Near end
	
	# Process past the end
	path_player._process(0.2)
	
	assert_true(loop_completed, "Should emit loop_completed signal")
	assert_eq(loop_count_received, 1, "Should report correct loop count")
	assert_eq(path_player.playback_time, 0.1, "Should wrap playback time")


func test_playback_completion_no_loop():
	path_player.sync_to_beat = false
	path_player.loop_enabled = false
	path_player.load_recording(test_recording)
	
	var playback_completed = false
	path_player.playback_completed.connect(func(): playback_completed = true)
	
	path_player.start_playback()
	path_player.playback_time = 4.9
	
	# Process past the end
	path_player._process(0.2)
	
	assert_true(playback_completed, "Should emit playback_completed signal")
	assert_eq(path_player.current_state, PathPlayer.PlaybackState.STOPPED, "Should stop playback")


func test_playback_speed():
	path_player.sync_to_beat = false
	path_player.playback_speed = 2.0
	path_player.load_recording(test_recording)
	path_player.start_playback()
	
	var initial_time = path_player.playback_time
	path_player._process(1.0)
	
	assert_almost_eq(path_player.playback_time - initial_time, 2.0, 0.01, "Should advance at 2x speed")


func test_max_loops():
	path_player.sync_to_beat = false
	path_player.loop_enabled = true
	path_player.max_loops = 2
	path_player.load_recording(test_recording)
	
	var completed = false
	path_player.playback_completed.connect(func(): completed = true)
	
	path_player.start_playback()
	
	# First loop
	path_player.playback_time = 4.9
	path_player._process(0.2)
	assert_false(completed, "Should not complete after first loop")
	
	# Second loop
	path_player.playback_time = 4.9
	path_player._process(0.2)
	assert_true(completed, "Should complete after max loops")


func test_current_position_getter():
	path_player.load_recording(test_recording)
	path_player.playback_time = 2.0
	
	var pos = path_player.get_current_position()
	assert_eq(pos, Vector2(200, 0), "Should return correct position")


func test_current_lane_getter():
	path_player.load_recording(test_recording)
	path_player.playback_time = 3.0
	
	var lane = path_player.get_current_lane()
	assert_eq(lane, 0, "Should return correct lane (3 % 3 = 0)")


func test_state_getters():
	path_player.sync_to_beat = false
	path_player.load_recording(test_recording)
	
	assert_false(path_player.is_playing(), "Should not be playing initially")
	assert_false(path_player.is_paused(), "Should not be paused initially")
	
	path_player.start_playback()
	assert_true(path_player.is_playing(), "Should be playing")
	assert_false(path_player.is_paused(), "Should not be paused")
	
	path_player.pause_playback()
	assert_false(path_player.is_playing(), "Should not be playing when paused")
	assert_true(path_player.is_paused(), "Should be paused")