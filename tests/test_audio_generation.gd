# Test Audio Generation
extends Node

var _audio_debugger: Node

func _ready():
	print("\n=== Testing Audio Generation ===")
	
	# Initialize audio debugger
	_audio_debugger = preload("res://scripts/components/audio_debugger.gd").new()
	add_child(_audio_debugger)
	
	# Test all sound types
	var sounds = ["sine", "square", "bass", "percussion"]
	
	for sound in sounds:
		print("\nTesting %s sound generation..." % sound)
		var result = _audio_debugger.test_effect(sound)
		
		if result:
			print("✓ %s sound generation successful" % sound)
			if result.has("bus"):
				print("  Bus: %s" % result.bus)
			if result.has("frequency"):
				print("  Frequency: %f Hz" % result.frequency)
			if result.has("duration"):
				print("  Duration: %f s" % result.duration)
		else:
			print("✗ %s sound generation failed" % sound)
		
		# Wait between tests
		await get_tree().create_timer(0.5).timeout
	
	print("\n=== Audio Generation Tests Complete ===")
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()
