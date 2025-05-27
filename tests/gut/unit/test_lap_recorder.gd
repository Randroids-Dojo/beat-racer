extends GutTest

# Unit tests for LapRecorder

var lap_recorder: LapRecorder
var mock_vehicle: Node2D
var mock_lane_detection: LaneDetectionSystem
var mock_track: Node2D


func before_each():
	# Create recorder
	lap_recorder = LapRecorder.new()
	add_child(lap_recorder)
	
	# Create mock vehicle
	mock_vehicle = Node2D.new()
	mock_vehicle.name = "MockVehicle"
	add_child(mock_vehicle)
	
	# Create mock systems
	mock_lane_detection = LaneDetectionSystem.new()
	mock_track = Node2D.new()
	add_child(mock_lane_detection)
	add_child(mock_track)
	
	await wait_frames(1)


func after_each():
	if lap_recorder:
		lap_recorder.queue_free()
	if mock_vehicle:
		mock_vehicle.queue_free()
	if mock_lane_detection:
		mock_lane_detection.queue_free()
	if mock_track:
		mock_track.queue_free()
	
	await wait_frames(1)


func test_initialization():
	assert_not_null(lap_recorder)
	assert_false(lap_recorder.is_recording)
	assert_eq(lap_recorder.sample_rate, 30.0)
	assert_eq(lap_recorder.min_lap_time, 5.0)
	assert_true(lap_recorder.store_velocity)
	assert_true(lap_recorder.store_rotation)


func test_setup():
	lap_recorder.setup(mock_vehicle, mock_lane_detection, mock_track)
	
	assert_eq(lap_recorder.vehicle_reference, mock_vehicle)
	assert_eq(lap_recorder.lane_detection_system, mock_lane_detection)
	assert_eq(lap_recorder.track_system, mock_track)


func test_start_recording():
	lap_recorder.setup(mock_vehicle, mock_lane_detection, mock_track)
	
	watch_signals(lap_recorder)
	
	lap_recorder.start_recording()
	
	assert_true(lap_recorder.is_recording)
	assert_not_null(lap_recorder.current_recording)
	assert_signal_emitted(lap_recorder, "recording_started")
	assert_signal_emitted(lap_recorder, "recording_state_changed", [true])


func test_stop_recording():
	lap_recorder.setup(mock_vehicle, mock_lane_detection, mock_track)
	lap_recorder.start_recording()
	
	await wait_frames(10)  # Let some samples accumulate
	
	watch_signals(lap_recorder)
	
	var recording = lap_recorder.stop_recording()
	
	assert_false(lap_recorder.is_recording)
	assert_not_null(recording)
	assert_gt(recording.total_samples, 0)
	assert_gt(recording.duration, 0.0)
	assert_signal_emitted(lap_recorder, "recording_stopped")
	assert_signal_emitted(lap_recorder, "recording_state_changed", [false])


func test_position_sampling():
	lap_recorder.setup(mock_vehicle, mock_lane_detection, mock_track)
	lap_recorder.sample_rate = 10.0  # Lower rate for testing
	
	watch_signals(lap_recorder)
	
	lap_recorder.start_recording()
	
	# Move vehicle
	mock_vehicle.position = Vector2(100, 200)
	mock_vehicle.rotation = PI / 4
	
	# Process for sampling
	await wait_for_signal(lap_recorder.position_sampled, 1.0)
	
	assert_signal_emitted(lap_recorder, "position_sampled")
	
	var recording = lap_recorder.stop_recording()
	assert_gt(recording.position_samples.size(), 0)
	
	var sample = recording.position_samples[0]
	assert_eq(sample.position, Vector2(100, 200))
	assert_eq(sample.rotation, PI / 4)


func test_sample_rate_control():
	lap_recorder.setup(mock_vehicle, mock_lane_detection, mock_track)
	lap_recorder.sample_rate = 5.0  # 5 samples per second
	
	lap_recorder.start_recording()
	
	# Wait for approximately 1 second
	await get_tree().create_timer(1.0).timeout
	
	var recording = lap_recorder.stop_recording()
	
	# Should have approximately 5 samples (±1 for timing variance)
	assert_between(recording.position_samples.size(), 4, 6)


