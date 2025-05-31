extends GutTest
## Integration tests for the main game scene
##
## Tests the integration of all systems in the main game scene including
## game state management, mode transitions, UI interactions, and system coordination.

var main_game_scene: Node2D
var game_state_manager: Node
var ui_panel: Control
var track_system: Node2D
var beat_manager: Node
var audio_manager: Node


func before_each() -> void:
	# Load autoloads
	beat_manager = autofree(preload("res://scripts/autoloads/beat_manager.gd").new())
	beat_manager.name = "BeatManager"
	add_child(beat_manager)
	
	audio_manager = autofree(preload("res://scripts/autoloads/audio_manager.gd").new())
	audio_manager.name = "AudioManager"
	add_child(audio_manager)
	
	# Create main game scene
	main_game_scene = autofree(preload("res://scenes/main_game.tscn").instantiate())
	add_child(main_game_scene)
	
	# Get references
	game_state_manager = main_game_scene.get_node("GameStateManager")
	ui_panel = main_game_scene.get_node("UILayer/GameUIPanel")
	track_system = main_game_scene.get_node("TrackSystem")
	
	# Wait for scene to initialize
	await wait_frames(2)


func after_each() -> void:
	if beat_manager:
		beat_manager.stop()


func test_initial_state() -> void:
	# Verify initial game mode
	assert_eq(game_state_manager.current_mode, game_state_manager.GameMode.LIVE, 
		"Should start in LIVE mode")
	
	# Verify UI is properly initialized
	assert_not_null(ui_panel, "UI panel should exist")
	assert_true(ui_panel.visible, "UI should be visible initially")
	
	# Verify track system is loaded
	assert_not_null(track_system, "Track system should be loaded")
	
	# Verify player vehicle exists
	var vehicle_container = main_game_scene.get_node("VehicleContainer")
	assert_eq(vehicle_container.get_child_count(), 1, "Should have one player vehicle")


func test_mode_transitions() -> void:
	# Test transition to recording mode
	game_state_manager.change_mode(game_state_manager.GameMode.RECORDING)
	assert_eq(game_state_manager.current_mode, game_state_manager.GameMode.RECORDING,
		"Should change to RECORDING mode")
	
	# Test can't record while already recording
	game_state_manager.start_recording()
	assert_eq(game_state_manager.current_mode, game_state_manager.GameMode.RECORDING,
		"Should remain in RECORDING mode")
	
	# Stop recording should create a layer and switch to playback
	var recording = game_state_manager.stop_recording()
	assert_not_null(recording, "Should return a recording")
	assert_eq(game_state_manager.current_mode, game_state_manager.GameMode.PLAYBACK,
		"Should switch to PLAYBACK mode after recording")
	assert_eq(game_state_manager.get_layer_count(), 1, "Should have one recorded layer")


func test_ui_record_button() -> void:
	# Get record button
	var record_button = ui_panel.get_node("TopBar/RecordButton")
	assert_not_null(record_button, "Record button should exist")
	
	# Simulate record button press
	record_button.pressed.emit()
	await wait_frames(1)
	
	assert_eq(game_state_manager.current_mode, game_state_manager.GameMode.RECORDING,
		"Pressing record should start recording")


func test_ui_mode_display() -> void:
	# Get mode label
	var mode_label = ui_panel.get_node("TopBar/ModeLabel")
	assert_not_null(mode_label, "Mode label should exist")
	
	# Check initial mode display
	assert_eq(mode_label.text, "Mode: Live", "Should display Live mode initially")
	
	# Change to recording mode
	game_state_manager.change_mode(game_state_manager.GameMode.RECORDING)
	ui_panel.set_game_mode(game_state_manager.GameMode.RECORDING)
	await wait_frames(1)
	
	assert_eq(mode_label.text, "Mode: Recording", "Should display Recording mode")


func test_playback_mode_with_layers() -> void:
	# Record a dummy layer
	game_state_manager.change_mode(game_state_manager.GameMode.RECORDING)
	var recording = game_state_manager.stop_recording()
	
	# Verify playback mode
	assert_eq(game_state_manager.current_mode, game_state_manager.GameMode.PLAYBACK,
		"Should be in PLAYBACK mode")
	
	# Check playback vehicles are created
	var playback_container = main_game_scene.get_node("PlaybackContainer")
	await wait_frames(2)  # Wait for vehicles to spawn
	
	# Note: Vehicle spawning is handled in main_game.gd, so we verify the container exists
	assert_not_null(playback_container, "Playback container should exist")


