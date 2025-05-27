extends Node2D

# Simple marker for visualizing sample points

var color: Color = Color(1.0, 0.0, 0.0, 0.5)
var radius: float = 3.0

func _ready():
	queue_redraw()

func _draw():
	draw_circle(Vector2.ZERO, radius, color)