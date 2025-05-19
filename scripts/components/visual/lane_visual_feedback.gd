# Visual feedback system for lane detection
extends Node2D
class_name LaneVisualFeedback

@export var lane_detection_system: LaneDetectionSystem
@export var vehicle: Vehicle
@export var show_debug_overlay := false

@export_group("Visual Settings")
@export var current_lane_color := Color(0.0, 1.0, 0.0, 0.5)  # Green
@export var transition_color := Color(1.0, 1.0, 0.0, 0.5)  # Yellow
@export var centered_color := Color(0.0, 0.5, 1.0, 0.8)  # Blue
@export var boundary_color := Color(1.0, 0.0, 0.0, 0.3)  # Red

@export_group("Indicators")
@export var show_lane_indicator := true
@export var indicator_size := 40.0
@export var indicator_offset := Vector2(0, -60)  # Above vehicle
@export var show_center_line := true
@export var center_line_length := 100.0

var current_lane_info := {}
var lane_boundaries := {}


func _ready() -> void:
	if lane_detection_system:
		lane_detection_system.lane_changed.connect(_on_lane_changed)
		lane_detection_system.lane_position_updated.connect(_on_lane_position_updated)
		lane_detection_system.entered_lane_center.connect(_on_entered_lane_center)
		lane_detection_system.exited_lane_center.connect(_on_exited_lane_center)


func _process(_delta: float) -> void:
	if not vehicle or not lane_detection_system:
		return
	
	current_lane_info = lane_detection_system.get_lane_info()
	lane_boundaries = lane_detection_system.get_lane_boundaries(vehicle.global_position)
	
	queue_redraw()


func _draw() -> void:
	if not vehicle or not lane_detection_system:
		return
	
	var vehicle_local := to_local(vehicle.global_position)
	
	# Draw debug overlay if enabled
	if show_debug_overlay:
		_draw_debug_overlay(vehicle_local)
	
	# Draw lane indicator
	if show_lane_indicator:
		_draw_lane_indicator(vehicle_local)
	
	# Draw center line guide
	if show_center_line and lane_boundaries.has("center"):
		_draw_center_line_guide(vehicle_local)


func _draw_debug_overlay(vehicle_pos: Vector2) -> void:
	# Draw lane boundaries
	if lane_boundaries.has("left_boundary") and lane_boundaries.has("right_boundary"):
		var left_local := to_local(lane_boundaries.left_boundary)
		var right_local := to_local(lane_boundaries.right_boundary)
		var center_local := to_local(lane_boundaries.center)
		
		# Draw boundary lines
		var tangent = lane_boundaries.get("tangent", Vector2.RIGHT)
		var line_extension = tangent * 200
		
		draw_line(left_local - line_extension, left_local + line_extension, 
				boundary_color, 3.0)
		draw_line(right_local - line_extension, right_local + line_extension, 
				boundary_color, 3.0)
		draw_line(center_local - line_extension, center_local + line_extension, 
				current_lane_color, 2.0)
		
		# Draw distance indicators
		var offset = current_lane_info.get("offset_from_center", 0.0)
		var text_pos = vehicle_pos + Vector2(0, -80)
		
		# Draw offset text background
		var text_bg_size = Vector2(150, 25)
		var text_bg_pos = text_pos - text_bg_size / 2
		draw_rect(Rect2(text_bg_pos, text_bg_size), Color(0, 0, 0, 0.7))
		
		# Draw the text using a label
		var label := Label.new()
		label.text = "Offset: %.1f" % offset
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 16)
		
		# This is a workaround - we'd normally use draw_string but Godot 4 requires a font
		# In a real implementation, you'd load a font resource
		draw_circle(text_pos, 3, Color.WHITE)  # Just draw a dot for now


func _draw_lane_indicator(vehicle_pos: Vector2) -> void:
	var indicator_pos = vehicle_pos + indicator_offset
	var lane_num = current_lane_info.get("current_lane", 0)
	var is_centered = current_lane_info.get("is_centered", false)
	
	# Choose color based on state
	var color = centered_color if is_centered else current_lane_color
	
	# Draw background circle
	draw_circle(indicator_pos, indicator_size / 2, Color(0, 0, 0, 0.7))
	
	# Draw lane indicator
	draw_circle(indicator_pos, indicator_size / 2 - 3, color)
	
	# Draw lane number (simple representation)
	var lane_markers_count = 3
	var marker_spacing = indicator_size / (lane_markers_count + 1)
	
	for i in range(lane_markers_count):
		var marker_pos = indicator_pos + Vector2(-indicator_size/2 + marker_spacing * (i + 1), 0)
		var marker_color = Color.WHITE if i == lane_num else Color(0.3, 0.3, 0.3)
		draw_circle(marker_pos, 4, marker_color)


func _draw_center_line_guide(vehicle_pos: Vector2) -> void:
	if not lane_boundaries.has("center"):
		return
	
	var center_local = to_local(lane_boundaries.center)
	var is_centered = current_lane_info.get("is_centered", false)
	var color = centered_color if is_centered else Color(1.0, 1.0, 1.0, 0.3)
	
	# Draw line from vehicle to lane center
	draw_line(vehicle_pos, center_local, color, 2.0)
	
	# Draw center point
	draw_circle(center_local, 5, color)


func _on_lane_changed(previous_lane: int, new_lane: int) -> void:
	# Could add animation or effects here
	pass


func _on_lane_position_updated(lane: int, offset_from_center: float) -> void:
	# Could update UI elements here
	pass


func _on_entered_lane_center(lane: int) -> void:
	# Could trigger visual effect
	pass


func _on_exited_lane_center(lane: int) -> void:
	# Could stop visual effect
	pass


func _exit_tree() -> void:
	# Disconnect signals
	if vehicle and vehicle.has_signal("entered_lane_center") and vehicle.entered_lane_center.is_connected(_on_entered_lane_center):
		vehicle.entered_lane_center.disconnect(_on_entered_lane_center)
	if vehicle and vehicle.has_signal("exited_lane_center") and vehicle.exited_lane_center.is_connected(_on_exited_lane_center):
		vehicle.exited_lane_center.disconnect(_on_exited_lane_center)
	
	# Clear references
	vehicle = null
	lane_detection_system = null
	
	# Force a final draw clear
	queue_redraw()