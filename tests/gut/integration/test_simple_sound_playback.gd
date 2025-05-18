extends GutTest
# Integration tests for Simple Sound Playback Test (Story 004)

var _scene: Node2D
var _lane_sound_system: Node
var _play_button: Button
var _bpm_slider: HSlider
var _volume_slider: HSlider

func before_all() -> void:
	print("Starting Simple Sound Playback integration tests...")

func before_each() -> void:
	_scene = preload("res://scenes/test/simple_sound_playback_test.tscn").instantiate()
	add_child(_scene)
	await get_tree().create_timer(0.1).timeout
	
	# Get references
	_lane_sound_system = _scene._lane_sound_system
	_play_button = _scene._play_button
	_bpm_slider = _scene._bpm_slider  
	_volume_slider = _scene._volume_slider

func after_each() -> void:
	BeatManager.stop()
	if _scene:
		_scene.queue_free()
		_scene = null
	await get_tree().create_timer(0.1).timeout

func test_keyboard_lane_triggers() -> void:
	# Test Q key triggers left lane
	var event = InputEventKey.new()
	event.keycode = KEY_Q
	event.pressed = true
	_scene._unhandled_key_input(event)
	
	assert_eq(_scene._current_lane, 0, "Q key should select left lane")
	assert_true(_lane_sound_system.is_playing(), "Left lane should be playing")
	assert_eq(_lane_sound_system.get_current_lane(), 0, "Current lane should be 0")
	
	# Test W key triggers center lane
	event.keycode = KEY_W
	_scene._unhandled_key_input(event)
	
	assert_eq(_scene._current_lane, 1, "W key should select center lane")
	assert_true(_lane_sound_system.is_playing(), "Center lane should be playing")
	assert_eq(_lane_sound_system.get_current_lane(), 1, "Current lane should be 1")
	
	# Test E key triggers right lane
	event.keycode = KEY_E
	_scene._unhandled_key_input(event)
	
	assert_eq(_scene._current_lane, 2, "E key should select right lane")
	assert_true(_lane_sound_system.is_playing(), "Right lane should be playing")
	assert_eq(_lane_sound_system.get_current_lane(), 2, "Current lane should be 2")

func test_space_key_toggles_playback() -> void:
	assert_false(BeatManager.is_playing, "BeatManager should start stopped")
	assert_eq(_play_button.text, "Start Playback", "Button should show Start")
	
	# Press space to start
	var event = InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	_scene._unhandled_key_input(event)
	
	assert_true(BeatManager.is_playing, "BeatManager should be playing")
	assert_eq(_play_button.text, "Stop Playback", "Button should show Stop")
	
	# Press space to stop
	_scene._unhandled_key_input(event)
	
	assert_false(BeatManager.is_playing, "BeatManager should stop")
	assert_eq(_play_button.text, "Start Playback", "Button should show Start again")

func test_esc_key_clears_lane() -> void:
	# First select a lane
	var event = InputEventKey.new()
	event.keycode = KEY_Q
	event.pressed = true
	_scene._unhandled_key_input(event)
	
	assert_eq(_scene._current_lane, 0, "Should have lane selected")
	assert_true(_lane_sound_system.is_playing(), "Lane should be playing")
	
	# Press ESC to clear
	event.keycode = KEY_ESCAPE
	_scene._unhandled_key_input(event)
	
	assert_eq(_scene._current_lane, -1, "ESC should clear current lane")
	assert_false(_lane_sound_system.is_playing(), "Lane should stop playing")

func test_visual_feedback_activation() -> void:
	var indicator = _scene._lane_indicators[0]
	var initial_modulate = indicator.modulate
	
	# Trigger lane
	var event = InputEventKey.new()
	event.keycode = KEY_Q
	event.pressed = true
	_scene._unhandled_key_input(event)
	
	# Check visual feedback
	assert_eq(indicator.modulate, Color(1.5, 1.5, 1.5), "Indicator should brighten")
	
	# Clear lane
	event.keycode = KEY_ESCAPE
	_scene._unhandled_key_input(event)
	
	assert_eq(indicator.modulate, Color.WHITE, "Indicator should return to normal")

func test_ui_controls_update_parameters() -> void:
	# Select a lane first
	var event = InputEventKey.new()
	event.keycode = KEY_Q
	event.pressed = true
	_scene._unhandled_key_input(event)
	
	# Test volume slider
	_volume_slider.value = 0.7
	_volume_slider.emit_signal("value_changed", 0.7)
	await get_tree().create_timer(0.1).timeout
	assert_eq(_scene._volume_label.text, "Volume: 70%", "Volume label should update")
	
	# Test BPM slider
	_bpm_slider.value = 140
	_bpm_slider.emit_signal("value_changed", 140.0)
	await get_tree().create_timer(0.1).timeout
	assert_eq(BeatManager.bpm, 140, "BPM should update")
	assert_eq(_scene._bpm_label.text, "BPM: 140", "BPM label should update")

