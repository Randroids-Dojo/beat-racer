# test_comprehensive_audio.gd
# Comprehensive audio system test for Beat Racer
extends SceneTree

var test_results: Dictionary = {}
var _audio_manager = null
var _verification_helper = null

func _init():
	print("\n===== BEAT RACER COMPREHENSIVE AUDIO TEST =====")
	print("Starting at: %s" % Time.get_time_string_from_system())
	
	# Run test suite
	run_all_tests()
	
	# Print results
	print_results()
	
	print("\n===== TEST COMPLETE =====")
	quit()

func run_all_tests():
	test_audio_effect_properties()
	test_audio_bus_setup()
	test_volume_controls()
	test_effect_verification()
	test_ui_configuration()

func test_audio_effect_properties():
	print("\n[TEST] Audio Effect Properties")
	var test_name = "audio_effect_properties"
	test_results[test_name] = {"passed": 0, "failed": 0, "details": []}
	
	# Test AudioEffectDelay - verify it doesn't have 'mix' property
	var delay = AudioEffectDelay.new()
	
	# List properties
	var props = []
	for prop in delay.get_property_list():
		if not prop.name.begins_with("_") and prop.name != "script":
			props.append(prop.name)
	
	# Test expected properties
	if "tap1_active" in props:
		test_results[test_name]["passed"] += 1
		test_results[test_name]["details"].append("✓ AudioEffectDelay has tap1_active")
	else:
		test_results[test_name]["failed"] += 1
		test_results[test_name]["details"].append("✗ AudioEffectDelay missing tap1_active")
	
	if "feedback_active" in props:
		test_results[test_name]["passed"] += 1
		test_results[test_name]["details"].append("✓ AudioEffectDelay has feedback_active")
	else:
		test_results[test_name]["failed"] += 1
		test_results[test_name]["details"].append("✗ AudioEffectDelay missing feedback_active")
	
	# Verify 'mix' doesn't exist (as per CLAUDE.md)
	if "mix" not in props:
		test_results[test_name]["passed"] += 1
		test_results[test_name]["details"].append("✓ AudioEffectDelay correctly lacks 'mix' property")
	else:
		test_results[test_name]["failed"] += 1
		test_results[test_name]["details"].append("✗ AudioEffectDelay incorrectly has 'mix' property")
	
	# Test correct property alternative
	if "dry" in props:
		test_results[test_name]["passed"] += 1
		test_results[test_name]["details"].append("✓ AudioEffectDelay has 'dry' property instead")
	else:
		test_results[test_name]["failed"] += 1
		test_results[test_name]["details"].append("✗ AudioEffectDelay missing 'dry' property")

func test_audio_bus_setup():
	print("\n[TEST] Audio Bus Setup")
	var test_name = "audio_bus_setup"
	test_results[test_name] = {"passed": 0, "failed": 0, "details": []}
	
	# Create audio manager instance
	var AudioManager = load("res://scripts/autoloads/audio_manager.gd")
	if not AudioManager:
		test_results[test_name]["failed"] += 1
		test_results[test_name]["details"].append("✗ Failed to load AudioManager script")
		return
	
	_audio_manager = AudioManager.new()
	_audio_manager._ready()
	
	# Test bus creation
	var expected_buses = ["Master", "Melody", "Bass", "Percussion", "SFX"]
	for bus_name in expected_buses:
		var idx = AudioServer.get_bus_index(bus_name)
		if idx >= 0:
			test_results[test_name]["passed"] += 1
			test_results[test_name]["details"].append("✓ Bus '%s' created at index %d" % [bus_name, idx])
		else:
			test_results[test_name]["failed"] += 1
			test_results[test_name]["details"].append("✗ Bus '%s' not found" % bus_name)
	
	# Verify effects on buses
	if _audio_manager._melody_idx >= 0:
		var effects = AudioServer.get_bus_effect_count(_audio_manager._melody_idx)
		if effects > 0:
			test_results[test_name]["passed"] += 1
			test_results[test_name]["details"].append("✓ Melody bus has %d effects" % effects)
		else:
			test_results[test_name]["failed"] += 1
			test_results[test_name]["details"].append("✗ Melody bus has no effects")

