extends GutTest

# Integration tests for lap recording system
# Tests complete flow with vehicle, track, and lane detection

var test_scene_helpers
var track_system: Node2D  # TrackSystem
var vehicle: Node2D  # RhythmVehicleWithLanes
var lane_detection: LaneDetectionSystem
var lap_recorder: LapRecorder
var recording_indicator: RecordingIndicator


func before_all():
	test_scene_helpers = load("res://scenes/test/test_scene_helpers.gd").new()
	
	# Initialize autoloads if needed
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
	
	# Create lap recorder
	lap_recorder = LapRecorder.new()
	lap_recorder.sample_rate = 20.0  # Lower for testing
	add_child(lap_recorder)
	
	# Create recording indicator
	recording_indicator = RecordingIndicator.new()
	add_child(recording_indicator)
	
	await wait_frames(2)
	
	# Setup systems
	lap_recorder.setup(vehicle, lane_detection, track_system)
	recording_indicator.setup(lap_recorder)


func after_each():
	if recording_indicator:
		recording_indicator.queue_free()
	if lap_recorder:
		lap_recorder.stop_recording() if lap_recorder.is_recording else null
		lap_recorder.queue_free()
	if lane_detection:
		lane_detection.queue_free()
	if vehicle:
		vehicle.queue_free()
	if track_system:
		track_system.queue_free()
	
	await wait_frames(2)


func test_full_recording_flow():
	gut.p("Testing complete recording flow")
	
	# Start recording
	lap_recorder.start_recording()
	assert_true(lap_recorder.is_recording)
	
	# Move vehicle along track
	for i in range(5):
		vehicle.position.x += 50
		vehicle.position.y += 20
		await wait_frames(5)
	
	# Stop recording
	var recording = lap_recorder.stop_recording()
	
	assert_not_null(recording)
	assert_gt(recording.total_samples, 0)
	assert_gt(recording.duration, 0.0)
	assert_true(recording.is_valid)
	
	gut.p("Recording completed with %d samples over %.2fs" % [recording.total_samples, recording.duration])


func test_lane_data_recording():
	gut.p("Testing lane data is recorded correctly")
	
	# Position vehicle in specific lane
	var lane_center = track_system.get_lane_center_position(0)
	vehicle.position = lane_center
	await wait_frames(2)
	
	# Start recording
	lap_recorder.start_recording()
	
	# Wait for samples
	await get_tree().create_timer(0.5).timeout
	
	# Move to different lane
	lane_center = track_system.get_lane_center_position(2)
	vehicle.position = lane_center
	await wait_frames(5)
	
	# Stop and check
	var recording = lap_recorder.stop_recording()
	
	# Verify lane data captured
	var found_lane_0 = false
	var found_lane_2 = false
	
	for sample in recording.position_samples:
		if sample.lane == 0:
			found_lane_0 = true
		elif sample.lane == 2:
			found_lane_2 = true
	
	assert_true(found_lane_0, "Should have samples in lane 0")
	assert_true(found_lane_2, "Should have samples in lane 2")


func test_beat_alignment_recording():
	gut.p("Testing beat alignment data recording")
	
	# Start beat manager
	BeatManager.set_bpm(120)
	BeatManager.start_beat()
	
	# Start recording
	lap_recorder.start_recording()
	
	# Wait for a few beats
	await wait_for_signal(BeatManager.beat_occurred, 3.0)
	
	var recording = lap_recorder.stop_recording()
	
	# Check beat data
	assert_eq(recording.bpm, 120.0)
	assert_gt(recording.start_beat, 0)
	
	# Verify samples have beat data
	var has_beat_data = false
	for sample in recording.position_samples:
		if sample.beat_number > 0:
			has_beat_data = true
			break
	
	assert_true(has_beat_data, "Samples should contain beat data")
	
	BeatManager.stop_beat()


func test_recording_indicator_integration():
	gut.p("Testing recording indicator responds to recorder")
	
	# Watch indicator signals
	watch_signals(recording_indicator)
	
	# Start recording through indicator
	recording_indicator.start_recording()
	
	assert_true(lap_recorder.is_recording)
	assert_true(recording_indicator.is_recording)
	
	# Wait for some samples
	await get_tree().create_timer(0.3).timeout
	
	# Stop through indicator
	recording_indicator.stop_recording()
	
	assert_false(lap_recorder.is_recording)
	assert_false(recording_indicator.is_recording)


