class_name PerfectHitIndicator
extends Node2D

@export_group("Visual Settings")
@export var perfect_color: Color = Color(0.0, 1.0, 0.5, 0.8)
@export var good_color: Color = Color(1.0, 1.0, 0.0, 0.8)
@export var ok_color: Color = Color(1.0, 0.5, 0.0, 0.8)
@export var particle_count: int = 20
@export var particle_spread: float = 30.0
@export var particle_lifetime: float = 0.8
@export var burst_scale: float = 2.0
@export var use_rainbow_effect: bool = false

@export_group("Animation")
@export var fade_duration: float = 0.5
@export var scale_duration: float = 0.3
@export var rotation_speed: float = 360.0  # degrees per second

# Particle system
var _particles: Array[Node2D] = []
var _particle_pool: Array[Node2D] = []
var _active_bursts: Array = []

# Visual elements
var _ring_visual: Node2D
var _burst_visual: Node2D
var _text_popup: Label

# State tracking
var _is_active: bool = false
var _current_quality: RhythmFeedbackManager.HitQuality
var _current_color: Color

func _ready():
	# Create visual components
	_create_ring_visual()
	_create_burst_visual()
	_create_text_popup()
	_create_particle_pool()
	
	# Hide everything initially
	visible = false

func _create_ring_visual():
	_ring_visual = Node2D.new()
	_ring_visual.name = "RingVisual"
	add_child(_ring_visual)

func _create_burst_visual():
	_burst_visual = Node2D.new()
	_burst_visual.name = "BurstVisual"
	add_child(_burst_visual)

func _create_text_popup():
	_text_popup = Label.new()
	_text_popup.name = "TextPopup"
	_text_popup.add_theme_font_size_override("font_size", 24)
	_text_popup.position = Vector2(0, -50)
	_text_popup.modulate = Color.WHITE
	add_child(_text_popup)

func _create_particle_pool():
	# Pre-allocate particles for performance
	for i in range(particle_count * 3):
		var particle = _create_particle()
		particle.visible = false
		_particle_pool.append(particle)

func _create_particle() -> Node2D:
	var particle = Node2D.new()
	add_child(particle)
	return particle

func _get_pooled_particle() -> Node2D:
	for particle in _particle_pool:
		if not particle.visible:
			return particle
	
	# If no available particles, create a new one
	var new_particle = _create_particle()
	_particle_pool.append(new_particle)
	return new_particle

func trigger_perfect_hit(quality: RhythmFeedbackManager.HitQuality, position: Vector2):
	global_position = position
	_current_quality = quality
	_current_color = _get_quality_color(quality)
	visible = true
	_is_active = true
	
	# Show feedback text
	_show_feedback_text(quality)
	
	# Trigger effects based on quality
	match quality:
		RhythmFeedbackManager.HitQuality.PERFECT:
			_show_perfect_effect()
		RhythmFeedbackManager.HitQuality.GOOD:
			_show_good_effect()
		RhythmFeedbackManager.HitQuality.OK:
			_show_ok_effect()
	
	# Trigger particle burst
	_emit_particles()

func _get_quality_color(quality: RhythmFeedbackManager.HitQuality) -> Color:
	match quality:
		RhythmFeedbackManager.HitQuality.PERFECT:
			return perfect_color if not use_rainbow_effect else _get_rainbow_color()
		RhythmFeedbackManager.HitQuality.GOOD:
			return good_color
		RhythmFeedbackManager.HitQuality.OK:
			return ok_color
		_:
			return Color.WHITE

func _get_rainbow_color() -> Color:
	var time = Time.get_ticks_msec() / 1000.0
	var hue = fmod(time * 0.5, 1.0)
	return Color.from_hsv(hue, 1.0, 1.0, perfect_color.a)

func _show_feedback_text(quality: RhythmFeedbackManager.HitQuality):
	match quality:
		RhythmFeedbackManager.HitQuality.PERFECT:
			_text_popup.text = "PERFECT!"
		RhythmFeedbackManager.HitQuality.GOOD:
			_text_popup.text = "GOOD!"
		RhythmFeedbackManager.HitQuality.OK:
			_text_popup.text = "OK"
	
	_text_popup.modulate = _current_color
	_text_popup.scale = Vector2(0.5, 0.5)
	
	# Animate text
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(_text_popup, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(_text_popup, "position", Vector2(0, -80), 0.5).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_text_popup, "modulate:a", 0.0, fade_duration).set_delay(0.3)

func _show_perfect_effect():
	# Create expanding ring effect
	_ring_visual.scale = Vector2(0.1, 0.1)
	_ring_visual.modulate = _current_color
	
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(_ring_visual, "scale", Vector2(burst_scale, burst_scale), scale_duration)
	tween.tween_property(_ring_visual, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(_on_effect_finished.bind(_ring_visual))

func _show_good_effect():
	# Smaller burst effect
	_burst_visual.scale = Vector2(0.5, 0.5)
	_burst_visual.modulate = _current_color
	
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(_burst_visual, "scale", Vector2(1.5, 1.5), scale_duration)
	tween.tween_property(_burst_visual, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(_on_effect_finished.bind(_burst_visual))

func _show_ok_effect():
	# Simple fade effect
	modulate = _current_color
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(_on_effect_finished.bind(self))

func _emit_particles():
	for i in range(particle_count):
		var particle = _get_pooled_particle()
		particle.visible = true
		particle.position = Vector2.ZERO
		particle.modulate = _current_color
		
		# Random direction and speed
		var angle = randf() * TAU
		var speed = randf_range(100, 200)
		var direction = Vector2.from_angle(angle)
		
		# Animate particle
		var tween = create_tween()
		tween.set_parallel()
		tween.tween_property(particle, "position", direction * speed, particle_lifetime)
		tween.tween_property(particle, "modulate:a", 0.0, particle_lifetime)
		tween.tween_property(particle, "scale", Vector2(0.1, 0.1), particle_lifetime)
		tween.chain().tween_callback(_return_particle_to_pool.bind(particle))

func _return_particle_to_pool(particle: Node2D):
	particle.visible = false
	particle.position = Vector2.ZERO
	particle.scale = Vector2.ONE
	particle.modulate = Color.WHITE

func _on_effect_finished(node: Node2D):
	if node == self:
		visible = false
	else:
		node.visible = false
	_is_active = false

func _draw():
	if _is_active and _ring_visual.visible:
		# Draw expanding ring
		draw_arc(Vector2.ZERO, 40.0 * _ring_visual.scale.x, 0, TAU, 64, _ring_visual.modulate, 3.0)
	
	if _is_active and _burst_visual.visible:
		# Draw burst pattern
		var points = 8
		for i in range(points):
			var angle = (TAU / points) * i
			var end_pos = Vector2.from_angle(angle) * 30.0 * _burst_visual.scale.x
			draw_line(Vector2.ZERO, end_pos, _burst_visual.modulate, 2.0)

func _process(delta: float):
	if _is_active:
		# Add rotation animation
		rotation += rotation_speed * delta * PI / 180.0
		queue_redraw()