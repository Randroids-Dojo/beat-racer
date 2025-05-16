extends Node2D

const TRACK_WIDTH = 360
const LANE_WIDTH = 120
const TRACK_RADIUS_X = 400
const TRACK_RADIUS_Y = 300
const SEGMENTS = 64

const COLOR_BACKGROUND = Color("#1A1A2E")
const COLOR_LEFT_LANE = Color("#4ECDC4")
const COLOR_RIGHT_LANE = Color("#FFD460")
const COLOR_CENTER_LANE = Color("#777777")
const COLOR_RACE_RED = Color("#E94560")
const COLOR_LANE_DIVIDER = Color.WHITE
const COLOR_TRACK = Color("#2A2A3E")

func _ready():
	setup_track()
	create_track_shapes()
	draw_start_finish_line()

func setup_track():
	$Background.color = COLOR_BACKGROUND

func create_track_shapes():
	# Create the track using polygon nodes
	create_track_base()
	create_lanes()
	create_lane_dividers()

func create_track_base():
	# Create outer track shape
	var track_shape = Polygon2D.new()
	track_shape.name = "TrackShape"
	track_shape.color = COLOR_TRACK
	
	var outer_points = []
	var inner_points = []
	
	for i in range(SEGMENTS + 1):
		var angle = 2 * PI * i / SEGMENTS
		outer_points.append(Vector2(cos(angle) * (TRACK_RADIUS_X + TRACK_WIDTH/2), 
			sin(angle) * (TRACK_RADIUS_Y + TRACK_WIDTH/2)))
		inner_points.append(Vector2(cos(angle) * (TRACK_RADIUS_X - TRACK_WIDTH/2), 
			sin(angle) * (TRACK_RADIUS_Y - TRACK_WIDTH/2)))
	
	inner_points.reverse()
	track_shape.polygon = PackedVector2Array(outer_points + inner_points)
	add_child(track_shape)

func create_lanes():
	# Create colored lane indicators
	var lane_container = Node2D.new()
	lane_container.name = "Lanes"
	add_child(lane_container)
	
	var num_dots = 48
	for i in range(num_dots):
		var angle = 2 * PI * i / num_dots
		
		# Left lane dots
		var left_dot = create_lane_dot(COLOR_LEFT_LANE)
		left_dot.position = Vector2(cos(angle) * (TRACK_RADIUS_X - LANE_WIDTH), 
			sin(angle) * (TRACK_RADIUS_Y - LANE_WIDTH))
		lane_container.add_child(left_dot)
		
		# Center lane dots
		var center_dot = create_lane_dot(COLOR_CENTER_LANE)
		center_dot.position = Vector2(cos(angle) * TRACK_RADIUS_X, 
			sin(angle) * TRACK_RADIUS_Y)
		lane_container.add_child(center_dot)
		
		# Right lane dots
		var right_dot = create_lane_dot(COLOR_RIGHT_LANE)
		right_dot.position = Vector2(cos(angle) * (TRACK_RADIUS_X + LANE_WIDTH), 
			sin(angle) * (TRACK_RADIUS_Y + LANE_WIDTH))
		lane_container.add_child(right_dot)

func create_lane_dot(color: Color) -> ColorRect:
	var dot = ColorRect.new()
	dot.size = Vector2(40, 40)
	dot.position = -dot.size / 2
	dot.color = color
	return dot

func create_lane_dividers():
	# Create dashed line effect using small ColorRects
	var divider_container = Node2D.new()
	divider_container.name = "LaneDividers"
	add_child(divider_container)
	
	var dash_count = 32
	for i in range(dash_count):
		if i % 2 == 0:  # Only create every other segment
			var angle1 = 2 * PI * i / dash_count
			var angle2 = 2 * PI * (i + 1) / dash_count
			
			# Left-center divider
			var left_dash = create_divider_dash()
			var left_pos = Vector2(cos((angle1 + angle2) / 2) * (TRACK_RADIUS_X - LANE_WIDTH/2), 
				sin((angle1 + angle2) / 2) * (TRACK_RADIUS_Y - LANE_WIDTH/2))
			left_dash.position = left_pos
			left_dash.rotation = (angle1 + angle2) / 2
			divider_container.add_child(left_dash)
			
			# Center-right divider
			var right_dash = create_divider_dash()
			var right_pos = Vector2(cos((angle1 + angle2) / 2) * (TRACK_RADIUS_X + LANE_WIDTH/2), 
				sin((angle1 + angle2) / 2) * (TRACK_RADIUS_Y + LANE_WIDTH/2))
			right_dash.position = right_pos
			right_dash.rotation = (angle1 + angle2) / 2
			divider_container.add_child(right_dash)

func create_divider_dash() -> ColorRect:
	var dash = ColorRect.new()
	dash.size = Vector2(40, 4)
	dash.position = Vector2(-20, -2)
	dash.color = COLOR_LANE_DIVIDER
	return dash

func draw_start_finish_line():
	$StartFinishLine.position = Vector2(TRACK_RADIUS_X, 0)
	$StartFinishLine.clear_points()
	$StartFinishLine.add_point(Vector2(0, -TRACK_WIDTH/2 + 10))
	$StartFinishLine.add_point(Vector2(0, TRACK_WIDTH/2 - 10))
	$StartFinishLine.width = 20
	$StartFinishLine.default_color = COLOR_RACE_RED