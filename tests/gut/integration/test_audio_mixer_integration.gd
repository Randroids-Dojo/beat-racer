extends GutTest

const AudioMixerPanel = preload("res://scripts/components/ui/audio_mixer_panel.gd")
const LaneSoundSystem = preload("res://scripts/components/sound/lane_sound_system.gd")
const AudioPresetResource = preload("res://scripts/resources/audio_preset_resource.gd")
const TEST_TIMEOUT = 5.0

var mixer_panel: AudioMixerPanel
var lane_sound_system: LaneSoundSystem
var test_scene: Node2D

func before_each():
	test_scene = Node2D.new()
	test_scene.name = "TestScene"
	add_child(test_scene)
	
	# Create and setup mixer panel
	mixer_panel = AudioMixerPanel.new()
	mixer_panel.name = "MixerPanel"
	test_scene.add_child(mixer_panel)
	
	# Create lane sound system
	lane_sound_system = LaneSoundSystem.new()
	lane_sound_system.name = "LaneSoundSystem"
	test_scene.add_child(lane_sound_system)
	
	await wait_frames(3)

func after_each():
	# Stop all sounds
	if lane_sound_system and is_instance_valid(lane_sound_system):
		lane_sound_system.stop_all_lanes()
	
	# Clean up
	if test_scene and is_instance_valid(test_scene):
		test_scene.queue_free()
	
	test_scene = null
	mixer_panel = null
	lane_sound_system = null
	await wait_frames(2)

func test_mixer_controls_audio_output():
	# Test that mixer controls actually affect audio output
	
	# Configure lane sound to use Melody bus
	lane_sound_system.set_lane_config(LaneSoundSystem.Lane.LEFT, {
		"waveform": LaneSoundSystem.Waveform.SINE,
		"bus": "Melody",
		"volume": 0.5,
		"octave": 4,
		"scale_degree": 0
	})
	
	await wait_frames(2)
	
	# Start lane sound
	lane_sound_system.start_lane(LaneSoundSystem.Lane.LEFT)
	await wait_frames(2)
	
	# Test volume control
	var melody_control = mixer_panel.get_node("MainVBox/SplitContainer/BusContainer/MelodyControl")
	var volume_slider = melody_control.get_node("VolumeSlider")
	
	# Change volume and verify
	volume_slider.value = -20.0
	volume_slider.value_changed.emit(-20.0)
	await wait_frames(1)
	
	assert_almost_eq(AudioManager.get_bus_volume_db("Melody"), -20.0, 0.1, "Volume should be applied to AudioManager")
	
	# Test mute
	var mute_button = melody_control.get_node("MuteButton")
	mute_button.button_pressed = true
	mute_button.toggled.emit(true)
	await wait_frames(1)
	
	assert_true(AudioManager.is_bus_muted("Melody"), "Bus should be muted")
	
	# Clean up
	lane_sound_system.stop_lane(LaneSoundSystem.Lane.LEFT)
	mute_button.button_pressed = false
	mute_button.toggled.emit(false)

func test_effect_controls_integration():
	# Test that effect controls integrate properly with audio system
	
	# Get effect controls for Melody bus
	var melody_control = mixer_panel.get_node("MainVBox/SplitContainer/BusContainer/MelodyControl")
	var effects_container = melody_control.get_node("EffectsContainer")
	
	assert_not_null(effects_container, "Effects container should exist")
	
	# Test reverb toggle
	var reverb_row = effects_container.get_child(0)
	var reverb_button = reverb_row.get_node("Effect0Button")
	var reverb_edit = reverb_row.get_node("Effect0EditButton")
	
	# Disable reverb
	reverb_button.button_pressed = false
	reverb_button.toggled.emit(false)
	await wait_frames(1)
	
	assert_false(AudioManager.is_bus_effect_enabled("Melody", 0), "Reverb should be disabled")
	
	# Re-enable reverb
	reverb_button.button_pressed = true
	reverb_button.toggled.emit(true)
	await wait_frames(1)
	
	assert_true(AudioManager.is_bus_effect_enabled("Melody", 0), "Reverb should be enabled")
	
	# Test effect parameter editing
	reverb_edit.pressed.emit()
	await wait_frames(2)
	
	var effect_panel = mixer_panel.get_node("MainVBox/SplitContainer/RightPanel/Effects/EffectVBox")
	var current_control = effect_panel.get_node_or_null("CurrentEffectControl")
	assert_not_null(current_control, "Effect control should be created when edit button is pressed")

