# Beat marker component for visualizing beats along the track
extends Node2D
class_name BeatMarker

@export var marker_size := 20.0
@export var marker_color := Color(1.0, 0.5, 0.0, 0.8)  # Orange
@export var accent_color := Color(1.0, 0.8, 0.0, 1.0)  # Yellow for measure starts
@export var is_measure_start := false
@export var beat_number := 0
@export_range(0.0, 1.0) var activation_threshold := 0.1

var is_active := false
var activation_timer := 0.0


func _ready() -> void:
	if BeatManager:
		BeatManager.beat_occurred.connect(_on_beat_occurred)
	queue_redraw()


func _process(delta: float) -> void:
	if is_active and activation_timer > 0.0:
		activation_timer -= delta
		if activation_timer <= 0.0:
			is_active = false
			queue_redraw()


func _draw() -> void:
	var current_color := accent_color if is_measure_start else marker_color
	var current_size := marker_size * 1.5 if is_measure_start else marker_size
	
	if is_active:
		current_size *= 1.3
		current_color.a = 1.0
	
	# Draw marker shape
	if is_measure_start:
		# Draw a diamond for measure starts
		var points := PackedVector2Array([
			Vector2(0, -current_size),
			Vector2(current_size, 0),
			Vector2(0, current_size),
			Vector2(-current_size, 0)
		])
		draw_colored_polygon(points, current_color)
	else:
		# Draw a circle for regular beats
		draw_circle(Vector2.ZERO, current_size / 2.0, current_color)
	
	# Draw beat number if it's a measure start
	if is_measure_start:
		var font := ThemeDB.fallback_font
		var text := str(beat_number / 4 + 1)  # Measure number
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
		draw_string(font, Vector2(-text_size.x / 2, text_size.y / 2), text, 
			HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)


func _on_beat_occurred(beat_count: int, _measure_count: int, 
		_beat_in_measure: int, _time_to_next_beat: float) -> void:
	"""Activate marker on matching beat"""
	if beat_count % 16 == beat_number:  # Assuming 16 beats per track loop
		activate()


func activate() -> void:
	"""Visually activate the marker"""
	is_active = true
	activation_timer = activation_threshold
	queue_redraw()


func get_track_position() -> float:
	"""Get the position along the track (0.0 to 1.0)"""
	return beat_number / 16.0  # Assuming 16 beats per lap