# GUT unit tests for the track system components
extends "res://addons/gut/test.gd"

const TrackGeometry = preload("res://scripts/components/track/track_geometry.gd")
const TrackBoundaries = preload("res://scripts/components/track/track_boundaries.gd")
const TrackSystem = preload("res://scripts/components/track/track_system.gd")
const StartFinishLine = preload("res://scripts/components/track/start_finish_line.gd")
const BeatMarker = preload("res://scripts/components/track/beat_marker.gd")

var track_geometry
var track_boundaries
var track_system
var start_finish_line
var beat_marker


func before_each() -> void:
	# Create instances - use autofree for automatic cleanup
	track_geometry = autofree(TrackGeometry.new())
	track_boundaries = autofree(TrackBoundaries.new())
	track_system = null  # Created per test where needed
	start_finish_line = autofree(StartFinishLine.new())
	beat_marker = autofree(BeatMarker.new())


func after_each() -> void:
	# Additional cleanup for nodes that may have been added to tree
	if track_system and is_instance_valid(track_system):
		track_system.queue_free()
		track_system = null
	
	# Wait for cleanup
	await wait_frames(1)


# Test TrackGeometry
func test_track_geometry_initialization() -> void:
	assert_eq(track_geometry.lane_count, 3, "Default lane count should be 3")
	assert_eq(track_geometry.track_width, 300.0, "Default track width should be 300")
	assert_eq(track_geometry.track_length, 2000.0, "Default track length should be 2000")
	assert_eq(track_geometry.curve_radius, 400.0, "Default curve radius should be 400")


func test_track_geometry_lane_width_calculation() -> void:
	track_geometry.track_width = 300.0
	track_geometry.lane_count = 3
	assert_eq(track_geometry.lane_width, 100.0, "Lane width should be track width / lane count")


func test_track_geometry_circumference_calculation() -> void:
	track_geometry.track_length = 2000.0
	track_geometry.curve_radius = 400.0
	var expected_circumference = 2 * 2000.0 + 2 * PI * 400.0
	assert_almost_eq(track_geometry.total_circumference, expected_circumference, 0.1)


func test_track_geometry_generates_polygon() -> void:
	add_child_autofree(track_geometry)
	await wait_frames(1)
	
	assert_false(track_geometry.track_polygon.is_empty(), "Track polygon should be generated")
	assert_gt(track_geometry.track_polygon.size(), 0, "Track polygon should have points")


func test_track_geometry_lane_center_position() -> void:
	add_child_autofree(track_geometry)
	await wait_frames(1)
	
	# Test middle lane at start
	var pos: Vector2 = track_geometry.get_lane_center_position(1, 0.0)
	assert_not_null(pos)
	assert_typeof(pos, TYPE_VECTOR2)
	
	# Test invalid lane index
	track_geometry.get_lane_center_position(-1, 0.0)  # Should show warning but not crash
	track_geometry.get_lane_center_position(5, 0.0)   # Should show warning but not crash


func test_track_geometry_closest_lane() -> void:
	add_child_autofree(track_geometry)
	await wait_frames(1)
	
	# Test center of middle lane
	var middle_pos: Vector2 = track_geometry.get_lane_center_position(1, 0.0)
	var closest: int = track_geometry.get_closest_lane(track_geometry.to_global(middle_pos))
	assert_eq(closest, 1, "Should detect middle lane")


# Test StartFinishLine
func test_start_finish_line_initialization() -> void:
	assert_eq(start_finish_line.line_width, 50.0, "Default line width should be 50")
	assert_eq(start_finish_line.stripe_count, 10, "Default stripe count should be 10")
	assert_false(start_finish_line.is_active, "Should not be active initially")


func test_start_finish_line_timing() -> void:
	start_finish_line.start_timing()
	assert_true(start_finish_line.is_active, "Should be active after starting")
	
	# Simulate some time passing
	await wait_seconds(0.1)
	
	var lap_time: float = start_finish_line.finish_timing()
	assert_gt(lap_time, 0.0, "Lap time should be greater than 0")
	assert_false(start_finish_line.is_active, "Should not be active after finishing")


# Test BeatMarker
func test_beat_marker_initialization() -> void:
	assert_eq(beat_marker.marker_size, 20.0, "Default marker size should be 20")
	assert_false(beat_marker.is_active, "Should not be active initially")
	assert_eq(beat_marker.beat_number, 0, "Default beat number should be 0")


func test_beat_marker_activation() -> void:
	add_child_autofree(beat_marker)
	await wait_frames(1)
	
	beat_marker.activate()
	assert_true(beat_marker.is_active, "Should be active after activation")
	assert_gt(beat_marker.activation_timer, 0.0, "Activation timer should be set")


func test_beat_marker_track_position() -> void:
	beat_marker.beat_number = 4
	var progress: float = beat_marker.get_track_position()
	assert_eq(progress, 0.25, "Beat 4 should be at 25% progress (4/16)")


# Test TrackBoundaries
func test_track_boundaries_requires_geometry() -> void:
	add_child_autofree(track_boundaries)
	await wait_frames(1)
	
	# Should not crash but should warn about missing geometry
	assert_not_null(track_boundaries)


func test_track_boundaries_with_geometry() -> void:
	add_child_autofree(track_geometry)
	track_boundaries.track_geometry = track_geometry
	add_child_autofree(track_boundaries)
	await wait_frames(1)
	
	# Should create collision bodies
	var outer_boundary = track_boundaries.get_node_or_null("OuterBoundary")
	var inner_boundary = track_boundaries.get_node_or_null("InnerBoundary")
	
	assert_not_null(outer_boundary, "Should create outer boundary")
	assert_not_null(inner_boundary, "Should create inner boundary")


# Test TrackSystem
func test_track_system_initialization() -> void:
	track_system = autofree(TrackSystem.new())
	add_child_autofree(track_system)
	await wait_frames(1)
	
	assert_not_null(track_system.track_geometry, "Should create track geometry")
	assert_not_null(track_system.track_boundaries, "Should create track boundaries")
	assert_not_null(track_system.start_finish_line, "Should create start/finish line")
	assert_eq(track_system.beats_per_lap, 16, "Default beats per lap should be 16")


func test_track_system_creates_beat_markers() -> void:
	track_system = autofree(TrackSystem.new())
	add_child_autofree(track_system)
	await wait_frames(1)
	
	assert_eq(track_system.beat_markers.size(), track_system.beats_per_lap, 
		"Should create one marker per beat")
	
	# Check measure markers
	var measure_count := 0
	for marker in track_system.beat_markers:
		if marker.is_measure_start:
			measure_count += 1
	
	assert_eq(measure_count, 4, "Should have 4 measure starts (16 beats / 4)")


func test_track_system_progress_calculation() -> void:
	track_system = autofree(TrackSystem.new())
	add_child_autofree(track_system)
	await wait_frames(1)
	
	# Test at start position
	var start_pos: Vector2 = track_system.track_geometry.get_lane_center_position(1, 0.0)
	var progress: float = track_system.get_track_progress_at_position(
		track_system.to_global(start_pos))
	assert_almost_eq(progress, 0.0, 0.05, "Progress at start should be near 0")


func test_track_system_lane_detection() -> void:
	track_system = autofree(TrackSystem.new())
	add_child_autofree(track_system)
	await wait_frames(1)
	
	# Test middle lane
	var middle_pos: Vector2 = track_system.track_geometry.get_lane_center_position(1, 0.0)
	var lane: int = track_system.get_current_lane(track_system.to_global(middle_pos))
	assert_eq(lane, 1, "Should detect middle lane correctly")