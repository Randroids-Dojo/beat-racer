extends GutTest

const AudioPresetResource = preload("res://scripts/resources/audio_preset_resource.gd")
const AudioPresetManager = preload("res://scripts/components/ui/audio_preset_manager.gd")
const TEST_TIMEOUT = 2.0
const TEST_PRESET_NAME = "TestPreset"

var preset_manager: AudioPresetManager
var original_audio_state: Dictionary = {}

func before_all():
	# Clean up any existing test presets
	_cleanup_test_presets()

func after_all():
	# Final cleanup
	_cleanup_test_presets()

func before_each():
	# Save current audio state
	_save_audio_state()
	
	preset_manager = AudioPresetManager.new()
	preset_manager.name = "TestPresetManager"
	add_child(preset_manager)
	await wait_frames(2)

func after_each():
	# Restore original audio state
	_restore_audio_state()
	
	if preset_manager and is_instance_valid(preset_manager):
		preset_manager.queue_free()
	preset_manager = null
	await wait_frames(2)

func _save_audio_state():
	var buses = ["Master", "Melody", "Bass", "Percussion", "SFX"]
	for bus_name in buses:
		var bus_idx = AudioServer.get_bus_index(bus_name)
		if bus_idx != -1:
			original_audio_state[bus_name] = {
				"volume_db": AudioServer.get_bus_volume_db(bus_idx),
				"muted": AudioServer.is_bus_mute(bus_idx),
				"soloed": AudioServer.is_bus_solo(bus_idx)
			}

func _restore_audio_state():
	for bus_name in original_audio_state:
		var state = original_audio_state[bus_name]
		AudioManager.set_bus_volume_db(bus_name, state["volume_db"])
		AudioManager.set_bus_mute(bus_name, state["muted"])
		AudioManager.set_bus_solo(bus_name, state["soloed"])

func _cleanup_test_presets():
	var dir = DirAccess.open("user://audio_presets/")
	if dir:
		if dir.file_exists(TEST_PRESET_NAME + ".tres"):
			dir.remove(TEST_PRESET_NAME + ".tres")

func test_preset_resource_save():
	# Test saving audio state to preset resource
	var preset = AudioPresetResource.new()
	preset.preset_name = TEST_PRESET_NAME
	
	# Set some test values
	AudioManager.set_bus_volume_db("Melody", -12.0)
	AudioManager.set_bus_mute("Bass", true)
	AudioManager.set_bus_solo("Percussion", true)
	
	# Save current state
	preset.save_from_audio_manager()
	
	# Verify saved data
	assert_false(preset.bus_settings.is_empty(), "Bus settings should not be empty")
	assert_has(preset.bus_settings, "Melody", "Should have Melody bus settings")
	assert_has(preset.bus_settings, "Bass", "Should have Bass bus settings")
	assert_has(preset.bus_settings, "Percussion", "Should have Percussion bus settings")
	
	# Check specific values
	assert_almost_eq(preset.bus_settings["Melody"]["volume_db"], -12.0, 0.1, "Melody volume should be saved")
	assert_true(preset.bus_settings["Bass"]["muted"], "Bass mute state should be saved")
	assert_true(preset.bus_settings["Percussion"]["soloed"], "Percussion solo state should be saved")

func test_preset_resource_apply():
	# Test applying preset to audio manager
	var preset = AudioPresetResource.new()
	preset.preset_name = TEST_PRESET_NAME
	
	# Create test preset data
	preset.bus_settings = {
		"Melody": {"volume_db": -15.0, "muted": true, "soloed": false, "effects": []},
		"Bass": {"volume_db": -3.0, "muted": false, "soloed": true, "effects": []},
		"Percussion": {"volume_db": -9.0, "muted": false, "soloed": false, "effects": []}
	}
	
	# Apply preset
	preset.apply_to_audio_manager()
	await wait_frames(1)
	
	# Verify applied values
	assert_almost_eq(AudioManager.get_bus_volume_db("Melody"), -15.0, 0.1, "Melody volume should be applied")
	assert_true(AudioManager.is_bus_muted("Melody"), "Melody should be muted")
	assert_false(AudioManager.is_bus_soloed("Melody"), "Melody should not be soloed")
	
	assert_almost_eq(AudioManager.get_bus_volume_db("Bass"), -3.0, 0.1, "Bass volume should be applied")
	assert_false(AudioManager.is_bus_muted("Bass"), "Bass should not be muted")
	assert_true(AudioManager.is_bus_soloed("Bass"), "Bass should be soloed")

func test_preset_manager_ui():
	# Test preset manager UI components
	assert_not_null(preset_manager, "Preset manager should exist")
	
	# Check for preset list
	var preset_list = preset_manager._preset_list
	assert_not_null(preset_list, "Preset list should exist")
	assert_gt(preset_list.get_item_count(), 0, "Should have default presets")
	
	# Check for controls
	var name_input = preset_manager._name_input
	assert_not_null(name_input, "Name input should exist")
	
	var save_button = preset_manager._save_button
	assert_not_null(save_button, "Save button should exist")
	assert_true(save_button.disabled, "Save button should be disabled initially")
	
	var load_button = preset_manager._load_button
	assert_not_null(load_button, "Load button should exist")
	assert_true(load_button.disabled, "Load button should be disabled initially")

