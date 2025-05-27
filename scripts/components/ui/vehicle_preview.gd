extends Panel

# Vehicle Preview
# Simple visual preview for vehicle selection

var vehicle_type: int = 0
var vehicle_color: Color = Color.WHITE

func _draw():
	var size = get_size()
	var center = size / 2
	
	# Draw vehicle based on type
	match vehicle_type:
		0:  # Standard
			_draw_standard_vehicle(center)
		1:  # Drift
			_draw_drift_vehicle(center)
		2:  # Speed
			_draw_speed_vehicle(center)
		3:  # Heavy
			_draw_heavy_vehicle(center)


func _draw_standard_vehicle(center: Vector2):
	"""Draw standard vehicle shape"""
	# Body
	var body_rect = Rect2(center.x - 20, center.y - 10, 40, 20)
	draw_rect(body_rect, vehicle_color)
	
	# Windshield
	var windshield_rect = Rect2(center.x - 10, center.y - 6, 20, 12)
	draw_rect(windshield_rect, vehicle_color.darkened(0.3))
	
	# Wheels
	draw_rect(Rect2(center.x - 18, center.y - 12, 6, 4), vehicle_color.darkened(0.5))
	draw_rect(Rect2(center.x + 12, center.y - 12, 6, 4), vehicle_color.darkened(0.5))
	draw_rect(Rect2(center.x - 18, center.y + 8, 6, 4), vehicle_color.darkened(0.5))
	draw_rect(Rect2(center.x + 12, center.y + 8, 6, 4), vehicle_color.darkened(0.5))


func _draw_drift_vehicle(center: Vector2):
	"""Draw drift vehicle with angled design"""
	# Angled body
	var points = PackedVector2Array([
		center + Vector2(-22, -8),
		center + Vector2(18, -10),
		center + Vector2(22, 10),
		center + Vector2(-18, 8)
	])
	draw_polygon(points, PackedColorArray([vehicle_color]))
	
	# Windshield
	var windshield_points = PackedVector2Array([
		center + Vector2(-10, -5),
		center + Vector2(8, -6),
		center + Vector2(10, 6),
		center + Vector2(-8, 5)
	])
	draw_polygon(windshield_points, PackedColorArray([vehicle_color.darkened(0.3)]))
	
	# Spoiler
	draw_rect(Rect2(center.x - 15, center.y + 10, 30, 3), vehicle_color.lightened(0.2))


func _draw_speed_vehicle(center: Vector2):
	"""Draw speed vehicle with streamlined design"""
	# Streamlined body
	var points = PackedVector2Array([
		center + Vector2(-15, -8),
		center + Vector2(25, -5),
		center + Vector2(25, 5),
		center + Vector2(-15, 8)
	])
	draw_polygon(points, PackedColorArray([vehicle_color]))
	
	# Windshield
	var windshield_points = PackedVector2Array([
		center + Vector2(-5, -5),
		center + Vector2(15, -3),
		center + Vector2(15, 3),
		center + Vector2(-5, 5)
	])
	draw_polygon(windshield_points, PackedColorArray([vehicle_color.darkened(0.3)]))
	
	# Speed lines
	draw_line(center + Vector2(-20, -3), center + Vector2(-25, -3), vehicle_color.lightened(0.3), 2)
	draw_line(center + Vector2(-20, 0), center + Vector2(-27, 0), vehicle_color.lightened(0.3), 2)
	draw_line(center + Vector2(-20, 3), center + Vector2(-25, 3), vehicle_color.lightened(0.3), 2)


func _draw_heavy_vehicle(center: Vector2):
	"""Draw heavy vehicle with bulky design"""
	# Bulky body
	var body_rect = Rect2(center.x - 22, center.y - 12, 44, 24)
	draw_rect(body_rect, vehicle_color)
	
	# Reinforced frame
	draw_rect(Rect2(center.x - 20, center.y - 10, 40, 20), vehicle_color.lightened(0.1), false, 2)
	
	# Small windshield
	var windshield_rect = Rect2(center.x - 8, center.y - 5, 16, 10)
	draw_rect(windshield_rect, vehicle_color.darkened(0.3))
	
	# Heavy wheels
	draw_rect(Rect2(center.x - 20, center.y - 14, 8, 5), vehicle_color.darkened(0.5))
	draw_rect(Rect2(center.x + 12, center.y - 14, 8, 5), vehicle_color.darkened(0.5))
	draw_rect(Rect2(center.x - 20, center.y + 9, 8, 5), vehicle_color.darkened(0.5))
	draw_rect(Rect2(center.x + 12, center.y + 9, 8, 5), vehicle_color.darkened(0.5))


func set_vehicle_type(type: int):
	"""Set the vehicle type to preview"""
	vehicle_type = type
	queue_redraw()


func set_vehicle_color(color: Color):
	"""Set the vehicle color"""
	vehicle_color = color
	queue_redraw()