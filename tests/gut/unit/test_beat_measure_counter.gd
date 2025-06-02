extends GutTest

# Unit tests for BeatMeasureCounter

var beat_counter: BeatMeasureCounter
var mock_beat_manager: Node


func before_each():
	# Create mock beat manager
	mock_beat_manager = Node.new()
	mock_beat_manager.name = "BeatManager"
	mock_beat_manager.set_script(preload("res://tests/gut/unit/mock_beat_manager.gd") if ResourceLoader.exists("res://tests/gut/unit/mock_beat_manager.gd") else null)
	get_tree().root.add_child(mock_beat_manager)
	
	beat_counter = BeatMeasureCounter.new()
	add_child_autofree(beat_counter)
	await get_tree().process_frame


func after_each():
	if mock_beat_manager:
		mock_beat_manager.queue_free()


func test_initialization():
	assert_not_null(beat_counter, "Beat counter should be created")
	assert_not_null(beat_counter.measure_label, "Should have measure label")
	assert_not_null(beat_counter.beat_label, "Should have beat label")
	assert_eq(beat_counter.current_measure, 0, "Should start at measure 0")
	assert_eq(beat_counter.current_beat, 0, "Should start at beat 0")


func test_beat_dots_creation():
	assert_true(beat_counter.show_beat_dots, "Beat dots should be enabled by default")
	assert_not_null(beat_counter.beat_dots_container, "Should have beat dots container")
	assert_eq(beat_counter.beat_dots.size(), beat_counter.beats_per_measure, "Should create dots for beats per measure")


func test_beat_occurred_handling():
	var beat_changed = false
	var measure_changed = false
	
	beat_counter.beat_changed.connect(func(_beat, _beat_in_measure):
		beat_changed = true
	)
	
	beat_counter.measure_changed.connect(func(_measure):
		measure_changed = true
	)
	
	# Simulate first beat
	beat_counter._on_beat_occurred(0, 0.0)
	assert_true(beat_changed, "Should emit beat_changed signal")
	assert_eq(beat_counter.beat_label.text, "1", "Beat label should show 1")
	
	# Simulate beat in measure
	beat_changed = false
	beat_counter._on_beat_occurred(2, 0.0)
	assert_true(beat_changed, "Should emit beat_changed signal")
	assert_eq(beat_counter.beat_label.text, "3", "Beat label should show 3")
	
	# Simulate new measure (beat 4 with 4/4 time)
	beat_counter._on_beat_occurred(4, 0.0)
	assert_eq(beat_counter.beat_label.text, "1", "Beat should reset to 1")
	assert_eq(beat_counter.measure_label.text, "2", "Measure should increment")


func test_beat_dots_update():
	# Create counter with visible dots
	beat_counter.show_beat_dots = true
	beat_counter._create_beat_dots()
	
	# Simulate beats
	beat_counter.beat_in_measure = 1
	beat_counter._update_display()
	
	# Check first dot is active
	var first_dot_style = beat_counter.beat_dots[0].get_theme_stylebox("panel") as StyleBoxFlat
	assert_eq(first_dot_style.bg_color, beat_counter.downbeat_color, "First dot should use downbeat color")
	
	# Simulate second beat
	beat_counter.beat_in_measure = 2
	beat_counter._update_display()
	
	var second_dot_style = beat_counter.beat_dots[1].get_theme_stylebox("panel") as StyleBoxFlat
	assert_eq(second_dot_style.bg_color, beat_counter.beat_color, "Second dot should use beat color")


func test_flash_animation():
	# Start flash
	beat_counter._start_flash(true)
	assert_true(beat_counter.is_flashing, "Should be flashing")
	assert_eq(beat_counter.flash_timer, beat_counter.beat_flash_duration, "Flash timer should be set")
	
	# Process to animate
	beat_counter._process(beat_counter.beat_flash_duration / 2)
	assert_true(beat_counter.is_flashing, "Should still be flashing")
	
	# Complete flash
	beat_counter._process(beat_counter.beat_flash_duration)
	assert_false(beat_counter.is_flashing, "Flash should be complete")


func test_reset():
	# Set some values
	beat_counter.current_measure = 5
	beat_counter.current_beat = 10
	beat_counter.beat_in_measure = 3
	beat_counter._update_display()
	
	# Reset
	beat_counter.reset()
	
	assert_eq(beat_counter.current_measure, 0, "Measure should reset to 0")
	assert_eq(beat_counter.current_beat, 0, "Beat should reset to 0")
	assert_eq(beat_counter.beat_in_measure, 0, "Beat in measure should reset to 0")
	assert_eq(beat_counter.measure_label.text, "0", "Measure label should show 0")
	assert_eq(beat_counter.beat_label.text, "0", "Beat label should show 0")


func test_beats_per_measure_change():
	# Change beats per measure
	beat_counter.set_beats_per_measure(3)
	assert_eq(beat_counter.beats_per_measure, 3, "Should update beats per measure")
	
	# Check dots were recreated
	if beat_counter.show_beat_dots:
		assert_eq(beat_counter.beat_dots.size(), 3, "Should have 3 dots")


func test_show_beat_dots_toggle():
	# Hide dots
	beat_counter.set_show_beat_dots(false)
	assert_false(beat_counter.beat_dots_container.visible, "Dots container should be hidden")
	
	# Show dots
	beat_counter.set_show_beat_dots(true)
	assert_true(beat_counter.beat_dots_container.visible, "Dots container should be visible")


func test_downbeat_detection():
	var received_beat = -1
	var received_beat_in_measure = -1
	
	# Track beat_changed signal emissions
	beat_counter.beat_changed.connect(func(beat: int, beat_in_measure: int):
		received_beat = beat
		received_beat_in_measure = beat_in_measure)
	
	# First beat of measure (downbeat)
	beat_counter.beat_in_measure = 1
	beat_counter._on_beat_occurred(0, 0.0)
	assert_eq(received_beat_in_measure, 1, "Should detect downbeat with beat_in_measure = 1")
	assert_eq(received_beat, 0, "Should report correct beat number")
	
	# Other beats in measure
	beat_counter.beat_in_measure = 2
	beat_counter._on_beat_occurred(1, 0.0)
	assert_eq(received_beat_in_measure, 2, "Should detect non-downbeat correctly")
	assert_eq(received_beat, 1, "Should report correct beat number")