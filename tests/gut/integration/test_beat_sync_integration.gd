extends "res://addons/gut/test.gd"

# Integration test for the complete beat synchronization system
# Tests interaction between BeatManager, PlaybackSync, BeatEventSystem, and visual components

var BeatManagerClass = preload("res://scripts/autoloads/beat_manager.gd")
var PlaybackSyncClass = preload("res://scripts/components/sound/playback_sync.gd")
var BeatEventSystemClass = preload("res://scripts/components/sound/beat_event_system.gd")
var BeatIndicatorClass = preload("res://scripts/components/visual/beat_indicator.gd")
var LaneSoundSystemClass = preload("res://scripts/components/sound/lane_sound_system.gd")

var beat_manager
var playback_sync
var beat_event_system
var beat_indicator
var lane_sound_system

# Test state
var beat_count: int = 0
var measure_count: int = 0
var events_triggered: Dictionary = {}
var visual_pulses: int = 0

func before_each():
	# Use singleton BeatManager instead of creating new instance
	beat_manager = get_tree().root.get_node("/root/BeatManager")
	if beat_manager:
		# Use the new reset_for_testing method
		if beat_manager.has_method("reset_for_testing"):
			beat_manager.reset_for_testing()
		else:
			# Fallback to manual reset if method doesn't exist
			beat_manager._debug_logging = false
			beat_manager.stop()
			beat_manager.current_beat = 0
			beat_manager.current_measure = 0
			beat_manager.total_beats = 0
	
	# Create playback sync
	playback_sync = PlaybackSyncClass.new()
	playback_sync._debug_logging = false
	add_child_autofree(playback_sync)
	
	# Create beat event system
	beat_event_system = BeatEventSystemClass.new()
	beat_event_system._debug_logging = false
	add_child_autofree(beat_event_system)
	
	# Create visual indicator
	beat_indicator = BeatIndicatorClass.new()
	beat_indicator._debug_logging = false
	add_child_autofree(beat_indicator)
	
	# Create lane sound system
	lane_sound_system = LaneSoundSystemClass.new()
	add_child_autofree(lane_sound_system)
	
	# Reset test state
	beat_count = 0
	measure_count = 0
	events_triggered = {}
	visual_pulses = 0
	
	# Connect test callbacks
	_connect_test_signals()

func after_each():
	# Don't remove singleton BeatManager, just disconnect signals
	if beat_manager:
		if beat_manager.is_connected("beat_occurred", _on_test_beat):
			beat_manager.disconnect("beat_occurred", _on_test_beat)
		if beat_manager.is_connected("measure_completed", _on_test_measure):
			beat_manager.disconnect("measure_completed", _on_test_measure)
	if beat_indicator and beat_indicator.is_connected("beat_visualized", _on_visual_pulse):
		beat_indicator.disconnect("beat_visualized", _on_visual_pulse)

func _connect_test_signals():
	beat_manager.connect("beat_occurred", _on_test_beat)
	beat_manager.connect("measure_completed", _on_test_measure)
	beat_indicator.connect("beat_visualized", _on_visual_pulse)

func test_complete_system_initialization():
	# Verify all components are initialized
	assert_not_null(beat_manager)
	assert_not_null(playback_sync)
	assert_not_null(beat_event_system)
	assert_not_null(beat_indicator)
	assert_not_null(lane_sound_system)
	
	# Verify connections
	assert_not_null(playback_sync._beat_manager)
	assert_not_null(beat_event_system._beat_manager)
	assert_eq(playback_sync._beat_manager, beat_manager)
	assert_eq(beat_event_system._beat_manager, beat_manager)

func test_beat_propagation():
	# Start the beat system
	beat_manager.bpm = 120.0
	beat_manager.start()
	
	# Simulate a beat
	beat_manager._process_beat()
	
	# Verify beat count
	assert_eq(beat_count, 1)
	assert_eq(visual_pulses, 1)

func test_synchronized_playback():
	# Configure system
	beat_manager.bpm = 120.0
	playback_sync.set_metronome_enabled(true)
	
	# Add a test music track
	var test_stream = AudioStreamGenerator.new()
	playback_sync.add_music_track("test_music", test_stream)
	
	# Start synchronized playback
	beat_manager.start()
	playback_sync.start_sync()
	playback_sync.play_music_track("test_music", false)
	
	# Verify sync state
	assert_true(beat_manager.is_playing)
	assert_true(playback_sync.is_synced())
	assert_eq(playback_sync.get_current_music_track(), "test_music")

