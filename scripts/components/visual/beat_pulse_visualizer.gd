extends Node2D
class_name BeatPulseVisualizer

# Beat Pulse Visualizer
# Creates visual pulses synchronized with the beat
# Can be attached to any node for beat-reactive visuals

signal pulse_triggered(intensity: float)
signal pulse_completed()

@export_group("Pulse Settings")
@export var base_scale: Vector2 = Vector2.ONE
@export var pulse_scale: float = 1.5  # Maximum scale during pulse
@export var pulse_duration: float = 0.2  # Duration of pulse animation
@export var pulse_curve: Curve  # Animation curve for pulse

@export_group("Visual Properties")
@export var pulse_color: Color = Color(0.0, 0.8, 1.0, 0.8)
@export var base_color: Color = Color(0.2, 0.2, 0.3, 0.5)
@export var enable_glow: bool = true
@export var glow_radius: float = 100.0
@export var glow_energy: float = 1.5

@export_group("Behavior")
@export var auto_pulse_on_beat: bool = true
@export var pulse_on_measure: bool = false
@export var intensity_from_volume: bool = true
@export var fade_between_beats: bool = true

# Internal state
var _is_pulsing: bool = false
var _pulse_timer: float = 0.0
var _pulse_intensity: float = 1.0
var _current_scale: Vector2
var _current_color: Color
var _fade_timer: float = 0.0
var _beat_manager: Node = null
var _target_node: Node2D = null

# Debug
var _debug_logging: bool = false


func _ready():
	_log("=== BeatPulseVisualizer Initialization ===")
	
	# Initialize properties
	_current_scale = base_scale
	_current_color = base_color
	
	# Get BeatManager reference
	_beat_manager = get_node("/root/BeatManager") if has_node("/root/BeatManager") else null
	
	if not _beat_manager:
		push_warning("BeatPulseVisualizer: BeatManager not found")
	else:
		_connect_beat_signals()
	
	# Find target node (parent by default)
	_target_node = get_parent() if get_parent() is Node2D else self
	
	_log("BeatPulseVisualizer ready")
	_log("====================================")


func _log(message: String) -> void:
	if _debug_logging:
		var timestamp = Time.get_time_string_from_system()
		print("[%s] BeatPulseVisualizer: %s" % [timestamp, message])


func _connect_beat_signals():
	"""Connect to beat manager signals"""
	if auto_pulse_on_beat:
		_beat_manager.beat_occurred.connect(_on_beat_occurred)
		_log("Connected to beat_occurred signal")
	
	if pulse_on_measure:
		_beat_manager.measure_completed.connect(_on_measure_completed)
		_log("Connected to measure_completed signal")


func _on_beat_occurred(beat_number: int, beat_time: float):
	"""Handle beat event"""
	if auto_pulse_on_beat:
		var intensity = 1.0
		
		# Stronger pulse on downbeat (first beat of measure)
		if beat_number % 4 == 0:
			intensity = 1.2
		
		trigger_pulse(intensity)


func _on_measure_completed(measure_number: int, measure_time: float):
	"""Handle measure completion"""
	if pulse_on_measure:
		trigger_pulse(1.5)  # Stronger pulse for measures


func trigger_pulse(intensity: float = 1.0):
	"""Trigger a visual pulse with given intensity"""
	_is_pulsing = true
	_pulse_timer = 0.0
	_pulse_intensity = clamp(intensity, 0.1, 2.0)
	_fade_timer = 0.0
	
	emit_signal("pulse_triggered", _pulse_intensity)
	_log("Pulse triggered with intensity: %.2f" % _pulse_intensity)


func _process(delta: float):
	"""Update pulse animation"""
	if _is_pulsing:
		_update_pulse(delta)
	elif fade_between_beats:
		_update_fade(delta)
	
	# Apply transformations to target node
	if _target_node and _target_node != self:
		_target_node.scale = _current_scale
		_target_node.modulate = _current_color


func _update_pulse(delta: float):
	"""Update pulse animation"""
	_pulse_timer += delta
	
	if _pulse_timer >= pulse_duration:
		_end_pulse()
		return
	
	# Calculate progress
	var progress = _pulse_timer / pulse_duration
	
	# Use curve if provided, otherwise use smooth interpolation
	var curve_value = 1.0
	if pulse_curve:
		curve_value = pulse_curve.sample(progress)
	else:
		# Default ease out curve
		curve_value = 1.0 - pow(1.0 - progress, 3.0)
	
	# Calculate scale
	var target_scale = base_scale * (1.0 + (pulse_scale - 1.0) * _pulse_intensity)
	_current_scale = base_scale.lerp(target_scale, 1.0 - curve_value)
	
	# Calculate color
	var target_color = pulse_color
	target_color.a *= _pulse_intensity
	_current_color = target_color.lerp(base_color, curve_value)
	
	# Request redraw for glow effect
	queue_redraw()


func _update_fade(delta: float):
	"""Fade effect between beats"""
	_fade_timer += delta
	
	# Fade out over time
	var fade_duration = 1.0
	var fade_progress = min(_fade_timer / fade_duration, 1.0)
	
	_current_color = _current_color.lerp(base_color, fade_progress * delta * 2.0)
	queue_redraw()


func _end_pulse():
	"""End pulse animation"""
	_is_pulsing = false
	_pulse_timer = 0.0
	_current_scale = base_scale
	
	emit_signal("pulse_completed")
	_log("Pulse completed")


func _draw():
	"""Draw glow effect"""
	if not enable_glow:
		return
	
	var glow_alpha = (_current_color.a - base_color.a) * 0.5
	if glow_alpha <= 0:
		return
	
	# Draw multiple circles for glow effect
	var glow_color = _current_color
	for i in range(5):
		var radius = glow_radius * (i + 1) / 5.0
		glow_color.a = glow_alpha * (1.0 - i / 5.0) * glow_energy
		draw_circle(Vector2.ZERO, radius, glow_color)


# Configuration methods
func set_target_node(node: Node2D):
	"""Set the node to apply pulse effects to"""
	_target_node = node


func set_pulse_scale(scale: float):
	"""Set maximum pulse scale"""
	pulse_scale = max(1.0, scale)


func set_pulse_duration(duration: float):
	"""Set pulse animation duration"""
	pulse_duration = max(0.01, duration)


func set_pulse_color(color: Color):
	"""Set pulse color"""
	pulse_color = color


func set_intensity_from_audio(audio_level: float):
	"""Set pulse intensity based on audio level"""
	if intensity_from_volume:
		_pulse_intensity = clamp(audio_level, 0.1, 2.0)


func enable_debug_logging(enabled: bool):
	"""Enable/disable debug logging"""
	_debug_logging = enabled


# Utility methods
func is_pulsing() -> bool:
	"""Check if currently pulsing"""
	return _is_pulsing


func get_pulse_progress() -> float:
	"""Get current pulse progress (0-1)"""
	if not _is_pulsing:
		return 0.0
	return _pulse_timer / pulse_duration


func reset():
	"""Reset to default state"""
	_is_pulsing = false
	_pulse_timer = 0.0
	_fade_timer = 0.0
	_current_scale = base_scale
	_current_color = base_color
	
	if _target_node and _target_node != self:
		_target_node.scale = base_scale
		_target_node.modulate = base_color
	
	queue_redraw()