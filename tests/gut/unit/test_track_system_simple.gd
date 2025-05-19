# Simple GUT unit test for track system components
extends "res://addons/gut/test.gd"

const TrackGeometry = preload("res://scripts/components/track/track_geometry.gd")
const TrackBoundaries = preload("res://scripts/components/track/track_boundaries.gd")
const StartFinishLine = preload("res://scripts/components/track/start_finish_line.gd")
const BeatMarker = preload("res://scripts/components/track/beat_marker.gd")
const TrackSystem = preload("res://scripts/components/track/track_system.gd")

var track_geometry
var track_system
var start_finish_line

func before_each() -> void:
	# Use autofree for automatic cleanup
	track_geometry = autofree(TrackGeometry.new())
	track_system = null  # Created per test where needed
	start_finish_line = autofree(StartFinishLine.new())

func after_each() -> void:
	# Additional cleanup for track system that might be in tree
	if track_system and is_instance_valid(track_system):
		track_system.queue_free()
		track_system = null
	
	# Wait for cleanup
	await wait_frames(1)

# Test TrackGeometry basics
func test_track_geometry_creation() -> void:
	assert_not_null(track_geometry, "Track geometry should be created")
	assert_eq(track_geometry.lane_count, 3, "Default lane count should be 3")
	assert_eq(track_geometry.track_width, 300.0, "Default track width should be 300")

func test_track_geometry_lane_calculations() -> void:
	track_geometry.track_width = 300.0
	track_geometry.lane_count = 3
	assert_eq(track_geometry.lane_width, 100.0, "Lane width should be 100")

# Test TrackSystem basics
func test_track_system_creation() -> void:
	track_system = autofree(TrackSystem.new())
	add_child_autofree(track_system)
	await wait_frames(1)
	
	assert_not_null(track_system, "Track system should be created")
	assert_not_null(track_system.track_geometry, "Track geometry should exist")
	assert_eq(track_system.beats_per_lap, 16, "Default beats per lap should be 16")

# Test StartFinishLine basics  
func test_start_finish_line_creation() -> void:
	assert_not_null(start_finish_line, "Start/finish line should be created")
	assert_eq(start_finish_line.line_width, 50.0, "Default line width should be 50")
	assert_eq(start_finish_line.stripe_count, 10, "Default stripe count should be 10")

func test_start_finish_line_timing() -> void:
	start_finish_line.start_timing()
	assert_true(start_finish_line.is_active, "Should be active after starting")
	
	await wait_seconds(0.1)
	
	var lap_time = start_finish_line.finish_timing()
	assert_gt(lap_time, 0.0, "Lap time should be greater than 0")
	assert_false(start_finish_line.is_active, "Should not be active after finishing")