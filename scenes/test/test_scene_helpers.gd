# Helper functions for creating test scenes
extends RefCounted
class_name TestSceneHelpers

static func create_test_track_system() -> TrackSystem:
	var track_system = TrackSystem.new()
	
	# Manually set up components
	var track_geometry = TrackGeometry.new()
	track_geometry.name = "TrackGeometry"
	track_system.add_child(track_geometry)
	track_system.track_geometry = track_geometry
	
	var track_boundaries = TrackBoundaries.new()
	track_boundaries.name = "TrackBoundaries"
	track_boundaries.track_geometry = track_geometry
	track_system.add_child(track_boundaries)
	track_system.track_boundaries = track_boundaries
	
	return track_system


static func create_test_vehicle_with_lanes() -> CharacterBody2D:
	# Create a base vehicle first
	var vehicle = CharacterBody2D.new()
	
	# Add the script manually
	vehicle.set_script(preload("res://scripts/components/vehicle/rhythm_vehicle_with_lanes.gd"))
	
	# Set up collision shape
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(30, 15)
	collision_shape.shape = shape
	vehicle.add_child(collision_shape)
	
	# Initialize vehicle properties
	vehicle.current_speed = 0.0
	vehicle.current_lane = 1
	vehicle.enable_lane_centering = false
	
	return vehicle


static func create_test_lane_detection() -> LaneDetectionSystem:
	var lane_detection = LaneDetectionSystem.new()
	return lane_detection