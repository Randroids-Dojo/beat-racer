extends GutTest

# Unit tests for VehicleSelector

var vehicle_selector: VehicleSelector


func before_each():
	vehicle_selector = VehicleSelector.new()
	add_child_autofree(vehicle_selector)
	await get_tree().process_frame


func test_initialization():
	assert_not_null(vehicle_selector, "Vehicle selector should be created")
	assert_not_null(vehicle_selector.vehicle_name_label, "Should have name label")
	assert_not_null(vehicle_selector.vehicle_desc_label, "Should have description label")
	assert_not_null(vehicle_selector.prev_button, "Should have previous button")
	assert_not_null(vehicle_selector.next_button, "Should have next button")
	assert_eq(vehicle_selector.current_vehicle_index, 0, "Should start at first vehicle")
	assert_eq(vehicle_selector.vehicle_data.size(), 4, "Should have 4 vehicle types")


func test_vehicle_data_initialization():
	var data = vehicle_selector.vehicle_data
	
	# Test standard vehicle
	assert_eq(data[0].name, "Standard", "First vehicle should be Standard")
	assert_eq(data[0].speed_modifier, 1.0, "Standard should have normal speed")
	assert_eq(data[0].handling_modifier, 1.0, "Standard should have normal handling")
	
	# Test other vehicles exist
	assert_eq(data[1].name, "Drift", "Second vehicle should be Drift")
	assert_eq(data[2].name, "Speed", "Third vehicle should be Speed")
	assert_eq(data[3].name, "Heavy", "Fourth vehicle should be Heavy")


func test_vehicle_navigation():
	var signal_emitted = false
	var selected_type
	
	vehicle_selector.vehicle_selected.connect(func(type):
		signal_emitted = true
		selected_type = type
	)
	
	# Test next button
	vehicle_selector._on_next_pressed()
	assert_eq(vehicle_selector.current_vehicle_index, 1, "Should move to next vehicle")
	assert_true(signal_emitted, "Should emit vehicle_selected signal")
	assert_eq(selected_type, VehicleSelector.VehicleType.DRIFT, "Should select drift type")
	assert_eq(vehicle_selector.vehicle_name_label.text, "Drift", "Should update name label")
	
	# Test previous button
	signal_emitted = false
	vehicle_selector._on_prev_pressed()
	assert_eq(vehicle_selector.current_vehicle_index, 0, "Should move to previous vehicle")
	assert_true(signal_emitted, "Should emit signal again")
	assert_eq(selected_type, VehicleSelector.VehicleType.STANDARD, "Should select standard type")


func test_vehicle_wrap_around():
	# Test wrap from last to first
	vehicle_selector.current_vehicle_index = 3  # Heavy
	vehicle_selector._on_next_pressed()
	assert_eq(vehicle_selector.current_vehicle_index, 0, "Should wrap to first vehicle")
	
	# Test wrap from first to last
	vehicle_selector._on_prev_pressed()
	assert_eq(vehicle_selector.current_vehicle_index, 3, "Should wrap to last vehicle")


func test_color_customization():
	if not vehicle_selector.allow_color_customization:
		return
	
	assert_not_null(vehicle_selector.color_picker_button, "Should have color picker")
	
	var color_changed = false
	var new_color
	
	vehicle_selector.color_changed.connect(func(color):
		color_changed = true
		new_color = color
	)
	
	# Change color
	vehicle_selector._on_color_changed(Color.RED)
	assert_eq(vehicle_selector.current_color, Color.RED, "Should update current color")
	assert_true(color_changed, "Should emit color_changed signal")
	assert_eq(new_color, Color.RED, "Should pass correct color")


func test_stats_display():
	var stats_container = vehicle_selector.stats_container
	assert_not_null(stats_container, "Should have stats container")
	
	var speed_bar = stats_container.find_child("SpeedBar") as ProgressBar
	var handling_bar = stats_container.find_child("HandlingBar") as ProgressBar
	
	assert_not_null(speed_bar, "Should have speed bar")
	assert_not_null(handling_bar, "Should have handling bar")
	
	# Select speed vehicle
	vehicle_selector._select_vehicle(2)  # Speed type
	var speed_data = vehicle_selector.vehicle_data[2]
	
	# Check stats updated
	assert_gt(speed_bar.value, 50, "Speed vehicle should have higher speed")
	assert_lt(handling_bar.value, 50, "Speed vehicle should have lower handling")


func test_vehicle_preview():
	if not vehicle_selector.show_vehicle_preview:
		return
	
	assert_not_null(vehicle_selector.vehicle_preview, "Should have preview panel")
	
	# Select different vehicle
	vehicle_selector._select_vehicle(1)
	
	# If preview has script, it should be updated
	if vehicle_selector.vehicle_preview.has_method("set_vehicle_type"):
		# Can't fully test without the visual component
		pass
	else:
		# Check fallback style update
		var style = vehicle_selector.vehicle_preview.get_theme_stylebox("panel") as StyleBoxFlat
		assert_eq(style.bg_color, vehicle_selector.current_color, "Should update preview color")


func test_get_selected_vehicle():
	vehicle_selector.current_vehicle_index = 2
	assert_eq(vehicle_selector.get_selected_vehicle(), VehicleSelector.VehicleType.SPEED, "Should return current vehicle type")


func test_get_selected_color():
	vehicle_selector.current_color = Color.BLUE
	assert_eq(vehicle_selector.get_selected_color(), Color.BLUE, "Should return current color")


func test_get_vehicle_data():
	var standard_data = vehicle_selector.get_vehicle_data(VehicleSelector.VehicleType.STANDARD)
	assert_not_null(standard_data, "Should return vehicle data")
	assert_eq(standard_data.name, "Standard", "Should return correct vehicle data")
	
	# Test invalid type
	var invalid_data = vehicle_selector.get_vehicle_data(99)
	assert_null(invalid_data, "Should return null for invalid type")


func test_select_vehicle_updates():
	# Select drift vehicle
	vehicle_selector._select_vehicle(1)
	
	# Check all updates
	assert_eq(vehicle_selector.vehicle_name_label.text, "Drift", "Name should update")
	assert_eq(vehicle_selector.vehicle_desc_label.text, "Better cornering", "Description should update")
	assert_eq(vehicle_selector.current_color, vehicle_selector.vehicle_data[1].base_color, "Color should update")
	
	if vehicle_selector.color_picker_button:
		assert_eq(vehicle_selector.color_picker_button.color, vehicle_selector.current_color, "Color picker should update")