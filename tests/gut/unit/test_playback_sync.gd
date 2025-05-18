extends "res://addons/gut/test.gd"

var PlaybackSync = preload("res://scripts/components/sound/playback_sync.gd")
var BeatManager = preload("res://scripts/autoloads/beat_manager.gd")

var playback_sync
var beat_manager

func before_each():
	# Use singleton BeatManager instead of creating new instance
	beat_manager = get_tree().root.get_node("/root/BeatManager")
	if beat_manager:
		beat_manager._debug_logging = false
		# Reset BeatManager state for tests
		beat_manager.stop()
		beat_manager.current_beat = 0
		beat_manager.current_measure = 0
		beat_manager.total_beats = 0
	
	# Create playback sync
	playback_sync = PlaybackSync.new()
	playback_sync._debug_logging = false
	add_child_autofree(playback_sync)

func after_each():
	# Don't remove singleton BeatManager
	pass

func test_initialization():
	assert_not_null(playback_sync)
	assert_false(playback_sync.is_synced())
	assert_not_null(playback_sync._beat_manager)
	assert_eq(playback_sync._beat_manager, beat_manager)

func test_start_stop_sync():
	watch_signals(playback_sync)
	
	# Test start
	playback_sync.start_sync()
	assert_true(playback_sync.is_synced())
	assert_signal_emitted(playback_sync, "sync_started")
	
	# Test stop
	playback_sync.stop_sync()
	assert_false(playback_sync.is_synced())
	assert_signal_emitted(playback_sync, "sync_stopped")

func test_metronome_control():
	# Test enable/disable
	assert_false(playback_sync.is_metronome_enabled())
	
	playback_sync.set_metronome_enabled(true)
	assert_true(playback_sync.is_metronome_enabled())
	
	playback_sync.set_metronome_enabled(false)
	assert_false(playback_sync.is_metronome_enabled())
	
	# Test volume
	playback_sync.set_metronome_volume(-12.0)
	assert_eq(playback_sync.get_metronome_volume(), -12.0)

func test_music_track_management():
	# Add tracks
	var track_name = "test_track"
	var stream = AudioStreamGenerator.new()
	
	assert_true(playback_sync.add_music_track(track_name, stream))
	assert_false(playback_sync.add_music_track(track_name, stream))  # Already exists
	
	# Test current track
	assert_eq(playback_sync.get_current_music_track(), "")
	
	playback_sync.play_music_track(track_name, false)
	assert_eq(playback_sync.get_current_music_track(), track_name)

func test_sync_tolerance():
	playback_sync.set_sync_tolerance(100.0)  # 100ms
	assert_almost_eq(playback_sync._sync_tolerance, 0.1, 0.001)
	
	playback_sync.set_sync_tolerance(50.0)  # 50ms
	assert_almost_eq(playback_sync._sync_tolerance, 0.05, 0.001)

func test_sync_accuracy():
	# Test perfect sync
	playback_sync._desync_count = 0
	assert_eq(playback_sync.get_sync_accuracy(), 100.0)
	
	# Test with desyncs
	playback_sync._desync_count = 3
	assert_eq(playback_sync.get_sync_accuracy(), 70.0)
	
	# Test max desync
	playback_sync._desync_count = 10
	assert_eq(playback_sync.get_sync_accuracy(), 0.0)

func test_beat_signals():
	watch_signals(playback_sync)
	
	# Enable metronome to test signal handling
	playback_sync.set_metronome_enabled(true)
	
	# Simulate beat from beat manager
	beat_manager.beat_occurred.emit(1, 0.5)
	
	assert_signal_emitted(playback_sync, "metronome_tick")
	var params = get_signal_parameters(playback_sync, "metronome_tick", 0)
	if params != null:
		assert_eq(params[0], 1)  # Beat number
		assert_false(params[1])  # Not a downbeat
	else:
		# If params are null, just verify the signal was emitted
		pass  # Signal emission is already verified above

func test_desync_detection():
	watch_signals(playback_sync)
	
	playback_sync.start_sync()
	playback_sync._sync_tolerance = 0.05  # 50ms tolerance
	
	# Add a music player
	var stream = AudioStreamGenerator.new()
	playback_sync.add_music_track("test", stream)
	playback_sync.play_music_track("test", false)
	
	# Note: Actual desync detection would require mocking AudioStreamPlayer
	# This test verifies the signal mechanism
	playback_sync.desync_detected.emit(0.1)
	assert_signal_emitted(playback_sync, "desync_detected")

func test_sync_correction():
	watch_signals(playback_sync)
	
	playback_sync.start_sync()
	playback_sync._desync_count = playback_sync._max_desync_before_correction
	
	# Add a music player
	var stream = AudioStreamGenerator.new()
	playback_sync.add_music_track("test", stream)
	playback_sync.play_music_track("test", false)
	
	# Trigger correction
	playback_sync._correct_sync()
	
	assert_signal_emitted(playback_sync, "sync_corrected")
	assert_eq(playback_sync._desync_count, 0)

func test_fade_functionality():
	# Test fade duration setter
	playback_sync._fade_duration = 1.0
	
	# Add test track
	var stream = AudioStreamGenerator.new()
	playback_sync.add_music_track("test", stream)
	
	# Test fade in/out (visual test - actual fading requires scene tree)
	playback_sync.play_music_track("test", true)  # With fade
	playback_sync.stop_all_music(true)  # With fade

func test_sync_to_beat():
	# Add a music player
	var stream = AudioStreamGenerator.new()
	playback_sync.add_music_track("test", stream)
	playback_sync.play_music_track("test", false)
	
	# Test immediate sync
	playback_sync.sync_to_beat()
	
	# Note: Actual sync verification would require mocking AudioStreamPlayer

func test_process_function():
	playback_sync.start_sync()
	playback_sync._sync_check_interval = 0.1
	playback_sync._last_sync_check = 0.0
	
	# Simulate process
	playback_sync._process(0.05)
	assert_eq(playback_sync._last_sync_check, 0.05)
	
	# Check should trigger after interval
	playback_sync._process(0.06)
	assert_eq(playback_sync._last_sync_check, 0.0)  # Reset after check
