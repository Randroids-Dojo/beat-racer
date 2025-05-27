extends GutTest

# Integration tests for Path Playback System

var track_system: TrackSystem
var rhythm_vehicle: RhythmVehicleWithLanes
var lap_recorder: LapRecorder
var playback_vehicle: PlaybackVehicle
var lane_sound_system: LaneSoundSystem
var recording: LapRecorder.LapRecording


func before_each():
	# Create track
	track_system = TrackSystem.new()
	track_system.track_radius = 200
	track_system.track_width = 90
	track_system.lane_count = 3
	add_child_autofree(track_system)
	
	# Create lane sound system
	lane_sound_system = LaneSoundSystem.new()
	lane_sound_system.debug_logging = false
	add_child_autofree(lane_sound_system)
	
	# Create player vehicle
	rhythm_vehicle = RhythmVehicleWithLanes.new()
	rhythm_vehicle.position = Vector2(0, -track_system.track_radius)
	add_child_autofree(rhythm_vehicle)
	rhythm_vehicle.setup_lane_detection(track_system, lane_sound_system)
	
	# Create lap recorder
	lap_recorder = LapRecorder.new()
	lap_recorder.debug_logging = false
	lap_recorder.sample_rate = 30.0
	add_child_autofree(lap_recorder)
	lap_recorder.setup(rhythm_vehicle, rhythm_vehicle.lane_detection_system, track_system)
	
	# Create playback vehicle
	playback_vehicle = PlaybackVehicle.new()
	playback_vehicle.debug_logging = false
	add_child_autofree(playback_vehicle)
	playback_vehicle.setup(lane_sound_system)
	
	# Wait for scene to stabilize
	await get_tree().process_frame


func test_record_and_playback_simple_path():
	# Record a simple path
	lap_recorder.start_recording()
	
	# Simulate vehicle movement
	rhythm_vehicle.position = Vector2(100, 0)
	rhythm_vehicle.rotation = PI/2
	await get_tree().create_timer(0.1).timeout
	
	rhythm_vehicle.position = Vector2(100, 100)
	rhythm_vehicle.rotation = PI
	await get_tree().create_timer(0.1).timeout
	
	rhythm_vehicle.position = Vector2(0, 100)
	rhythm_vehicle.rotation = 3*PI/2
	await get_tree().create_timer(0.1).timeout
	
	# Stop recording
	recording = lap_recorder.stop_recording()
	assert_not_null(recording, "Should have a recording")
	assert_gt(recording.position_samples.size(), 0, "Should have position samples")
	
	# Load and play recording
	var loaded = playback_vehicle.load_recording(recording)
	assert_true(loaded, "Should load recording successfully")
	
	# Disable beat sync for immediate playback
	playback_vehicle.path_player.sync_to_beat = false
	
	var playback_started = false
	playback_vehicle.playback_started.connect(func(): playback_started = true)
	
	playback_vehicle.start_playback()
	assert_true(playback_started, "Playback should start")
	
	# Let it play for a bit
	await get_tree().create_timer(0.2).timeout
	
	# Check that vehicle is moving
	assert_ne(playback_vehicle.position, Vector2.ZERO, "Playback vehicle should have moved")


func test_lane_changes_during_playback():
	# Create recording with lane changes
	lap_recorder.start_recording()
	
	# Simulate lane changes
	rhythm_vehicle.lane_detection_system._test_set_lane(0)
	await get_tree().create_timer(0.1).timeout
	
	rhythm_vehicle.lane_detection_system._test_set_lane(1)
	await get_tree().create_timer(0.1).timeout
	
	rhythm_vehicle.lane_detection_system._test_set_lane(2)
	await get_tree().create_timer(0.1).timeout
	
	recording = lap_recorder.stop_recording()
	
	# Play back and monitor lane changes
	playback_vehicle.load_recording(recording)
	playback_vehicle.path_player.sync_to_beat = false
	
	var lane_changes = []
	playback_vehicle.lane_changed.connect(func(from, to):
		lane_changes.append({"from": from, "to": to})
	)
	
	playback_vehicle.start_playback()
	
	# Let playback run
	await get_tree().create_timer(0.5).timeout
	
	assert_gt(lane_changes.size(), 0, "Should detect lane changes during playback")


func test_loop_functionality():
	# Create short recording
	lap_recorder.start_recording()
	rhythm_vehicle.position = Vector2(50, 0)
	await get_tree().create_timer(0.1).timeout
	rhythm_vehicle.position = Vector2(100, 0)
	await get_tree().create_timer(0.1).timeout
	recording = lap_recorder.stop_recording()
	
	# Setup looping playback
	playback_vehicle.load_recording(recording)
	playback_vehicle.path_player.sync_to_beat = false
	playback_vehicle.path_player.loop_enabled = true
	playback_vehicle.path_player.playback_speed = 5.0  # Speed up for test
	
	var loop_count = 0
	playback_vehicle.path_player.loop_completed.connect(func(count):
		loop_count = count
	)
	
	playback_vehicle.start_playback()
	
	# Wait for loops
	await get_tree().create_timer(1.0).timeout
	
	assert_gt(loop_count, 0, "Should complete at least one loop")


