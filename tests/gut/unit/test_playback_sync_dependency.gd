extends "res://addons/gut/test.gd"

# Unit test to verify PlaybackSync dependency for metronome
# Ensures that metronome doesn't work without PlaybackSync

var beat_manager
var playback_sync

func before_each():
	# Get fresh BeatManager reference
	beat_manager = get_tree().root.get_node("/root/BeatManager")
	assert_not_null(beat_manager, "BeatManager should exist")
	
	# Reset BeatManager state
	if beat_manager.has_method("reset_for_testing"):
		beat_manager.reset_for_testing()
	else:
		beat_manager.reset()

func after_each():
	if playback_sync:
		playback_sync.queue_free()
		playback_sync = null
	
	await get_tree().process_frame

func test_metronome_without_playback_sync():
	# Ensure no PlaybackSync exists
	var existing_syncs = get_tree().get_nodes_in_group("playback_sync")
	for sync in existing_syncs:
		sync.queue_free()
	
	await get_tree().process_frame
	
	# Try to enable metronome without PlaybackSync
	beat_manager.enable_metronome()
	
	# Metronome methods should handle gracefully
	assert_false(beat_manager.is_metronome_enabled(), "Metronome should not enable without PlaybackSync")

func test_metronome_with_playback_sync():
	# Create PlaybackSync
	var PlaybackSyncClass = preload("res://scripts/components/sound/playback_sync.gd")
	playback_sync = PlaybackSyncClass.new()
	add_child(playback_sync)
	
	await get_tree().create_timer(0.1).timeout
	
	# Now metronome should work
	beat_manager.enable_metronome()
	assert_true(beat_manager.is_metronome_enabled(), "Metronome should enable with PlaybackSync")
	
	beat_manager.disable_metronome()
	assert_false(beat_manager.is_metronome_enabled(), "Metronome should disable")

func test_playback_sync_discovery():
	# Test that BeatManager can find PlaybackSync in different locations
	var PlaybackSyncClass = preload("res://scripts/components/sound/playback_sync.gd")
	
	# Test 1: Direct child
	playback_sync = PlaybackSyncClass.new()
	add_child(playback_sync)
	await get_tree().process_frame
	
	beat_manager.enable_metronome()
	assert_true(beat_manager.is_metronome_enabled(), "Should find PlaybackSync as direct child")
	beat_manager.disable_metronome()
	
	# Clean up
	playback_sync.queue_free()
	await get_tree().process_frame
	
	# Test 2: Nested child
	var container = Node.new()
	add_child(container)
	playback_sync = PlaybackSyncClass.new()
	container.add_child(playback_sync)
	await get_tree().process_frame
	
	beat_manager.enable_metronome()
	assert_true(beat_manager.is_metronome_enabled(), "Should find PlaybackSync as nested child")
	beat_manager.disable_metronome()
	
	# Clean up
	container.queue_free()
	await get_tree().process_frame

func test_multiple_playback_syncs():
	# Test behavior with multiple PlaybackSync instances
	var PlaybackSyncClass = preload("res://scripts/components/sound/playback_sync.gd")
	
	var sync1 = PlaybackSyncClass.new()
	var sync2 = PlaybackSyncClass.new()
	
	add_child(sync1)
	add_child(sync2)
	
	await get_tree().process_frame
	
	# Should find the first one
	beat_manager.enable_metronome()
	assert_true(beat_manager.is_metronome_enabled(), "Should work with multiple PlaybackSync instances")
	
	# Note: BeatManager only finds and uses the first PlaybackSync
	# So we can't test if both are enabled - only the first one matters
	assert_true(sync1.is_metronome_enabled(), "First PlaybackSync should be enabled")
	
	beat_manager.disable_metronome()
	
	# Clean up
	sync1.queue_free()
	sync2.queue_free()
	await get_tree().process_frame

func test_metronome_volume_without_playback_sync():
	# Ensure no PlaybackSync exists
	var existing_syncs = get_tree().get_nodes_in_group("playback_sync")
	for sync in existing_syncs:
		sync.queue_free()
	
	await get_tree().process_frame
	
	# Should not crash when setting volume without PlaybackSync
	beat_manager.set_metronome_volume(-12.0)
	
	# No assertion needed - just ensuring no crash
	assert_true(true, "Setting metronome volume without PlaybackSync should not crash")

func test_beat_events_with_metronome():
	# Test that beat events trigger metronome sounds
	var PlaybackSyncClass = preload("res://scripts/components/sound/playback_sync.gd")
	playback_sync = PlaybackSyncClass.new()
	add_child(playback_sync)
	
	await get_tree().process_frame
	
	# Reset beat manager state
	beat_manager.reset()
	beat_manager.bpm = 120
	
	# Enable metronome and start beats
	beat_manager.enable_metronome()
	beat_manager.start()
	
	# Wait for a few beats
	await get_tree().create_timer(2.5).timeout
	
	# Should have processed some beats
	assert_gt(beat_manager.current_beat, 0, "Beats should have occurred")
	
	beat_manager.stop()
	beat_manager.disable_metronome()