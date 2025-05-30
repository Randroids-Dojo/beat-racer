extends GutTest

const AudioEffectControl = preload("res://scripts/components/ui/audio_effect_control.gd")
const TEST_TIMEOUT = 2.0

var effect_control: AudioEffectControl

func before_each():
	effect_control = AudioEffectControl.new()
	effect_control.name = "TestEffectControl"
	add_child(effect_control)
	await wait_frames(2)

func after_each():
	if effect_control and is_instance_valid(effect_control):
		effect_control.queue_free()
	effect_control = null
	await wait_frames(2)

func test_effect_control_initialization():
	# Test basic initialization
	assert_not_null(effect_control, "Effect control should exist")
	assert_eq(effect_control.get_child_count(), 0, "Should have no children initially")

func test_setup_with_reverb():
	# Test setup with reverb effect
	var melody_idx = AudioServer.get_bus_index("Melody")
	var reverb_idx = 0  # First effect on Melody bus is reverb
	
	effect_control.setup("Melody", reverb_idx)
	await wait_frames(2)
	
	# Check title
	var title = effect_control.get_child(0) as Label
	assert_not_null(title, "Should have title label")
	assert_eq(title.text, "Reverb", "Title should be 'Reverb'")
	
	# Check for parameter controls
	var param_count = 0
	for child in effect_control.get_children():
		if child is HBoxContainer and child.has_node("Slider"):
			param_count += 1
	
	assert_gt(param_count, 0, "Should have parameter controls for reverb")

func test_setup_with_delay():
	# Test setup with delay effect
	var melody_idx = AudioServer.get_bus_index("Melody")
	var delay_idx = 1  # Second effect on Melody bus is delay
	
	effect_control.setup("Melody", delay_idx)
	await wait_frames(2)
	
	# Check title
	var title = effect_control.get_child(0) as Label
	assert_not_null(title, "Should have title label")
	assert_eq(title.text, "Delay", "Title should be 'Delay'")
	
	# Check for dry parameter (NOT mix)
	var found_dry = false
	for child in effect_control.get_children():
		if child is HBoxContainer:
			var label = child.get_child(0) as Label
			if label and label.text == "Dry":
				found_dry = true
				break
	
	assert_true(found_dry, "Delay should have 'Dry' parameter, not 'mix'")

func test_parameter_slider_properties():
	# Test that sliders have correct properties
	effect_control.setup("Melody", 0)  # Reverb
	await wait_frames(2)
	
	for child in effect_control.get_children():
		if child is HBoxContainer and child.has_node("Slider"):
			var slider = child.get_node("Slider") as HSlider
			assert_not_null(slider, "Slider should exist")
			assert_almost_eq(slider.step, 0.01, 0.001, "Slider step should be 0.01")
			assert_gte(slider.min_value, -60.0, "Min value should be reasonable")
			assert_lte(slider.max_value, 60.0, "Max value should be reasonable")

func test_parameter_value_updates():
	# Test that parameter values update correctly
	var melody_idx = AudioServer.get_bus_index("Melody")
	var reverb = AudioServer.get_bus_effect(melody_idx, 0) as AudioEffectReverb
	
	if not reverb:
		pass("No reverb effect to test")
		return
	
	# Set initial value
	reverb.room_size = 0.5
	
	effect_control.setup("Melody", 0)
	await wait_frames(2)
	
	# Find room size control
	var room_size_slider = null
	for child in effect_control.get_children():
		if child is HBoxContainer:
			var label = child.get_child(0) as Label
			if label and label.text == "Room Size":
				room_size_slider = child.get_node("Slider") as HSlider
				break
	
	assert_not_null(room_size_slider, "Room size slider should exist")
	assert_almost_eq(room_size_slider.value, 0.5, 0.01, "Slider should show current value")

