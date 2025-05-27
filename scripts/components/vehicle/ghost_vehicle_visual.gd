extends Sprite2D

# Ghost Vehicle Visual
# Custom drawing for playback ghost vehicles

func _draw():
	# Draw a simple car shape
	var car_color = modulate
	car_color.a = 1.0  # Full alpha for drawing, modulate handles transparency
	
	# Car body
	draw_rect(Rect2(-15, -10, 30, 20), car_color)
	
	# Windshield
	var windshield_color = car_color
	windshield_color = windshield_color.darkened(0.3)
	draw_rect(Rect2(-8, -6, 16, 8), windshield_color)
	
	# Direction indicator (front)
	draw_circle(Vector2(12, 0), 3, car_color.lightened(0.3))
	
	# Wheels
	var wheel_color = car_color.darkened(0.5)
	draw_rect(Rect2(-15, -12, 6, 4), wheel_color)
	draw_rect(Rect2(9, -12, 6, 4), wheel_color)
	draw_rect(Rect2(-15, 8, 6, 4), wheel_color)
	draw_rect(Rect2(9, 8, 6, 4), wheel_color)