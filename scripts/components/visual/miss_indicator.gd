class_name MissIndicator
extends Node2D

@export_group("Visual Settings")
@export var miss_color: Color = Color(1.0, 0.0, 0.0, 0.5)
@export var recovery_color: Color = Color(0.5, 0.5, 1.0, 0.5)
@export var pulse_strength: float = 0.3
@export var shake_strength: float = 10.0
@export var desaturation_amount: float = 0.5

@export_group("Animation")
@export var pulse_duration: float = 0.4
@export var shake_duration: float = 0.3
@export var recovery_duration: float = 1.0

# Visual elements
var _screen_overlay: ColorRect
var _pulse_visual: Node2D
var _recovery_guide: Node2D

# Camera reference for shake effect
var _camera: Camera2D

# State tracking
var _is_active: bool = false
var _shake_time: float = 0.0
var _original_camera_position: Vector2
var _canvas_layer: CanvasLayer

func _ready():
	# Create canvas layer for screen effects
	_canvas_layer = CanvasLayer.new()
	add_child(_canvas_layer)
	
	# Create visual components
	_create_screen_overlay()
	_create_pulse_visual()
	_create_recovery_guide()
	
	# Find camera in scene
	_find_camera()
	
	# Hide everything initially
	visible = false

func _create_screen_overlay():
	_screen_overlay = ColorRect.new()
	_screen_overlay.name = "ScreenOverlay"
	_screen_overlay.color = miss_color
	_screen_overlay.color.a = 0.0
	_screen_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas_layer.add_child(_screen_overlay)

func _create_pulse_visual():
	_pulse_visual = Node2D.new()
	_pulse_visual.name = "PulseVisual"
	add_child(_pulse_visual)

func _create_recovery_guide():
	_recovery_guide = Node2D.new()
	_recovery_guide.name = "RecoveryGuide"
	_recovery_guide.modulate = recovery_color
	add_child(_recovery_guide)

func _find_camera():
	# Try to find main camera in scene
	var cameras = get_tree().get_nodes_in_group("main_camera")
	if cameras.size() > 0:
		_camera = cameras[0]
	else:
		# Look for any Camera2D in the scene
		var all_cameras = []
		_find_cameras_recursive(get_tree().root, all_cameras)
		if all_cameras.size() > 0:
			_camera = all_cameras[0]

func _find_cameras_recursive(node: Node, cameras: Array):
	if node is Camera2D and node.enabled:
		cameras.append(node)
	
	for child in node.get_children():
		_find_cameras_recursive(child, cameras)

func trigger_miss(vehicle_position: Vector2):
	global_position = vehicle_position
	visible = true
	_is_active = true
	
	# Trigger effects
	_show_screen_pulse()
	_show_miss_feedback()
	_start_camera_shake()
	_show_recovery_guide()

func _show_screen_pulse():
	# Pulse the screen overlay
	_screen_overlay.color.a = pulse_strength
	
	var tween = create_tween()
	tween.tween_property(_screen_overlay, "color:a", 0.0, pulse_duration)

func _show_miss_feedback():
	# Visual feedback at vehicle position
	_pulse_visual.scale = Vector2(0.5, 0.5)
	_pulse_visual.modulate = miss_color
	
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(_pulse_visual, "scale", Vector2(2.0, 2.0), pulse_duration)
	tween.tween_property(_pulse_visual, "modulate:a", 0.0, pulse_duration)

func _start_camera_shake():
	if not _camera:
		return
	
	_shake_time = shake_duration
	_original_camera_position = _camera.position

func _show_recovery_guide():
	# Show guide to help player get back on rhythm
	_recovery_guide.modulate.a = 0.0
	_recovery_guide.scale = Vector2(1.5, 1.5)
	
	var tween = create_tween()
	tween.tween_property(_recovery_guide, "modulate:a", 1.0, 0.2)
	tween.tween_property(_recovery_guide, "scale", Vector2(1.0, 1.0), recovery_duration)
	tween.tween_property(_recovery_guide, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_on_recovery_finished)

func _on_recovery_finished():
	visible = false
	_is_active = false

func _process(delta: float):
	# Handle camera shake
	if _shake_time > 0 and _camera:
		_shake_time -= delta
		
		var shake_amount = (_shake_time / shake_duration) * shake_strength
		var offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		
		_camera.position = _original_camera_position + offset
		
		if _shake_time <= 0:
			_camera.position = _original_camera_position

func _draw():
	if not _is_active:
		return
	
	# Draw pulse visual
	if _pulse_visual.visible and _pulse_visual.modulate.a > 0:
		var radius = 30.0 * _pulse_visual.scale.x
		draw_circle(Vector2.ZERO, radius, _pulse_visual.modulate)
	
	# Draw recovery guide
	if _recovery_guide.visible and _recovery_guide.modulate.a > 0:
		# Draw pulsing circles to guide timing
		for i in range(3):
			var radius = 20.0 + (i * 15.0)
			var alpha = _recovery_guide.modulate.a * (1.0 - (i * 0.3))
			var color = _recovery_guide.modulate
			color.a = alpha
			draw_arc(Vector2.ZERO, radius, 0, TAU, 32, color, 2.0)

# Utility methods for effects
func set_desaturation_effect(enable: bool):
	# This would typically be done with a shader on the main viewport
	# For now, we'll just adjust the overlay
	if enable:
		_screen_overlay.color = Color(0.5, 0.5, 0.5, desaturation_amount)
	else:
		_screen_overlay.color.a = 0.0

func flash_border():
	# Create a border flash effect
	var border = ColorRect.new()
	border.color = miss_color
	border.color.a = 0.5
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Set border margins
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.set_offsets_preset(Control.PRESET_FULL_RECT)
	var margin = 10
	border.set_offset(SIDE_LEFT, margin)
	border.set_offset(SIDE_TOP, margin)
	border.set_offset(SIDE_RIGHT, -margin)
	border.set_offset(SIDE_BOTTOM, -margin)
	
	_canvas_layer.add_child(border)
	
	# Animate border
	var tween = create_tween()
	tween.tween_property(border, "color:a", 0.0, 0.5)
	tween.tween_callback(border.queue_free)

func cleanup():
	# Clean up any active effects
	if _camera and _original_camera_position:
		_camera.position = _original_camera_position
	
	visible = false
	_is_active = false
	_shake_time = 0.0