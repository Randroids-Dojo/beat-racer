extends Node2D
class_name EnvironmentVisualizer

# Environment Visualizer
# Makes the track environment react to music
# Includes track borders, background elements, and ambient effects

signal environment_pulse_triggered(intensity: float)
signal effect_activated(effect_type: String)

@export_group("Track Border Effects")
@export var track_border_enabled: bool = true
@export var border_pulse_intensity: float = 1.5
@export var border_base_color: Color = Color(0.3, 0.3, 0.4, 0.5)
@export var border_pulse_color: Color = Color(0.8, 0.9, 1.0, 0.8)
@export var border_width: float = 5.0

@export_group("Background Effects")
@export var background_enabled: bool = true
@export var background_grid_size: int = 50
@export var grid_pulse_delay: float = 0.05  # Ripple effect delay
@export var grid_base_color: Color = Color(0.1, 0.1, 0.15, 0.3)
@export var grid_pulse_color: Color = Color(0.3, 0.5, 0.8, 0.5)

@export_group("Ambient Particles")
@export var ambient_particles_enabled: bool = true
@export var particle_count: int = 100
@export var particle_base_speed: float = 20.0
@export var particle_react_multiplier: float = 3.0
@export var particle_color: Color = Color(0.5, 0.7, 1.0, 0.3)

@export_group("Beat Markers Enhancement")
@export var enhance_beat_markers: bool = true
@export var beat_marker_scale_multiplier: float = 1.5
@export var beat_marker_glow_radius: float = 30.0

@export_group("Reaction Settings")
@export var react_to_beat: bool = true
@export var react_to_measure: bool = true
@export var react_to_volume: bool = true
@export var reaction_decay_speed: float = 2.0

# Grid system for background
class GridNode:
	var position: Vector2
	var pulse_timer: float = 0.0
	var pulse_active: bool = false
	var intensity: float = 0.0

# Particle system
class AmbientParticle:
	var position: Vector2
	var velocity: Vector2
	var base_velocity: Vector2
	var color: Color
	var size: float = 2.0

# Internal state
var grid_nodes: Array[GridNode] = []
var ambient_particles: Array[AmbientParticle] = []
var track_boundaries: Array[Vector2] = []  # Track border points
var beat_markers: Array[Node2D] = []  # References to beat markers

var current_intensity: float = 0.0
var border_pulse_timer: float = 0.0
var grid_ripple_origin: Vector2 = Vector2.ZERO
var grid_ripple_active: bool = false
var grid_ripple_timer: float = 0.0

# References
var beat_manager: Node = null
var track_system: Node = null
var rhythm_feedback_manager: Node = null

# Screen bounds
var screen_rect: Rect2

# Debug
var _debug_logging: bool = false


func _ready():
	_log("=== EnvironmentVisualizer Initialization ===")
	
	# Get screen bounds
	screen_rect = get_viewport_rect()
	
	# Initialize systems
	if background_enabled:
		_initialize_grid()
	
	if ambient_particles_enabled:
		_initialize_particles()
	
	# Find references
	_find_references()
	_connect_signals()
	
	# Find track elements
	_find_track_elements()
	
	_log("EnvironmentVisualizer ready")
	_log("===========================================")


func _log(message: String) -> void:
	if _debug_logging:
		var timestamp = Time.get_time_string_from_system()
		print("[%s] EnvironmentVisualizer: %s" % [timestamp, message])


func _find_references():
	"""Find system references"""
	# Get BeatManager
	beat_manager = get_node("/root/BeatManager") if has_node("/root/BeatManager") else null
	
	# Find TrackSystem
	var tracks = get_tree().get_nodes_in_group("track_system")
	if tracks.size() > 0:
		track_system = tracks[0]
	
	# Find RhythmFeedbackManager
	var managers = get_tree().get_nodes_in_group("rhythm_feedback")
	if managers.size() > 0:
		rhythm_feedback_manager = managers[0]


func _connect_signals():
	"""Connect to system signals"""
	if beat_manager:
		if react_to_beat:
			beat_manager.beat_occurred.connect(_on_beat_occurred)
		if react_to_measure:
			beat_manager.measure_completed.connect(_on_measure_completed)
		_log("Connected to BeatManager")
	
	if rhythm_feedback_manager:
		rhythm_feedback_manager.perfect_hit_detected.connect(_on_perfect_hit)
		rhythm_feedback_manager.combo_updated.connect(_on_combo_updated)
		_log("Connected to RhythmFeedbackManager")


