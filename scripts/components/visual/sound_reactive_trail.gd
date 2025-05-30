extends Line2D
class_name SoundReactiveTrail

# Sound Reactive Trail
# Creates a light trail behind vehicles that reacts to sound/music
# Color, width, and intensity change based on audio properties

signal trail_updated(point_count: int)

@export_group("Trail Properties")
@export var max_points: int = 50
@export var point_lifetime: float = 1.0
@export var base_width: float = 20.0
@export var max_width: float = 40.0
@export var min_width: float = 5.0
@export var update_distance: float = 5.0  # Minimum distance before adding new point

@export_group("Sound Reaction")
@export var react_to_beat: bool = true
@export var react_to_volume: bool = true
@export var react_to_lane_change: bool = true
@export var beat_pulse_multiplier: float = 2.0
@export var volume_influence: float = 0.5

@export_group("Visual Style")
@export var base_color: Color = Color(0.5, 0.8, 1.0, 0.8)
@export var beat_color: Color = Color(1.0, 0.8, 0.2, 1.0)
@export var gradient_enabled: bool = true
@export var use_lane_colors: bool = true
@export var glow_enabled: bool = true
@export var glow_amount: float = 2.0

@export_group("Lane Colors")
@export var left_lane_color: Color = Color(1.0, 0.3, 0.3, 0.8)
@export var center_lane_color: Color = Color(0.3, 1.0, 0.3, 0.8)
@export var right_lane_color: Color = Color(0.3, 0.3, 1.0, 0.8)

# Trail point data
class TrailPoint:
	var position: Vector2
	var timestamp: float
	var lane: int = -1
	var intensity: float = 1.0
	var beat_aligned: bool = false

# Internal state
var trail_points: Array[TrailPoint] = []
var last_position: Vector2
var current_lane: int = -1
var current_intensity: float = 1.0
var beat_pulse_timer: float = 0.0
var beat_pulse_active: bool = false
var volume_level: float = 0.0

# References
var beat_manager: Node = null
var lane_audio_controller: LaneAudioController = null
var vehicle: Node2D = null

# Debug
var _debug_logging: bool = false


func _ready():
	_log("=== SoundReactiveTrail Initialization ===")
	
	# Setup Line2D properties
	width = base_width
	default_color = base_color
	joint_mode = Line2D.LINE_JOINT_ROUND
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND
	antialiased = true
	
	# Setup gradient if enabled
	if gradient_enabled:
		gradient = Gradient.new()
		gradient.add_point(0.0, Color(base_color.r, base_color.g, base_color.b, 0.0))
		gradient.add_point(1.0, base_color)
	
	# Find references
	_find_references()
	_connect_signals()
	
	# Get parent vehicle
	vehicle = get_parent() if get_parent() is Node2D else null
	
	_log("SoundReactiveTrail ready")
	_log("========================================")


func _log(message: String) -> void:
	if _debug_logging:
		var timestamp = Time.get_time_string_from_system()
		print("[%s] SoundReactiveTrail: %s" % [timestamp, message])


func _find_references():
	"""Find required system references"""
	# Get BeatManager
	beat_manager = get_node("/root/BeatManager") if has_node("/root/BeatManager") else null
	
	# Find LaneAudioController
	var controllers = get_tree().get_nodes_in_group("lane_audio_controller")
	if controllers.size() > 0:
		lane_audio_controller = controllers[0]


func _connect_signals():
	"""Connect to system signals"""
	if beat_manager and react_to_beat:
		beat_manager.beat_occurred.connect(_on_beat_occurred)
		_log("Connected to BeatManager")
	
	if lane_audio_controller:
		if lane_audio_controller.has_signal("lane_volume_changed"):
			lane_audio_controller.lane_volume_changed.connect(_on_lane_volume_changed)
		_log("Connected to LaneAudioController")


func _on_beat_occurred(beat_number: int, beat_time: float):
	"""Handle beat event"""
	if react_to_beat:
		beat_pulse_active = true
		beat_pulse_timer = 0.0
		
		# Mark current position as beat-aligned
		if trail_points.size() > 0:
			trail_points[-1].beat_aligned = true


func _on_lane_volume_changed(lane: int, volume: float):
	"""Handle lane volume change"""
	if react_to_volume and lane == current_lane:
		volume_level = volume


func _process(delta: float):
	"""Update trail"""
	# Update beat pulse
	if beat_pulse_active:
		beat_pulse_timer += delta
		if beat_pulse_timer > 0.2:  # Pulse duration
			beat_pulse_active = false
	
	# Update trail points
	_update_trail_points(delta)
	
	# Update trail appearance
	_update_trail_appearance()
	
	# Add new points based on vehicle movement
	if vehicle:
		_check_add_new_point()