func test_volume_controls():
	print("\n[TEST] Volume Controls")
	var test_name = "volume_controls"
	test_results[test_name] = {"passed": 0, "failed": 0, "details": []}
	
	if not _audio_manager:
		test_results[test_name]["failed"] += 1
		test_results[test_name]["details"].append("✗ AudioManager not initialized")
		return
	
	# Test volume setting
	_audio_manager.set_bus_volume_db("Melody", -10.0)
	var volume = _audio_manager.get_bus_volume_db("Melody")
	
	if abs(volume - (-10.0)) < 0.01:
		test_results[test_name]["passed"] += 1
		test_results[test_name]["details"].append("✓ Volume control works (-10.0dB)")
	else:
		test_results[test_name]["failed"] += 1
		test_results[test_name]["details"].append("✗ Volume control failed (expected -10.0, got %f)" % volume)
	
	# Test linear volume conversion
	_audio_manager.set_bus_volume_linear("Melody", 0.5)
	var linear = _audio_manager.get_bus_volume_linear("Melody")
	
	if abs(linear - 0.5) < 0.1:  # Allow some tolerance for conversion
		test_results[test_name]["passed"] += 1
		test_results[test_name]["details"].append("✓ Linear volume control works (0.5)")
	else:
		test_results[test_name]["failed"] += 1
		test_results[test_name]["details"].append("✗ Linear volume failed (expected 0.5, got %f)" % linear)

func test_effect_verification():
	print("\n[TEST] Effect Property Verification")
	var test_name = "effect_verification"
	test_results[test_name] = {"passed": 0, "failed": 0, "details": []}
	
	# Load verification helpers
	var helpers = load("res://scripts/components/verification_helpers.gd")
	if not helpers:
		test_results[test_name]["failed"] += 1
		test_results[test_name]["details"].append("✗ Failed to load verification helpers")
		return
	
	# Test property checking on AudioEffectDelay
	var delay = AudioEffectDelay.new()
	
	# Check property exists (expected to pass)
	if helpers.property_exists(delay, "tap1_active"):
		test_results[test_name]["passed"] += 1
		test_results[test_name]["details"].append("✓ property_exists() correctly found tap1_active")
	else:
		test_results[test_name]["failed"] += 1
		test_results[test_name]["details"].append("✗ property_exists() failed to find tap1_active")
	
	# Check property doesn't exist (expected to pass)
	if not helpers.property_exists(delay, "mix"):
		test_results[test_name]["passed"] += 1
		test_results[test_name]["details"].append("✓ property_exists() correctly reported 'mix' doesn't exist")
	else:
		test_results[test_name]["failed"] += 1
		test_results[test_name]["details"].append("✗ property_exists() incorrectly found 'mix' property")

func test_ui_configuration():
	print("\n[TEST] UI Configuration Guidelines")
	var test_name = "ui_configuration"
	test_results[test_name] = {"passed": 0, "failed": 0, "details": []}
	
	# Create a test slider to verify configuration
	var slider = HSlider.new()
	
	# Set proper configuration as per CLAUDE.md
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01  # Critical for smooth operation
	slider.value = 0.5
	
	# Verify configuration
	if abs(slider.step - 0.01) < 0.001:
		test_results[test_name]["passed"] += 1
		test_results[test_name]["details"].append("✓ Slider step correctly set to 0.01")
	else:
		test_results[test_name]["failed"] += 1
		test_results[test_name]["details"].append("✗ Slider step incorrect (expected 0.01, got %f)" % slider.step)
	
	# Test value change precision
	slider.value = 0.567
	if abs(slider.value - 0.567) < 0.01:
		test_results[test_name]["passed"] += 1
		test_results[test_name]["details"].append("✓ Slider can handle precise values")
	else:
		test_results[test_name]["failed"] += 1
		test_results[test_name]["details"].append("✗ Slider precision issue (expected 0.567, got %f)" % slider.value)

func print_results():
	print("\n===== TEST RESULTS SUMMARY =====")
	
	var total_passed = 0
	var total_failed = 0
	
	for test_name in test_results:
		var result = test_results[test_name]
		print("\n[%s]" % test_name.to_upper())
		print("Passed: %d | Failed: %d" % [result["passed"], result["failed"]])
		
		for detail in result["details"]:
			print("  %s" % detail)
		
		total_passed += result["passed"]
		total_failed += result["failed"]
	
	print("\n===== OVERALL RESULTS =====")
	print("Total Passed: %d" % total_passed)
	print("Total Failed: %d" % total_failed)
	print("Success Rate: %.1f%%" % (float(total_passed) / float(total_passed + total_failed) * 100.0))
	
	if total_failed == 0:
		print("\n✓ ALL TESTS PASSED!")
	else:
		print("\n✗ Some tests failed - review details above")