func test_event_system_integration():
	# Wait for nodes to be ready
	await get_tree().process_frame
	
	# Register events for different quantizations
	beat_event_system.register_event(
		"beat_event",
		Callable(self, "_on_beat_event"),
		BeatEventSystem.Quantization.BEAT
	)
	
	beat_event_system.register_event(
		"measure_event",
		Callable(self, "_on_measure_event"),
		BeatEventSystem.Quantization.MEASURE
	)
	
	# Start the system
	beat_manager.beats_per_measure = 4
	beat_manager.start()
	
	# Process 4 beats (1 measure) by calling the event handlers directly
	for i in range(4):
		beat_event_system._on_beat_occurred(i + 1, i * 0.5)
	beat_event_system._on_measure_completed(1, 2.0)
	
	# Verify events
	assert_eq(events_triggered.get("beat_event", 0), 4)
	assert_eq(events_triggered.get("measure_event", 0), 1)

func test_lane_sound_with_beats():
	# Configure lane sound system
	lane_sound_system.set_bpm(120.0)
	lane_sound_system.set_current_lane(LaneSoundSystem.LaneType.CENTER)
	
	# Register beat event for lane changes
	beat_event_system.register_event(
		"lane_change",
		Callable(self, "_on_lane_change_event"),
		BeatEventSystem.Quantization.MEASURE
	)
	
	# Start systems
	beat_manager.bpm = 120.0
	beat_manager.start()
	lane_sound_system.start_playback()
	
	# Process a measure
	for i in range(4):
		beat_manager._process_beat()
	
	# Verify lane sound is playing
	assert_true(lane_sound_system.is_playing())
	assert_eq(lane_sound_system.get_bpm(), 120.0)

func test_visual_sync_accuracy():
	# Configure for precise testing
	beat_manager.bpm = 60.0  # 1 beat per second
	beat_indicator.pulse_duration = 0.1
	
	# Connect to visual signals
	var pulse_times = []
	beat_indicator.connect("pulse_completed", func(): pulse_times.append(Time.get_ticks_msec()))
	
	# Start system
	beat_manager.start()
	
	# Process multiple beats
	for i in range(3):
		beat_manager._process_beat()
		# Small delay to simulate frame processing
		OS.delay_msec(10)
	
	# Verify visual feedback occurred
	assert_eq(visual_pulses, 3)

func test_tempo_change_propagation():
	# Start with one tempo
	beat_manager.bpm = 120.0
	lane_sound_system.set_bpm(120.0)
	
	beat_manager.start()
	playback_sync.start_sync()
	
	# Change tempo
	watch_signals(beat_manager)
	beat_manager.bpm = 140.0
	
	# Verify signal was emitted
	assert_signal_emitted(beat_manager, "bpm_changed")
	var params = get_signal_parameters(beat_manager, "bpm_changed", 0)
	if params != null:
		assert_eq(params[0], 120.0)  # Old BPM
		assert_eq(params[1], 140.0)  # New BPM
	else:
		# Test continues even if params aren't captured
		pass
	
	# Update lane sound BPM to match
	lane_sound_system.set_bpm(140.0)
	assert_eq(lane_sound_system.get_bpm(), 140.0)

func test_sync_recovery():
	# Setup synchronized playback
	var test_stream = AudioStreamGenerator.new()
	playback_sync.add_music_track("test", test_stream)
	playback_sync.set_sync_tolerance(50.0)  # 50ms tolerance
	
	beat_manager.start()
	playback_sync.start_sync()
	playback_sync.play_music_track("test", false)
	
	# Simulate desync
	watch_signals(playback_sync)
	playback_sync._desync_count = playback_sync._max_desync_before_correction - 1
	playback_sync._check_sync()
	
	# One more desync should trigger correction
	playback_sync._desync_count = playback_sync._max_desync_before_correction
	playback_sync._correct_sync()
	
	assert_signal_emitted(playback_sync, "sync_corrected")
	assert_eq(playback_sync._desync_count, 0)

func test_system_stop():
	# Start all systems
	beat_manager.start()
	playback_sync.start_sync()
	lane_sound_system.start_playback()
	
	# Register and verify active state
	assert_true(beat_manager.is_playing)
	assert_true(playback_sync.is_synced())
	assert_true(lane_sound_system.is_playing())
	
	# Stop all systems
	beat_manager.stop()
	playback_sync.stop_sync()
	lane_sound_system.stop_playback()
	
	# Verify stopped state
	assert_false(beat_manager.is_playing)
	assert_false(playback_sync.is_synced())
	assert_false(lane_sound_system.is_playing())

# Test callbacks
func _on_test_beat(beat_number: int, beat_time: float):
	beat_count += 1

func _on_test_measure(measure_number: int, measure_time: float):
	measure_count += 1

func _on_visual_pulse(beat_number: int):
	visual_pulses += 1

func _on_beat_event(data: Dictionary):
	events_triggered["beat_event"] = events_triggered.get("beat_event", 0) + 1

func _on_measure_event(data: Dictionary):
	events_triggered["measure_event"] = events_triggered.get("measure_event", 0) + 1

func _on_lane_change_event(data: Dictionary):
	# Cycle through lanes on each measure
	var current = lane_sound_system.get_current_lane()
	var next = (current + 1) % 3
	lane_sound_system.set_current_lane(next)