extends Control
class_name BeatIndicator

# Visual Beat Indicator
# Provides visual feedback for beat synchronization
# Can be used for debugging or as a game UI element

signal beat_visualized(beat_number: int)
signal pulse_completed()

# Visual properties
@export var pulse_color: Color = Color.CYAN
@export var base_color: Color = Color(0.2, 0.2, 0.2)
@export var pulse_duration: float = 0.1
@export var pulse_scale: float = 1.2
@export var enable_glow: bool = true
@export var glow_radius: float = 50.0

# Shape properties  
@export_enum("Circle", "Square", "Diamond") var indicator_shape: String = "Circle"
@export var indicator_size: float = 80.0

# Animation properties
var _is_pulsing: bool = false
var _pulse_timer: float = 0.0
var _original_scale: Vector2
var _current_scale: Vector2
var _current_color: Color
var _glow_strength: float = 0.0

# References
var _beat_manager: Node = null
var _beat_event_system: Node = null

# Debug
var _debug_logging: bool = false
var _pulse_count: int = 0

func _ready():
	_log("=== BeatIndicator Initialization ===")
	
	# Set default size
	custom_minimum_size = Vector2(indicator_size, indicator_size)
	
	# Store original scale
	_original_scale = scale
	_current_scale = scale
	_current_color = base_color
	
	# Get references
	_beat_manager = get_node("/root/BeatManager") if has_node("/root/BeatManager") else null
	
	if not _beat_manager:
		push_warning("BeatManager not found. Beat indicator will not respond to beats.")
	
	_connect_signals()
	
	_log("BeatIndicator initialized")
	_log("==============================")

func _log(message: String) -> void:
	if _debug_logging:
		var timestamp = Time.get_time_string_from_system()
		print("[%s] BeatIndicator: %s" % [timestamp, message])

func _connect_signals():
	if _beat_manager:
		_beat_manager.connect("beat_occurred", _on_beat_occurred)
		_log("Connected to BeatManager")

func _draw():
	var center = size / 2
	var radius = min(size.x, size.y) / 2
	
	# Draw glow effect if enabled
	if enable_glow and _glow_strength > 0:
		var glow_color = pulse_color
		glow_color.a = _glow_strength * 0.3
		
		for i in range(5):
			var glow_size = radius + (glow_radius * (i + 1) / 5.0)
			var glow_alpha = glow_color.a * (1.0 - (i / 5.0))
			glow_color.a = glow_alpha
			
			_draw_shape(center, glow_size, glow_color)
	
	# Draw main shape
	_draw_shape(center, radius, _current_color)

func _draw_shape(center: Vector2, radius: float, color: Color):
	match indicator_shape:
		"Circle":
			draw_circle(center, radius, color)
			
		"Square":
			var rect = Rect2(center - Vector2(radius, radius), Vector2(radius * 2, radius * 2))
			draw_rect(rect, color)
			
		"Diamond":
			var points = PackedVector2Array([
				center + Vector2(0, -radius),
				center + Vector2(radius, 0),
				center + Vector2(0, radius),
				center + Vector2(-radius, 0)
			])
			draw_polygon(points, PackedColorArray([color]))

func _process(delta: float):
	if _is_pulsing:
		_update_pulse(delta)

func _on_beat_occurred(beat_number: int, beat_time: float):
	trigger_pulse()
	emit_signal("beat_visualized", beat_number)

func trigger_pulse():
	_is_pulsing = true
	_pulse_timer = 0.0
	_pulse_count += 1
	_log("Pulse triggered (#%d)" % _pulse_count)

func _update_pulse(delta: float):
	_pulse_timer += delta
	
	if _pulse_timer >= pulse_duration:
		_end_pulse()
		return
	
	# Calculate pulse progress
	var progress = _pulse_timer / pulse_duration
	
	# Smooth easing curve
	var eased_progress = 1.0 - pow(1.0 - progress, 3.0)
	
	# Update scale
	var scale_factor = lerp(pulse_scale, 1.0, eased_progress)
	_current_scale = _original_scale * scale_factor
	scale = _current_scale
	
	# Update color
	_current_color = pulse_color.lerp(base_color, eased_progress)
	
	# Update glow
	_glow_strength = 1.0 - eased_progress
	
	# Trigger redraw
	queue_redraw()

func _end_pulse():
	_is_pulsing = false
	_pulse_timer = 0.0
	_current_scale = _original_scale
	scale = _current_scale
	_current_color = base_color
	_glow_strength = 0.0
	
	queue_redraw()
	emit_signal("pulse_completed")

# Configuration methods
func set_pulse_color(color: Color):
	pulse_color = color
	queue_redraw()

func set_base_color(color: Color):
	base_color = color
	_current_color = color
	queue_redraw()

func set_indicator_shape(shape: String):
	if shape in ["Circle", "Square", "Diamond"]:
		indicator_shape = shape
		queue_redraw()

func set_indicator_size(size: float):
	indicator_size = size
	custom_minimum_size = Vector2(size, size)
	queue_redraw()

func set_pulse_duration(duration: float):
	pulse_duration = max(0.01, duration)

func set_pulse_scale(scale: float):
	pulse_scale = max(1.0, scale)

func set_glow_enabled(enabled: bool):
	enable_glow = enabled
	queue_redraw()

func set_glow_radius(radius: float):
	glow_radius = max(0.0, radius)
	queue_redraw()

# Utility methods
func is_pulsing() -> bool:
	return _is_pulsing

func get_pulse_progress() -> float:
	if not _is_pulsing:
		return 0.0
	return _pulse_timer / pulse_duration

func reset():
	_is_pulsing = false
	_pulse_timer = 0.0
	_pulse_count = 0
	_current_scale = _original_scale
	scale = _current_scale
	_current_color = base_color
	_glow_strength = 0.0
	queue_redraw()

# Debug methods
func enable_debug_logging(enabled: bool):
	_debug_logging = enabled

func get_pulse_count() -> int:
	return _pulse_count

func print_debug_info():
	print("=== BeatIndicator Debug Info ===")
	print("Shape: %s" % indicator_shape)
	print("Size: %.1f" % indicator_size)
	print("Is Pulsing: %s" % str(_is_pulsing))
	print("Pulse Count: %d" % _pulse_count)
	print("Pulse Progress: %.1f%%" % (get_pulse_progress() * 100))
	print("Glow Enabled: %s" % str(enable_glow))
	print("===============================")