func test_recording_validation():
	lap_recorder.setup(mock_vehicle, mock_lane_detection, mock_track)
	lap_recorder.min_lap_time = 2.0
	
	# Start and immediately stop (too short)
	lap_recorder.start_recording()
	await wait_frames(5)
	
	var recording = lap_recorder.stop_recording()
	
	assert_false(recording.is_valid)  # Too short


func test_pause_resume_recording():
	lap_recorder.setup(mock_vehicle, mock_lane_detection, mock_track)
	
	lap_recorder.start_recording()
	assert_true(lap_recorder.is_recording)
	
	lap_recorder.pause_recording()
	assert_false(lap_recorder.is_recording)
	assert_not_null(lap_recorder.current_recording)
	
	lap_recorder.resume_recording()
	assert_true(lap_recorder.is_recording)


func test_cancel_recording():
	lap_recorder.setup(mock_vehicle, mock_lane_detection, mock_track)
	
	watch_signals(lap_recorder)
	
	lap_recorder.start_recording()
	lap_recorder.cancel_recording()
	
	assert_false(lap_recorder.is_recording)
	assert_null(lap_recorder.current_recording)
	assert_signal_emitted(lap_recorder, "recording_stopped")


func test_recording_duration():
	lap_recorder.setup(mock_vehicle, mock_lane_detection, mock_track)
	
	lap_recorder.start_recording()
	
	await get_tree().create_timer(0.5).timeout
	
	var duration = lap_recorder.get_recording_duration()
	assert_almost_eq(duration, 0.5, 0.1)


func test_sample_count():
	lap_recorder.setup(mock_vehicle, mock_lane_detection, mock_track)
	lap_recorder.sample_rate = 10.0
	
	lap_recorder.start_recording()
	
	await get_tree().create_timer(0.5).timeout
	
	var count = lap_recorder.get_sample_count()
	assert_between(count, 4, 6)  # ~5 samples at 10Hz for 0.5s


func test_lap_recording_resource():
	var recording = LapRecorder.LapRecording.new()
	
	# Add some test samples
	for i in range(3):
		var sample = LapRecorder.PositionSample.new()
		sample.timestamp = i * 0.1
		sample.position = Vector2(i * 100, 0)
		recording.position_samples.append(sample)
	
	# Test sample retrieval
	var sample_at_0_15 = recording.get_sample_at_time(0.15)
	assert_not_null(sample_at_0_15)
	assert_almost_eq(sample_at_0_15.timestamp, 0.15, 0.01)
	assert_almost_eq(sample_at_0_15.position.x, 150.0, 1.0)  # Interpolated


func test_position_sample_interpolation():
	var sample_a = LapRecorder.PositionSample.new()
	sample_a.timestamp = 0.0
	sample_a.position = Vector2(0, 0)
	sample_a.rotation = 0.0
	sample_a.lane = 0
	
	var sample_b = LapRecorder.PositionSample.new()
	sample_b.timestamp = 1.0
	sample_b.position = Vector2(100, 100)
	sample_b.rotation = PI
	sample_b.lane = 2
	
	var interpolated = LapRecorder.PositionSample.interpolate(sample_a, sample_b, 0.5)
	
	assert_almost_eq(interpolated.timestamp, 0.5, 0.01)
	assert_almost_eq(interpolated.position.x, 50.0, 1.0)
	assert_almost_eq(interpolated.position.y, 50.0, 1.0)
	assert_eq(interpolated.lane, 0)  # Uses first value at t=0.5


func test_max_recording_time():
	lap_recorder.setup(mock_vehicle, mock_lane_detection, mock_track)
	lap_recorder.max_recording_time = 0.5  # Very short for testing
	
	watch_signals(lap_recorder)
	
	lap_recorder.start_recording()
	
	# Wait for timeout
	await wait_for_signal(lap_recorder.recording_stopped, 1.0)
	
	assert_false(lap_recorder.is_recording)
	assert_signal_emitted(lap_recorder, "recording_stopped")