func test_toggle_same_lane_stops_playback() -> void:
	# Select a lane
	var event = InputEventKey.new()
	event.keycode = KEY_Q
	event.pressed = true
	_scene._unhandled_key_input(event)
	
	assert_eq(_scene._current_lane, 0, "Lane should be selected")
	assert_true(_lane_sound_system.is_playing(), "Lane should be playing")
	
	# Press same key again
	_scene._unhandled_key_input(event)
	
	assert_eq(_scene._current_lane, -1, "Lane should be cleared")
	assert_false(_lane_sound_system.is_playing(), "Lane should stop")

func test_parameter_updates_affect_current_lane() -> void:
	# Select a lane
	var event = InputEventKey.new()
	event.keycode = KEY_W
	event.pressed = true
	_scene._unhandled_key_input(event)
	
	# Update octave
	_scene._octave_spin.value = 2
	_scene._octave_spin.emit_signal("value_changed", 2.0)
	await get_tree().create_timer(0.1).timeout
	
	# Update waveform
	_scene._waveform_option.selected = 1  # Square wave
	_scene._waveform_option.emit_signal("item_selected", 1)
	await get_tree().create_timer(0.1).timeout
	
	# Update scale
	_scene._scale_option.selected = 2  # Pentatonic
	_scene._scale_option.emit_signal("item_selected", 2)
	await get_tree().create_timer(0.1).timeout
	
	# Verify lane is still playing with new parameters
	assert_true(_lane_sound_system.is_playing(), "Lane should still be playing")

func test_beat_visualization_responds_to_playback() -> void:
	assert_not_null(_scene._beat_visualization, "Beat visualization should exist")
	
	# Start playback
	var event = InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	_scene._unhandled_key_input(event)
	
	await get_tree().create_timer(0.5).timeout
	
	# Beat visualization should be active (checking through BeatManager)
	assert_true(BeatManager.is_playing, "BeatManager should be playing")

func test_status_label_updates() -> void:
	assert_eq(_scene._status_label.text, "Status: Ready", "Initial status")
	
	# Select a lane
	var event = InputEventKey.new()
	event.keycode = KEY_E
	event.pressed = true
	_scene._unhandled_key_input(event)
	
	assert_eq(_scene._status_label.text, "Playing Lane 2", "Status should show lane")
	
	# Clear lane
	event.keycode = KEY_ESCAPE
	_scene._unhandled_key_input(event)
	
	assert_eq(_scene._status_label.text, "Status: Ready", "Status should reset")

func test_lane_switching_during_playback() -> void:
	# Start with lane 0
	var event = InputEventKey.new()
	event.keycode = KEY_Q
	event.pressed = true
	_scene._unhandled_key_input(event)
	
	assert_eq(_scene._current_lane, 0, "Should be on lane 0")
	assert_true(_lane_sound_system.is_playing(), "Should be playing")
	
	# Switch to lane 1 without stopping
	event.keycode = KEY_W
	_scene._unhandled_key_input(event)
	
	assert_eq(_scene._current_lane, 1, "Should switch to lane 1")
	assert_true(_lane_sound_system.is_playing(), "Should still be playing")
	assert_eq(_lane_sound_system.get_current_lane(), 1, "Sound system should be on lane 1")
	
	# Verify previous lane indicator was reset
	assert_eq(_scene._lane_indicators[0].modulate, Color.WHITE, "Previous lane indicator should reset")

func test_metronome_toggle() -> void:
	# Start beat manager
	var event = InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	_scene._unhandled_key_input(event)
	
	assert_true(BeatManager.is_playing, "BeatManager should be playing")
	
	# Enable metronome
	_scene._metronome_check.button_pressed = true
	_scene._metronome_check.emit_signal("toggled", true)
	
	await get_tree().create_timer(0.1).timeout
	assert_true(BeatManager.is_metronome_enabled(), "Metronome should be enabled")
	
	# Disable metronome
	_scene._metronome_check.button_pressed = false
	_scene._metronome_check.emit_signal("toggled", false)
	
	await get_tree().create_timer(0.1).timeout
	assert_false(BeatManager.is_metronome_enabled(), "Metronome should be disabled")