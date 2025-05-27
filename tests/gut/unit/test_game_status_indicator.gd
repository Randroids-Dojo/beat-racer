extends GutTest

# Unit tests for GameStatusIndicator

var status_indicator: GameStatusIndicator


func before_each():
	status_indicator = GameStatusIndicator.new()
	add_child_autofree(status_indicator)
	await get_tree().process_frame


func test_initialization():
	assert_not_null(status_indicator, "Status indicator should be created")
	assert_eq(status_indicator.current_mode, GameStatusIndicator.Mode.IDLE, "Should start in IDLE mode")
	assert_not_null(status_indicator.mode_label, "Should have mode label")
	assert_not_null(status_indicator.time_label, "Should have time label")
	assert_not_null(status_indicator.info_label, "Should have info label")


func test_mode_changes():
	var mode_changed = false
	var received_mode
	
	status_indicator.mode_changed.connect(func(mode):
		mode_changed = true
		received_mode = mode
	)
	
	# Test recording mode
	status_indicator.set_recording()
	assert_eq(status_indicator.current_mode, GameStatusIndicator.Mode.RECORDING, "Should be in recording mode")
	assert_true(mode_changed, "Should emit mode_changed signal")
	assert_eq(received_mode, GameStatusIndicator.Mode.RECORDING, "Should pass correct mode")
	assert_eq(status_indicator.mode_label.text, "REC", "Label should show REC")
	
	# Test playback mode
	mode_changed = false
	status_indicator.set_playback()
	assert_eq(status_indicator.current_mode, GameStatusIndicator.Mode.PLAYING, "Should be in playing mode")
	assert_true(mode_changed, "Should emit mode_changed signal")
	assert_eq(status_indicator.mode_label.text, "PLAY", "Label should show PLAY")
	
	# Test paused mode
	mode_changed = false
	status_indicator.set_paused()
	assert_eq(status_indicator.current_mode, GameStatusIndicator.Mode.PAUSED, "Should be in paused mode")
	assert_eq(status_indicator.mode_label.text, "PAUSE", "Label should show PAUSE")
	
	# Test idle mode
	mode_changed = false
	status_indicator.set_idle()
	assert_eq(status_indicator.current_mode, GameStatusIndicator.Mode.IDLE, "Should be in idle mode")
	assert_eq(status_indicator.mode_label.text, "IDLE", "Label should show IDLE")


func test_info_updates():
	status_indicator.update_info("Test message")
	assert_eq(status_indicator.info_label.text, "Test message", "Info label should update")
	
	status_indicator.update_info("Another message")
	assert_eq(status_indicator.info_label.text, "Another message", "Info label should update again")


func test_loop_info():
	# Test loop enabled
	status_indicator.set_loop_info(true, 0)
	assert_eq(status_indicator.is_looping, true, "Should track looping state")
	
	# Test with loop count
	status_indicator.set_mode(GameStatusIndicator.Mode.PLAYING)
	status_indicator.set_loop_info(true, 3)
	assert_eq(status_indicator.loop_count, 3, "Should track loop count")
	assert_eq(status_indicator.info_label.text, "Loop 3", "Should show loop count")
	
	# Test loop disabled
	status_indicator.set_loop_info(false)
	assert_eq(status_indicator.is_looping, false, "Should track looping disabled")


func test_time_formatting():
	# Test various time formats
	assert_eq(status_indicator._format_time(0), "0:00", "Should format 0 seconds")
	assert_eq(status_indicator._format_time(5), "0:05", "Should format 5 seconds")
	assert_eq(status_indicator._format_time(65), "1:05", "Should format 65 seconds")
	assert_eq(status_indicator._format_time(125.5), "2:05", "Should format 125.5 seconds")


func test_theme_colors():
	# Test recording color
	status_indicator.set_recording()
	var style = status_indicator.get_theme_stylebox("panel") as StyleBoxFlat
	assert_eq(style.border_color, status_indicator.recording_color, "Should use recording color")
	
	# Test playback color
	status_indicator.set_playback()
	style = status_indicator.get_theme_stylebox("panel") as StyleBoxFlat
	assert_eq(style.border_color, status_indicator.playback_color, "Should use playback color")
	
	# Test paused color
	status_indicator.set_paused()
	style = status_indicator.get_theme_stylebox("panel") as StyleBoxFlat
	assert_eq(style.border_color, status_indicator.paused_color, "Should use paused color")


func test_time_display_updates():
	# Start recording mode
	status_indicator.set_recording()
	var start_time = status_indicator.mode_start_time
	
	# Wait a bit
	await get_tree().create_timer(0.1).timeout
	
	# Process to update time
	status_indicator._process(0.1)
	
	# Check that time label has been updated
	assert_ne(status_indicator.time_label.text, "0:00", "Time should have updated")


func test_mode_no_change_when_same():
	var signal_count = 0
	status_indicator.mode_changed.connect(func(_mode): signal_count += 1)
	
	# Set to recording
	status_indicator.set_recording()
	assert_eq(signal_count, 1, "Should emit signal once")
	
	# Set to recording again
	status_indicator.set_recording()
	assert_eq(signal_count, 1, "Should not emit signal when mode unchanged")


func test_icon_creation():
	# Just verify icons are created without errors
	status_indicator._set_icon_idle()
	assert_not_null(status_indicator.mode_icon.texture, "Should create idle icon")
	
	status_indicator._set_icon_recording()
	assert_not_null(status_indicator.mode_icon.texture, "Should create recording icon")
	
	status_indicator._set_icon_playing()
	assert_not_null(status_indicator.mode_icon.texture, "Should create playing icon")
	
	status_indicator._set_icon_paused()
	assert_not_null(status_indicator.mode_icon.texture, "Should create paused icon")