# Track geometry component for creating oval tracks with lanes
extends Node2D
class_name TrackGeometry

# Track configuration
@export var track_width := 300.0  # Total width of the track
@export var lane_count := 3  # Number of lanes
@export var track_length := 2000.0  # Length of straight sections
@export var curve_radius := 400.0  # Radius of the curves
@export var line_width := 5.0  # Width of lane divider lines

# Visual configuration
@export var track_color := Color(0.2, 0.2, 0.2)  # Asphalt color
@export var lane_line_color := Color(1.0, 1.0, 1.0, 0.8)  # White lane lines
@export var center_line_color := Color(1.0, 1.0, 0.0, 0.8)  # Yellow center line
@export var edge_line_color := Color(1.0, 1.0, 1.0)  # White edge lines

# Calculated properties
var lane_width: float:
	get: return track_width / lane_count

var total_circumference: float:
	get: return 2 * track_length + 2 * PI * curve_radius

# Cached geometry
var track_polygon: PackedVector2Array
var lane_dividers: Array[PackedVector2Array] = []
var center_line: PackedVector2Array
var edge_lines: Array[PackedVector2Array] = []


func _ready() -> void:
	set_notify_transform(true)
	_generate_track_geometry()
	queue_redraw()


func _draw() -> void:
	if track_polygon.is_empty():
		return
	
	# Draw track base
	draw_colored_polygon(track_polygon, track_color)
	
	# Draw edge lines
	for edge_line in edge_lines:
		draw_polyline(edge_line, edge_line_color, line_width * 1.5)
	
	# Draw lane dividers
	for i in range(lane_dividers.size()):
		if i == 1:  # Center lane separator
			draw_polyline(lane_dividers[i], center_line_color, line_width)
		else:
			_draw_dashed_line(lane_dividers[i], lane_line_color, line_width)


func _generate_track_geometry() -> void:
	track_polygon.clear()
	lane_dividers.clear()
	edge_lines.clear()
	
	# Generate outer and inner edge of track
	var outer_edge := _generate_oval_path(curve_radius + track_width / 2.0)
	var inner_edge := _generate_oval_path(curve_radius - track_width / 2.0)
	
	# Create track polygon
	track_polygon = outer_edge
	for i in range(inner_edge.size() - 1, -1, -1):
		track_polygon.append(inner_edge[i])
	
	# Store edge lines
	edge_lines.append(outer_edge)
	edge_lines.append(inner_edge)
	
	# Generate lane dividers
	for i in range(1, lane_count):
		var lane_offset := -track_width / 2.0 + i * lane_width
		var lane_line := _generate_oval_path(curve_radius + lane_offset)
		lane_dividers.append(lane_line)


func _generate_oval_path(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var segments := 64  # Number of segments for curves
	
	# Top straight section
	for i in range(11):
		var x := -track_length / 2.0 + i * track_length / 10.0
		points.append(Vector2(x, -radius))
	
	# Right curve
	for i in range(segments / 2 + 1):
		var angle := -PI / 2.0 + i * PI / (segments / 2)
		var x := track_length / 2.0 + radius * cos(angle)
		var y := radius * sin(angle)
		points.append(Vector2(x, y))
	
	# Bottom straight section
	for i in range(11):
		var x := track_length / 2.0 - i * track_length / 10.0
		points.append(Vector2(x, radius))
	
	# Left curve
	for i in range(segments / 2 + 1):
		var angle := PI / 2.0 + i * PI / (segments / 2)
		var x := -track_length / 2.0 + radius * cos(angle)
		var y := radius * sin(angle)
		points.append(Vector2(x, y))
	
	return points


func _draw_dashed_line(points: PackedVector2Array, color: Color, width: float) -> void:
	var dash_length := 30.0
	var gap_length := 15.0
	var current_length := 0.0
	var is_dash := true
	
	var dash_points := PackedVector2Array()
	
	for i in range(points.size() - 1):
		var p1 := points[i]
		var p2 := points[i + 1]
		var segment_length := p1.distance_to(p2)
		var remaining_length := segment_length
		var segment_start := 0.0
		
		while remaining_length > 0:
			var target_length := dash_length if is_dash else gap_length
			var draw_length: float = min(remaining_length, target_length - current_length)
			
			if is_dash:
				var start_t := segment_start / segment_length
				var end_t: float = (segment_start + draw_length) / segment_length
				var start_point := p1.lerp(p2, start_t)
				var end_point := p1.lerp(p2, end_t)
				
				if dash_points.is_empty():
					dash_points.append(start_point)
				dash_points.append(end_point)
				
				if current_length + draw_length >= dash_length:
					draw_polyline(dash_points, color, width)
					dash_points.clear()
			
			current_length += draw_length
			remaining_length -= draw_length
			segment_start += draw_length
			
			if current_length >= target_length:
				is_dash = not is_dash
				current_length = 0.0


func get_lane_center_position(lane_index: int, progress: float) -> Vector2:
	"""Get the center position of a lane at a given progress along the track"""
	if lane_index < 0 or lane_index >= lane_count:
		push_warning("Invalid lane index: " + str(lane_index))
		return Vector2.ZERO
	
	# Calculate the radius for this lane's center
	var lane_offset := -track_width / 2.0 + (lane_index + 0.5) * lane_width
	var lane_radius := curve_radius + lane_offset
	
	# Generate the path for this lane's center
	var lane_path := _generate_oval_path(lane_radius)
	
	# Find the position at the given progress
	var total_length := 0.0
	for i in range(lane_path.size() - 1):
		total_length += lane_path[i].distance_to(lane_path[i + 1])
	
	var target_length := progress * total_length
	var current_length := 0.0
	
	for i in range(lane_path.size() - 1):
		var segment_length := lane_path[i].distance_to(lane_path[i + 1])
		if current_length + segment_length >= target_length:
			var t := (target_length - current_length) / segment_length
			return lane_path[i].lerp(lane_path[i + 1], t)
		current_length += segment_length
	
	return lane_path[-1]


func get_closest_lane(global_position: Vector2) -> int:
	"""Get the index of the lane closest to the given position"""
	var local_pos := to_local(global_position)
	var min_distance := INF
	var closest_lane := 0
	
	for lane in range(lane_count):
		# Check multiple points along the track
		for progress in range(0, 100, 5):
			var lane_pos := get_lane_center_position(lane, progress / 100.0)
			var distance := local_pos.distance_to(lane_pos)
			if distance < min_distance:
				min_distance = distance
				closest_lane = lane
	
	return closest_lane
