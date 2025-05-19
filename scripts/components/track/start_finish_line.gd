# Start/finish line marker component
extends Area2D
class_name StartFinishLine

@export var line_width := 50.0
@export var line_height := 10.0
@export var stripe_count := 10
@export var primary_color := Color.WHITE
@export var secondary_color := Color.BLACK

signal lap_completed(lap_time: float)

var lap_start_time := 0.0
var is_active := false


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var stripe_width := line_width / stripe_count
	
	for i in range(stripe_count):
		var color := primary_color if i % 2 == 0 else secondary_color
		var rect := Rect2(
			i * stripe_width - line_width / 2.0,
			-line_height / 2.0,
			stripe_width,
			line_height
		)
		draw_rect(rect, color)


func start_timing() -> void:
	"""Start timing a lap"""
	lap_start_time = Time.get_ticks_msec() / 1000.0
	is_active = true


func finish_timing() -> float:
	"""Finish timing and return lap time"""
	if not is_active:
		return 0.0
	
	var lap_time := (Time.get_ticks_msec() / 1000.0) - lap_start_time
	is_active = false
	lap_completed.emit(lap_time)
	return lap_time


func _on_body_entered(body: Node2D) -> void:
	"""Handle vehicle crossing the line"""
	if body.has_method("is_vehicle") and body.is_vehicle():
		if is_active:
			finish_timing()
		else:
			start_timing()