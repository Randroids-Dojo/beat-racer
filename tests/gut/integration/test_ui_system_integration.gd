extends GutTest

# Integration tests for UI System

var game_ui: GameUIPanel
var mock_beat_manager: Node


func before_each():
	# Create mock beat manager
	mock_beat_manager = Node.new()
	mock_beat_manager.name = "BeatManager"
	mock_beat_manager.set_script(preload("res://tests/gut/unit/mock_beat_manager.gd") if ResourceLoader.exists("res://tests/gut/unit/mock_beat_manager.gd") else null)
	get_tree().root.add_child(mock_beat_manager)
	
	# Create game UI
	game_ui = GameUIPanel.new()
	add_child_autofree(game_ui)
	await get_tree().process_frame


func after_each():
	if mock_beat_manager:
		mock_beat_manager.queue_free()


func test_ui_panel_initialization():
	assert_not_null(game_ui, "Game UI should be created")
	assert_not_null(game_ui.status_indicator, "Should have status indicator")
	assert_not_null(game_ui.beat_counter, "Should have beat counter")
	assert_not_null(game_ui.bpm_control, "Should have BPM control")
	assert_not_null(game_ui.vehicle_selector, "Should have vehicle selector")


func test_recording_mode_integration():
	var recording_started = false
	game_ui.recording_started.connect(func(): recording_started = true)
	
	# Set recording mode
	game_ui.set_recording_mode(true)
	
	# Check UI state
	assert_eq(game_ui.status_indicator.current_mode, GameStatusIndicator.Mode.RECORDING, "Status should show recording")
	assert_false(game_ui.bpm_control.bpm_slider.editable, "BPM should be locked during recording")
	assert_false(game_ui.vehicle_selector.visible, "Vehicle selector should be hidden")
	
	# Stop recording
	game_ui.set_recording_mode(false)
	
	assert_eq(game_ui.status_indicator.current_mode, GameStatusIndicator.Mode.IDLE, "Status should return to idle")
	assert_true(game_ui.bpm_control.bpm_slider.editable, "BPM should be unlocked")
	assert_true(game_ui.vehicle_selector.visible, "Vehicle selector should be visible")


func test_playback_mode_integration():
	var playback_started = false
	game_ui.playback_started.connect(func(): playback_started = true)
	
	# Set playback mode
	game_ui.set_playback_mode(true)
	
	assert_eq(game_ui.status_indicator.current_mode, GameStatusIndicator.Mode.PLAYING, "Status should show playing")
	assert_false(game_ui.bpm_control.bpm_slider.editable, "BPM should be locked during playback")
	assert_false(game_ui.vehicle_selector.visible, "Vehicle selector should be hidden")
	
	# Test pause
	game_ui.set_playback_mode(true, true)
	assert_eq(game_ui.status_indicator.current_mode, GameStatusIndicator.Mode.PAUSED, "Status should show paused")
	
	# Stop playback
	game_ui.set_playback_mode(false)
	assert_eq(game_ui.status_indicator.current_mode, GameStatusIndicator.Mode.IDLE, "Status should return to idle")


func test_vehicle_selection_signals():
	var vehicle_changed = false
	var received_type
	var received_color
	
	game_ui.vehicle_changed.connect(func(type, color):
		vehicle_changed = true
		received_type = type
		received_color = color
	)
	
	# Change vehicle through selector
	game_ui.vehicle_selector._select_vehicle(1)  # Drift
	
	assert_true(vehicle_changed, "Should emit vehicle_changed signal")
	assert_eq(received_type, VehicleSelector.VehicleType.DRIFT, "Should pass correct type")
	assert_eq(received_color, game_ui.vehicle_selector.get_selected_color(), "Should pass correct color")


func test_bpm_control_signals():
	var bpm_changed = false
	var received_bpm
	
	game_ui.bpm_changed.connect(func(bpm):
		bpm_changed = true
		received_bpm = bpm
	)
	
	# Change BPM
	game_ui.bpm_control.set_bpm(140.0)
	
	assert_true(bpm_changed, "Should emit bpm_changed signal")
	assert_eq(received_bpm, 140.0, "Should pass correct BPM")


