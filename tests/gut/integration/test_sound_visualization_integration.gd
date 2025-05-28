extends GutTest
# Integration tests for Sound Visualization System

# Components
var _beat_manager: BeatManager
var _lane_sound_system: LaneSoundSystem
var _rhythm_vehicle: RhythmVehicleWithLanes
var _track_system: TrackSystem

# Visual components
var _beat_pulse_visualizer: BeatPulseVisualizer
var _lane_sound_visualizer: LaneSoundVisualizer
var _sound_reactive_trail: SoundReactiveTrail
var _environment_visualizer: EnvironmentVisualizer

# Test scene root
var _test_root: Node2D


func before_each():
	# Create test root
	_test_root = Node2D.new()
	add_child_autoqfree(_test_root)
	
	# Create BeatManager
	_beat_manager = BeatManager.new()
	_beat_manager.name = "BeatManager"
	if has_node("/root/BeatManager"):
		get_node("/root/BeatManager").queue_free()
	get_node("/root").add_child(_beat_manager)
	
	# Create core systems
	_setup_core_systems()
	
	# Create visual components
	_setup_visual_components()
	
	gut.p("=== Starting Sound Visualization Integration Test ===")


func after_each():
	# Clean up BeatManager
	if has_node("/root/BeatManager"):
		get_node("/root/BeatManager").queue_free()
	
	gut.p("=== Completed Sound Visualization Integration Test ===")
	gut.p("")


func _setup_core_systems():
	"""Setup core game systems"""
	# Create TrackSystem
	_track_system = TrackSystem.new()
	_track_system.add_to_group("track_system")
	_test_root.add_child(_track_system)
	
	# Create LaneSoundSystem
	_lane_sound_system = LaneSoundSystem.new()
	_lane_sound_system.add_to_group("lane_sound_system")
	_test_root.add_child(_lane_sound_system)
	
	# Create vehicle
	_rhythm_vehicle = RhythmVehicleWithLanes.new()
	_rhythm_vehicle.position = Vector2(400, 300)
	_test_root.add_child(_rhythm_vehicle)


func _setup_visual_components():
	"""Setup all visual components"""
	# Beat pulse visualizer (attached to vehicle)
	_beat_pulse_visualizer = BeatPulseVisualizer.new()
	_rhythm_vehicle.add_child(_beat_pulse_visualizer)
	
	# Lane sound visualizer
	_lane_sound_visualizer = LaneSoundVisualizer.new()
	_test_root.add_child(_lane_sound_visualizer)
	
	# Sound reactive trail (attached to vehicle)
	_sound_reactive_trail = SoundReactiveTrail.new()
	_rhythm_vehicle.add_child(_sound_reactive_trail)
	
	# Environment visualizer
	_environment_visualizer = EnvironmentVisualizer.new()
	_environment_visualizer.z_index = -10  # Behind everything
	_test_root.add_child(_environment_visualizer)


func test_all_components_initialize():
	"""Test that all visual components initialize properly"""
	assert_not_null(_beat_pulse_visualizer, "Beat pulse visualizer should exist")
	assert_not_null(_lane_sound_visualizer, "Lane sound visualizer should exist")
	assert_not_null(_sound_reactive_trail, "Sound reactive trail should exist")
	assert_not_null(_environment_visualizer, "Environment visualizer should exist")
	
	# Check connections
	assert_not_null(_beat_pulse_visualizer._beat_manager, "Beat pulse should find BeatManager")
	assert_eq(_sound_reactive_trail.get_parent(), _rhythm_vehicle, "Trail should be attached to vehicle")


func test_beat_triggers_all_visuals():
	"""Test that beat events trigger all visual components"""
	# Watch signals
	watch_signals(_beat_pulse_visualizer)
	watch_signals(_environment_visualizer)
	
	# Start beat system
	_beat_manager.set_bpm(120)
	_beat_manager.start()
	
	# Wait for a beat
	await wait_for_beat()
	
	# Check that components reacted
	assert_signal_emitted(_beat_pulse_visualizer, "pulse_triggered")
	assert_signal_emitted(_environment_visualizer, "environment_pulse_triggered")
	assert_true(_beat_pulse_visualizer.is_pulsing(), "Beat pulse should be active")


func test_lane_change_triggers_visuals():
	"""Test that lane changes trigger appropriate visuals"""
	# Setup vehicle in a lane
	_rhythm_vehicle.setup(_track_system)
	_rhythm_vehicle.current_lane = 1
	
	# Activate lane in sound system
	_lane_sound_system.play_lane(1)
	
	# Let systems process
	_test_root._process(0.016)
	
	# Check lane visualizer
	if _lane_sound_visualizer.lane_states.size() > 1:
		assert_true(_lane_sound_visualizer.lane_states[1].active, "Lane 1 should be active visually")
	
	# Change lane
	_rhythm_vehicle.current_lane = 2
	_sound_reactive_trail.set_current_lane(2)
	
	# Check trail reacted
	assert_eq(_sound_reactive_trail.current_lane, 2, "Trail should track lane change")


