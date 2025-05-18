# test_audio_system.gd
extends SceneTree

func _init():
	print("======= TESTING AUDIO SYSTEM =======")
	
	# Test individual property access first
	test_audio_effect_properties()
	
	# Then test the full audio system
	test_audio_bus_setup()
	
	print("======= TEST COMPLETE =======")
	quit()

func test_audio_effect_properties():
	print("\nTesting audio effect properties...")
	
	# Test AudioEffectReverb
	var reverb = AudioEffectReverb.new()
	print("AudioEffectReverb properties:")
	var reverb_properties = list_properties(reverb)
	
	# Test AudioEffectDelay
	var delay = AudioEffectDelay.new()
	print("\nAudioEffectDelay properties:")
	var delay_properties = list_properties(delay)
	
	# Test setting properties
	print("\nTesting property assignments...")
	
	# This should work
	delay.tap1_active = true
	print("Set delay.tap1_active = true: SUCCESS")
	
	delay.tap1_delay_ms = 250.0
	print("Set delay.tap1_delay_ms = 250.0: SUCCESS")
	
	delay.feedback_active = true
	print("Set delay.feedback_active = true: SUCCESS")
	
	# Simulate checking for wrong property
	if "mix" in delay_properties:
		delay.mix = 0.5
		print("Set delay.mix = 0.5: SUCCESS")
	else:
		print("CORRECTLY AVOIDED: 'mix' is not a property of AudioEffectDelay")
		print("The correct properties are tap1_active, feedback_active, etc.")

func test_audio_bus_setup():
	print("\nTesting full audio bus setup...")
	
	# Load and instantiate the audio system
	var AudioManager = load("res://scripts/autoloads/audio_manager.gd")
	var audio_manager = AudioManager.new()
	
	# Run the setup
	audio_manager._ready()
	
	# Check if buses were created
	var expected_buses = ["Master", "Melody", "Bass", "Percussion", "SFX"]
	var all_found = true
	
	print("\nChecking for expected buses:")
	for bus_name in expected_buses:
		var idx = AudioServer.get_bus_index(bus_name)
		if idx < 0:
			print("ERROR: Bus '%s' not found!" % bus_name)
			all_found = false
		else:
			print("✓ Bus '%s' found at index %d" % [bus_name, idx])
			# Check for effects on each bus
			var effect_count = AudioServer.get_bus_effect_count(idx)
			print("  - Has %d effects" % effect_count)
	
	if all_found:
		print("\nSUCCESS: All audio buses created successfully")
	else:
		print("\nFAILURE: Some audio buses were not created")

# Helper function to list all properties of an object
func list_properties(obj) -> Array:
	var properties = []
	
	for prop in obj.get_property_list():
		if not prop.name.begins_with("_") and not prop.name.begins_with("script"):
			properties.append(prop.name)
			print("  - %s: %s" % [prop.name, _get_type_name(prop.type)])
	
	return properties

func _get_type_name(type: int) -> String:
	match type:
		TYPE_NIL: return "nil"
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "String"
		TYPE_VECTOR2: return "Vector2"
		TYPE_VECTOR3: return "Vector3"
		TYPE_COLOR: return "Color"
		TYPE_OBJECT: return "Object"
		TYPE_ARRAY: return "Array"
		TYPE_DICTIONARY: return "Dictionary"
		_: return "Unknown"