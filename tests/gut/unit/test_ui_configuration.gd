# test_ui_configuration.gd
# UI configuration tests converted to GUT framework
extends GutTest

func test_slider_step_configuration():
	gut.p("Testing HSlider step configuration for smooth control")
	
	var slider = HSlider.new()
	
	# Test default step (often problematic)
	gut.p("Default slider step: %f" % slider.step)
	
	# Configure for smooth operation
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	
	assert_eq(slider.min_value, 0.0, "Min value should be 0")
	assert_eq(slider.max_value, 1.0, "Max value should be 1")
	assert_eq(slider.step, 0.01, "Step should be 0.01 for smooth control")
	
	# Test that fine control is possible
	slider.value = 0.5
	assert_eq(slider.value, 0.5, "Should set value to 0.5")
	
	slider.value = 0.75
	assert_eq(slider.value, 0.75, "Should set value to 0.75")
	
	# Without proper step, values would jump to 0 or 1
	slider.value = 0.33
	assert_almost_eq(slider.value, 0.33, 0.01, "Should set value to 0.33 with precision")
	
	# Clean up properly
	remove_child(slider)
	slider.queue_free()

func test_vslider_configuration():
	gut.p("Testing VSlider configuration")
	
	var vslider = VSlider.new()
	
	# Configure same as HSlider
	vslider.min_value = 0.0
	vslider.max_value = 1.0
	vslider.step = 0.01
	
	assert_eq(vslider.step, 0.01, "VSlider should also have 0.01 step")
	
	# Test intermediate values
	vslider.value = 0.25
	assert_eq(vslider.value, 0.25, "Should set value to 0.25")

func test_slider_audio_volume_mapping():
	gut.p("Testing slider to audio volume dB mapping")
	
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	
	# Test common volume mappings
	var test_values = {
		1.0: 0.0,    # Full volume = 0 dB
		0.5: -6.0,   # Half linear = -6 dB (approximately)
		0.0: -80.0   # Silence = -80 dB (or -inf)
	}
	
	for linear_value in test_values:
		var expected_db = test_values[linear_value]
		var actual_db = linear_to_db(linear_value)
		
		if linear_value == 0.0:
			# Special case for silence
			assert_lt(actual_db, -60.0, "Silence should be very low dB")
		else:
			# Allow some tolerance for floating point
			assert_almost_eq(actual_db, expected_db, 1.0, 
				"Linear %f should map to approximately %f dB" % [linear_value, expected_db])

func test_slider_scene_configuration():
	gut.p("Testing slider scene configuration best practices")
	
	# This test documents the correct way to configure sliders
	var slider = HSlider.new()
	
	# CRITICAL: Always set step property
	slider.step = 0.01
	
	# Set reasonable defaults
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.value = 1.0  # Default to full volume
	
	# Verify configuration
	assert_eq(slider.step, 0.01, "Step MUST be 0.01 for smooth control")
	assert_eq(slider.value, 1.0, "Default value should be 1.0")
	
	# Test that all intermediate values work
	var test_values = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
	for val in test_values:
		slider.value = val
		assert_almost_eq(slider.value, val, 0.01, 
			"Should be able to set value to %f" % val)

func test_multiple_slider_configuration():
	gut.p("Testing multiple slider configuration for audio buses")
	
	var sliders = {
		"master": HSlider.new(),
		"melody": HSlider.new(),
		"bass": HSlider.new(),
		"percussion": HSlider.new()
	}
	
	# Add all sliders as children first
	for name in sliders:
		add_child(sliders[name])
	
	# Configure all sliders uniformly
	for name in sliders:
		var slider = sliders[name]
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.value = 0.5  # Start at -6dB
		
		# Verify configuration
		assert_eq(slider.step, 0.01, "%s slider should have 0.01 step" % name)
		assert_eq(slider.value, 0.5, "%s slider should start at 0.5" % name)
	
	# Clean up properly
	for name in sliders:
		var slider = sliders[name]
		remove_child(slider)
		slider.queue_free()

func test_ui_control_initialization_order():
	gut.p("Testing UI control initialization order")
	
	# Test that controls can be configured after creation
	var slider = HSlider.new()
	
	# Even if step isn't set initially, it can be configured later
	assert_gte(slider.step, 0, "Slider should have non-negative step")
	
	# Configure programmatically
	slider.step = 0.01
	assert_eq(slider.step, 0.01, "Step should be configurable after creation")
	
	# This is important for scene initialization where properties might be set in _ready()