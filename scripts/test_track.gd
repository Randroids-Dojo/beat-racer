extends Node2D

func _ready():
	print("Test track loaded")
	queue_redraw()

func _draw():
	print("Drawing test track")
	# Draw a simple circle to test
	draw_circle(Vector2(0, 0), 100, Color.RED)
	# Draw a rectangle
	draw_rect(Rect2(-200, -200, 400, 400), Color.GREEN, false, 5.0)
	print("Test drawing complete")