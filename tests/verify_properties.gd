# verify_properties.gd
# Quick property verification for audio effects
extends SceneTree

func _init():
	print("=== PROPERTY VERIFICATION ===")
	
	var effects = {
		"AudioEffectReverb": AudioEffectReverb.new(),
		"AudioEffectDelay": AudioEffectDelay.new(),
		"AudioEffectChorus": AudioEffectChorus.new(),
		"AudioEffectCompressor": AudioEffectCompressor.new(),
		"AudioEffectEQ": AudioEffectEQ.new()
	}
	
	for effect_name in effects:
		print("\n%s properties:" % effect_name)
		var effect = effects[effect_name]
		
		# Check common properties
		check_property(effect, "mix")
		check_property(effect, "wet")
		check_property(effect, "dry")
		check_property(effect, "feedback")
		check_property(effect, "feedback_active")
		check_property(effect, "tap1_active")
		
		# List first 10 actual properties
		print("  Actual properties:")
		var count = 0
		for prop in effect.get_property_list():
			if not prop.name.begins_with("_") and not prop.name == "script":
				print("    - %s" % prop.name)
				count += 1
				if count >= 10:
					print("    ... (more properties available)")
					break
	
	print("\n=== VERIFICATION COMPLETE ===")
	quit()

func check_property(obj, prop_name: String):
	if prop_name in obj:
		print("  ✓ Has '%s'" % prop_name)
	else:
		print("  ✗ No '%s'" % prop_name)