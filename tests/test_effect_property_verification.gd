# Test Effect Property Verification Helpers
extends SceneTree

func _init():
	print("\n=== Testing Effect Property Verification ===")
	
	# Load verification helpers
	var VerificationHelpers = preload("res://scripts/components/verification_helpers.gd")
	var helpers = VerificationHelpers.new()
	
	# Test property_exists function
	print("\n1. Testing property_exists function...")
	var delay = AudioEffectDelay.new()
	
	# Test known properties
	var known_properties = [
		"tap1_active", "tap1_delay_ms", "tap1_level_db", "tap1_pan",
		"tap2_active", "tap2_delay_ms", "tap2_level_db", "tap2_pan",
		"feedback_active", "feedback_delay_ms", "feedback_level_db", "feedback_lowpass",
		"dry", "wet"
	]
	
	for prop in known_properties:
		if helpers.property_exists(delay, prop):
			print("✓ Property '%s' exists" % prop)
		else:
			print("✗ Property '%s' missing" % prop)
	
	# Test non-existent properties
	print("\n2. Testing non-existent properties...")
	var fake_properties = ["mix", "blend", "volume"]
	
	for prop in fake_properties:
		if helpers.property_exists(delay, prop):
			print("✗ Property '%s' should not exist!" % prop)
		else:
			print("✓ Property '%s' correctly not found" % prop)
	
	# Test list_properties function
	print("\n3. Testing list_properties function...")
	var properties = helpers.list_properties(delay)
	print("AudioEffectDelay has %d properties:" % properties.size())
	for prop in properties.slice(0, 5): # Show first 5
		print("  - %s" % prop)
	print("  ... and %d more" % (properties.size() - 5))
	
	# Test with different effect types
	print("\n4. Testing property listing for different effects...")
	var effects = {
		"AudioEffectChorus": AudioEffectChorus.new(),
		"AudioEffectReverb": AudioEffectReverb.new(),
		"AudioEffectDistortion": AudioEffectDistortion.new()
	}
	
	for effect_name in effects:
		var effect = effects[effect_name]
		var props = helpers.list_properties(effect)
		print("\n%s has %d properties:" % [effect_name, props.size()])
		for prop in props.slice(0, 3): # Show first 3
			print("  - %s" % prop)
	
	print("\n=== Effect Property Verification Test Complete ===")
	quit()
