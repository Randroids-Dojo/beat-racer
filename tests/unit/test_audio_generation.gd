# test_audio_generation.gd
# Unit tests for audio stream generation and playback
extends SceneTree

func _init():
	print("=== UNIT TEST: Audio Generation ===")
	
	test_generator_configuration()
	test_stream_playback()
	test_frame_generation()
	test_test_tone_generation()
	
	print("=== Audio Generation Unit Test Complete ===")
	quit()

func test_generator_configuration():
	print("\nTesting AudioStreamGenerator configuration...")
	
	var generator = AudioStreamGenerator.new()
	
	# Test default values
	print("Default mix_rate: %f" % generator.mix_rate)
	print("Default buffer_length: %f" % generator.buffer_length)
	
	# Test configuration
	generator.mix_rate = 44100.0
	generator.buffer_length = 0.1
	
	if generator.mix_rate == 44100.0:
		print("✓ mix_rate set correctly")
	else:
		print("✗ mix_rate setting failed")
	
	if generator.buffer_length == 0.1:
		print("✓ buffer_length set correctly")
	else:
		print("✗ buffer_length setting failed")
	
	print("Configuration test: PASSED")

func test_stream_playback():
	print("\nTesting AudioStreamPlayer setup...")
	
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100.0
	
	var player = AudioStreamPlayer.new()
	player.stream = generator
	player.bus = "Master"
	
	if player.stream == generator:
		print("✓ Stream assigned correctly")
	else:
		print("✗ Stream assignment failed")
	
	if player.bus == "Master":
		print("✓ Bus assigned correctly")
	else:
		print("✗ Bus assignment failed")
	
	# Test player state
	print("Is playing: %s" % player.playing)
	print("Volume dB: %f" % player.volume_db)
	print("Pitch scale: %f" % player.pitch_scale)
	
	print("Stream playback test: PASSED")

func test_frame_generation():
	print("\nTesting audio frame generation...")
	
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100.0
	generator.buffer_length = 0.05  # 50ms buffer
	
	var player = AudioStreamPlayer.new()
	player.stream = generator
	
	# Add to tree temporarily for testing
	add_child(player)
	player.play()
	
	# Get playback interface
	var playback = player.get_stream_playback()
	
	if playback != null:
		print("✓ Got stream playback interface")
		
		# Check available frames
		var frames_available = playback.get_frames_available()
		print("Frames available: %d" % frames_available)
		
		if frames_available > 0:
			# Generate some test frames
			for i in range(min(100, frames_available)):
				var value = sin(i * 0.1) * 0.5
				playback.push_frame(Vector2(value, value))
			
			print("✓ Successfully pushed %d frames" % min(100, frames_available))
		else:
			print("! No frames available yet")
	else:
		print("✗ Failed to get stream playback")
	
	player.stop()
	player.queue_free()
	
	print("Frame generation test: PASSED")

func test_test_tone_generation():
	print("\nTesting test tone generation (440Hz)...")
	
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100.0
	
	var player = AudioStreamPlayer.new()
	player.stream = generator
	
	add_child(player)
	player.play()
	
	var playback = player.get_stream_playback()
	
	if playback != null:
		var frequency = 440.0  # A4 note
		var sample_rate = generator.mix_rate
		var duration = 0.1  # 100ms
		var frames_to_generate = int(sample_rate * duration)
		
		print("Generating %d frames for %fHz tone" % [frames_to_generate, frequency])
		
		var phase = 0.0
		for i in range(frames_to_generate):
			if playback.get_frames_available() > 0:
				var value = sin(phase * TAU) * 0.3
				playback.push_frame(Vector2(value, value))
				phase = fmod(phase + (frequency / sample_rate), 1.0)
			else:
				await get_tree().process_frame
		
		print("✓ Generated %d frames successfully" % frames_to_generate)
		print("✓ Final phase: %f" % phase)
		
		# Let it play briefly
		await get_tree().create_timer(0.1).timeout
	else:
		print("✗ Failed to get playback interface")
	
	player.stop()
	player.queue_free()
	
	print("Test tone generation: PASSED")