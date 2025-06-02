# Lane detection test scene controller
extends Node2D

@onready var vehicle := $RhythmVehicleWithLanes
@onready var track_system := $TrackSystem
@onready var lane_detection := $LaneDetectionSystem
@onready var visual_feedback := $LaneVisualFeedback
@onready var camera := $Camera2D
@onready var info_label := $UI/InfoLabel


func _ready() -> void:
	# Setup references
	lane_detection.track_geometry = track_system.track_geometry
	vehicle.lane_detection_system = lane_detection
	visual_feedback.lane_detection_system = lane_detection
	visual_feedback.vehicle = vehicle
	
	# Position vehicle at start
	var start_pos: Vector2 = track_system.track_geometry.get_lane_center_position(1, 0.0)
	vehicle.reset_position(start_pos, 0.0)
	
	# Setup camera to follow vehicle
	camera.position = vehicle.position
	
	# Connect signals
	vehicle.entered_lane.connect(_on_vehicle_entered_lane)
	vehicle.lane_centered.connect(_on_vehicle_lane_centered)
	lane_detection.lane_position_updated.connect(_on_lane_position_updated)


func _process(_delta: float) -> void:
	# Update camera to follow vehicle
	camera.position = vehicle.position
	
	# Handle input
	if Input.is_key_pressed(KEY_SPACE):  # Space bar
		visual_feedback.show_debug_overlay = not visual_feedback.show_debug_overlay
	
	if Input.is_key_pressed(KEY_R):  # R key
		var start_pos: Vector2 = track_system.track_geometry.get_lane_center_position(1, 0.0)
		vehicle.reset_position(start_pos, 0.0)
	
	# Manual lane changes for testing
	if Input.is_key_pressed(KEY_Q):  # Q key
		if vehicle.has_method("change_lane"):
			vehicle.change_lane(-1)  # Left
	if Input.is_key_pressed(KEY_E):  # E key
		if vehicle.has_method("change_lane"):
			vehicle.change_lane(1)   # Right
	
	# Update info display
	_update_info_display()


func _update_info_display() -> void:
	var lane_info: Dictionary = vehicle.get_lane_position()
	var speed_pct: float = vehicle.get_speed_percentage() * 100.0
	
	info_label.text = "[b]Lane Detection Test[/b]\n"
	info_label.text += "Current Lane: %d\n" % lane_info.current_lane
	info_label.text += "Offset from Center: %.1f\n" % lane_info.offset_from_center
	info_label.text += "Is Centered: %s\n" % str(lane_info.is_centered)
	info_label.text += "Speed: %.0f%%\n\n" % speed_pct
	info_label.text += "[b]Controls:[/b]\n"
	info_label.text += "Arrow Keys: Drive\n"
	info_label.text += "Q/E: Change lanes manually\n"
	info_label.text += "Space: Toggle debug overlay\n"
	info_label.text += "R: Reset position"


func _on_vehicle_entered_lane(_lane_index: int) -> void:
	# Vehicle entered a new lane
	pass


func _on_vehicle_lane_centered(_lane_index: int) -> void:
	# Vehicle is now centered in its lane
	pass


func _on_lane_position_updated(_lane: int, _offset_from_center: float) -> void:
	# Could add visual or audio feedback here
	pass


func _exit_tree() -> void:
	# Disconnect all signals to prevent orphaned connections
	if vehicle and vehicle.entered_lane.is_connected(_on_vehicle_entered_lane):
		vehicle.entered_lane.disconnect(_on_vehicle_entered_lane)
	if vehicle and vehicle.lane_centered.is_connected(_on_vehicle_lane_centered):
		vehicle.lane_centered.disconnect(_on_vehicle_lane_centered)
	if lane_detection and lane_detection.lane_position_updated.is_connected(_on_lane_position_updated):
		lane_detection.lane_position_updated.disconnect(_on_lane_position_updated)
	
	# Clear references
	vehicle = null
	track_system = null
	lane_detection = null
	visual_feedback = null
	camera = null
	info_label = null