func test_status_info_updates():
	game_ui.update_status_info("Test message")
	assert_eq(game_ui.status_indicator.info_label.text, "Test message", "Should update status info")
	
	game_ui.update_loop_info(true, 3)
	assert_eq(game_ui.status_indicator.loop_count, 3, "Should update loop info")


func test_ui_visibility_controls():
	# Test show
	game_ui.show_ui()
	assert_true(game_ui.is_visible, "Should be marked visible")
	assert_true(game_ui.visible, "Should be actually visible")
	
	# Test hide
	game_ui.hide_ui()
	assert_false(game_ui.is_visible, "Should be marked invisible")
	
	# Test toggle
	game_ui.toggle_ui()
	assert_true(game_ui.is_visible, "Should toggle to visible")
	
	game_ui.toggle_ui()
	assert_false(game_ui.is_visible, "Should toggle to invisible")


func test_beat_counter_integration():
	# Simulate beat from mock manager
	if mock_beat_manager and mock_beat_manager.has_signal("beat_occurred"):
		mock_beat_manager.emit_signal("beat_occurred", 0, 0.0)
		
		# Check beat counter updated
		assert_eq(game_ui.beat_counter.current_beat, 0, "Beat counter should receive beat")


func test_panel_layout():
	# Check panels exist
	assert_not_null(game_ui.top_panel, "Should have top panel")
	assert_not_null(game_ui.bottom_panel, "Should have bottom panel")
	assert_not_null(game_ui.left_panel, "Should have left panel")
	assert_not_null(game_ui.right_panel, "Should have right panel")
	
	# Check component placement
	assert_true(game_ui.status_indicator.get_parent() == game_ui.top_panel, "Status should be in top panel")
	assert_true(game_ui.beat_counter.get_parent() == game_ui.top_panel, "Beat counter should be in top panel")
	assert_true(game_ui.bpm_control.get_parent() == game_ui.top_panel, "BPM control should be in top panel")
	assert_true(game_ui.vehicle_selector.get_parent() == game_ui.bottom_panel, "Vehicle selector should be in bottom panel")


func test_getter_methods():
	# Set some values
	game_ui.vehicle_selector.current_vehicle_index = 2
	game_ui.vehicle_selector.current_color = Color.GREEN
	game_ui.bpm_control.set_bpm(130.0)
	
	# Test getters
	assert_eq(game_ui.get_selected_vehicle(), VehicleSelector.VehicleType.SPEED, "Should return selected vehicle")
	assert_eq(game_ui.get_selected_vehicle_color(), Color.GREEN, "Should return selected color")
	assert_eq(game_ui.get_current_bpm(), 130.0, "Should return current BPM")


func test_beat_counter_reset():
	# Set some values
	game_ui.beat_counter.current_measure = 5
	game_ui.beat_counter.current_beat = 10
	
	# Reset
	game_ui.reset_beat_counter()
	
	assert_eq(game_ui.beat_counter.current_measure, 0, "Should reset measure")
	assert_eq(game_ui.beat_counter.current_beat, 0, "Should reset beat")


func test_mode_change_signals():
	var mode_changes = []
	
	game_ui.status_indicator.mode_changed.connect(func(mode):
		mode_changes.append(mode)
	)
	
	# Trigger mode changes
	game_ui.status_indicator.set_recording()
	game_ui.status_indicator.set_playback()
	game_ui.status_indicator.set_idle()
	
	assert_eq(mode_changes.size(), 3, "Should track all mode changes")
	assert_eq(mode_changes[0], GameStatusIndicator.Mode.RECORDING, "First should be recording")
	assert_eq(mode_changes[1], GameStatusIndicator.Mode.PLAYING, "Second should be playing")
	assert_eq(mode_changes[2], GameStatusIndicator.Mode.IDLE, "Third should be idle")