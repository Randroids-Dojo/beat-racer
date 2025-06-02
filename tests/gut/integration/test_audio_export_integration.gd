extends GutTest
## Integration tests for the audio export system
##
## Tests the complete audio export workflow including UI interaction,
## recording during playback, and file generation.

var main_game_scene: Node2D
var game_state_manager: Node
var composition_recorder: CompositionRecorder
var export_dialog: ExportDialog
var ui_panel: Control
var test_scene_path = "res://scenes/main_game_with_save.tscn"


func before_each() -> void:
	# Clean up test recordings
	var dir = DirAccess.open("user://")
	if dir.dir_exists("recordings"):
		# Clean up test files but keep the directory
		var recordings_dir = DirAccess.open("user://recordings/")
		if recordings_dir:
			var files = recordings_dir.get_files()
			for file in files:
				if file.begins_with("test_"):
					recordings_dir.remove(file)
	
	# Load the main game scene with save functionality
	main_game_scene = load(test_scene_path).instantiate()
	add_child_autofree(main_game_scene)
	
	# Wait for scene to be ready
	await wait_frames(2)
	
	# Get references
	game_state_manager = main_game_scene.get_node("GameStateManager")
	composition_recorder = main_game_scene.get_node_or_null("CompositionRecorder")
	ui_panel = main_game_scene.get_node_or_null("UILayer/GameUIPanel")
	
	# Find export dialog in UI layer
	if main_game_scene.has_node("UILayer"):
		var ui_layer = main_game_scene.get_node("UILayer")
		for child in ui_layer.get_children():
			if child is ExportDialog:
				export_dialog = child
				break


func after_each() -> void:
	# Clean up test recordings
	var dir = DirAccess.open("user://recordings/")
	if dir:
		var files = dir.get_files()
		for file in files:
			if file.begins_with("test_"):
				dir.remove(file)


func test_export_button_exists() -> void:
	# Test that export button exists in UI
	assert_not_null(ui_panel, "UI panel should exist")
	
	var export_button = ui_panel.get_node_or_null("TopBar/ExportButton")
	assert_not_null(export_button, "Export button should exist in UI")


func test_export_dialog_setup() -> void:
	# Test that export dialog is properly set up
	assert_not_null(export_dialog, "Export dialog should exist")
	assert_false(export_dialog.visible, "Export dialog should be hidden initially")
	
	# Test dialog has required controls
	var filename_input = export_dialog.get_node_or_null("VBox/FilenameContainer/FilenameInput")
	assert_not_null(filename_input, "Export dialog should have filename input")
	
	var format_option = export_dialog.get_node_or_null("VBox/FormatContainer/FormatOption")
	assert_not_null(format_option, "Export dialog should have format selector")


func test_export_requires_layers() -> void:
	# Test that export is disabled without recorded layers
	assert_not_null(game_state_manager, "Game state manager should exist")
	assert_eq(game_state_manager.recorded_layers.size(), 0, "Should have no layers initially")
	
	# Try to export without layers
	if ui_panel and ui_panel.has_signal("export_requested"):
		ui_panel.export_requested.emit()
		await wait_frames(1)
		
		# Check status message
		var status_label = ui_panel.get_node_or_null("BottomBar/StatusLabel")
		if status_label:
			assert_true(status_label.text.contains("No layers"), "Should show 'no layers' message")


func test_audio_recorder_integration() -> void:
	# Test that composition recorder is properly integrated
	assert_not_null(composition_recorder, "Composition recorder should exist")
	assert_false(composition_recorder.is_recording, "Should not be recording initially")
	
	# Test recorder can start
	composition_recorder.start_recording()
	assert_true(composition_recorder.is_recording, "Recorder should start")
	
	await wait_seconds(0.1)
	
	composition_recorder.stop_recording()
	assert_false(composition_recorder.is_recording, "Recorder should stop")


