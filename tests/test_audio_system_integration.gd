# Test Full Audio System Integration
extends Node

func _ready():
	print("\n=== Testing Audio System Integration ===")
	
	# Test AudioManager initialization
	var audio_manager = preload("res://scripts/autoloads/audio_manager.gd").new()
	add_child(audio_manager)
	
	print("\n1. Testing AudioManager initialization...")
	await get_tree().create_timer(0.1).timeout
	
	if audio_manager:
		print("✓ AudioManager created successfully")
		
		# Check if buses exist
		var master_idx = AudioServer.get_bus_index("Master")
		var sfx_idx = AudioServer.get_bus_index("SFX")
		var melody_idx = AudioServer.get_bus_index("Melody")
		var bass_idx = AudioServer.get_bus_index("Bass")
		
		if master_idx != -1:
			print("✓ Master bus exists")
		else:
			print("✗ Master bus missing")
			
		if sfx_idx != -1:
			print("✓ SFX bus exists")
		else:
			print("✗ SFX bus missing")
			
		if melody_idx != -1:
			print("✓ Melody bus exists")
		else:
			print("✗ Melody bus missing")
			
		if bass_idx != -1:
			print("✓ Bass bus exists")
		else:
			print("✗ Bass bus missing")
		
		# Test playing sounds
		print("\n2. Testing sound playback...")
		
		# Test tone generation function exists
		if audio_manager.has_method("play_test_tone"):
			print("✓ play_test_tone method exists")
			
			# Try playing a test tone
			print("  Attempting to play test tone on SFX bus...")
			audio_manager.play_test_tone("SFX", 440.0, 0.5)
			await get_tree().create_timer(0.6).timeout
			print("  Test tone completed")
		else:
			print("✗ play_test_tone method missing")
		
		# Test volume control
		print("\n3. Testing volume control...")
		
		if audio_manager.has_method("set_bus_volume"):
			print("✓ set_bus_volume method exists")
			
			# Test setting volume
			audio_manager.set_bus_volume("Master", 0.7)
			audio_manager.set_bus_volume("SFX", 0.5)
			
			# Verify volumes
			var master_vol = AudioServer.get_bus_volume_db(master_idx)
			var sfx_vol = AudioServer.get_bus_volume_db(sfx_idx)
			
			print("  Master volume: %f dB" % master_vol)
			print("  SFX volume: %f dB" % sfx_vol)
		else:
			print("✗ set_bus_volume method missing")
	else:
		print("✗ Failed to create AudioManager")
	
	print("\n=== Audio System Integration Test Complete ===")
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()