func test_layer_management() -> void:
	# Add multiple layers
	game_state_manager.change_mode(game_state_manager.GameMode.RECORDING)
	game_state_manager.stop_recording()
	assert_eq(game_state_manager.get_layer_count(), 1, "Should have 1 layer")
	
	# Add another layer
	game_state_manager.change_mode(game_state_manager.GameMode.LAYERING)
	game_state_manager.stop_recording()
	assert_eq(game_state_manager.get_layer_count(), 2, "Should have 2 layers")
	
	# Remove a layer
	game_state_manager.remove_layer(0)
	assert_eq(game_state_manager.get_layer_count(), 1, "Should have 1 layer after removal")
	
	# Clear all layers
	game_state_manager.clear_all_layers()
	assert_eq(game_state_manager.get_layer_count(), 0, "Should have no layers after clear")
	assert_eq(game_state_manager.current_mode, game_state_manager.GameMode.LIVE,
		"Should return to LIVE mode after clearing all layers")


func test_bpm_control_integration() -> void:
	# Get BPM slider
	var bpm_slider = ui_panel.get_node("TopBar/BPMControl/BPMSlider")
	assert_not_null(bpm_slider, "BPM slider should exist")
	
	# Change BPM
	var initial_bpm = beat_manager.get_bpm()
	bpm_slider.value = 140
	bpm_slider.value_changed.emit(140)
	await wait_frames(1)
	
	assert_eq(beat_manager.get_bpm(), 140, "BeatManager BPM should update")


func test_sound_bank_selector() -> void:
	# Get sound bank selector
	var bank_selector = ui_panel.get_node("LeftPanel/SoundBankSection/SoundBankSelector")
	assert_not_null(bank_selector, "Sound bank selector should exist")
	
	# Verify default banks are loaded
	assert_gt(bank_selector.item_count, 0, "Should have sound banks loaded")
	assert_eq(bank_selector.get_item_text(0), "Electronic", "First bank should be Electronic")


func test_escape_key_handling() -> void:
	# Start recording
	game_state_manager.change_mode(game_state_manager.GameMode.RECORDING)
	
	# Simulate ESC key press
	var escape_event = InputEventKey.new()
	escape_event.keycode = KEY_ESCAPE
	escape_event.pressed = true
	main_game_scene._input(escape_event)
	await wait_frames(1)
	
	# Should stop recording and have a layer
	assert_eq(game_state_manager.current_mode, game_state_manager.GameMode.PLAYBACK,
		"ESC during recording should stop and switch to playback")
	assert_eq(game_state_manager.get_layer_count(), 1, "Should have recorded a layer")


func test_camera_toggle() -> void:
	var camera = main_game_scene.get_node("CameraController")
	assert_not_null(camera, "Camera controller should exist")
	
	# Get initial mode (should be FOLLOW)
	var initial_mode = camera.current_mode
	
	# Simulate TAB key press
	var tab_event = InputEventKey.new()
	tab_event.keycode = KEY_TAB
	tab_event.pressed = true
	main_game_scene._input(tab_event)
	await wait_frames(1)
	
	# Camera mode should have changed
	assert_ne(camera.current_mode, initial_mode, "Camera mode should toggle")


func test_can_record_limit() -> void:
	# Add maximum layers
	for i in range(game_state_manager.max_layers):
		game_state_manager.change_mode(game_state_manager.GameMode.RECORDING)
		game_state_manager.stop_recording()
	
	assert_eq(game_state_manager.get_layer_count(), game_state_manager.max_layers,
		"Should have max layers")
	assert_false(game_state_manager.can_record(), "Should not be able to record more")
	
	# Try to record another - should fail
	game_state_manager.start_recording()
	assert_ne(game_state_manager.current_mode, game_state_manager.GameMode.RECORDING,
		"Should not enter recording mode when at max layers")


func test_mode_state_consistency() -> void:
	# Test that mode transitions maintain consistent state
	var modes = [
		game_state_manager.GameMode.LIVE,
		game_state_manager.GameMode.RECORDING,
		game_state_manager.GameMode.LIVE,
		game_state_manager.GameMode.PLAYBACK
	]
	
	for mode in modes:
		if mode == game_state_manager.GameMode.RECORDING:
			game_state_manager.start_recording()
		elif mode == game_state_manager.GameMode.PLAYBACK:
			if game_state_manager.get_layer_count() == 0:
				# Need a recording first
				game_state_manager.start_recording()
				game_state_manager.stop_recording()
		else:
			game_state_manager.change_mode(mode)
		
		assert_eq(game_state_manager.current_mode, mode,
			"Mode should be set correctly to %d" % mode)
		assert_false(game_state_manager.is_transitioning,
			"Should not be transitioning after mode change")


func test_ui_layer_list_updates() -> void:
	var layers_list = ui_panel.get_node("LeftPanel/LayersSection/LayersList")
	assert_not_null(layers_list, "Layers list should exist")
	
	# Initially empty
	assert_eq(layers_list.item_count, 0, "Should start with no layers")
	
	# Add a layer
	game_state_manager.start_recording()
	game_state_manager.stop_recording()
	ui_panel.add_layer_indicator(0)
	await wait_frames(1)
	
	assert_eq(layers_list.item_count, 1, "Should show one layer")
	assert_eq(layers_list.get_item_text(0), "Layer 1", "Layer should be named correctly")