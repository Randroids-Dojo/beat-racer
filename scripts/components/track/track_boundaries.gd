# Track boundaries component for collision detection
extends Node2D
class_name TrackBoundaries

@export var track_geometry: TrackGeometry
@export var boundary_thickness := 50.0

var outer_boundary_body: StaticBody2D
var inner_boundary_body: StaticBody2D
var outer_collision_polygon: CollisionPolygon2D
var inner_collision_polygon: CollisionPolygon2D


func _ready() -> void:
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
	
	outer_collision_polygon = CollisionPolygon2D.new()
	outer_boundary_body.add_child(outer_collision_polygon)
	
	# Create inner boundary
	inner_boundary_body = StaticBody2D.new()
	inner_boundary_body.name = "InnerBoundary"
	add_child(inner_boundary_body)
	
	inner_collision_polygon = CollisionPolygon2D.new()
	inner_boundary_body.add_child(inner_collision_polygon)


func _update_collision_shapes() -> void:
	if not track_geometry or not outer_collision_polygon or not inner_collision_polygon:
		return
	
	# Generate outer boundary polygon
	var outer_radius := track_geometry.curve_radius + track_geometry.track_width / 2.0 + boundary_thickness
	var outer_points := _generate_oval_boundary(outer_radius, track_geometry.track_length)
	
	# Generate inner boundary polygon
	var inner_radius := track_geometry.curve_radius - track_geometry.track_width / 2.0 - boundary_thickness
	var inner_points := _generate_oval_boundary(inner_radius, track_geometry.track_length)
	
	# Create outer boundary collision shape (wall outside the track)
	var outer_wall_points := _create_wall_polygon(
		_generate_oval_boundary(
			track_geometry.curve_radius + track_geometry.track_width / 2.0,
			track_geometry.track_length
		),
		outer_points,
		true
	)
	outer_collision_polygon.polygon = outer_wall_points
	
	# Create inner boundary collision shape (wall inside the track)
	var inner_wall_points := _create_wall_polygon(
		inner_points,
		_generate_oval_boundary(
			track_geometry.curve_radius - track_geometry.track_width / 2.0,
			track_geometry.track_length
		),
		false
	)
	inner_collision_polygon.polygon = inner_wall_points


func _generate_oval_boundary(radius: float, straight_length: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var segments := 32  # Number of segments for curves
	
	# Top straight section
	for i in range(6):
		var x := -straight_length / 2.0 + i * straight_length / 5.0
		points.append(Vector2(x, -radius))
	
	# Right curve
	for i in range(segments / 2 + 1):
		var angle := -PI / 2.0 + i * PI / (segments / 2)
		var x := straight_length / 2.0 + radius * cos(angle)
		var y := radius * sin(angle)
		points.append(Vector2(x, y))
	
	# Bottom straight section
	for i in range(6):
		var x := straight_length / 2.0 - i * straight_length / 5.0
		points.append(Vector2(x, radius))
	
	# Left curve
	for i in range(segments / 2 + 1):
		var angle := PI / 2.0 + i * PI / (segments / 2)
		var x := -straight_length / 2.0 + radius * cos(angle)
		var y := radius * sin(angle)
		points.append(Vector2(x, y))
	
	return points


func _create_wall_polygon(inner_edge: PackedVector2Array, outer_edge: PackedVector2Array, 
		is_outer_wall: bool) -> PackedVector2Array:
	var wall_points := PackedVector2Array()
	
	if is_outer_wall:
		# For outer wall: track edge -> outer boundary -> reverse
		wall_points.append_array(inner_edge)
		wall_points.append_array(outer_edge)
		# Close the polygon
		wall_points.append(inner_edge[0])
	else:
		# For inner wall: inner boundary -> track edge -> reverse
		wall_points.append_array(inner_edge)
		for i in range(outer_edge.size() - 1, -1, -1):
			wall_points.append(outer_edge[i])
		# Close the polygon
		wall_points.append(inner_edge[0])
	
	return wall_points