func _find_track_elements():
	"""Find track boundaries and beat markers"""
	# Find track boundaries
	if track_system and track_system.has_method("get_track_boundaries"):
		track_boundaries = track_system.get_track_boundaries()
		_log("Found %d track boundary points" % track_boundaries.size())
	
	# Find beat markers
	beat_markers = get_tree().get_nodes_in_group("beat_markers")
	_log("Found %d beat markers" % beat_markers.size())


func _initialize_grid():
	"""Initialize background grid"""
	grid_nodes.clear()
	
	var grid_cols = int(screen_rect.size.x / background_grid_size) + 2
	var grid_rows = int(screen_rect.size.y / background_grid_size) + 2
	
	for y in grid_rows:
		for x in grid_cols:
			var node = GridNode.new()
			node.position = Vector2(x * background_grid_size, y * background_grid_size)
			grid_nodes.append(node)
	
	_log("Initialized grid with %d nodes" % grid_nodes.size())


func _initialize_particles():
	"""Initialize ambient particles"""
	ambient_particles.clear()
	
	for i in particle_count:
		var particle = AmbientParticle.new()
		particle.position = Vector2(
			randf() * screen_rect.size.x,
			randf() * screen_rect.size.y
		)
		
		# Random upward drift
		var angle = randf_range(-PI/4, PI/4) - PI/2
		particle.base_velocity = Vector2.from_angle(angle) * particle_base_speed
		particle.velocity = particle.base_velocity
		particle.color = particle_color
		particle.size = randf_range(1.0, 3.0)
		
		ambient_particles.append(particle)
	
	_log("Initialized %d ambient particles" % ambient_particles.size())


func _on_beat_occurred(beat_number: int, beat_time: float):
	"""Handle beat event"""
	current_intensity = 1.0
	
	# Trigger border pulse
	if track_border_enabled:
		border_pulse_timer = 0.0
	
	# Trigger grid ripple from center
	if background_enabled:
		_trigger_grid_ripple(screen_rect.size / 2)
	
	# Boost particles
	if ambient_particles_enabled:
		_boost_particles()
	
	# Enhance beat markers
	if enhance_beat_markers:
		_pulse_beat_markers(beat_number)
	
	emit_signal("environment_pulse_triggered", current_intensity)
	emit_signal("effect_activated", "beat_pulse")


func _on_measure_completed(measure_number: int, measure_time: float):
	"""Handle measure completion"""
	if react_to_measure:
		# Stronger reaction for measures
		current_intensity = 1.5
		
		# Create a larger ripple effect
		_trigger_grid_ripple(screen_rect.size / 2, 2.0)
		
		emit_signal("effect_activated", "measure_pulse")


func _on_perfect_hit(accuracy: float, lane: int):
	"""Handle perfect hit event"""
	# Create localized effect based on lane
	var lane_x = screen_rect.size.x * (0.25 + lane * 0.25)
	var effect_pos = Vector2(lane_x, screen_rect.size.y * 0.75)
	
	_trigger_grid_ripple(effect_pos, 1.5)
	emit_signal("effect_activated", "perfect_hit")


func _on_combo_updated(combo: int):
	"""Handle combo update"""
	# Increase particle activity with combo
	if combo > 0 and combo % 5 == 0:
		_boost_particles(1.0 + combo * 0.1)


func _trigger_grid_ripple(origin: Vector2, intensity: float = 1.0):
	"""Trigger a ripple effect in the grid"""
	grid_ripple_origin = origin
	grid_ripple_active = true
	grid_ripple_timer = 0.0
	
	# Start ripple from origin
	for node in grid_nodes:
		var distance = node.position.distance_to(origin)
		node.pulse_timer = distance * grid_pulse_delay / 100.0
		node.pulse_active = true
		node.intensity = intensity


func _boost_particles(multiplier: float = 1.0):
	"""Boost particle velocities"""
	for particle in ambient_particles:
		# Add random burst velocity
		var burst_angle = randf() * TAU
		var burst_velocity = Vector2.from_angle(burst_angle) * particle_base_speed * particle_react_multiplier * multiplier
		particle.velocity = particle.base_velocity + burst_velocity