func test_preset_save_load():
	# Test saving and loading presets through UI
	var name_input = preset_manager._name_input
	var save_button = preset_manager._save_button
	
	# Set test values
	AudioManager.set_bus_volume_db("Melody", -18.0)
	AudioManager.set_bus_mute("Bass", true)
	
	# Enter preset name
	name_input.text = TEST_PRESET_NAME
	name_input.text_changed.emit(TEST_PRESET_NAME)
	await wait_frames(1)
	
	assert_false(save_button.disabled, "Save button should be enabled with name")
	
	# Save preset
	save_button.pressed.emit()
	await wait_frames(5)  # Wait for file I/O
	
	# Check file exists
	var file_path = "user://audio_presets/" + TEST_PRESET_NAME + ".tres"
	assert_true(ResourceLoader.exists(file_path), "Preset file should exist")
	
	# Change audio state
	AudioManager.set_bus_volume_db("Melody", 0.0)
	AudioManager.set_bus_mute("Bass", false)
	
	# Load preset back
	var preset_list = preset_manager._preset_list
	var load_button = preset_manager._load_button
	
	# Find and select saved preset
	for i in range(preset_list.get_item_count()):
		if preset_list.get_item_text(i) == TEST_PRESET_NAME:
			preset_list.select(i)
			preset_list.item_selected.emit(i)
			await wait_frames(1)
			break
	
	assert_false(load_button.disabled, "Load button should be enabled")
	
	# Load preset
	load_button.pressed.emit()
	await wait_frames(2)
	
	# Verify loaded values
	assert_almost_eq(AudioManager.get_bus_volume_db("Melody"), -18.0, 0.1, "Melody volume should be restored")
	assert_true(AudioManager.is_bus_muted("Bass"), "Bass mute should be restored")

func test_default_presets():
	# Test that default presets exist and work
	var preset_list = preset_manager._preset_list
	var load_button = preset_manager._load_button
	
	# Find Ambient preset
	var ambient_idx = -1
	for i in range(preset_list.get_item_count()):
		if preset_list.get_item_text(i) == "⭐ Ambient":
			ambient_idx = i
			break
	
	assert_ne(ambient_idx, -1, "Ambient preset should exist")
	
	# Select and load
	preset_list.select(ambient_idx)
	preset_list.item_selected.emit(ambient_idx)
	await wait_frames(1)
	
	load_button.pressed.emit()
	await wait_frames(2)
	
	# Verify some expected values for Ambient preset
	assert_almost_eq(AudioManager.get_bus_volume_db("Melody"), -3.0, 0.1, "Melody should have Ambient volume")
	assert_almost_eq(AudioManager.get_bus_volume_db("Percussion"), -12.0, 0.1, "Percussion should have Ambient volume")

func test_preset_signals():
	# Test that signals are emitted
	var loaded_signal_emitted = false
	var saved_signal_emitted = false
	var loaded_preset_name = ""
	var saved_preset_name = ""
	
	preset_manager.preset_loaded.connect(func(name): 
		loaded_signal_emitted = true
		loaded_preset_name = name
	)
	preset_manager.preset_saved.connect(func(name): 
		saved_signal_emitted = true
		saved_preset_name = name
	)
	
	# Test save signal
	var name_input = preset_manager._name_input
	var save_button = preset_manager._save_button
	
	name_input.text = TEST_PRESET_NAME
	name_input.text_changed.emit(TEST_PRESET_NAME)
	await wait_frames(1)
	
	save_button.pressed.emit()
	await wait_frames(5)
	
	assert_true(saved_signal_emitted, "Save signal should be emitted")
	assert_eq(saved_preset_name, TEST_PRESET_NAME, "Save signal should include preset name")
	
	# Test load signal
	var preset_list = preset_manager._preset_list
	var load_button = preset_manager._load_button
	
	# Select first default preset
	preset_list.select(0)
	preset_list.item_selected.emit(0)
	await wait_frames(1)
	
	load_button.pressed.emit()
	await wait_frames(2)
	
	assert_true(loaded_signal_emitted, "Load signal should be emitted")
	assert_false(loaded_preset_name.is_empty(), "Load signal should include preset name")

func test_effect_parameters_save():
	# Test that effect parameters are saved correctly
	var preset = AudioPresetResource.new()
	
	# Get Melody bus reverb effect
	var melody_idx = AudioServer.get_bus_index("Melody")
	var reverb = AudioServer.get_bus_effect(melody_idx, 0) as AudioEffectReverb
	
	if reverb:
		# Set custom values
		reverb.room_size = 0.5
		reverb.wet = 0.4
		
		# Save preset
		preset.save_from_audio_manager()
		
		# Check saved effect data
		var melody_effects = preset.bus_settings["Melody"]["effects"]
		assert_false(melody_effects.is_empty(), "Melody should have effects saved")
		
		var reverb_data = melody_effects[0]
		assert_eq(reverb_data["class_name"], "AudioEffectReverb", "Should save effect class name")
		assert_has(reverb_data["parameters"], "room_size", "Should save room_size")
		assert_has(reverb_data["parameters"], "wet", "Should save wet")
		assert_almost_eq(reverb_data["parameters"]["room_size"], 0.5, 0.01, "Room size should be saved")
		assert_almost_eq(reverb_data["parameters"]["wet"], 0.4, 0.01, "Wet should be saved")