func test_export_workflow_simulation() -> void:
	# Simulate a complete export workflow
	if not game_state_manager or not composition_recorder:
		pending("Required components not available")
		return
	
	# Add a dummy layer to enable export
	var dummy_layer = {
		"samples": [],
		"duration": 2.0,
		"lap_time": 2.0
	}
	game_state_manager.recorded_layers.append(dummy_layer)
	
	# Start the export process
	var export_started = false
	if composition_recorder.has_signal("recording_started"):
		composition_recorder.recording_started.connect(func(): export_started = true, CONNECT_ONE_SHOT)
	
	# Trigger export through the main game function
	if main_game_scene.has_method("_on_export_requested"):
		main_game_scene._on_export_requested()
		
		# Wait for recording to start
		await wait_seconds(0.2)
		assert_true(export_started, "Export recording should have started")
		
		# Check that we're in playback mode
		assert_eq(game_state_manager.current_mode, game_state_manager.GameMode.PLAYBACK, 
			"Should switch to playback mode for export")


func test_export_dialog_interaction() -> void:
	# Test export dialog interaction
	if not export_dialog:
		pending("Export dialog not available")
		return
	
	# Setup dialog with test data
	export_dialog.setup("Test Composition", 10.5)
	
	# Check that dialog is populated correctly
	var filename_input = export_dialog.get_node_or_null("VBox/FilenameContainer/FilenameInput")
	assert_not_null(filename_input, "Should have filename input")
	assert_true(filename_input.text.contains("test_composition"), "Filename should be based on composition name")
	
	var duration_label = export_dialog.get_node_or_null("VBox/InfoContainer/DurationLabel")
	assert_not_null(duration_label, "Should have duration label")
	assert_true(duration_label.text.contains("0:10"), "Duration should show 10 seconds")
	
	var size_label = export_dialog.get_node_or_null("VBox/InfoContainer/SizeLabel")
	assert_not_null(size_label, "Should have size estimate label")
	assert_true(size_label.text.contains("MB"), "Should show size estimate")


func test_metadata_capture() -> void:
	# Test that metadata is properly captured during export
	if not composition_recorder:
		pending("Composition recorder not available")
		return
	
	# Set up some test metadata
	composition_recorder.set_sound_bank_info("Test Bank", 0)
	
	# Start recording with test data
	composition_recorder.start_composition_recording("Metadata Test", [])
	
	await wait_seconds(0.1)
	
	var result = composition_recorder.stop_composition_recording()
	
	assert_has(result, "metadata", "Should have metadata")
	var metadata = result.metadata
	
	assert_eq(metadata.track_name, "Metadata Test", "Should capture track name")
	assert_has(metadata, "sound_bank_info", "Should capture sound bank info")
	assert_eq(metadata.sound_bank_info.bank_name, "Test Bank", "Should have correct bank name")


func test_export_file_generation() -> void:
	# Test that export generates actual files
	if not composition_recorder:
		pending("Composition recorder not available")
		return
	
	# Record some test audio
	composition_recorder.start_composition_recording("File Test", [])
	await wait_seconds(0.2)
	composition_recorder.stop_composition_recording()
	
	# Export with test options
	var options = {
		"filename": "test_export_file",
		"include_metadata": true
	}
	
	var result = composition_recorder.export_with_options(options)
	
	assert_has(result, "audio_path", "Should return audio path")
	
	# Verify files exist
	var dir = DirAccess.open("user://recordings/")
	assert_true(dir.file_exists("test_export_file.wav"), "WAV file should be created")
	
	if options.include_metadata:
		assert_true(dir.file_exists("test_export_file_metadata.json"), "Metadata file should be created")


func test_audio_bus_configuration() -> void:
	# Test that audio buses are properly configured for recording
	var record_bus_idx = AudioServer.get_bus_index("Record")
	assert_ne(record_bus_idx, -1, "Record bus should exist")
	
	# Check that game audio buses route to Record bus
	var expected_buses = ["Melody", "Bass", "Percussion", "SFX"]
	for bus_name in expected_buses:
		var bus_idx = AudioServer.get_bus_index(bus_name)
		if bus_idx != -1:
			var send = AudioServer.get_bus_send(bus_idx)
			assert_eq(send, "Record", "%s bus should send to Record bus" % bus_name)