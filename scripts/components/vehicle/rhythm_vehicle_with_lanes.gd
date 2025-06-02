# Extended vehicle class with lane detection integration
extends Vehicle
class_name RhythmVehicleWithLanes

@export var lane_detection_system: LaneDetectionSystem
@export var enable_lane_centering := true
@export var centering_force := 0.5  # How strongly to center in lane
@export var lane_change_speed := 2.0  # How quickly to change lanes

signal entered_lane(lane_index: int)
signal exited_lane(lane_index: int)
signal lane_centered(lane_index: int)

var current_lane := 1  # Starting lane (middle)
var target_lane := 1  # Lane we're trying to reach
var is_changing_lanes := false


func _ready() -> void:
	super._ready()
	
	if lane_detection_system:
		lane_detection_system.lane_changed.connect(_on_lane_changed)
		lane_detection_system.entered_lane_center.connect(_on_entered_lane_center)
		lane_detection_system.exited_lane_center.connect(_on_exited_lane_center)


func _physics_process(delta: float) -> void:
	if lane_detection_system:
		var detected_lane := lane_detection_system.detect_lane_position(global_position)
		current_lane = detected_lane
	
	# Apply lane centering if enabled
	if enable_lane_centering and not is_changing_lanes:
		apply_lane_centering(delta)
	
	super._physics_process(delta)


func apply_lane_centering(delta: float) -> void:
	"""Apply subtle force to keep vehicle centered in lane"""
	if not lane_detection_system:
		return
	
	var lane_info: Dictionary = lane_detection_system.get_lane_info()
	var offset: float = lane_info.get("offset_from_center", 0.0)
	
	# Only apply centering if we're moving and not perfectly centered
	if abs(current_speed) > 10.0 and abs(offset) > 1.0:
		var boundaries: Dictionary = lane_detection_system.get_lane_boundaries(global_position)
		if boundaries.has("center") and boundaries.has("normal"):
			var center_local := to_local(boundaries.center)
			var direction_to_center := center_local.normalized()
			
			# Apply a perpendicular force towards the lane center
			var centering_velocity: Vector2 = direction_to_center * offset * centering_force
			velocity += centering_velocity * delta


func change_lane(direction: int) -> void:
	"""Initiate a lane change (-1 for left, 1 for right)"""
	if not lane_detection_system:
		return
	
	var new_target_lane := current_lane + direction
	var lane_count := lane_detection_system.track_geometry.lane_count
	
	# Clamp to valid lanes
	new_target_lane = clamp(new_target_lane, 0, lane_count - 1)
	
	if new_target_lane != current_lane:
		target_lane = new_target_lane
		is_changing_lanes = true


func _on_lane_changed(previous_lane: int, new_lane: int) -> void:
	current_lane = new_lane
	exited_lane.emit(previous_lane)
	entered_lane.emit(new_lane)
	
	# Check if we've reached our target lane
	if new_lane == target_lane:
		is_changing_lanes = false


func _on_entered_lane_center(lane: int) -> void:
	lane_centered.emit(lane)


func _on_exited_lane_center(_lane: int) -> void:
	pass


func get_lane_position() -> Dictionary:
	"""Get current lane position information"""
	if lane_detection_system:
		return lane_detection_system.get_lane_info()
	else:
		return {
			"current_lane": current_lane,
			"offset_from_center": 0.0,
			"is_centered": false,
			"lane_count": 3,
			"transition_progress": 0.0
		}