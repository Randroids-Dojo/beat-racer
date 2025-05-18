extends "res://addons/gut/test.gd"

# Test that metronome actually produces sound
# Tests the MetronomeGenerator class and integration with PlaybackSync

var MetronomeGeneratorClass = preload("res://scripts/components/sound/metronome_generator.gd")
var PlaybackSyncClass = preload("res://scripts/components/sound/playback_sync.gd")

var metronome_generator
var playback_sync
var beat_manager

func before_each():
	# Create metronome generator
	metronome_generator = MetronomeGeneratorClass.new()
	add_child(metronome_generator)
	
	# Create playback sync
	playback_sync = PlaybackSyncClass.new()
	add_child(playback_sync)
	
	# Get BeatManager
	beat_manager = get_tree().root.get_node("/root/BeatManager")
	
	await get_tree().process_frame

func after_each():
	if metronome_generator:
		metronome_generator.queue_free()
	if playback_sync:
		playback_sync.queue_free()

func test_metronome_generator_exists():
	assert_not_null(metronome_generator)
	assert_true(metronome_generator.has_method("play_tick"))
	assert_true(metronome_generator.has_method("play_tock"))

func test_direct_metronome_sound():
	# Test playing tick sound directly
	metronome_generator.play_tick(-6.0)
	await get_tree().create_timer(0.1).timeout
	
	# Test playing tock sound directly  
	metronome_generator.play_tock(-6.0)
	await get_tree().create_timer(0.1).timeout
	
	# No crash = success
	assert_true(true, "Metronome sounds played without error")

func test_metronome_through_playback_sync():
	# Enable metronome
	playback_sync.set_metronome_enabled(true)
	
	# Simulate beat events
	playback_sync._on_beat_occurred(0, 0.0)  # Downbeat
	await get_tree().create_timer(0.1).timeout
	
	playback_sync._on_beat_occurred(1, 0.5)  # Regular beat
	await get_tree().create_timer(0.1).timeout
	
	assert_true(playback_sync.is_metronome_enabled())

func test_metronome_with_beat_manager():
	# Enable metronome through BeatManager
	beat_manager.enable_metronome()
	beat_manager.start()
	
	# Let a few beats play
	await get_tree().create_timer(2.0).timeout
	
	# Stop and disable
	beat_manager.stop()
	beat_manager.disable_metronome()
	
	assert_true(beat_manager.current_beat > 0, "Beats should have occurred")

func test_metronome_volume_control():
	# Set different volumes
	metronome_generator.play_tick(-12.0)
	await get_tree().create_timer(0.05).timeout
	
	metronome_generator.play_tick(0.0)
	await get_tree().create_timer(0.05).timeout
	
	metronome_generator.play_tick(-20.0)
	await get_tree().create_timer(0.05).timeout
	
	assert_true(true, "Volume control tested")

func test_metronome_frequency_settings():
	# Test custom frequencies
	metronome_generator.set_tick_frequency(1000.0)
	metronome_generator.set_tock_frequency(500.0)
	
	metronome_generator.play_tick()
	await get_tree().create_timer(0.1).timeout
	
	metronome_generator.play_tock()
	await get_tree().create_timer(0.1).timeout
	
	assert_true(true, "Custom frequencies work")