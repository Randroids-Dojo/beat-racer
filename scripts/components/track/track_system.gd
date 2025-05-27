# Complete track system that combines all track components
extends Node2D
class_name TrackSystem

@export var beats_per_lap := 16  # Number of beats to complete one lap
@export_group("Components")
@export var track_geometry: TrackGeometry
@export var track_boundaries: TrackBoundaries
@export var start_finish_line: StartFinishLine

var beat_markers: Array[BeatMarker] = []


func _ready() -> void:
	_setup_components()
	_create_beat_markers()
	
	if BeatManager:
		BeatManager.beat_occurred.connect(_on_beat_occurred)


func _setup_components() -> void:
	# Setup track geometry
	if not track_geometry:
		track_geometry = TrackGeometry.new()
		track_geometry.name = "TrackGeometry"
		add_child(track_geometry)
	
	# Setup boundaries
	if not track_boundaries:
		track_boundaries = TrackBoundaries.new()
		track_boundaries.name = "TrackBoundaries"
		track_boundaries.track_geometry = track_geometry
		add_child(track_boundaries)
	
	# Setup start/finish line
	if not start_finish_line:
		start_finish_line = preload("res://scenes/components/track/start_finish_line.tscn").instantiate()
		start_finish_line.name = "StartFinishLine"
		add_child(start_finish_line)
		
		# Position at the top center of the track
		start_finish_line.position = Vector2(0, -track_geometry.curve_radius)
		start_finish_line.rotation = 0  # Horizontal line


func _create_beat_markers() -> void:
	var beat_markers_container := Node2D.new()
	beat_markers_container.name = "BeatMarkers"
	add_child(beat_markers_container)
	
	for i in range(beats_per_lap):
		var marker := BeatMarker.new()
		marker.beat_number = i
		marker.is_measure_start = (i % 4 == 0)  # Every 4th beat is a measure start
		
		# Position marker along the track
		var progress := float(i) / float(beats_per_lap)
		var lane_pos := track_geometry.get_lane_center_position(1, progress)  # Middle lane
		marker.position = lane_pos
		
		# Calculate angle for proper orientation
		var next_progress := float(i + 1) / float(beats_per_lap)
		if i == beats_per_lap - 1:
			next_progress = 0.0
		var next_pos := track_geometry.get_lane_center_position(1, next_progress)
		var direction: Vector2 = (next_pos - lane_pos).normalized()
		marker.rotation = direction.angle() + PI / 2
		
		beat_markers_container.add_child(marker)
		beat_markers.append(marker)


func _on_beat_occurred(beat_count: int, _beat_time: float) -> void:
	# Activate the current beat marker
	var marker_index := beat_count % beats_per_lap
	if marker_index < beat_markers.size():
		beat_markers[marker_index].activate()


func get_track_progress_at_position(global_position: Vector2) -> float:
	"""Get the progress along the track (0.0 to 1.0) for a given position"""
	var local_pos := to_local(global_position)
	var closest_progress := 0.0
	var min_distance := INF
	
	# Sample points along the track to find closest
	for i in range(100):
		var progress := float(i) / 100.0
		var track_pos := track_geometry.get_lane_center_position(1, progress)  # Use middle lane
		var distance := local_pos.distance_to(track_pos)
		
		if distance < min_distance:
			min_distance = distance
			closest_progress = progress
	
	return closest_progress


func get_current_lane(global_position: Vector2) -> int:
	"""Get the current lane index for a given position"""
	return track_geometry.get_closest_lane(global_position)