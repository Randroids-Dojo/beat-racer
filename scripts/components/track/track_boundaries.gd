# Track boundaries component for collision detection
extends Node2D
class_name TrackBoundaries

@export var track_geometry: TrackGeometry
@export var boundary_thickness := 50.0

var outer_boundary_body: StaticBody2D
var inner_boundary_body: StaticBody2D


func _ready() -> void:
	# Try to find TrackGeometry in parent if not set
	if not track_geometry:
		var parent_node = get_parent()
		if parent_node:
			track_geometry = parent_node.get_node_or_null("TrackGeometry")
	
	if not track_geometry:
		push_error("TrackBoundaries requires a TrackGeometry reference")
		return
	
	_create_boundary_bodies()
	_update_collision_shapes()
	
	# Update boundaries if track geometry changes
	track_geometry.draw.connect(_update_collision_shapes)


func _create_boundary_bodies() -> void:
	# Create outer boundary
	outer_boundary_body = StaticBody2D.new()
	outer_boundary_body.name = "OuterBoundary"
	add_child(outer_boundary_body)
	
	# Create inner boundary
	inner_boundary_body = StaticBody2D.new()
	inner_boundary_body.name = "InnerBoundary"
	add_child(inner_boundary_body)


func _update_collision_shapes() -> void:
	if not track_geometry or not outer_boundary_body or not inner_boundary_body:
		return
	
	# Clear existing collision shapes
	for child in outer_boundary_body.get_children():
		child.queue_free()
	for child in inner_boundary_body.get_children():
		child.queue_free()
	
	# Create outer boundary using multiple convex segments
	var outer_radius := track_geometry.curve_radius + track_geometry.track_width / 2.0 + boundary_thickness
	var track_outer_radius := track_geometry.curve_radius + track_geometry.track_width / 2.0
	_create_segmented_boundary(outer_boundary_body, track_outer_radius, outer_radius, track_geometry.track_length, true)
	
	# Create inner boundary using multiple convex segments
	var inner_radius := track_geometry.curve_radius - track_geometry.track_width / 2.0 - boundary_thickness
	var track_inner_radius := track_geometry.curve_radius - track_geometry.track_width / 2.0
	_create_segmented_boundary(inner_boundary_body, inner_radius, track_inner_radius, track_geometry.track_length, false)


func _create_segmented_boundary(body: StaticBody2D, inner_radius: float, outer_radius: float, 
		straight_length: float, is_outer: bool) -> void:
	var segments := 16  # Number of segments for curves
	
	# Create top straight section
	var top_collision := CollisionPolygon2D.new()
	top_collision.polygon = _create_straight_segment(
		-straight_length / 2.0, straight_length / 2.0,
		inner_radius if is_outer else -outer_radius,
		outer_radius if is_outer else -inner_radius
	)
	body.add_child(top_collision)
	
	# Create bottom straight section
	var bottom_collision := CollisionPolygon2D.new()
	bottom_collision.polygon = _create_straight_segment(
		straight_length / 2.0, -straight_length / 2.0,
		inner_radius if not is_outer else -outer_radius,
		outer_radius if not is_outer else -inner_radius
	)
	body.add_child(bottom_collision)
	
	# Create right curve segments
	for i in range(segments / 2):
		var start_angle := -PI / 2.0 + i * PI / (segments / 2)
		var end_angle := -PI / 2.0 + (i + 1) * PI / (segments / 2)
		
		var collision := CollisionPolygon2D.new()
		collision.polygon = _create_curve_segment(
			straight_length / 2.0, 0.0,
			inner_radius, outer_radius,
			start_angle, end_angle,
			is_outer
		)
		body.add_child(collision)
	
	# Create left curve segments
	for i in range(segments / 2):
		var start_angle := PI / 2.0 + i * PI / (segments / 2)
		var end_angle := PI / 2.0 + (i + 1) * PI / (segments / 2)
		
		var collision := CollisionPolygon2D.new()
		collision.polygon = _create_curve_segment(
			-straight_length / 2.0, 0.0,
			inner_radius, outer_radius,
			start_angle, end_angle,
			is_outer
		)
		body.add_child(collision)


func _create_straight_segment(x1: float, x2: float, y1: float, y2: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	points.append(Vector2(x1, y1))
	points.append(Vector2(x2, y1))
	points.append(Vector2(x2, y2))
	points.append(Vector2(x1, y2))
	return points


func _create_curve_segment(center_x: float, center_y: float, inner_radius: float, 
		outer_radius: float, start_angle: float, end_angle: float, is_outer: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := 8
	
	# Add inner arc points
	for i in range(steps + 1):
		var angle := start_angle + i * (end_angle - start_angle) / steps
		var x := center_x + inner_radius * cos(angle)
		var y := center_y + inner_radius * sin(angle)
		points.append(Vector2(x, y))
	
	# Add outer arc points in reverse order
	for i in range(steps, -1, -1):
		var angle := start_angle + i * (end_angle - start_angle) / steps
		var x := center_x + outer_radius * cos(angle)
		var y := center_y + outer_radius * sin(angle)
		points.append(Vector2(x, y))
	
	return points