func _update_trail_points(delta: float):
	"""Update trail point lifetimes and remove old points"""
	var current_time = Time.get_ticks_msec() / 1000.0
	var points_to_remove = []
	
	for i in trail_points.size():
		var point = trail_points[i]
		var age = current_time - point.timestamp
		
		if age > point_lifetime:
			points_to_remove.append(i)
	
	# Remove old points (in reverse order)
	for i in range(points_to_remove.size() - 1, -1, -1):
		trail_points.remove_at(points_to_remove[i])
	
	# Limit maximum points
	while trail_points.size() > max_points:
		trail_points.pop_front()


func _check_add_new_point():
	"""Check if we should add a new trail point"""
	var current_pos = vehicle.global_position
	
	# Check distance from last point
	if last_position == Vector2.ZERO or current_pos.distance_to(last_position) >= update_distance:
		add_trail_point(current_pos, current_lane, current_intensity)
		last_position = current_pos


func add_trail_point(position: Vector2, lane: int = -1, intensity: float = 1.0):
	"""Add a new point to the trail"""
	var point = TrailPoint.new()
	point.position = position
	point.timestamp = Time.get_ticks_msec() / 1000.0
	point.lane = lane
	point.intensity = intensity
	
	trail_points.append(point)
	
	# Update Line2D points
	_update_line_points()
	
	emit_signal("trail_updated", trail_points.size())


func _update_line_points():
	"""Update Line2D points from trail data"""
	clear_points()
	
	for point in trail_points:
		add_point(to_local(point.position))


func _update_trail_appearance():
	"""Update trail visual properties based on sound"""
	var target_width = base_width
	var target_color = base_color
	
	# Apply beat pulse
	if beat_pulse_active and react_to_beat:
		var pulse_progress = 1.0 - (beat_pulse_timer / 0.2)
		target_width *= 1.0 + (beat_pulse_multiplier - 1.0) * pulse_progress
		target_color = base_color.lerp(beat_color, pulse_progress * 0.5)
	
	# Apply volume influence
	if react_to_volume:
		var volume_factor = 1.0 + volume_level * volume_influence
		target_width *= volume_factor
	
	# Apply lane color
	if use_lane_colors and current_lane >= 0:
		var lane_color = _get_lane_color(current_lane)
		target_color = target_color.lerp(lane_color, 0.7)
	
	# Clamp width
	target_width = clamp(target_width, min_width, max_width)
	
	# Smooth transitions
	width = lerp(width, target_width, 0.1)
	
	# Update color or gradient
	if gradient_enabled and gradient:
		# Update gradient colors
		for i in gradient.get_point_count():
			var color = target_color
			color.a *= gradient.get_color(i).a  # Preserve alpha gradient
			gradient.set_color(i, color)
	else:
		default_color = target_color
	
	# Apply glow effect
	if glow_enabled:
		material = _create_glow_material(target_color)


func _get_lane_color(lane: int) -> Color:
	"""Get color for a specific lane"""
	match lane:
		0:
			return left_lane_color
		1:
			return center_lane_color
		2:
			return right_lane_color
		_:
			return base_color


func _create_glow_material(color: Color) -> Material:
	"""Create a glow material for the trail"""
	if not material or not material is CanvasItemMaterial:
		material = CanvasItemMaterial.new()
	
	var mat = material as CanvasItemMaterial
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	
	# Could enhance with shaders for better glow
	return mat


func set_current_lane(lane: int):
	"""Set the current lane for color reactions"""
	if current_lane != lane and react_to_lane_change:
		current_lane = lane
		
		# Create a visual burst on lane change
		if trail_points.size() > 0:
			trail_points[-1].intensity = 1.5


func set_sound_intensity(intensity: float):
	"""Set the current sound intensity"""
	current_intensity = clamp(intensity, 0.0, 2.0)


func clear_trail():
	"""Clear all trail points"""
	trail_points.clear()
	clear_points()
	last_position = Vector2.ZERO


func set_debug_logging(enabled: bool):
	"""Enable/disable debug logging"""
	_debug_logging = enabled


func get_trail_length() -> int:
	"""Get current number of trail points"""
	return trail_points.size()


func get_oldest_point_age() -> float:
	"""Get age of oldest trail point"""
	if trail_points.is_empty():
		return 0.0
	
	var current_time = Time.get_ticks_msec() / 1000.0
	return current_time - trail_points[0].timestamp