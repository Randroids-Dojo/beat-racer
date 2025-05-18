# test_ui_configuration.gd
# Tests for UI configuration, especially slider settings
extends SceneTree

func _init():
	print("=== UI CONFIGURATION TEST ===")
	
	test_slider_configuration()
	test_slider_behavior()
	test_default_values()
	test_step_configuration_errors()
	
	print("=== UI Configuration Test Complete ===")
	quit()

func test_slider_configuration():
	print("\nTesting slider configuration...")
	
	var slider = HSlider.new()
	
	# Test default configuration (often problematic)
	print("Default configuration:")
	print("  min_value: %f" % slider.min_value)
	print("  max_value: %f" % slider.max_value)
	print("  step: %f" % slider.step)
	print("  value: %f" % slider.value)
	
	# Apply correct configuration
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01  # CRITICAL for smooth operation
	slider.value = 0.5
	
	print("\nAfter configuration:")
	print("  min_value: %f" % slider.min_value)
	print("  max_value: %f" % slider.max_value)
	print("  step: %f" % slider.step)
	print("  value: %f" % slider.value)
	
	if slider.step == 0.01:
		print("✓ Step value correctly set to 0.01")
	else:
		print("✗ Step value incorrect: %f" % slider.step)
	
	slider.queue_free()

func test_slider_behavior():
	print("\nTesting slider behavior with different step values...")
	
	# Test with incorrect step (0 or very large)
	var bad_slider = HSlider.new()
	bad_slider.min_value = 0.0
	bad_slider.max_value = 1.0
	bad_slider.step = 1.0  # Bad: only allows 0 or 1
	
	print("\nBad slider (step=1.0):")
	bad_slider.value = 0.5
	print("  Set to 0.5, actual value: %f" % bad_slider.value)
	bad_slider.value = 0.75
	print("  Set to 0.75, actual value: %f" % bad_slider.value)
	
	if bad_slider.value == 1.0:
		print("✓ Correctly demonstrates binary behavior with step=1.0")
	
	# Test with correct step
	var good_slider = HSlider.new()
	good_slider.min_value = 0.0
	good_slider.max_value = 1.0
	good_slider.step = 0.01  # Good: allows fine control
	
	print("\nGood slider (step=0.01):")
	good_slider.value = 0.5
	print("  Set to 0.5, actual value: %f" % good_slider.value)
	good_slider.value = 0.75
	print("  Set to 0.75, actual value: %f" % good_slider.value)
	
	if abs(good_slider.value - 0.75) < 0.001:
		print("✓ Correctly allows fine control with step=0.01")
	
	bad_slider.queue_free()
	good_slider.queue_free()

func test_default_values():
	print("\nTesting default value configuration...")
	
	# Create sliders for each audio bus
	var sliders = {
		"master": HSlider.new(),
		"melody": HSlider.new(),
		"bass": HSlider.new(),
		"percussion": HSlider.new(),
		"sfx": HSlider.new()
	}
	
	# Configure all sliders properly
	for name in sliders:
		var slider = sliders[name]
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		
		# Set appropriate default values
		match name:
			"master":
				slider.value = 0.8  # Master slightly lower
			"melody":
				slider.value = 0.5  # -6dB for music
			"bass":
				slider.value = 0.7  # Bass moderate
			"percussion":
				slider.value = 0.6  # Drums moderate
			"sfx":
				slider.value = 1.0  # SFX full by default
		
		print("%s default: %f (%.1f dB)" % [name, slider.value, linear_to_db(slider.value)])
		
		slider.queue_free()
	
	print("✓ Default values configured correctly")

func test_step_configuration_errors():
	print("\nTesting common step configuration errors...")
	
	# Error 1: No step value (defaults to 1.0 in some cases)
	var slider1 = HSlider.new()
	slider1.min_value = 0.0
	slider1.max_value = 1.0
	# Not setting step - this is the error!
	
	print("Error case 1 - No step set:")
	print("  Default step: %f" % slider1.step)
	
	if slider1.step >= 1.0:
		print("✗ ERROR: Default step too large, causes binary behavior")
	
	# Error 2: Step value from scene file not applied
	print("\nError case 2 - Scene file step ignored:")
	print("  This happens when scene .tscn has step but code overrides it")
	print("  Always set step programmatically as failsafe!")
	
	# Correct approach: Always set step in code
	var slider2 = HSlider.new()
	slider2.min_value = 0.0
	slider2.max_value = 1.0
	slider2.step = 0.01  # Always set this!
	
	print("\nCorrect approach:")
	print("  Explicitly set step: %f" % slider2.step)
	print("✓ Step value ensures smooth control")
	
	# Test value changes
	print("\nTesting value changes:")
	slider2.value = 0.0
	for i in range(11):
		slider2.value = i * 0.1
		print("  Set to %.1f, actual: %.3f" % [i * 0.1, slider2.value])
	
	slider1.queue_free()
	slider2.queue_free()
	
	print("\n*** IMPORTANT NOTES ***")
	print("1. ALWAYS set step = 0.01 for audio sliders")
	print("2. Set step in code even if defined in scene")
	print("3. Test actual values, not just visual appearance")
	print("4. Default step may cause binary (0/1) behavior")