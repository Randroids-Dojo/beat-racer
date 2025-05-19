# Simplified integration tests for lane detection
extends GutTest

var track_system: TrackSystem
var vehicle: CharacterBody2D
var lane_detection: LaneDetectionSystem


func before_each() -> void:
	# Create a simplified track system
	track_system = TrackSystem.new()
	add_child(track_system)
	
	# Wait for track to initialize
	await get_tree().process_frame
	
	# Create lane detection
	lane_detection = LaneDetectionSystem.new()
	lane_detection.track_geometry = track_system.track_geometry
	add_child(lane_detection)
	
	# Create a basic vehicle  
	vehicle = CharacterBody2D.new()
	vehicle.set_script(preload("res://scripts/components/vehicle/rhythm_vehicle_with_lanes.gd"))
	add_child(vehicle)
	
	# Set the lane detection on vehicle
	if vehicle.has_method("_ready"):
		vehicle._ready()
		
	vehicle.lane_detection_system = lane_detection
	
	# Give everything time to initialize
	await get_tree().process_frame


func after_each() -> void:
	if is_instance_valid(vehicle):
		vehicle.queue_free()
	if is_instance_valid(lane_detection):
		lane_detection.queue_free()
	if is_instance_valid(track_system):
		track_system.queue_free()


func test_basic_lane_detection() -> void:
	# Position vehicle in center lane
	var center_pos := track_system.track_geometry.get_lane_center_position(1, 0.0)
	vehicle.global_position = center_pos
	
	# Detect lane
	var detected_lane := lane_detection.detect_lane_position(center_pos)
	
	assert_eq(detected_lane, 1, "Should detect center lane")


func test_basic_lane_change() -> void:
	# Start in center lane
	var center_pos := track_system.track_geometry.get_lane_center_position(1, 0.0)
	vehicle.global_position = center_pos
	
	# Move to left lane
	var left_pos := track_system.track_geometry.get_lane_center_position(0, 0.0)
	vehicle.global_position = left_pos
	
	var detected_lane := lane_detection.detect_lane_position(left_pos)
	assert_eq(detected_lane, 0, "Should detect left lane")


func test_lane_boundaries() -> void:
	var center_pos := track_system.track_geometry.get_lane_center_position(1, 0.0)
	var boundaries := lane_detection.get_lane_boundaries(center_pos)
	
	assert_false(boundaries.is_empty(), "Should have boundary information")
	
	if not boundaries.is_empty():
		assert_has(boundaries, "center", "Should have center position")
		assert_has(boundaries, "width", "Should have lane width")


func test_is_vehicle_in_bounds() -> void:
	# Position in center lane
	var center_pos := track_system.track_geometry.get_lane_center_position(1, 0.0)
	var in_bounds := lane_detection.is_vehicle_in_lane_bounds(center_pos)
	
	assert_true(in_bounds, "Center position should be in bounds")
	
	# Position outside track
	var outside_pos := center_pos + Vector2(1000, 0)
	in_bounds = lane_detection.is_vehicle_in_lane_bounds(outside_pos)
	
	assert_false(in_bounds, "Far position should be out of bounds")