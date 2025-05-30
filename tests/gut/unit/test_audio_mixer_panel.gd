extends GutTest

const AudioMixerPanel = preload("res://scripts/components/ui/audio_mixer_panel.gd")
const TEST_TIMEOUT = 2.0

var mixer_panel: AudioMixerPanel

func before_each():
	mixer_panel = AudioMixerPanel.new()
	mixer_panel.name = "AudioMixerPanel"
	add_child(mixer_panel)
	await wait_frames(2)

func after_each():
	if mixer_panel and is_instance_valid(mixer_panel):
		mixer_panel.queue_free()
	mixer_panel = null
	await wait_frames(2)

func test_panel_initialization():
	# Test that panel initializes with correct structure
	assert_not_null(mixer_panel, "Mixer panel should exist")
	
	var main_vbox = mixer_panel.get_node("MainVBox")
	assert_not_null(main_vbox, "Main VBox should exist")
	
	var split_container = main_vbox.get_node("SplitContainer")
	assert_not_null(split_container, "Split container should exist")
	
	var bus_container = split_container.get_node("BusContainer")
	assert_not_null(bus_container, "Bus container should exist")
	
	var right_panel = split_container.get_node("RightPanel")
	assert_not_null(right_panel, "Right panel should exist")

func test_bus_controls_created():
	# Test that controls are created for each bus
	var buses = ["Master", "Melody", "Bass", "Percussion", "SFX"]
	var bus_container = mixer_panel.get_node("MainVBox/SplitContainer/BusContainer")
	
	for bus_name in buses:
		var control = bus_container.get_node(bus_name + "Control")
		assert_not_null(control, "Control for %s bus should exist" % bus_name)
		
		# Check for volume slider
		var volume_slider = control.get_node("VolumeSlider")
		assert_not_null(volume_slider, "Volume slider for %s should exist" % bus_name)
		assert_almost_eq(volume_slider.step, 0.01, 0.001, "Slider step should be 0.01")
		
		# Check for mute/solo buttons
		var mute_button = control.get_node("MuteButton")
		assert_not_null(mute_button, "Mute button for %s should exist" % bus_name)
		assert_true(mute_button.toggle_mode, "Mute button should be toggle mode")
		
		var solo_button = control.get_node("SoloButton")
		assert_not_null(solo_button, "Solo button for %s should exist" % bus_name)
		assert_true(solo_button.toggle_mode, "Solo button should be toggle mode")

func test_volume_control():
	# Test volume slider functionality
	var melody_control = mixer_panel.get_node("MainVBox/SplitContainer/BusContainer/MelodyControl")
	var volume_slider = melody_control.get_node("VolumeSlider")
	var volume_label = melody_control.get_node("VolumeLabel")
	
	# Initial state
	assert_almost_eq(volume_slider.value, -6.0, 0.1, "Initial volume should be -6.0 dB")
	
	# Change volume
	volume_slider.value = -12.0
	volume_slider.value_changed.emit(-12.0)
	await wait_frames(1)
	
	# Check AudioManager was updated
	assert_almost_eq(AudioManager.get_bus_volume_db("Melody"), -12.0, 0.1, "AudioManager should have new volume")
	
	# Check label updated
	assert_string_contains(volume_label.text, "-12.0")

func test_mute_functionality():
	# Test mute button
	var melody_control = mixer_panel.get_node("MainVBox/SplitContainer/BusContainer/MelodyControl")
	var mute_button = melody_control.get_node("MuteButton")
	
	# Initial state
	assert_false(mute_button.button_pressed, "Mute should be off initially")
	assert_false(AudioManager.is_bus_muted("Melody"), "Bus should not be muted")
	
	# Toggle mute
	mute_button.button_pressed = true
	mute_button.toggled.emit(true)
	await wait_frames(1)
	
	assert_true(AudioManager.is_bus_muted("Melody"), "Bus should be muted")
	
	# Toggle back
	mute_button.button_pressed = false
	mute_button.toggled.emit(false)
	await wait_frames(1)
	
	assert_false(AudioManager.is_bus_muted("Melody"), "Bus should not be muted")

func test_solo_functionality():
	# Test solo button
	var melody_control = mixer_panel.get_node("MainVBox/SplitContainer/BusContainer/MelodyControl")
	var solo_button = melody_control.get_node("SoloButton")
	
	# Initial state
	assert_false(solo_button.button_pressed, "Solo should be off initially")
	assert_false(AudioManager.is_bus_soloed("Melody"), "Bus should not be soloed")
	
	# Toggle solo
	solo_button.button_pressed = true
	solo_button.toggled.emit(true)
	await wait_frames(1)
	
	assert_true(AudioManager.is_bus_soloed("Melody"), "Bus should be soloed")

