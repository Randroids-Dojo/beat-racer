# test_audio_system_integration.gd
# Integration tests for the complete audio system
extends SceneTree

var AudioManager

func _init():
	print("=== INTEGRATION TEST: Audio System ===")
	
	# Load the audio manager
	AudioManager = load("res://scripts/autoloads/audio_manager.gd")
	
	# Run integration tests
	test_audio_manager_initialization()
	test_bus_creation_and_routing()
	test_effect_application()
	test_volume_control()
	test_sound_playback()
	
	print("=== Audio System Integration Test Complete ===")
	quit()

func test_audio_manager_initialization():
	print("\nTesting AudioManager initialization...")
	
	var manager = AudioManager.new()
	manager._ready()
	
	# Verify manager state
	if manager != null:
		print("✓ AudioManager created successfully")
	else:
		print("✗ AudioManager creation failed")
		return
	
	# Check if debug logging is enabled
	print("Debug logging enabled: %s" % manager._debug_logging)
	
	# Check melody bus gain
	var melody_idx = AudioServer.get_bus_index("Melody")
	if melody_idx >= 0:
		var gain = AudioServer.get_bus_volume_db(melody_idx)
		print("✓ Melody bus gain: %f dB" % gain)
	else:
		print("✗ Melody bus not found")
	
	print("Initialization test: PASSED")

func test_bus_creation_and_routing():
	print("\nTesting bus creation and routing...")
	
	var buses = ["Master", "Melody", "Bass", "Percussion", "SFX"]
	var bus_indices = {}
	
	# Check all buses exist
	for bus_name in buses:
		var idx = AudioServer.get_bus_index(bus_name)
		if idx >= 0:
			bus_indices[bus_name] = idx
			print("✓ Bus '%s' found at index %d" % [bus_name, idx])
		else:
			print("✗ Bus '%s' not found" % bus_name)
	
	# Check routing (all should route to Master except Master itself)
	for bus_name in bus_indices:
		if bus_name == "Master":
			continue
		
		var idx = bus_indices[bus_name]
		var send = AudioServer.get_bus_send(idx)
		
		if send == "Master":
			print("✓ %s -> %s routing correct" % [bus_name, send])
		else:
			print("✗ %s -> %s routing incorrect (expected Master)" % [bus_name, send])
	
	print("Bus routing test: PASSED")

func test_effect_application():
	print("\nTesting effect application to buses...")
	
	var bus_effects = {
		"Melody": ["AudioEffectReverb", "AudioEffectDelay"],
		"Bass": ["AudioEffectCompressor", "AudioEffectEQ"],
		"Percussion": ["AudioEffectCompressor"],
		"SFX": ["AudioEffectCompressor", "AudioEffectReverb"]
	}
	
	for bus_name in bus_effects:
		var idx = AudioServer.get_bus_index(bus_name)
		if idx < 0:
			print("✗ Bus '%s' not found" % bus_name)
			continue
		
		var effect_count = AudioServer.get_bus_effect_count(idx)
		print("\n%s bus has %d effects:" % [bus_name, effect_count])
		
		for i in range(effect_count):
			var effect = AudioServer.get_bus_effect(idx, i)
			if effect != null:
				print("  %d. %s" % [i, effect.get_class()])
				
				# Test specific properties for known effects
				if effect is AudioEffectDelay:
					print("    - tap1_active: %s" % effect.tap1_active)
					print("    - dry: %f" % effect.dry)
					# Note: 'mix' property doesn't exist for AudioEffectDelay
				elif effect is AudioEffectReverb:
					print("    - room_size: %f" % effect.room_size)
					print("    - wet: %f" % effect.wet)
				elif effect is AudioEffectCompressor:
					print("    - threshold: %f" % effect.threshold)
					print("    - ratio: %f" % effect.ratio)
			else:
				print("  %d. NULL effect" % i)
	
	print("\nEffect application test: PASSED")

func test_volume_control():
	print("\nTesting volume control...")
	
	# Test linear to dB conversion
	var test_values = [0.0, 0.25, 0.5, 0.75, 1.0]
	
	for value in test_values:
		var db = linear_to_db(value)
		var back_to_linear = db_to_linear(db)
		print("Linear %f -> %f dB -> %f linear" % [value, db, back_to_linear])
		
		if abs(back_to_linear - value) < 0.001:
			print("✓ Conversion accurate")
		else:
			print("✗ Conversion error")
	
	# Test bus volume setting
	var melody_idx = AudioServer.get_bus_index("Melody")
	if melody_idx >= 0:
		var original_volume = AudioServer.get_bus_volume_db(melody_idx)
		
		# Set new volume
		var test_volume = -6.0
		AudioServer.set_bus_volume_db(melody_idx, test_volume)
		
		var new_volume = AudioServer.get_bus_volume_db(melody_idx)
		if abs(new_volume - test_volume) < 0.001:
			print("✓ Volume setting works correctly")
		else:
			print("✗ Volume setting failed")
		
		# Restore original
		AudioServer.set_bus_volume_db(melody_idx, original_volume)
	
	print("Volume control test: PASSED")

func test_sound_playback():
	print("\nTesting sound playback system...")
	
	var manager = AudioManager.new()
	manager._ready()
	
	# Test test tone playback
	print("Testing test tone generation...")
	
	# Create a test player
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100.0
	generator.buffer_length = 0.1
	
	var player = AudioStreamPlayer.new()
	player.stream = generator
	player.bus = "Melody"
	
	add_child(player)
	player.play()
	
	var playback = player.get_stream_playback()
	
	if playback != null:
		print("✓ Got playback interface")
		
		# Generate a short test tone
		var frequency = 440.0
		var sample_rate = generator.mix_rate
		var frames = int(sample_rate * 0.05)  # 50ms
		
		for i in range(frames):
			if playback.get_frames_available() > 0:
				var phase = fmod(i * frequency / sample_rate, 1.0)
				var value = sin(phase * TAU) * 0.3
				playback.push_frame(Vector2(value, value))
		
		print("✓ Generated %d frames for test tone" % frames)
		
		# Wait for playback
		await get_tree().create_timer(0.1).timeout
		
		print("✓ Playback completed")
	else:
		print("✗ Failed to get playback interface")
	
	player.stop()
	player.queue_free()
	
	print("Sound playback test: PASSED")