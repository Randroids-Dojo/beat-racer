extends Camera2D
class_name CameraController

## Dynamic camera that follows vehicles with smooth movement and speed-based zoom

signal camera_mode_changed(mode: CameraMode)
signal target_changed(new_target: Node2D)
signal transition_started()
signal transition_completed()

enum CameraMode {
	FOLLOW,       # Follow a specific vehicle
	OVERVIEW,     # Show entire track
	TRANSITION    # Transitioning between targets
}

## Current camera mode
var current_mode: CameraMode = CameraMode.FOLLOW:
	set(value):
		if current_mode != value:
			current_mode = value
			camera_mode_changed.emit(value)

## Target to follow in FOLLOW mode
var follow_target: Node2D:
	set(value):
		if follow_target != value:
			var old_target := follow_target
			follow_target = value
			if old_target and value:
				_start_transition(old_target, value)
			target_changed.emit(value)

## Camera configuration
@export_group("Follow Settings")
@export var follow_smoothing: float = 0.1  # Lower = smoother, higher = more responsive
@export var position_offset: Vector2 = Vector2.ZERO  # Offset from target
@export var look_ahead_factor: float = 0.3  # How much to look ahead based on velocity

@export_group("Zoom Settings")
@export var base_zoom: Vector2 = Vector2(1.0, 1.0)  # Default zoom level
@export var min_zoom: Vector2 = Vector2(0.5, 0.5)  # Maximum zoom in
@export var max_zoom: Vector2 = Vector2(2.0, 2.0)  # Maximum zoom out
@export var zoom_smoothing: float = 0.1  # Zoom interpolation speed
@export var speed_zoom_factor: float = 0.001  # How much speed affects zoom
@export var max_speed_for_zoom: float = 1000.0  # Speed at which max zoom is reached

@export_group("Overview Settings")
@export var overview_zoom: Vector2 = Vector2(0.3, 0.3)  # Zoom level for overview
@export var overview_position: Vector2 = Vector2.ZERO  # Center position for overview

@export_group("Transition Settings")
@export var transition_duration: float = 1.0  # Duration of transitions
@export var transition_curve: Curve  # Animation curve for transitions

## Internal state
var _target_zoom: Vector2 = Vector2(1.0, 1.0)
var _transition_timer: float = 0.0
var _transition_start_pos: Vector2
var _transition_end_pos: Vector2
var _transition_start_zoom: Vector2
var _transition_end_zoom: Vector2
var _last_target_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Set initial zoom
	zoom = base_zoom
	_target_zoom = base_zoom
	
	# Create default transition curve if not set
	if not transition_curve:
		transition_curve = Curve.new()
		transition_curve.add_point(Vector2(0.0, 0.0))
		transition_curve.add_point(Vector2(0.3, 0.8))
		transition_curve.add_point(Vector2(1.0, 1.0))

func _physics_process(delta: float) -> void:
	match current_mode:
		CameraMode.FOLLOW:
			_update_follow(delta)
		CameraMode.OVERVIEW:
			_update_overview(delta)
		CameraMode.TRANSITION:
			_update_transition(delta)
	
	# Always update zoom smoothly
	zoom = zoom.lerp(_target_zoom, zoom_smoothing)

func _update_follow(delta: float) -> void:
	if not follow_target:
		return
	
	# Calculate target position with look-ahead
	var target_pos := follow_target.global_position + position_offset
	
	# Add look-ahead based on velocity if target has it
	if follow_target.has_method("get_velocity"):
		var velocity: Vector2 = follow_target.get_velocity()
		_last_target_velocity = velocity
		target_pos += velocity * look_ahead_factor
	
	# Smooth follow
	global_position = global_position.lerp(target_pos, follow_smoothing)
	
	# Update zoom based on speed
	_update_speed_zoom()

func _update_overview(delta: float) -> void:
	# Move to overview position
	global_position = global_position.lerp(overview_position, follow_smoothing)
	_target_zoom = overview_zoom

func _update_transition(delta: float) -> void:
	_transition_timer += delta
	
	if _transition_timer >= transition_duration:
		# Transition complete
		current_mode = CameraMode.FOLLOW
		transition_completed.emit()
		return
	
	# Calculate transition progress
	var progress := _transition_timer / transition_duration
	if transition_curve:
		progress = transition_curve.sample_baked(progress)
	
	# Interpolate position and zoom
	global_position = _transition_start_pos.lerp(_transition_end_pos, progress)
	_target_zoom = _transition_start_zoom.lerp(_transition_end_zoom, progress)

func _update_speed_zoom() -> void:
	if not follow_target or not follow_target.has_method("get_velocity"):
		_target_zoom = base_zoom
		return
	
	# Calculate zoom based on speed
	var speed: float = _last_target_velocity.length()
	var speed_ratio: float = clamp(speed / max_speed_for_zoom, 0.0, 1.0)
	
	# Zoom out as speed increases
	_target_zoom = base_zoom.lerp(max_zoom, speed_ratio * speed_zoom_factor)
	_target_zoom = _target_zoom.clamp(min_zoom, max_zoom)

func _start_transition(from_target: Node2D, to_target: Node2D) -> void:
	if current_mode == CameraMode.TRANSITION:
		return  # Already transitioning
	
	current_mode = CameraMode.TRANSITION
	_transition_timer = 0.0
	
	# Store transition endpoints
	_transition_start_pos = global_position
	_transition_end_pos = to_target.global_position + position_offset
	_transition_start_zoom = zoom
	_transition_end_zoom = base_zoom
	
	transition_started.emit()

## Set camera to follow mode with given target
func set_follow_mode(target: Node2D) -> void:
	follow_target = target
	current_mode = CameraMode.FOLLOW

## Set camera to overview mode
func set_overview_mode() -> void:
	current_mode = CameraMode.OVERVIEW

## Immediately snap to target without transition
func snap_to_target(target: Node2D) -> void:
	if target:
		global_position = target.global_position + position_offset
		follow_target = target
		current_mode = CameraMode.FOLLOW

## Set overview parameters
func configure_overview(center: Vector2, zoom_level: Vector2) -> void:
	overview_position = center
	overview_zoom = zoom_level

## Apply camera shake effect
func shake(intensity: float, duration: float) -> void:
	# This could be expanded with a proper shake implementation
	# For now, we'll leave it as a placeholder for the screen shake system
	pass

## Get current zoom level as a percentage (0.0 = min_zoom, 1.0 = max_zoom)
func get_zoom_percentage() -> float:
	var current_zoom_avg := (zoom.x + zoom.y) / 2.0
	var min_zoom_avg := (min_zoom.x + min_zoom.y) / 2.0
	var max_zoom_avg := (max_zoom.x + max_zoom.y) / 2.0
	
	return (current_zoom_avg - min_zoom_avg) / (max_zoom_avg - min_zoom_avg)