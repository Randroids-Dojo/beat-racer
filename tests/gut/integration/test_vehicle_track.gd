# GUT integration test for vehicle and track interaction
extends GutTest

const TrackSystem = preload("res://scripts/components/track/track_system.gd")
const Vehicle = preload("res://scripts/components/vehicle/vehicle.gd")

var track_system: TrackSystem
var vehicle: Vehicle


func before_each() -> void:
	track_system = autofree(TrackSystem.new())
	vehicle = autofree(Vehicle.new())
	
	add_child(track_system)
	add_child(vehicle)
	await wait_frames(1)


func test_vehicle_track_setup() -> void:
	assert_not_null(track_system)
	assert_not_null(vehicle)
	
	# Check for collision shape in children
	var has_collision_shape = false
	for child in vehicle.get_children():
		if child is CollisionShape2D:
			has_collision_shape = true
			break
	assert_true(has_collision_shape, "Vehicle should have a CollisionShape2D child")


func test_vehicle_lane_detection() -> void:
	# Position vehicle in each lane
	for lane in range(3):
		var lane_pos = track_system.track_geometry.get_lane_center_position(lane, 0.0)
		vehicle.global_position = track_system.to_global(lane_pos)
		
		var detected_lane = track_system.get_current_lane(vehicle.global_position)
		assert_eq(detected_lane, lane, "Vehicle should be detected in lane %d" % lane)


func test_vehicle_start_position() -> void:
	# Position at start line in middle lane
	var middle_lane_pos = track_system.track_geometry.get_lane_center_position(1, 0.0)
	vehicle.reset_position(track_system.to_global(middle_lane_pos))
	
	# Wait for position to update
	await wait_frames(1)
	
	# Verify position
	var progress = track_system.get_track_progress_at_position(vehicle.global_position)
	assert_almost_eq(progress, 0.0, 0.1, "Vehicle should be near start (progress 0)")
	
	var lane = track_system.get_current_lane(vehicle.global_position)
	assert_eq(lane, 1, "Vehicle should be in middle lane")


func test_vehicle_movement_along_track() -> void:
	# Start at beginning of track, slightly off 0.0 to avoid edge case
	var start_pos = track_system.track_geometry.get_lane_center_position(1, 0.1)
	vehicle.global_position = track_system.to_global(start_pos)
	await wait_frames(1)
	
	# Record initial position
	var initial_position = vehicle.global_position
	var initial_progress = track_system.get_track_progress_at_position(vehicle.global_position)
	
	# Set velocity directly for testing instead of using throttle
	vehicle.current_speed = 300.0
	vehicle.velocity = vehicle.transform.x * vehicle.current_speed
	
	# Move the vehicle for several frames
	for i in range(10):
		vehicle.move_and_slide()
		await wait_frames(1)
	
	# Check position changed
	var final_position = vehicle.global_position
	var distance_moved = initial_position.distance_to(final_position)
	assert_gt(distance_moved, 10.0, "Vehicle should have moved significantly")
	
	# Check progress increased
	var final_progress = track_system.get_track_progress_at_position(vehicle.global_position)
	assert_gt(final_progress, initial_progress, "Vehicle should have made progress along track")


func test_lap_detection_with_vehicle() -> void:
	# Connect to lap signal
	watch_signals(track_system.start_finish_line)
	
	# Position vehicle just before finish line
	var before_finish = track_system.track_geometry.get_lane_center_position(1, 0.98)
	vehicle.global_position = track_system.to_global(before_finish)
	
	# Start timing
	track_system.start_finish_line.start_timing()
	
	# Simulate crossing finish line
	var finish_pos = track_system.track_geometry.get_lane_center_position(1, 0.02)
	vehicle.global_position = track_system.to_global(finish_pos)
	
	# Trigger the body_entered event manually (since we're not using physics)
	track_system.start_finish_line._on_body_entered(vehicle)
	
	# Verify lap completion
	assert_signal_emitted(track_system.start_finish_line, "lap_completed")
	assert_false(track_system.start_finish_line.is_active)


func test_vehicle_collision_layers() -> void:
	# Check vehicle is on correct layer
	assert_eq(vehicle.collision_layer, 2, "Vehicle should be on layer 2")
	assert_eq(vehicle.collision_mask, 5, "Vehicle should collide with layers 1 and 4")
	
	# Check track boundaries are on correct layer
	var boundaries = track_system.track_boundaries
	var outer_boundary = boundaries.get_node("OuterBoundary")
	var inner_boundary = boundaries.get_node("InnerBoundary")
	
	assert_eq(outer_boundary.collision_layer, 1, "Boundaries should be on layer 1")
	assert_eq(inner_boundary.collision_layer, 1, "Boundaries should be on layer 1")


func test_vehicle_on_different_track_positions() -> void:
	var test_positions = [0.0, 0.25, 0.5, 0.75, 1.0]
	
	for progress in test_positions:
		for lane in range(3):
			var pos = track_system.track_geometry.get_lane_center_position(lane, progress)
			vehicle.global_position = track_system.to_global(pos)
			
			var detected_lane = track_system.get_current_lane(vehicle.global_position)
			assert_eq(detected_lane, lane, 
				"Lane detection at progress %.2f, lane %d" % [progress, lane])
			
			# For progress 1.0, it should wrap to 0.0
			var detected_progress = track_system.get_track_progress_at_position(
				vehicle.global_position)
			var expected_progress = 0.0 if progress == 1.0 else progress
			assert_almost_eq(detected_progress, expected_progress, 0.1,
				"Progress detection at %.2f" % progress)