func test_parameter_change_signal():
	# Test that parameter changes emit signal
	var signal_emitted = false
	var signal_bus_name = ""
	var signal_effect_idx = -1
	var signal_param_name = ""
	var signal_value = 0.0
	
	effect_control.parameter_changed.connect(func(bus, idx, param, val):
		signal_emitted = true
		signal_bus_name = bus
		signal_effect_idx = idx
		signal_param_name = param
		signal_value = val
	)
	
	effect_control.setup("Melody", 0)  # Reverb
	await wait_frames(2)
	
	# Find and change room size
	for child in effect_control.get_children():
		if child is HBoxContainer:
			var label = child.get_child(0) as Label
			if label and label.text == "Room Size":
				var slider = child.get_node("Slider") as HSlider
				slider.value = 0.7
				slider.value_changed.emit(0.7)
				await wait_frames(1)
				break
	
	assert_true(signal_emitted, "Parameter change signal should be emitted")
	assert_eq(signal_bus_name, "Melody", "Signal should include bus name")
	assert_eq(signal_effect_idx, 0, "Signal should include effect index")
	assert_eq(signal_param_name, "room_size", "Signal should include parameter name")
	assert_almost_eq(signal_value, 0.7, 0.01, "Signal should include new value")

func test_value_label_formatting():
	# Test that value labels are formatted correctly
	effect_control.setup("Melody", 0)  # Reverb
	await wait_frames(2)
	
	# Check various formatting
	for child in effect_control.get_children():
		if child is HBoxContainer and child.has_node("ValueLabel"):
			var label_node = child.get_child(0) as Label
			var value_label = child.get_node("ValueLabel") as Label
			
			if label_node:
				var param_text = label_node.text
				var value_text = value_label.text
				
				# Check formatting based on parameter
				if param_text.contains("Level") and param_text.contains("dB"):
					assert_string_contains(value_text, "dB", "dB parameters should show 'dB'")
				elif param_text.contains("Delay") and param_text.contains("ms"):
					assert_string_contains(value_text, "ms", "ms parameters should show 'ms'")
				elif param_text == "Tap1 Pan":
					# Pan should show L/C/R format
					assert_true(
						value_text.begins_with("L") or 
						value_text.begins_with("R") or 
						value_text == "C",
						"Pan should show L/C/R format"
					)

func test_compressor_parameters():
	# Test compressor-specific parameters
	var bass_idx = AudioServer.get_bus_index("Bass")
	var compressor_idx = 0  # First effect on Bass bus is compressor
	
	effect_control.setup("Bass", compressor_idx)
	await wait_frames(2)
	
	# Check for compressor-specific parameters
	var params_found = {
		"Threshold (dB)": false,
		"Ratio": false,
		"Attack (μs)": false,
		"Release (ms)": false,
		"Gain (dB)": false
	}
	
	for child in effect_control.get_children():
		if child is HBoxContainer:
			var label = child.get_child(0) as Label
			if label and label.text in params_found:
				params_found[label.text] = true
	
	for param in params_found:
		assert_true(params_found[param], "Compressor should have %s parameter" % param)

func test_eq_parameters():
	# Test EQ-specific parameters
	var percussion_idx = AudioServer.get_bus_index("Percussion")
	var eq_idx = 1  # Second effect on Percussion bus is EQ
	
	effect_control.setup("Percussion", eq_idx)
	await wait_frames(2)
	
	# Check for frequency bands
	var band_found = false
	for child in effect_control.get_children():
		if child is HBoxContainer:
			var label = child.get_child(0) as Label
			if label and label.text.contains("Hz"):
				band_found = true
				break
	
	assert_true(band_found, "EQ should have frequency band controls")

func test_effect_parameter_application():
	# Test that changing parameters actually affects the effect
	var melody_idx = AudioServer.get_bus_index("Melody")
	var reverb = AudioServer.get_bus_effect(melody_idx, 0) as AudioEffectReverb
	
	if not reverb:
		pass("No reverb effect to test")
		return
	
	var original_room_size = reverb.room_size
	
	effect_control.setup("Melody", 0)
	await wait_frames(2)
	
	# Change room size
	for child in effect_control.get_children():
		if child is HBoxContainer:
			var label = child.get_child(0) as Label
			if label and label.text == "Room Size":
				var slider = child.get_node("Slider") as HSlider
				slider.value = 0.9
				slider.value_changed.emit(0.9)
				await wait_frames(1)
				break
	
	# Verify effect was updated
	assert_almost_eq(reverb.room_size, 0.9, 0.01, "Effect parameter should be updated")
	
	# Restore original value
	reverb.room_size = original_room_size