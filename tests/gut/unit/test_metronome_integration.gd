extends "res://addons/gut/test.gd"

# Test metronome integration between BeatManager and PlaybackSync
# Verifies that the metronome enable/disable methods work correctly

var PlaybackSyncClass = preload("res://scripts/components/sound/playback_sync.gd")
var beat_manager
var playback_sync

func before_each():
	# Get BeatManager singleton
	beat_manager = get_tree().root.get_node("/root/BeatManager")
	assert_not_null(beat_manager, "BeatManager singleton should exist")
	
	# Create PlaybackSync instance
	playback_sync = PlaybackSyncClass.new()
	add_child(playback_sync)
	
	# Give time for nodes to be ready
	await get_tree().process_frame

func after_each():
	if playback_sync:
		playback_sync.queue_free()
		playback_sync = null

func test_metronome_methods_exist():
	# Verify BeatManager has metronome methods
	assert_true(beat_manager.has_method("enable_metronome"), "BeatManager should have enable_metronome method")
	assert_true(beat_manager.has_method("disable_metronome"), "BeatManager should have disable_metronome method")
	assert_true(beat_manager.has_method("is_metronome_enabled"), "BeatManager should have is_metronome_enabled method")
	assert_true(beat_manager.has_method("set_metronome_volume"), "BeatManager should have set_metronome_volume method")

func test_enable_disable_metronome():
	# Test enabling metronome
	beat_manager.enable_metronome()
	await get_tree().create_timer(0.1).timeout
	
	assert_true(beat_manager.is_metronome_enabled(), "Metronome should be enabled")
	assert_true(playback_sync.is_metronome_enabled(), "PlaybackSync should report metronome enabled")
	
	# Test disabling metronome
	beat_manager.disable_metronome()
	await get_tree().create_timer(0.1).timeout
	
	assert_false(beat_manager.is_metronome_enabled(), "Metronome should be disabled")
	assert_false(playback_sync.is_metronome_enabled(), "PlaybackSync should report metronome disabled")

func test_metronome_volume_control():
	var test_volume = -10.0
	
	beat_manager.set_metronome_volume(test_volume)
	await get_tree().create_timer(0.1).timeout
	
	# Verify volume was set on PlaybackSync
	assert_eq(playback_sync._metronome_volume, test_volume, "Metronome volume should be set correctly")

func test_metronome_plays_on_beat():
	# Enable metronome
	beat_manager.enable_metronome()
	
	# Start beat tracking
	beat_manager.start()
	
	# Wait for a few beats
	await get_tree().create_timer(1.0).timeout
	
	# Verify beat occurred signals were emitted
	assert_gt(beat_manager.current_beat, 0, "Beats should have occurred")
	
	# Stop beat tracking
	beat_manager.stop()
	beat_manager.disable_metronome()

func test_metronome_without_playback_sync():
	# Remove PlaybackSync
	playback_sync.queue_free()
	playback_sync = null
	await get_tree().process_frame
	
	# Should not crash when calling metronome methods
	beat_manager.enable_metronome()
	beat_manager.disable_metronome()
	var enabled = beat_manager.is_metronome_enabled()
	
	assert_false(enabled, "Metronome should be disabled when PlaybackSync is not available")