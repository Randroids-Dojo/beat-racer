# GUT integration test for complete track functionality
extends GutTest

const TrackSystem = preload("res://scripts/components/track/track_system.gd")

var track_system
var mock_vehicle: Node2D


func before_each() -> void:
	track_system = TrackSystem.new()
	mock_vehicle = Node2D.new()
	
	add_child_autofree(track_system)
	add_child_autofree(mock_vehicle)
	await wait_frames(1)


func test_complete_track_setup() -> void:
	# Verify all components are created
	assert_not_null(track_system.track_geometry, "Track geometry should exist")
	assert_not_null(track_system.track_boundaries, "Track boundaries should exist")
	assert_not_null(track_system.start_finish_line, "Start/finish line should exist")
	assert_eq(track_system.beat_markers.size(), 16, "Should have 16 beat markers")
	
	# Verify boundaries reference geometry
	assert_eq(track_system.track_boundaries.track_geometry, track_system.track_geometry,
		"Boundaries should reference track geometry")


func test_vehicle_movement_on_track() -> void:
	# Simulate vehicle moving through different lanes
	var positions = []
	var lanes = []
	
	for i in range(3):
		var pos = track_system.track_geometry.get_lane_center_position(i, 0.0)
		mock_vehicle.global_position = track_system.to_global(pos)
		
		positions.append(mock_vehicle.global_position)
		lanes.append(track_system.get_current_lane(mock_vehicle.global_position))
	
	# Verify different lanes detected
	assert_eq(lanes[0], 0, "Should detect lane 0")
	assert_eq(lanes[1], 1, "Should detect lane 1")
	assert_eq(lanes[2], 2, "Should detect lane 2")


func test_lap_completion_detection() -> void:
	# Test direct timing functionality without collision detection
	var start_finish = track_system.start_finish_line
	assert_not_null(start_finish, "StartFinishLine should exist")
	
	# Test that it's not active initially
	assert_false(start_finish.is_active, "Should not be active initially")
	
	# Use watch_signals to properly catch the signal
	watch_signals(start_finish)
	
	# Start timing
	start_finish.start_timing()
	assert_true(start_finish.is_active, "Should be active after starting")
	
	# Wait and accumulate time
	await wait_seconds(0.1)
	
	# Finish timing and verify the lap time
	var elapsed_time = start_finish.finish_timing()
	
	# Check that timing worked correctly
	assert_false(start_finish.is_active, "Should not be active after finishing")
	assert_gt(elapsed_time, 0.0, "Elapsed time should be greater than 0")
	assert_almost_eq(elapsed_time, 0.1, 0.05, "Elapsed time should be approximately 0.1 seconds")
	
	# Verify signal was emitted with GUT's signal watching
	assert_signal_emitted(start_finish, "lap_completed", "Should emit lap_completed signal")
	
	# Get the signal parameters to verify the time
	var signal_params = get_signal_parameters(start_finish, "lap_completed", 0)
	if signal_params.size() > 0:
		assert_almost_eq(signal_params[0], elapsed_time, 0.01, "Signal time should match returned time")


func test_beat_marker_activation_sequence() -> void:
	# Connect to beat manager if available
	if not BeatManager:
		pass  # Skip test when BeatManager is not available
		return
	
	# Test that markers exist and can be activated
	assert_gt(track_system.beat_markers.size(), 0, "Should have beat markers")
	
	# Track which markers get activated by checking their state after beats
	var initial_states = []
	for marker in track_system.beat_markers:
		initial_states.append(marker.is_active)
	
	# Simulate beats - this should activate markers
	for beat in range(4):
		track_system._on_beat_occurred(beat, 0, beat, 0.25)
		await wait_frames(1)
	
	# Check that some markers were activated (we can't override the method, but we can check state)
	var activated_count = 0
	for i in range(track_system.beat_markers.size()):
		if track_system.beat_markers[i].is_active != initial_states[i]:
			activated_count += 1
	
	assert_gt(activated_count, 0, "Some markers should have been activated")


func test_track_progress_calculation() -> void:
	# Test progress at various points
	var test_points = [
		{progress = 0.0, expected = 0.0},
		{progress = 0.25, expected = 0.25},
		{progress = 0.5, expected = 0.5},
		{progress = 0.75, expected = 0.75},
		{progress = 1.0, expected = 0.0}  # Wraps back to start
	]
	
	for point in test_points:
		var pos = track_system.track_geometry.get_lane_center_position(1, point.progress)
		var calculated_progress = track_system.get_track_progress_at_position(
			track_system.to_global(pos))
		
		# Allow some tolerance due to discrete sampling
		assert_almost_eq(calculated_progress, point.expected, 0.05,
			"Progress at %.2f should be near %.2f" % [point.progress, point.expected])


func test_visual_elements_rendering() -> void:
	# Verify visual elements are set up correctly
	
	# Check track geometry colors
	assert_eq(track_system.track_geometry.track_color, Color(0.2, 0.2, 0.2),
		"Track should be dark gray")
	assert_eq(track_system.track_geometry.lane_line_color, Color(1.0, 1.0, 1.0, 0.8),
		"Lane lines should be white")
	assert_eq(track_system.track_geometry.center_line_color, Color(1.0, 1.0, 0.0, 0.8),
		"Center line should be yellow")
	
	# Check beat marker setup
	var measure_markers = 0
	for marker in track_system.beat_markers:
		if marker.is_measure_start:
			measure_markers += 1
			assert_eq(marker.accent_color, Color(1.0, 0.8, 0.0, 1.0),
				"Measure markers should be yellow")
	
	assert_eq(measure_markers, 4, "Should have 4 measure start markers")


func test_track_boundaries_collision() -> void:
	# Verify collision shapes are created
	var outer_boundary = track_system.track_boundaries.get_node_or_null("OuterBoundary")
	var inner_boundary = track_system.track_boundaries.get_node_or_null("InnerBoundary")
	
	assert_not_null(outer_boundary, "Outer boundary should exist")
	assert_not_null(inner_boundary, "Inner boundary should exist")
	
	# Check that they have collision shapes
	var outer_collision = outer_boundary.get_child(0) as CollisionPolygon2D
	var inner_collision = inner_boundary.get_child(0) as CollisionPolygon2D
	
	assert_not_null(outer_collision, "Outer collision polygon should exist")
	assert_not_null(inner_collision, "Inner collision polygon should exist")
	assert_gt(outer_collision.polygon.size(), 0, "Outer polygon should have points")
	assert_gt(inner_collision.polygon.size(), 0, "Inner polygon should have points")