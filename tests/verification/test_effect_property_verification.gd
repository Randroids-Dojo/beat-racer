# test_effect_property_verification.gd
# Comprehensive verification of all audio effect properties
extends SceneTree

var VerificationHelpers

# Maps of expected properties for each effect type
var effect_property_maps = {
	"AudioEffectReverb": {
		"required": ["room_size", "damping", "spread", "wet", "dry", "predelay_msec", "predelay_feedback"],
		"forbidden": []
	},
	"AudioEffectDelay": {
		"required": ["dry", "tap1_active", "tap1_delay_ms", "tap1_level_db", "tap1_pan", 
					"tap2_active", "tap2_delay_ms", "tap2_level_db", "tap2_pan",
					"feedback_active", "feedback_delay_ms", "feedback_level_db", "feedback_lowpass"],
		"forbidden": ["mix"]  # IMPORTANT: AudioEffectDelay does NOT have 'mix' property
	},
	"AudioEffectChorus": {
		"required": ["voice_count", "dry", "wet"],
		"forbidden": []
	},
	"AudioEffectCompressor": {
		"required": ["threshold", "ratio", "gain", "attack_us", "release_ms", "mix", "sidechain"],
		"forbidden": []
	},
	"AudioEffectDistortion": {
		"required": ["mode", "pre_gain", "post_gain", "keep_hf_hz", "drive"],
		"forbidden": []
	},
	"AudioEffectFilter": {
		"required": ["cutoff_hz", "resonance", "gain", "db"],
		"forbidden": []
	},
	"AudioEffectPitchShift": {
		"required": ["pitch_scale", "oversampling", "fft_size"],
		"forbidden": []
	},
	"AudioEffectPhaser": {
		"required": ["range_min_hz", "range_max_hz", "rate_hz", "feedback", "depth"],
		"forbidden": []
	}
}

func _init():
	print("=== COMPREHENSIVE EFFECT PROPERTY VERIFICATION ===")
	print("This test verifies all audio effect properties against expected values")
	print("as documented in CLAUDE.md\n")
	
	VerificationHelpers = load("res://scripts/components/verification_helpers.gd")
	
	var all_passed = true
	
	for effect_name in effect_property_maps:
		if not test_effect_properties(effect_name):
			all_passed = false
	
	print("\n=== VERIFICATION SUMMARY ===")
	if all_passed:
		print("✓ ALL EFFECTS PASSED VERIFICATION")
	else:
		print("✗ SOME EFFECTS FAILED VERIFICATION")
		print("Please update code to match actual Godot 4 API")
	
	quit()

func test_effect_properties(effect_name: String) -> bool:
	print("\n--- Testing %s ---" % effect_name)
	
	# Get the effect class
	var effect_class = ClassDB.instantiate(effect_name)
	if effect_class == null:
		print("✗ Failed to instantiate %s" % effect_name)
		return false
	
	var expected = effect_property_maps[effect_name]
	var actual_properties = get_all_properties(effect_class)
	
	print("Found %d properties" % actual_properties.size())
	
	var passed = true
	
	# Check required properties
	print("\nRequired properties:")
	for prop in expected.required:
		if prop in actual_properties:
			print("✓ %s" % prop)
		else:
			print("✗ %s (MISSING)" % prop)
			passed = false
	
	# Check forbidden properties
	if expected.forbidden.size() > 0:
		print("\nForbidden properties (should NOT exist):")
		for prop in expected.forbidden:
			if prop in actual_properties:
				print("✗ %s (EXISTS - SHOULD NOT)" % prop)
				passed = false
			else:
				print("✓ %s (correctly absent)" % prop)
	
	# List unexpected properties
	print("\nAdditional properties found:")
	for prop in actual_properties:
		if not prop in expected.required and not prop in expected.forbidden:
			print("  - %s" % prop)
	
	# Special validation for AudioEffectDelay
	if effect_name == "AudioEffectDelay":
		print("\n*** SPECIAL VALIDATION FOR AudioEffectDelay ***")
		if "mix" in actual_properties:
			print("✗ ERROR: AudioEffectDelay has 'mix' property!")
			print("  This violates CLAUDE.md documentation")
			print("  AudioEffectDelay should use dry/wet instead")
			passed = false
		else:
			print("✓ Confirmed: AudioEffectDelay does not have 'mix' property")
			print("  This matches CLAUDE.md documentation")
		
		if "dry" in actual_properties:
			print("✓ AudioEffectDelay has 'dry' property (correct)")
		else:
			print("✗ AudioEffectDelay missing 'dry' property")
			passed = false
	
	# Test property access
	print("\nTesting property access:")
	var test_props = expected.required[0:min(3, expected.required.size())]
	for prop in test_props:
		if test_property_access(effect_class, prop):
			print("✓ Can access %s" % prop)
		else:
			print("✗ Cannot access %s" % prop)
			passed = false
	
	effect_class.queue_free()
	
	return passed

func get_all_properties(obj) -> Array:
	var properties = []
	
	for prop in obj.get_property_list():
		# Skip internal and script properties
		if not prop.name.begins_with("_") and \
		   not prop.name.begins_with("script") and \
		   not prop.name in ["Node", "resource_path", "resource_name"]:
			properties.append(prop.name)
	
	return properties

func test_property_access(obj, property_name: String) -> bool:
	# Try to read the property
	var value = obj.get(property_name)
	if value == null and not VerificationHelpers.property_exists(obj, property_name):
		return false
	
	# Try to write the property (with appropriate value)
	match typeof(value):
		TYPE_BOOL:
			obj.set(property_name, true)
		TYPE_INT:
			obj.set(property_name, 1)
		TYPE_FLOAT:
			obj.set(property_name, 1.0)
		TYPE_STRING:
			obj.set(property_name, "test")
		_:
			# Just try to set the same value back
			obj.set(property_name, value)
	
	return true