func test_vehicle_movement_creates_trail():
	"""Test that vehicle movement creates trail points"""
	# Setup
	_rhythm_vehicle.position = Vector2(100, 100)
	
	# Move vehicle and update trail
	for i in 5:
		_rhythm_vehicle.position += Vector2(20, 0)
		_sound_reactive_trail._check_add_new_point()
	
	assert_gt(_sound_reactive_trail.get_trail_length(), 0, "Trail should have points")
	assert_le(_sound_reactive_trail.get_trail_length(), 5, "Trail should not exceed movement count")


func test_visual_synchronization():
	"""Test that all visuals stay synchronized"""
	# Start systems
	_beat_manager.set_bpm(120)
	_beat_manager.start()
	_lane_sound_system.play_lane(0)
	
	# Process multiple frames
	for i in 10:
		_test_root._process(0.016)
		
		# Update trail position
		_rhythm_vehicle.position += Vector2(5, 0)
		_sound_reactive_trail._process(0.016)
	
	# All components should have processed
	assert_gt(_lane_sound_visualizer.waveform_update_timer, 0, "Lane visualizer should be updating")
	assert_gt(_sound_reactive_trail.get_trail_length(), 0, "Trail should have points")


func test_performance_with_all_effects():
	"""Test performance with all effects active"""
	var start_time = Time.get_ticks_msec()
	
	# Activate everything
	_beat_manager.set_bpm(180)  # Fast BPM
	_beat_manager.start()
	
	for lane in 3:
		_lane_sound_system.play_lane(lane)
		_lane_sound_visualizer.activate_lane(lane)
	
	# Process many frames
	for i in 60:  # 1 second at 60 FPS
		_test_root._process(0.016)
		_beat_pulse_visualizer._process(0.016)
		_lane_sound_visualizer._process(0.016)
		_sound_reactive_trail._process(0.016)
		_environment_visualizer._process(0.016)
		
		# Trigger some effects
		if i % 10 == 0:
			_environment_visualizer._on_beat_occurred(i, 0.0)
	
	var end_time = Time.get_ticks_msec()
	var elapsed = end_time - start_time
	
	gut.p("Performance test completed in %d ms" % elapsed)
	assert_lt(elapsed, 2000, "All effects should process 60 frames in under 2 seconds")


func test_cleanup_and_reset():
	"""Test that all components clean up properly"""
	# Activate effects
	_beat_pulse_visualizer.trigger_pulse()
	_lane_sound_visualizer.activate_lane(0)
	_sound_reactive_trail.add_trail_point(Vector2.ZERO)
	_environment_visualizer.set_reaction_intensity(1.0)
	
	# Reset all
	_beat_pulse_visualizer.reset()
	_lane_sound_visualizer.reset()
	_sound_reactive_trail.clear_trail()
	_environment_visualizer.reset()
	
	# Verify reset state
	assert_false(_beat_pulse_visualizer.is_pulsing(), "Beat pulse should be reset")
	assert_false(_lane_sound_visualizer.lane_states[0].active, "Lane should be inactive")
	assert_eq(_sound_reactive_trail.get_trail_length(), 0, "Trail should be empty")
	assert_eq(_environment_visualizer.current_intensity, 0.0, "Environment intensity should be 0")


func test_visual_feedback_chain():
	"""Test the complete visual feedback chain from input to visuals"""
	# Setup rhythm feedback manager
	var rhythm_feedback = RhythmFeedbackManager.new()
	rhythm_feedback.add_to_group("rhythm_feedback")
	_test_root.add_child(rhythm_feedback)
	
	# Connect beat indicator to feedback
	_beat_pulse_visualizer._rhythm_feedback_manager = rhythm_feedback
	_beat_pulse_visualizer._connect_feedback_signals()
	
	# Simulate perfect hit
	rhythm_feedback.emit_signal("perfect_hit_detected", 0.01, 1)
	
	# Process
	_beat_pulse_visualizer._process(0.016)
	
	# Should trigger enhanced visuals
	assert_true(_beat_pulse_visualizer._is_perfect_pulse, "Should register perfect pulse")


# Helper functions
func wait_for_beat():
	"""Wait for next beat to occur"""
	if not _beat_manager.is_playing():
		_beat_manager.start()
	
	var beat_interval = _beat_manager.get_beat_interval()
	return wait_seconds(beat_interval + 0.1)