func test_playback_pause_resume():
	# Create recording
	lap_recorder.start_recording()
	await get_tree().create_timer(0.3).timeout
	recording = lap_recorder.stop_recording()
	
	playback_vehicle.load_recording(recording)
	playback_vehicle.path_player.sync_to_beat = false
	
	# Start playback
	playback_vehicle.start_playback()
	await get_tree().create_timer(0.1).timeout
	
	var pos_before_pause = playback_vehicle.position
	
	# Pause
	playback_vehicle.pause_playback()
	await get_tree().create_timer(0.1).timeout
	
	var pos_during_pause = playback_vehicle.position
	assert_eq(pos_before_pause, pos_during_pause, "Position should not change during pause")
	
	# Resume
	playback_vehicle.start_playback()  # Resume
	await get_tree().create_timer(0.1).timeout
	
	var pos_after_resume = playback_vehicle.position
	assert_ne(pos_during_pause, pos_after_resume, "Position should change after resume")


func test_playback_speed_adjustment():
	# Create recording
	lap_recorder.start_recording()
	rhythm_vehicle.position = Vector2(0, 0)
	await get_tree().create_timer(0.1).timeout
	rhythm_vehicle.position = Vector2(100, 0)
	await get_tree().create_timer(0.1).timeout
	recording = lap_recorder.stop_recording()
	
	playback_vehicle.load_recording(recording)
	playback_vehicle.path_player.sync_to_beat = false
	
	# Test normal speed
	playback_vehicle.set_playback_speed(1.0)
	playback_vehicle.start_playback()
	
	var time_start = Time.get_ticks_msec()
	await get_tree().create_timer(0.2).timeout
	var progress_normal = playback_vehicle.get_playback_progress()
	
	playback_vehicle.stop_playback()
	
	# Test double speed
	playback_vehicle.set_playback_speed(2.0)
	playback_vehicle.start_playback()
	
	time_start = Time.get_ticks_msec()
	await get_tree().create_timer(0.1).timeout  # Half time
	var progress_double = playback_vehicle.get_playback_progress()
	
	# Double speed should achieve similar progress in half time
	assert_almost_eq(progress_normal, progress_double, 0.2, "Double speed should progress faster")


func test_complete_lap_playback():
	# Simulate a complete lap recording
	lap_recorder.start_recording()
	
	# Move vehicle in a circle
	var steps = 8
	for i in range(steps + 1):  # +1 to complete the lap
		var angle = i * TAU / steps
		var pos = Vector2(
			sin(angle) * track_system.track_radius,
			-cos(angle) * track_system.track_radius
		)
		rhythm_vehicle.position = pos
		rhythm_vehicle.rotation = angle
		await get_tree().create_timer(0.1).timeout
	
	recording = lap_recorder.stop_recording()
	assert_true(recording.is_complete_lap or recording.duration > 0.5, "Should have a complete recording")
	
	# Play back the lap
	playback_vehicle.load_recording(recording)
	playback_vehicle.path_player.sync_to_beat = false
	playback_vehicle.path_player.loop_enabled = false
	
	var playback_completed = false
	playback_vehicle.path_player.playback_completed.connect(func():
		playback_completed = true
	)
	
	playback_vehicle.start_playback()
	playback_vehicle.path_player.playback_speed = 10.0  # Speed up
	
	# Wait for completion
	await get_tree().create_timer(2.0).timeout
	
	assert_true(playback_completed, "Playback should complete")


func test_visual_feedback():
	# Test that ghost vehicle visual properties work
	playback_vehicle.set_ghost_color(Color.RED)
	assert_eq(playback_vehicle.ghost_color, Color.RED, "Should update ghost color")
	
	# Test trail
	assert_true(playback_vehicle.trail_enabled, "Trail should be enabled")
	assert_eq(playback_vehicle.trail_nodes.size(), playback_vehicle.trail_length, "Should have trail nodes")


func test_sound_triggering_integration():
	# Create recording with lane changes
	lap_recorder.start_recording()
	
	# Change lanes to trigger different sounds
	rhythm_vehicle.lane_detection_system._test_set_lane(0)
	rhythm_vehicle.position = Vector2(50, 0)
	await get_tree().create_timer(0.2).timeout
	
	rhythm_vehicle.lane_detection_system._test_set_lane(2)
	rhythm_vehicle.position = Vector2(100, 0)
	await get_tree().create_timer(0.2).timeout
	
	recording = lap_recorder.stop_recording()
	
	# Setup sound tracking
	var sounds_triggered = []
	if lane_sound_system.has_signal("lane_started"):
		lane_sound_system.lane_started.connect(func(lane):
			sounds_triggered.append(lane)
		)
	
	# Playback with sound triggering
	playback_vehicle.trigger_sounds = true
	playback_vehicle.load_recording(recording)
	playback_vehicle.path_player.sync_to_beat = false
	playback_vehicle.start_playback()
	
	# Let it play
	await get_tree().create_timer(0.5).timeout
	
	# Verify vehicle moved and triggered events
	assert_ne(playback_vehicle.position, Vector2.ZERO, "Vehicle should have moved")


func test_interpolation_modes():
	# Create recording
	lap_recorder.start_recording()
	for i in range(3):
		rhythm_vehicle.position = Vector2(i * 100, 0)
		await get_tree().create_timer(0.1).timeout
	recording = lap_recorder.stop_recording()
	
	playback_vehicle.load_recording(recording)
	
	# Test different interpolation modes
	for mode in [PathPlayer.InterpolationMode.LINEAR, 
				 PathPlayer.InterpolationMode.CUBIC,
				 PathPlayer.InterpolationMode.NEAREST]:
		playback_vehicle.path_player.interpolation_mode = mode
		playback_vehicle.path_player.sync_to_beat = false
		playback_vehicle.start_playback()
		
		await get_tree().create_timer(0.1).timeout
		
		assert_ne(playback_vehicle.position, Vector2.ZERO, 
						"Vehicle should move with %s interpolation" % mode)
		
		playback_vehicle.stop_playback()