func _pulse_beat_markers(beat_number: int):
	"""Pulse beat markers on beat"""
	for marker in beat_markers:
		if marker.has_method("trigger_pulse"):
			marker.trigger_pulse()
		elif marker.has_method("scale"):
			# Simple scale animation
			var tween = create_tween()
			tween.tween_property(marker, "scale", Vector2.ONE * beat_marker_scale_multiplier, 0.1)
			tween.tween_property(marker, "scale", Vector2.ONE, 0.2)


func _process(delta: float):
	"""Update all visual effects"""
	# Update intensity decay
	current_intensity = max(0.0, current_intensity - delta * reaction_decay_speed)
	
	# Update border pulse
	if track_border_enabled:
		border_pulse_timer = max(0.0, border_pulse_timer - delta)
	
	# Update grid
	if background_enabled:
		_update_grid(delta)
	
	# Update particles
	if ambient_particles_enabled:
		_update_particles(delta)
	
	# Request redraw
	queue_redraw()


func _update_grid(delta: float):
	"""Update grid node states"""
	for node in grid_nodes:
		if node.pulse_active:
			if node.pulse_timer > 0:
				node.pulse_timer -= delta
			else:
				# Node is pulsing
				node.intensity = max(0.0, node.intensity - delta * 3.0)
				if node.intensity <= 0:
					node.pulse_active = false


func _update_particles(delta: float):
	"""Update particle positions and velocities"""
	for particle in ambient_particles:
		# Update position
		particle.position += particle.velocity * delta
		
		# Wrap around screen
		if particle.position.y < -50:
			particle.position.y = screen_rect.size.y + 50
		if particle.position.x < -50:
			particle.position.x = screen_rect.size.x + 50
		elif particle.position.x > screen_rect.size.x + 50:
			particle.position.x = -50
		
		# Gradually return to base velocity
		particle.velocity = particle.velocity.lerp(particle.base_velocity, delta * 2.0)


func _draw():
	"""Draw all environment effects"""
	# Draw background grid
	if background_enabled:
		_draw_grid()
	
	# Draw track borders
	if track_border_enabled and track_boundaries.size() > 0:
		_draw_track_borders()
	
	# Draw ambient particles
	if ambient_particles_enabled:
		_draw_particles()


func _draw_grid():
	"""Draw background grid with pulse effects"""
	for node in grid_nodes:
		var color = grid_base_color
		
		if node.pulse_active and node.pulse_timer <= 0:
			color = grid_base_color.lerp(grid_pulse_color, node.intensity)
		
		var size = background_grid_size * 0.1
		if node.intensity > 0:
			size *= 1.0 + node.intensity
		
		draw_circle(node.position, size, color)


func _draw_track_borders():
	"""Draw enhanced track borders"""
	if track_boundaries.size() < 2:
		return
	
	var color = border_base_color
	var width = border_width
	
	# Apply pulse effect
	if border_pulse_timer > 0:
		var pulse_progress = border_pulse_timer / 0.3  # 0.3 second pulse
		color = border_base_color.lerp(border_pulse_color, pulse_progress)
		width *= 1.0 + (border_pulse_intensity - 1.0) * pulse_progress
	
	# Draw track boundary lines
	var points = PackedVector2Array()
	for point in track_boundaries:
		points.append(to_local(point))
	
	if points.size() > 1:
		draw_polyline(points, color, width, true)


func _draw_particles():
	"""Draw ambient particles"""
	for particle in ambient_particles:
		var color = particle.color
		# Fade based on current intensity
		color.a = particle.color.a * (0.5 + 0.5 * current_intensity)
		
		draw_circle(particle.position, particle.size, color)


# Configuration methods
func set_track_boundaries(boundaries: Array[Vector2]):
	"""Set track boundary points"""
	track_boundaries = boundaries


func set_reaction_intensity(intensity: float):
	"""Set overall reaction intensity"""
	current_intensity = clamp(intensity, 0.0, 2.0)


func set_debug_logging(enabled: bool):
	"""Enable/disable debug logging"""
	_debug_logging = enabled


func reset():
	"""Reset all effects to default state"""
	current_intensity = 0.0
	border_pulse_timer = 0.0
	grid_ripple_active = false
	
	# Reset grid
	for node in grid_nodes:
		node.pulse_active = false
		node.intensity = 0.0
		node.pulse_timer = 0.0
	
	# Reset particles
	for particle in ambient_particles:
		particle.velocity = particle.base_velocity
	
	queue_redraw()