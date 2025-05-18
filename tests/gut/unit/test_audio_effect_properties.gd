# test_audio_effect_properties.gd
# Audio effect property tests converted to GUT framework
extends GutTest

var VerificationHelpers

func before_all():
	VerificationHelpers = load("res://scripts/components/verification_helpers.gd")

func test_audio_effect_delay_properties():
	gut.p("Testing AudioEffectDelay property validation")
	
	var delay = AudioEffectDelay.new()
	
	# List properties
	var props = []
	for prop in delay.get_property_list():
		if not prop.name.begins_with("_") and prop.name != "script":
			props.append(prop.name)
	
	# Test expected properties
	assert_has(props, "tap1_active", "AudioEffectDelay should have tap1_active property")
	assert_has(props, "feedback_active", "AudioEffectDelay should have feedback_active property")
	
	# Test that 'mix' property doesn't exist
	assert_does_not_have(props, 'mix', "AudioEffectDelay should NOT have 'mix' property")
	
	# Test that 'dry' property exists instead
	assert_has(props, 'dry', "AudioEffectDelay should have 'dry' property instead of 'mix'")

func test_reverb_properties():
	gut.p("Testing AudioEffectReverb property validation")
	
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
	
	for prop in expected_properties:
		assert_true(
			VerificationHelpers.property_exists(reverb, prop),
			"AudioEffectReverb should have %s property" % prop
		)
	
	# Test property ranges
	reverb.room_size = 0.8
	reverb.damping = 0.5
	reverb.spread = 1.0
	reverb.wet = 0.3
	
	assert_almost_eq(reverb.room_size, 0.8, 0.01, "room_size should be set correctly")
	assert_almost_eq(reverb.damping, 0.5, 0.01, "damping should be set correctly")
	assert_almost_eq(reverb.spread, 1.0, 0.01, "spread should be set correctly")
	assert_almost_eq(reverb.wet, 0.3, 0.01, "wet should be set correctly")

func test_chorus_properties():
	gut.p("Testing AudioEffectChorus property validation")
	
	var chorus = AudioEffectChorus.new()
	var expected_properties = [
		"voice_count",
		"wet",
		"dry"
	]
	
	for prop in expected_properties:
		assert_true(
			VerificationHelpers.property_exists(chorus, prop),
			"AudioEffectChorus should have %s property" % prop
		)
	
	# Test voice properties dynamically
	for i in range(4):  # Default max voices
		var cutoff_prop = "voice/%d/cutoff_hz" % (i + 1)
		var delay_prop = "voice/%d/delay_ms" % (i + 1)
		var depth_prop = "voice/%d/depth_ms" % (i + 1)
		var level_prop = "voice/%d/level_db" % (i + 1)
		var pan_prop = "voice/%d/pan" % (i + 1)
		var rate_prop = "voice/%d/rate_hz" % (i + 1)
		
		for prop in [cutoff_prop, delay_prop, depth_prop, level_prop, pan_prop, rate_prop]:
			assert_true(
				VerificationHelpers.property_exists(chorus, prop),
				"Voice %d should have %s" % [i + 1, prop]
			)

func test_property_verification_helper():
	gut.p("Testing property verification helper functionality")
	
	var delay = AudioEffectDelay.new()
	
	# Test that helper correctly identifies existing properties
	assert_true(
		VerificationHelpers.property_exists(delay, "dry"),
		"Helper should detect 'dry' property exists"
	)
	
	# Test that helper correctly identifies non-existent properties
	assert_false(
		VerificationHelpers.property_exists(delay, "mix"),
		"Helper should detect 'mix' property doesn't exist"
	)
	
	# Test listing properties
	var props = VerificationHelpers.list_properties(delay)
	assert_true(props.size() > 0, "Helper should list properties")
	assert_has(props, "dry", "Listed properties should include 'dry'")
	assert_does_not_have(props, "mix", "Listed properties should not include 'mix'")