func test_effect_controls_exist():
	# Test that buses with effects have effect controls
	var melody_control = mixer_panel.get_node("MainVBox/SplitContainer/BusContainer/MelodyControl")
	var effects_container = melody_control.get_node("EffectsContainer")
	
	assert_not_null(effects_container, "Effects container should exist for Melody bus")
	assert_gt(effects_container.get_child_count(), 0, "Should have effect controls")
	
	# Check first effect (Reverb)
	var reverb_row = effects_container.get_child(0)
	var reverb_button = reverb_row.get_node("Effect0Button")
	assert_not_null(reverb_button, "Reverb toggle button should exist")
	assert_eq(reverb_button.text, "Reverb", "Button should be labeled Reverb")
	
	var reverb_edit = reverb_row.get_node("Effect0EditButton")
	assert_not_null(reverb_edit, "Reverb edit button should exist")

func test_effect_toggle():
	# Test effect enable/disable
	var melody_control = mixer_panel.get_node("MainVBox/SplitContainer/BusContainer/MelodyControl")
	var effects_container = melody_control.get_node("EffectsContainer")
	var reverb_row = effects_container.get_child(0)
	var reverb_button = reverb_row.get_node("Effect0Button")
	
	# Initial state (should be enabled)
	assert_true(reverb_button.button_pressed, "Effect should be enabled initially")
	assert_true(AudioManager.is_bus_effect_enabled("Melody", 0), "Effect should be enabled in AudioManager")
	
	# Toggle off
	reverb_button.button_pressed = false
	reverb_button.toggled.emit(false)
	await wait_frames(1)
	
	assert_false(AudioManager.is_bus_effect_enabled("Melody", 0), "Effect should be disabled in AudioManager")

func test_signals_emitted():
	# Test that signals are properly emitted
	var volume_signal_emitted = false
	var mute_signal_emitted = false
	var solo_signal_emitted = false
	var effect_signal_emitted = false
	
	mixer_panel.volume_changed.connect(func(bus, vol): volume_signal_emitted = true)
	mixer_panel.mute_changed.connect(func(bus, muted): mute_signal_emitted = true)
	mixer_panel.solo_changed.connect(func(bus, soloed): solo_signal_emitted = true)
	mixer_panel.effect_toggled.connect(func(bus, idx, enabled): effect_signal_emitted = true)
	
	# Test volume signal
	var melody_control = mixer_panel.get_node("MainVBox/SplitContainer/BusContainer/MelodyControl")
	var volume_slider = melody_control.get_node("VolumeSlider")
	volume_slider.value_changed.emit(-12.0)
	await wait_frames(1)
	assert_true(volume_signal_emitted, "Volume change signal should be emitted")
	
	# Test mute signal
	var mute_button = melody_control.get_node("MuteButton")
	mute_button.toggled.emit(true)
	await wait_frames(1)
	assert_true(mute_signal_emitted, "Mute change signal should be emitted")
	
	# Test solo signal
	var solo_button = melody_control.get_node("SoloButton")
	solo_button.toggled.emit(true)
	await wait_frames(1)
	assert_true(solo_signal_emitted, "Solo change signal should be emitted")
	
	# Test effect signal
	var effects_container = melody_control.get_node("EffectsContainer")
	var reverb_row = effects_container.get_child(0)
	var reverb_button = reverb_row.get_node("Effect0Button")
	reverb_button.toggled.emit(false)
	await wait_frames(1)
	assert_true(effect_signal_emitted, "Effect toggle signal should be emitted")

func test_preset_manager_exists():
	# Test that preset manager is included
	var preset_manager = mixer_panel.get_node("MainVBox/SplitContainer/RightPanel/Presets/PresetManager")
	assert_not_null(preset_manager, "Preset manager should exist")

func test_public_methods():
	# Test public getter/setter methods
	mixer_panel.set_bus_volume("Melody", -20.0)
	assert_almost_eq(mixer_panel.get_bus_volume("Melody"), -20.0, 0.1, "Should get/set volume correctly")
	
	assert_false(mixer_panel.is_bus_muted("Melody"), "Should report mute status")
	assert_false(mixer_panel.is_bus_soloed("Melody"), "Should report solo status")