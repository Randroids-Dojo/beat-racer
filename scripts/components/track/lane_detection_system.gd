# Lane detection system that tracks vehicle position relative to track lanes
extends Node2D
class_name LaneDetectionSystem

@export var track_geometry: TrackGeometry
@export var detection_radius := 50.0  # Distance to check for lane boundaries
@export var lane_center_tolerance := 20.0  # Distance from center to be considered "in lane"
@export var transition_threshold := 0.8  # How much of the vehicle must be in a lane to transition

signal lane_changed(previous_lane: int, new_lane: int)
signal lane_position_updated(lane: int, offset_from_center: float)
signal entered_lane_center(lane: int)
signal exited_lane_center(lane: int)

var current_lane := 1  # Start in middle lane (0-based index)
var lane_offset_from_center := 0.0
var is_in_lane_center := false
var transition_progress := 0.0  # 0.0 = fully in current lane, 1.0 = fully in next lane


func _ready() -> void:
	set_process(true)


func detect_lane_position(vehicle_position: Vector2) -> int:
	"""Detect which lane the vehicle is currently in"""
	if not track_geometry:
		push_warning("LaneDetectionSystem: No track geometry assigned")
		return current_lane
	
	var local_pos := track_geometry.to_local(vehicle_position)
	var closest_lane := -1
	var min_distance := INF
	
	# Check distance to each lane center
	for lane_idx in range(track_geometry.lane_count):
		# Sample multiple points along the track to find closest
		for progress in range(0, 100, 10):  # Check every 10%
			var lane_center := track_geometry.get_lane_center_position(lane_idx, progress / 100.0)
			var distance := local_pos.distance_to(lane_center)
			
			if distance < min_distance:
				min_distance = distance
				closest_lane = lane_idx
	
	# Calculate offset from lane center
	var track_system = track_geometry.get_parent() if track_geometry else null
	var current_progress: float = 0.0
	if track_system and track_system.has_method("get_track_progress_at_position"):
		current_progress = track_system.get_track_progress_at_position(vehicle_position)
	else:
		# Fallback calculation
		current_progress = 0.0
	var lane_center_pos := track_geometry.get_lane_center_position(closest_lane, current_progress)
	lane_offset_from_center = local_pos.distance_to(lane_center_pos)
	
	# Check if in lane center
	var was_in_center := is_in_lane_center
	is_in_lane_center = lane_offset_from_center <= lane_center_tolerance
	
	if is_in_lane_center and not was_in_center:
		entered_lane_center.emit(closest_lane)
	elif not is_in_lane_center and was_in_center:
		exited_lane_center.emit(closest_lane)
	
	# Emit position update
	lane_position_updated.emit(closest_lane, lane_offset_from_center)
	
	# Handle lane transitions
	if closest_lane != current_lane:
		_handle_lane_transition(closest_lane)
	
	return closest_lane


func _handle_lane_transition(new_lane: int) -> void:
	"""Handle smooth lane transitions"""
	# Simple transition - could be enhanced with gradual transition
	var previous_lane := current_lane
	current_lane = new_lane
	lane_changed.emit(previous_lane, new_lane)


func get_lane_boundaries(vehicle_position: Vector2) -> Dictionary:
	"""Get the boundaries of the current lane at the vehicle's position"""
	if not track_geometry:
		return {}
	
	var track_system = track_geometry.get_parent() if track_geometry else null
	var progress: float = 0.0
	if track_system and track_system.has_method("get_track_progress_at_position"):
		progress = track_system.get_track_progress_at_position(vehicle_position)
	else:
		# Fallback calculation
		progress = 0.0
	var lane_width := track_geometry.lane_width
	var lane_center := track_geometry.get_lane_center_position(current_lane, progress)
	
	# Calculate tangent direction at this point
	var next_progress: float = progress + 0.01
	if next_progress > 1.0:
		next_progress -= 1.0
	var next_pos := track_geometry.get_lane_center_position(current_lane, next_progress)
	var tangent := (next_pos - lane_center).normalized()
	var normal := Vector2(-tangent.y, tangent.x)  # Perpendicular to tangent
	
	return {
		"center": lane_center,
		"left_boundary": lane_center - normal * (lane_width / 2.0),
		"right_boundary": lane_center + normal * (lane_width / 2.0),
		"tangent": tangent,
		"normal": normal,
		"width": lane_width
	}


func get_distance_to_lane_edge(vehicle_position: Vector2, side: String = "nearest") -> float:
	"""Get distance to the edge of the current lane"""
	var boundaries := get_lane_boundaries(vehicle_position)
	if boundaries.is_empty():
		return 0.0
	
	var local_pos := track_geometry.to_local(vehicle_position)
	var left_dist := local_pos.distance_to(boundaries.left_boundary)
	var right_dist := local_pos.distance_to(boundaries.right_boundary)
	
	match side:
		"left":
			return left_dist
		"right":
			return right_dist
		"nearest":
			return min(left_dist, right_dist)
		_:
			return 0.0


func get_lane_info() -> Dictionary:
	"""Get comprehensive information about current lane position"""
	return {
		"current_lane": current_lane,
		"offset_from_center": lane_offset_from_center,
		"is_centered": is_in_lane_center,
		"lane_count": track_geometry.lane_count if track_geometry else 0,
		"transition_progress": transition_progress
	}


func is_vehicle_in_lane_bounds(vehicle_position: Vector2) -> bool:
	"""Check if vehicle is within the boundaries of any lane"""
	if not track_geometry:
		return false
	
	var detected_lane := detect_lane_position(vehicle_position) as int
	var boundaries := get_lane_boundaries(vehicle_position)
	
	if boundaries.is_empty():
		return false
	
	var local_pos := track_geometry.to_local(vehicle_position)
	var dist_to_center := local_pos.distance_to(boundaries.center)
	
	return dist_to_center <= boundaries.width / 2.0