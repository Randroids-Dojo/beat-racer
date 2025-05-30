extends Node
class_name ScreenShakeSystem

## Manages camera shake effects with multiple shake sources

signal shake_started()
signal shake_ended()

## Active shake data
class ShakeInstance:
	var intensity: float
	var duration: float
	var elapsed: float = 0.0
	var frequency: float = 60.0
	var decay_curve: Curve
	var directional: bool = false
	var direction: Vector2 = Vector2.ZERO

## Camera to apply shake to
@export var camera: Camera2D

## Configuration
@export_group("Shake Settings")
@export var max_offset: float = 50.0  # Maximum shake offset in pixels
@export var default_frequency: float = 60.0  # Shake frequency in Hz
@export var rotation_enabled: bool = true  # Whether to apply rotation shake
@export var max_rotation: float = 0.1  # Maximum rotation in radians

## Shake presets
@export_group("Presets")
@export var impact_curve: Curve  # Quick, sharp shake for impacts
@export var rumble_curve: Curve  # Sustained rumble for continuous effects
@export var explosion_curve: Curve  # Big initial shake with decay

## Internal state
var _active_shakes: Array[ShakeInstance] = []
var _original_offset: Vector2
var _shake_offset: Vector2 = Vector2.ZERO
var _shake_rotation: float = 0.0
var _is_shaking: bool = false

func _ready() -> void:
	# Create default curves if not set
	if not impact_curve:
		impact_curve = _create_impact_curve()
	if not rumble_curve:
		rumble_curve = _create_rumble_curve()
	if not explosion_curve:
		explosion_curve = _create_explosion_curve()
	
	# Find camera if not assigned
	if not camera and has_node("../Camera2D"):
		camera = get_node("../Camera2D")

func _physics_process(delta: float) -> void:
	if _active_shakes.is_empty():
		if _is_shaking:
			_end_shake()
		return
	
	if not _is_shaking:
		_start_shake()
	
	# Update all active shakes
	var total_offset := Vector2.ZERO
	var total_rotation := 0.0
	var completed_shakes := []
	
	for i in range(_active_shakes.size()):
		var shake := _active_shakes[i]
		shake.elapsed += delta
		
		if shake.elapsed >= shake.duration:
			completed_shakes.append(i)
			continue
		
		# Calculate shake intensity with decay
		var progress := shake.elapsed / shake.duration
		var intensity_multiplier := 1.0
		if shake.decay_curve:
			intensity_multiplier = shake.decay_curve.sample_baked(progress)
		else:
			# Linear decay if no curve
			intensity_multiplier = 1.0 - progress
		
		var current_intensity := shake.intensity * intensity_multiplier
		
		# Calculate shake offset
		var shake_offset := _calculate_shake_offset(shake, current_intensity)
		total_offset += shake_offset
		
		# Calculate rotation if enabled
		if rotation_enabled:
			var rotation_offset := _calculate_shake_rotation(shake, current_intensity)
			total_rotation += rotation_offset
	
	# Remove completed shakes
	for i in range(completed_shakes.size() - 1, -1, -1):
		_active_shakes.remove_at(completed_shakes[i])
	
	# Apply shake to camera
	_apply_shake(total_offset, total_rotation)

func _calculate_shake_offset(shake: ShakeInstance, intensity: float) -> Vector2:
	var offset := Vector2.ZERO
	
	if shake.directional and shake.direction != Vector2.ZERO:
		# Directional shake
		var perpendicular := Vector2(-shake.direction.y, shake.direction.x).normalized()
		var parallel_shake := sin(shake.elapsed * shake.frequency * TAU) * shake.direction
		var perpendicular_shake := sin(shake.elapsed * shake.frequency * TAU * 1.3) * perpendicular * 0.5
		offset = (parallel_shake + perpendicular_shake) * intensity * max_offset
	else:
		# Random shake
		var time := shake.elapsed * shake.frequency
		offset.x = sin(time * TAU) * cos(time * 3.7) * intensity * max_offset
		offset.y = cos(time * TAU) * sin(time * 2.9) * intensity * max_offset
	
	return offset

