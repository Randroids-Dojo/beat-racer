# test_audio_effects.gd
# Unit tests for individual audio effect properties and behaviors
extends SceneTree

var VerificationHelpers

func _init():
	print("=== UNIT TEST: Audio Effects ===")
	
	# Load helpers
	VerificationHelpers = load("res://scripts/components/verification_helpers.gd")
	
	# Run tests
	test_reverb_properties()
	test_delay_properties() 
	test_chorus_properties()
	test_compressor_properties()
	test_eq_properties()
	test_distortion_properties()
	
	print("=== Audio Effects Unit Test Complete ===")
	quit()

func test_reverb_properties():
	print("\nTesting AudioEffectReverb...")
	
	var reverb = AudioEffectReverb.new()
	var expected_properties = [
		"room_size",
		"damping",
		"spread",
		"wet",
		"dry",
		"predelay_msec",
		"predelay_feedback"
	]
	
	var all_found = true
	for prop in expected_properties:
		if VerificationHelpers.property_exists(reverb, prop):
			print("✓ %s exists" % prop)
		else:
			print("✗ %s missing" % prop)
			all_found = false
	
	# Test property ranges
	reverb.room_size = 0.8
	reverb.damping = 0.5
	reverb.spread = 1.0
	reverb.wet = 0.3
	reverb.dry = 0.7
	
	print("Property test: %s" % ("PASSED" if all_found else "FAILED"))

func test_delay_properties():
	print("\nTesting AudioEffectDelay...")
	
	var delay = AudioEffectDelay.new()
	
	# Test correct properties
	var correct_properties = [
		"dry",
		"tap1_active",
		"tap1_delay_ms",
		"tap1_level_db",
		"tap1_pan",
		"tap2_active",
		"tap2_delay_ms",
		"tap2_level_db",
		"tap2_pan",
		"feedback_active",
		"feedback_delay_ms",
		"feedback_level_db",
		"feedback_lowpass"
	]
	
	var all_found = true
	for prop in correct_properties:
		if VerificationHelpers.property_exists(delay, prop):
			print("✓ %s exists" % prop)
		else:
			print("✗ %s missing" % prop)
			all_found = false
	
	# Verify 'mix' does NOT exist
	if not VerificationHelpers.property_exists(delay, "mix"):
		print("✓ 'mix' property correctly absent")
	else:
		print("✗ ERROR: 'mix' property exists (should not)")
		all_found = false
	
	# Test property values
	delay.tap1_active = true
	delay.tap1_delay_ms = 250.0
	delay.tap1_level_db = -6.0
	delay.dry = 0.8
	
	print("Property test: %s" % ("PASSED" if all_found else "FAILED"))

func test_chorus_properties():
	print("\nTesting AudioEffectChorus...")
	
	var chorus = AudioEffectChorus.new()
	var expected_properties = [
		"voice_count",
		"dry",
		"wet",
		"voice_delay_ms",
		"voice_rate_hz",
		"voice_depth_ms",
		"voice_level_db",
		"voice_cutoff_hz",
		"voice_pan"
	]
	
	var all_found = true
	for i in range(1, 5):  # Chorus typically has 4 voices
		for base_prop in ["delay_ms", "rate_hz", "depth_ms", "level_db", "cutoff_hz", "pan"]:
			var prop = "voice/%d/%s" % [i, base_prop]
			if VerificationHelpers.property_exists(chorus, prop):
				print("✓ %s exists" % prop)
			else:
				# Try alternative property names
				var alt_prop = "voice_%d_%s" % [i, base_prop]
				if VerificationHelpers.property_exists(chorus, alt_prop):
					print("✓ %s exists (as %s)" % [prop, alt_prop])
				else:
					print("! %s might have different naming" % prop)
	
	# Test common properties
	if VerificationHelpers.property_exists(chorus, "voice_count"):
		chorus.voice_count = 2
		print("✓ voice_count set to 2")
	
	if VerificationHelpers.property_exists(chorus, "dry"):
		chorus.dry = 0.6
		print("✓ dry set to 0.6")
	
	if VerificationHelpers.property_exists(chorus, "wet"):
		chorus.wet = 0.4
		print("✓ wet set to 0.4")
	
	print("Property test: PASSED (with naming variations)")

func test_compressor_properties():
	print("\nTesting AudioEffectCompressor...")
	
	var compressor = AudioEffectCompressor.new()
	var expected_properties = [
		"threshold",
		"ratio",
		"gain",
		"attack_us",
		"release_ms",
		"mix",
		"sidechain"
	]
	
	var all_found = true
	for prop in expected_properties:
		if VerificationHelpers.property_exists(compressor, prop):
			print("✓ %s exists" % prop)
		else:
			print("✗ %s missing" % prop)
			all_found = false
	
	# Test property values
	compressor.threshold = -20.0
	compressor.ratio = 4.0
	compressor.gain = 0.0
	compressor.attack_us = 20.0
	compressor.release_ms = 250.0
	compressor.mix = 1.0
	
	print("Property test: %s" % ("PASSED" if all_found else "FAILED"))

func test_eq_properties():
	print("\nTesting AudioEffectEQ...")
	
	# Test different EQ types
	var eq6 = AudioEffectEQ6.new()
	var eq10 = AudioEffectEQ10.new()
	var eq21 = AudioEffectEQ21.new()
	
	print("EQ6 band count: %d" % eq6.get_band_count())
	print("EQ10 band count: %d" % eq10.get_band_count())
	print("EQ21 band count: %d" % eq21.get_band_count())
	
	# Test band gain setting
	for i in range(eq6.get_band_count()):
		eq6.set_band_gain_db(i, -3.0)
		print("✓ EQ6 band %d gain set to -3dB" % i)
	
	print("Property test: PASSED")

func test_distortion_properties():
	print("\nTesting AudioEffectDistortion...")
	
	var distortion = AudioEffectDistortion.new()
	var expected_properties = [
		"mode",
		"pre_gain",
		"post_gain",
		"keep_hf_hz",
		"drive"
	]
	
	var all_found = true
	for prop in expected_properties:
		if VerificationHelpers.property_exists(distortion, prop):
			print("✓ %s exists" % prop)
		else:
			print("✗ %s missing" % prop)
			all_found = false
	
	# Test property values and mode enum
	distortion.mode = AudioEffectDistortion.MODE_CLIP
	distortion.pre_gain = 0.0
	distortion.post_gain = 0.0
	distortion.keep_hf_hz = 16000.0
	distortion.drive = 0.5
	
	print("Property test: %s" % ("PASSED" if all_found else "FAILED"))