func test_preset_system_integration():
	# Test that preset system works with mixer panel
	
	# Set custom mixer state
	var melody_control = mixer_panel.get_node("MainVBox/SplitContainer/BusContainer/MelodyControl")
	var volume_slider = melody_control.get_node("VolumeSlider")
	var mute_button = melody_control.get_node("MuteButton")
	
	volume_slider.value = -15.0
	volume_slider.value_changed.emit(-15.0)
	mute_button.button_pressed = true
	mute_button.toggled.emit(true)
	await wait_frames(1)
	
	# Save preset
	var preset_manager = mixer_panel.get_node("MainVBox/SplitContainer/RightPanel/Presets/PresetManager")
	var name_input = preset_manager._name_input
	var save_button = preset_manager._save_button
	
	name_input.text = "TestIntegration"
	name_input.text_changed.emit("TestIntegration")
	await wait_frames(1)
	
	save_button.pressed.emit()
	await wait_frames(5)  # Wait for file I/O
	
	# Change state
	volume_slider.value = 0.0
	volume_slider.value_changed.emit(0.0)
	mute_button.button_pressed = false
	mute_button.toggled.emit(false)
	await wait_frames(1)
	
	# Load preset back
	var preset_list = preset_manager._preset_list
	var load_button = preset_manager._load_button
	
	# Find saved preset
	for i in range(preset_list.get_item_count()):
		if preset_list.get_item_text(i) == "TestIntegration":
			preset_list.select(i)
			preset_list.item_selected.emit(i)
			await wait_frames(1)
			break
	
	load_button.pressed.emit()
	await wait_frames(2)
	
	# Verify state restored
	assert_almost_eq(AudioManager.get_bus_volume_db("Melody"), -15.0, 0.1, "Volume should be restored from preset")
	assert_true(AudioManager.is_bus_muted("Melody"), "Mute should be restored from preset")
	
	# Clean up test preset
	var dir = DirAccess.open("user://audio_presets/")
	if dir and dir.file_exists("TestIntegration.tres"):
		dir.remove("TestIntegration.tres")

func test_multiple_bus_interaction():
	# Test interaction between multiple buses (solo functionality)
	
	var melody_control = mixer_panel.get_node("MainVBox/SplitContainer/BusContainer/MelodyControl")
	var bass_control = mixer_panel.get_node("MainVBox/SplitContainer/BusContainer/BassControl")
	
	var melody_solo = melody_control.get_node("SoloButton")
	var bass_solo = bass_control.get_node("SoloButton")
	
	# Solo melody bus
	melody_solo.button_pressed = true
	melody_solo.toggled.emit(true)
	await wait_frames(1)
	
	assert_true(AudioManager.is_bus_soloed("Melody"), "Melody should be soloed")
	
	# Solo bass bus (should unsolo melody if exclusive)
	bass_solo.button_pressed = true
	bass_solo.toggled.emit(true)
	await wait_frames(1)
	
	assert_true(AudioManager.is_bus_soloed("Bass"), "Bass should be soloed")
	
	# Clean up
	melody_solo.button_pressed = false
	melody_solo.toggled.emit(false)
	bass_solo.button_pressed = false
	bass_solo.toggled.emit(false)