func _calculate_shake_rotation(shake: ShakeInstance, intensity: float) -> float:
	var time := shake.elapsed * shake.frequency * 0.7  # Slightly different frequency for rotation
	return sin(time * TAU) * intensity * max_rotation

func _apply_shake(offset: Vector2, rotation: float) -> void:
	if not camera:
		return
	
	_shake_offset = offset
	_shake_rotation = rotation
	
	# Apply offset and rotation
	camera.offset = _original_offset + _shake_offset
	if rotation_enabled:
		camera.rotation = _shake_rotation

func _start_shake() -> void:
	_is_shaking = true
	if camera:
		_original_offset = camera.offset
	shake_started.emit()

func _end_shake() -> void:
	_is_shaking = false
	if camera:
		camera.offset = _original_offset
		camera.rotation = 0.0
	_shake_offset = Vector2.ZERO
	_shake_rotation = 0.0
	shake_ended.emit()

## Add a basic shake
func shake(intensity: float, duration: float) -> void:
	var shake_instance := ShakeInstance.new()
	shake_instance.intensity = clamp(intensity, 0.0, 1.0)
	shake_instance.duration = duration
	shake_instance.frequency = default_frequency
	_active_shakes.append(shake_instance)

## Add a shake with custom settings
func shake_advanced(intensity: float, duration: float, frequency: float, decay_curve: Curve) -> void:
	var shake_instance := ShakeInstance.new()
	shake_instance.intensity = clamp(intensity, 0.0, 1.0)
	shake_instance.duration = duration
	shake_instance.frequency = frequency
	shake_instance.decay_curve = decay_curve
	_active_shakes.append(shake_instance)

## Add a directional shake
func shake_directional(intensity: float, duration: float, direction: Vector2) -> void:
	var shake_instance := ShakeInstance.new()
	shake_instance.intensity = clamp(intensity, 0.0, 1.0)
	shake_instance.duration = duration
	shake_instance.frequency = default_frequency
	shake_instance.directional = true
	shake_instance.direction = direction.normalized()
	_active_shakes.append(shake_instance)

## Preset shake methods
func shake_impact(intensity: float = 0.5) -> void:
	shake_advanced(intensity, 0.2, 80.0, impact_curve)

func shake_rumble(intensity: float = 0.3, duration: float = 1.0) -> void:
	shake_advanced(intensity, duration, 40.0, rumble_curve)

func shake_explosion(intensity: float = 0.8) -> void:
	shake_advanced(intensity, 0.5, 60.0, explosion_curve)

## Stop all active shakes
func stop_all_shakes() -> void:
	_active_shakes.clear()
	_end_shake()

## Get current shake intensity (0.0 - 1.0)
func get_shake_intensity() -> float:
	if _active_shakes.is_empty():
		return 0.0
	
	var max_intensity := 0.0
	for shake in _active_shakes:
		var progress := shake.elapsed / shake.duration
		var intensity_multiplier := 1.0 - progress
		if shake.decay_curve:
			intensity_multiplier = shake.decay_curve.sample_baked(progress)
		max_intensity = max(max_intensity, shake.intensity * intensity_multiplier)
	
	return max_intensity

## Create default curves
func _create_impact_curve() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.1, 0.6))
	curve.add_point(Vector2(0.3, 0.2))
	curve.add_point(Vector2(1.0, 0.0))
	return curve

func _create_rumble_curve() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.8))
	curve.add_point(Vector2(0.7, 0.8))
	curve.add_point(Vector2(1.0, 0.0))
	return curve

func _create_explosion_curve() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.05, 0.8))
	curve.add_point(Vector2(0.2, 0.4))
	curve.add_point(Vector2(0.5, 0.1))
	curve.add_point(Vector2(1.0, 0.0))
	return curve