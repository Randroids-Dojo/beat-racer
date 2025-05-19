# Unit tests for the lane detection system
extends GutTest

var lane_detection: LaneDetectionSystem
var track_geometry: TrackGeometry


func before_each() -> void:
	lane_detection = LaneDetectionSystem.new()
	track_geometry = TrackGeometry.new()
	track_geometry.track_width = 300.0
	track_geometry.lane_count = 3
	
	lane_detection.track_geometry = track_geometry
	
	add_child(track_geometry)
	add_child(lane_detection)


func after_each() -> void:
	if is_instance_valid(lane_detection):
		lane_detection.queue_free()
	if is_instance_valid(track_geometry):
		track_geometry.queue_free()


func test_initial_state() -> void:
	assert_eq(lane_detection.current_lane, 1, "Should start in middle lane")
	assert_eq(lane_detection.lane_offset_from_center, 0.0, "Should start with no offset")
	assert_false(lane_detection.is_in_lane_center, "Should not be centered initially")


func test_detect_lane_position() -> void:
	# Test detection at various positions
	track_geometry._generate_track_geometry()
	
	# Test center lane
	var center_pos := track_geometry.get_lane_center_position(1, 0.0)
	var detected := lane_detection.detect_lane_position(center_pos)
	assert_eq(detected, 1, "Should detect center lane correctly")
	
	# Test left lane
	var left_pos := track_geometry.get_lane_center_position(0, 0.0)
	detected = lane_detection.detect_lane_position(left_pos)
	assert_eq(detected, 0, "Should detect left lane correctly")
	
	# Test right lane
	var right_pos := track_geometry.get_lane_center_position(2, 0.0)
	detected = lane_detection.detect_lane_position(right_pos)
	assert_eq(detected, 2, "Should detect right lane correctly")


func test_lane_boundaries() -> void:
	track_geometry._generate_track_geometry()
	
	var center_pos := track_geometry.get_lane_center_position(1, 0.0)
	var boundaries := lane_detection.get_lane_boundaries(center_pos)
	
	assert_has(boundaries, "center", "Should have center position")
	assert_has(boundaries, "left_boundary", "Should have left boundary")
	assert_has(boundaries, "right_boundary", "Should have right boundary")
	assert_has(boundaries, "width", "Should have lane width")
	
	assert_eq(boundaries.width, track_geometry.lane_width, "Lane width should match")


func test_lane_change_signal() -> void:
	track_geometry._generate_track_geometry()
	
	watch_signals(lane_detection)
	
	# Move from center to left lane
	var left_pos := track_geometry.get_lane_center_position(0, 0.0)
	lane_detection.detect_lane_position(left_pos)
	
	assert_signal_emitted(lane_detection, "lane_changed")
	assert_signal_emit_count(lane_detection, "lane_changed", 1)
	
	var signal_params = get_signal_parameters(lane_detection, "lane_changed", 0)
	assert_eq(signal_params[0], 1, "Previous lane should be 1")
	assert_eq(signal_params[1], 0, "New lane should be 0")


func test_distance_to_lane_edge() -> void:
	track_geometry._generate_track_geometry()
	
	var center_pos := track_geometry.get_lane_center_position(1, 0.0)
	
	# At center, distances should be equal
	var left_dist := lane_detection.get_distance_to_lane_edge(center_pos, "left")
	var right_dist := lane_detection.get_distance_to_lane_edge(center_pos, "right")
	
	assert_almost_eq(left_dist, right_dist, 1.0, "Distances should be equal at center")
	assert_almost_eq(left_dist, track_geometry.lane_width / 2.0, 1.0, 
			"Distance should be half lane width")


func test_lane_center_detection() -> void:
	track_geometry._generate_track_geometry()
	lane_detection.lane_center_tolerance = 20.0
	
	watch_signals(lane_detection)
	
	# Test entering lane center
	var center_pos := track_geometry.get_lane_center_position(1, 0.0)
	lane_detection.detect_lane_position(center_pos)
	
	assert_signal_emitted(lane_detection, "entered_lane_center")
	assert_true(lane_detection.is_in_lane_center, "Should be in lane center")
	
	# Test exiting lane center
	var offset_pos := center_pos + Vector2(30, 0)  # Move beyond tolerance
	lane_detection.detect_lane_position(offset_pos)
	
	assert_signal_emitted(lane_detection, "exited_lane_center")
	assert_false(lane_detection.is_in_lane_center, "Should not be in lane center")


func test_is_vehicle_in_lane_bounds() -> void:
	track_geometry._generate_track_geometry()
	
	# Test position in lane
	var center_pos := track_geometry.get_lane_center_position(1, 0.0)
	assert_true(lane_detection.is_vehicle_in_lane_bounds(center_pos), 
			"Center position should be in bounds")
	
	# Test position outside lane
	var outside_pos := center_pos + Vector2(track_geometry.track_width, 0)
	assert_false(lane_detection.is_vehicle_in_lane_bounds(outside_pos), 
			"Position outside track should not be in bounds")


func test_get_lane_info() -> void:
	track_geometry._generate_track_geometry()
	
	var center_pos := track_geometry.get_lane_center_position(1, 0.0)
	lane_detection.detect_lane_position(center_pos)
	
	var info := lane_detection.get_lane_info()
	
	assert_has(info, "current_lane", "Should have current lane")
	assert_has(info, "offset_from_center", "Should have offset")
	assert_has(info, "is_centered", "Should have centered state")
	assert_has(info, "lane_count", "Should have lane count")
	assert_has(info, "transition_progress", "Should have transition progress")
	
	assert_eq(info.current_lane, 1, "Current lane should be 1")
	assert_eq(info.lane_count, 3, "Lane count should be 3")