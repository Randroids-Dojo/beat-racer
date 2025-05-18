# test_audio_generation.gd
# Audio generation tests converted to GUT framework
extends GutTest

var SoundGenerator

func before_all():
	SoundGenerator = load("res://scripts/components/sound/sound_generator.gd")

func test_audio_stream_generator_creation():
	gut.p("Testing AudioStreamGenerator creation")
	
	var generator = AudioStreamGenerator.new()
	assert_not_null(generator, "Should create AudioStreamGenerator")
	
	# Test default properties
	assert_gt(generator.mix_rate, 0.0, "Mix rate should be positive")
	assert_gt(generator.buffer_length, 0.0, "Buffer length should be positive")
	
	# Test setting properties
	generator.mix_rate = 44100.0
	generator.buffer_length = 0.1
	
	assert_eq(generator.mix_rate, 44100.0, "Should set mix rate correctly")
	assert_almost_eq(generator.buffer_length, 0.1, 0.01, "Should set buffer length correctly")

func test_sound_generator_initialization():
	gut.p("Testing SoundGenerator initialization")
	
	var sound_gen = SoundGenerator.new()
	assert_not_null(sound_gen, "Should create SoundGenerator instance")
	
	# Check default properties if they exist
	if "sample_rate" in sound_gen:
		assert_eq(sound_gen.sample_rate, 44100.0, "Default sample rate should be 44100")
	
	# Clean up
	sound_gen.queue_free()

func test_audio_stream_player_setup():
	gut.p("Testing AudioStreamPlayer setup for generation")
	
	var player = AudioStreamPlayer.new()
	var generator = AudioStreamGenerator.new()
	
	# Configure generator
	generator.mix_rate = 44100.0
	generator.buffer_length = 0.1
	
	# Assign stream
	player.stream = generator
	assert_eq(player.stream, generator, "Stream should be assigned correctly")
	
	# Test bus assignment
	player.bus = "Melody"
	assert_eq(player.bus, "Melody", "Bus should be assigned correctly")
	
	# Test volume and pitch
	player.volume_db = -6.0
	player.pitch_scale = 1.5
	
	assert_eq(player.volume_db, -6.0, "Volume should be set correctly")
	assert_eq(player.pitch_scale, 1.5, "Pitch scale should be set correctly")
	
	# Clean up properly
	player.queue_free()

func test_stream_playback_retrieval():
	gut.p("Testing stream playback retrieval")
	
	var player = AudioStreamPlayer.new()
	# Add to scene tree first
	add_child(player)
	var generator = AudioStreamGenerator.new()
	
	generator.mix_rate = 44100.0
	player.stream = generator
	
	player.play()
	
	# Get playback
	var playback = player.get_stream_playback()
	# Note: Playback might be null if not playing
	if player.playing:
		assert_not_null(playback, "Should get stream playback when playing")
	
	# Clean up
	player.stop()
	remove_child(player)
	player.queue_free()

func test_audio_frame_generation():
	gut.p("Testing audio frame generation")
	gut.p("WARNING: This test creates a simple audio player but doesn't generate actual audio data")
	gut.p("Full audio generation testing requires running in the scene tree with proper timing")
	
	var player = AudioStreamPlayer.new()
	var generator = AudioStreamGenerator.new()
	
	generator.mix_rate = 44100.0
	generator.buffer_length = 0.1
	player.stream = generator
	
	add_child(player)
	
	# Basic setup verification only
	assert_not_null(player.stream, "Player should have stream assigned")
	assert_eq(player.stream.mix_rate, 44100.0, "Stream should have correct mix rate")
	
	remove_child(player)
	player.queue_free()

func test_multiple_generator_instances():
	gut.p("Testing multiple generator instances")
	
	var generators = []
	var count = 3
	
	for i in range(count):
		var gen = AudioStreamGenerator.new()
		gen.mix_rate = 44100.0
		gen.buffer_length = 0.05 + (i * 0.05)  # Different buffer lengths
		generators.append(gen)
	
	assert_eq(generators.size(), count, "Should create all generators")
	
	# Verify each has different buffer length
	for i in range(count):
		var expected_length = 0.05 + (i * 0.05)
		assert_almost_eq(generators[i].buffer_length, expected_length, 0.01,
			"Generator %d should have buffer length %f" % [i, expected_length])

func test_generator_with_different_sample_rates():
	gut.p("Testing generator with different sample rates")
	
	var sample_rates = [22050.0, 44100.0, 48000.0]
	
	for rate in sample_rates:
		var gen = AudioStreamGenerator.new()
		gen.mix_rate = rate
		assert_eq(gen.mix_rate, rate, "Should set sample rate to %f" % rate)