func test_lap_completion_detection():
	gut.p("Testing lap completion detection")
	
	# This test would require a full lap simulation
	# For now, test the signal mechanism
	
	watch_signals(lap_recorder)
	
	lap_recorder.start_recording()
	
	# Simulate lap completion
	if track_system.has_signal("lap_completed"):
		track_system.emit_signal("lap_completed")
		
		assert_signal_emitted(lap_recorder, "lap_completed")
		assert_false(lap_recorder.is_recording, "Recording should stop on lap completion")


func test_velocity_and_rotation_recording():
	gut.p("Testing velocity and rotation data recording")
	
	# Configure recorder
	lap_recorder.store_velocity = true
	lap_recorder.store_rotation = true
	
	# Start recording
	lap_recorder.start_recording()
	
	# Apply velocity and rotation
	vehicle.linear_velocity = Vector2(100, 50)
	vehicle.rotation = PI / 3
	
	await get_tree().create_timer(0.2).timeout
	
	var recording = lap_recorder.stop_recording()
	
	# Check data
	var has_velocity = false
	var has_rotation = false
	
	for sample in recording.position_samples:
		if sample.velocity.length() > 0:
			has_velocity = true
		if abs(sample.rotation) > 0:
			has_rotation = true
	
	assert_true(has_velocity, "Should record velocity data")
	assert_true(has_rotation, "Should record rotation data")


func test_sample_rate_accuracy():
	gut.p("Testing sample rate accuracy")
	
	# Set specific sample rate
	lap_recorder.sample_rate = 10.0  # 10 samples per second
	
	lap_recorder.start_recording()
	
	# Record for exactly 1 second
	await get_tree().create_timer(1.0).timeout
	
	var recording = lap_recorder.stop_recording()
	
	# Should have approximately 10 samples (±1 for timing)
	assert_between(recording.position_samples.size(), 9, 11,
		"Should have ~10 samples at 10Hz for 1 second")


func test_recording_metadata():
	gut.p("Testing recording metadata")
	
	# Setup beat manager state
	BeatManager.set_bpm(140)
	BeatManager.beats_per_measure = 3
	BeatManager.start_beat()
	
	await wait_frames(5)
	
	# Start recording
	lap_recorder.start_recording()
	await get_tree().create_timer(0.5).timeout
	var recording = lap_recorder.stop_recording()
	
	# Verify metadata
	assert_eq(recording.bpm, 140.0)
	assert_eq(recording.beats_per_measure, 3)
	assert_gt(recording.start_time, 0.0)
	assert_gt(recording.end_time, recording.start_time)
	assert_almost_eq(recording.duration, recording.end_time - recording.start_time, 0.01)
	
	BeatManager.stop_beat()


func test_sample_interpolation():
	gut.p("Testing sample interpolation in recordings")
	
	lap_recorder.sample_rate = 5.0  # Low rate to test interpolation
	
	lap_recorder.start_recording()
	
	# Move vehicle smoothly
	for i in range(10):
		vehicle.position.x = i * 10
		await wait_frames(2)
	
	var recording = lap_recorder.stop_recording()
	
	# Test interpolation at various times
	var sample_at_half = recording.get_sample_at_time(recording.duration * 0.5)
	assert_not_null(sample_at_half)
	
	# Position should be somewhere in the middle of the movement
	assert_gt(sample_at_half.position.x, 20)
	assert_lt(sample_at_half.position.x, 80)


func test_concurrent_recordings_prevention():
	gut.p("Testing prevention of concurrent recordings")
	
	# Start first recording
	lap_recorder.start_recording()
	assert_true(lap_recorder.is_recording)
	
	# Try to start another
	lap_recorder.start_recording()
	
	# Should still be recording the first one
	assert_true(lap_recorder.is_recording)
	assert_eq(lap_recorder.get_sample_count(), 1)  # Only initial sample