func test_lane_sound_bus_routing():
	# Test that lane sounds route through correct buses and are affected by mixer
	
	# Configure different lanes to different buses
	lane_sound_system.set_lane_config(LaneSoundSystem.Lane.LEFT, {
		"waveform": LaneSoundSystem.Waveform.SINE,
		"bus": "Melody",
		"volume": 0.5,
		"octave": 4,
		"scale_degree": 0
	})
	
	lane_sound_system.set_lane_config(LaneSoundSystem.Lane.CENTER, {
		"waveform": LaneSoundSystem.Waveform.SQUARE,
		"bus": "Bass",
		"volume": 0.4,
		"octave": 2,
		"scale_degree": 0
	})
	
	await wait_frames(2)
	
	# Start lane sounds
	lane_sound_system.start_lane(LaneSoundSystem.Lane.LEFT)
	lane_sound_system.start_lane(LaneSoundSystem.Lane.CENTER)
	await wait_frames(2)
	
	# Mute melody bus - should affect left lane
	var melody_control = mixer_panel.get_node("MainVBox/SplitContainer/BusContainer/MelodyControl")
	var melody_mute = melody_control.get_node("MuteButton")
	
	melody_mute.button_pressed = true
	melody_mute.toggled.emit(true)
	await wait_frames(1)
	
	# Verify melody bus is muted (affects left lane)
	assert_true(AudioManager.is_bus_muted("Melody"), "Melody bus should be muted")
	assert_false(AudioManager.is_bus_muted("Bass"), "Bass bus should not be muted")
	
	# Clean up
	lane_sound_system.stop_all_lanes()
	melody_mute.button_pressed = false
	melody_mute.toggled.emit(false)

func test_ui_synchronization():
	# Test that UI stays synchronized with audio state changes
	
	# Make changes through AudioManager directly
	AudioManager.set_bus_volume_db("Melody", -18.0)
	AudioManager.set_bus_mute("Bass", true)
	AudioManager.set_bus_solo("Percussion", true)
	
	# Update mixer panel from current state
	mixer_panel._update_from_audio_manager()
	await wait_frames(1)
	
	# Verify UI reflects the changes
	var melody_control = mixer_panel.get_node("MainVBox/SplitContainer/BusContainer/MelodyControl")
	var melody_slider = melody_control.get_node("VolumeSlider")
	assert_almost_eq(melody_slider.value, -18.0, 0.1, "Melody slider should reflect AudioManager volume")
	
	var bass_control = mixer_panel.get_node("MainVBox/SplitContainer/BusContainer/BassControl")
	var bass_mute = bass_control.get_node("MuteButton")
	assert_true(bass_mute.button_pressed, "Bass mute button should reflect AudioManager state")
	
	var percussion_control = mixer_panel.get_node("MainVBox/SplitContainer/BusContainer/PercussionControl")
	var percussion_solo = percussion_control.get_node("SoloButton")
	assert_true(percussion_solo.button_pressed, "Percussion solo button should reflect AudioManager state")
	
	# Clean up
	AudioManager.reset_for_testing()

func test_signal_chain_integrity():
	# Test that signal chain from UI to audio system is intact
	var signals_received = {
		"volume_changed": false,
		"mute_changed": false,
		"solo_changed": false,
		"effect_toggled": false
	}
	
	mixer_panel.volume_changed.connect(func(bus, vol): signals_received["volume_changed"] = true)
	mixer_panel.mute_changed.connect(func(bus, muted): signals_received["mute_changed"] = true)
	mixer_panel.solo_changed.connect(func(bus, soloed): signals_received["solo_changed"] = true)
	mixer_panel.effect_toggled.connect(func(bus, idx, enabled): signals_received["effect_toggled"] = true)
	
	# Trigger all signal types
	var melody_control = mixer_panel.get_node("MainVBox/SplitContainer/BusContainer/MelodyControl")
	
	# Volume
	var volume_slider = melody_control.get_node("VolumeSlider")
	volume_slider.value_changed.emit(-10.0)
	await wait_frames(1)
	
	# Mute
	var mute_button = melody_control.get_node("MuteButton")
	mute_button.toggled.emit(true)
	await wait_frames(1)
	
	# Solo
	var solo_button = melody_control.get_node("SoloButton")
	solo_button.toggled.emit(true)
	await wait_frames(1)
	
	# Effect
	var effects_container = melody_control.get_node("EffectsContainer")
	var reverb_row = effects_container.get_child(0)
	var reverb_button = reverb_row.get_node("Effect0Button")
	reverb_button.toggled.emit(false)
	await wait_frames(1)
	
	# Verify all signals received
	for signal_name in signals_received:
		assert_true(signals_received[signal_name], "%s signal should be emitted" % signal_name)