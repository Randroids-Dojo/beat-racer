extends GutTest

# Unit tests for BPMControl

var bpm_control: BPMControl


func before_each():
	bpm_control = BPMControl.new()
	add_child_autofree(bpm_control)
	await get_tree().process_frame


func test_initialization():
	assert_not_null(bpm_control, "BPM control should be created")
	assert_not_null(bpm_control.bpm_label, "Should have BPM label")
	assert_not_null(bpm_control.bpm_value_label, "Should have BPM value label")
	assert_not_null(bpm_control.bpm_slider, "Should have BPM slider")
	assert_not_null(bpm_control.decrease_button, "Should have decrease button")
	assert_not_null(bpm_control.increase_button, "Should have increase button")
	assert_eq(bpm_control.current_bpm, bpm_control.default_bpm, "Should start at default BPM")


func test_bpm_slider_configuration():
	# Test slider follows guidelines
	assert_eq(bpm_control.bpm_slider.step, 0.01, "Slider step should be 0.01 for smooth control")
	assert_eq(bpm_control.bpm_slider.min_value, bpm_control.min_bpm, "Slider min should match min BPM")
	assert_eq(bpm_control.bpm_slider.max_value, bpm_control.max_bpm, "Slider max should match max BPM")


func test_bpm_changes():
	var signal_emitted = false
	var received_bpm = 0.0
	
	bpm_control.bpm_changed.connect(func(bpm):
		signal_emitted = true
		received_bpm = bpm
	)
	
	# Test set BPM
	bpm_control.set_bpm(140.0)
	assert_eq(bpm_control.current_bpm, 140.0, "Should update current BPM")
	assert_true(signal_emitted, "Should emit bpm_changed signal")
	assert_eq(received_bpm, 140.0, "Should pass correct BPM value")
	assert_eq(bpm_control.bpm_value_label.text, "140", "Should update display")
	
	# Test clamping
	bpm_control.set_bpm(300.0)
	assert_eq(bpm_control.current_bpm, bpm_control.max_bpm, "Should clamp to max BPM")
	
	bpm_control.set_bpm(30.0)
	assert_eq(bpm_control.current_bpm, bpm_control.min_bpm, "Should clamp to min BPM")


func test_button_controls():
	# Start at middle value
	bpm_control.set_bpm(120.0)
	
	# Test increase
	bpm_control._on_increase_pressed()
	assert_eq(bpm_control.current_bpm, 125.0, "Should increase by step amount")
	
	# Test decrease
	bpm_control._on_decrease_pressed()
	bpm_control._on_decrease_pressed()
	assert_eq(bpm_control.current_bpm, 115.0, "Should decrease by step amount")


func test_button_states():
	# Set to minimum
	bpm_control.set_bpm(bpm_control.min_bpm)
	bpm_control._update_display()
	assert_true(bpm_control.decrease_button.disabled, "Decrease should be disabled at min")
	assert_false(bpm_control.increase_button.disabled, "Increase should be enabled")
	
	# Set to maximum
	bpm_control.set_bpm(bpm_control.max_bpm)
	bpm_control._update_display()
	assert_false(bpm_control.decrease_button.disabled, "Decrease should be enabled")
	assert_true(bpm_control.increase_button.disabled, "Increase should be disabled at max")


func test_preset_buttons():
	var preset_container = bpm_control.preset_container
	assert_gt(preset_container.get_child_count(), 0, "Should have preset buttons")
	
	# Test clicking first preset (80 BPM)
	var first_preset = preset_container.get_child(0) as Button
	assert_eq(first_preset.text, "80", "First preset should be 80")
	
	bpm_control._on_preset_pressed(80)
	assert_eq(bpm_control.current_bpm, 80.0, "Should set BPM to preset value")


func test_tap_tempo_basic():
	if not bpm_control.enable_tap_tempo:
		return
	
	# Simulate taps
	bpm_control._on_tap_tempo()
	await get_tree().create_timer(0.5).timeout  # 0.5 second interval
	
	var tap_detected = false
	var detected_bpm = 0.0
	
	bpm_control.tap_tempo_detected.connect(func(bpm):
		tap_detected = true
		detected_bpm = bpm
	)
	
	bpm_control._on_tap_tempo()
	
	# With 0.5 second interval, BPM should be 120
	assert_true(tap_detected, "Should detect tap tempo")
	assert_almost_eq(detected_bpm, 120.0, 10.0, "Should calculate BPM from tap interval")


func test_tap_tempo_reset():
	if not bpm_control.enable_tap_tempo:
		return
	
	# First tap
	bpm_control._on_tap_tempo()
	assert_eq(bpm_control.tap_times.size(), 1, "Should have one tap")
	
	# Wait longer than timeout
	await get_tree().create_timer(bpm_control.tap_timeout + 0.1).timeout
	
	# Next tap should reset
	bpm_control._on_tap_tempo()
	assert_eq(bpm_control.tap_times.size(), 1, "Should reset tap history")


func test_slider_value_change():
	var signal_count = 0
	bpm_control.bpm_changed.connect(func(_bpm): signal_count += 1)
	
	# Simulate slider change
	bpm_control._on_bpm_slider_changed(130.5)
	assert_eq(bpm_control.current_bpm, 130.0, "Should round to nearest step")
	assert_eq(signal_count, 1, "Should emit signal once")


func test_enable_controls():
	# Disable controls
	bpm_control.enable_controls(false)
	assert_false(bpm_control.bpm_slider.editable, "Slider should be disabled")
	assert_true(bpm_control.decrease_button.disabled, "Decrease should be disabled")
	assert_true(bpm_control.increase_button.disabled, "Increase should be disabled")
	
	# Enable controls
	bpm_control.enable_controls(true)
	assert_true(bpm_control.bpm_slider.editable, "Slider should be enabled")
	# Note: button states depend on current BPM value


func test_get_bpm():
	bpm_control.set_bpm(145.0)
	assert_eq(bpm_control.get_bpm(), 145.0, "Should return current BPM")