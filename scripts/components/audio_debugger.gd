# audio_debugger.gd
extends Node

func _ready():
	print("Audio Debugger initialized")

# Test creating an effect and assigning properties
func test_effect(effect_type: String) -> AudioEffect:
	var effect = null
	
	match effect_type:
		"reverb":
			effect = AudioEffectReverb.new()
			print("Reverb properties:")
			_print_properties(effect)
		"delay":
			effect = AudioEffectDelay.new()
			print("Delay properties:")
			_print_properties(effect)
		"chorus":
			effect = AudioEffectChorus.new()
			print("Chorus properties:")
			_print_properties(effect)
		"compressor":
			effect = AudioEffectCompressor.new()
			print("Compressor properties:")
			_print_properties(effect)
		"eq":
			effect = AudioEffectEQ.new()
			print("EQ properties:")
			_print_properties(effect)
		# Add more effect types as needed
		_:
			print("Unknown effect type: %s" % effect_type)
	
	return effect

# Print all accessible properties for an object
func _print_properties(obj) -> void:
	if obj == null:
		print("Object is null")
		return
	
	for prop in obj.get_property_list():
		if not prop.name.begins_with("_"):  # Skip internal properties
			var value = "?"
			if obj.get(prop.name) != null:
				value = str(obj.get(prop.name))
			print("- %s: %s" % [prop.name, value])