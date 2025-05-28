extends Node2D
class_name LaneSoundVisualizer

# Lane Sound Visualizer
# Creates visual effects for each lane that respond to sound activity
# Shows waveforms, pulses, and particle effects based on lane audio

signal lane_activated(lane: int, intensity: float)
signal lane_deactivated(lane: int)

@export_group("Lane Configuration")
@export var lane_count: int = 3
@export var lane_width: float = 150.0
@export var lane_spacing: float = 200.0
@export var center_lane_offset: Vector2 = Vector2.ZERO

@export_group("Visual Effects")
@export var waveform_enabled: bool = true
@export var waveform_height: float = 50.0
@export var waveform_resolution: int = 32
@export var waveform_color: Color = Color(0.3, 0.8, 1.0, 0.8)

@export var particle_enabled: bool = true
@export var particles_per_lane: int = 50
@export var particle_lifetime: float = 2.0
@export var particle_speed: float = 100.0

@export var glow_enabled: bool = true
@export var glow_radius: float = 80.0
@export var glow_intensity: float = 1.5

@export_group("Lane Colors")
@export var left_lane_color: Color = Color(1.0, 0.3, 0.3, 0.8)  # Red
@export var center_lane_color: Color = Color(0.3, 1.0, 0.3, 0.8)  # Green
@export var right_lane_color: Color = Color(0.3, 0.3, 1.0, 0.8)  # Blue

@export_group("Animation")
@export var fade_in_time: float = 0.1
@export var fade_out_time: float = 0.5
@export var pulse_on_activation: bool = true
@export var reactive_to_volume: bool = true

# Lane state
class LaneVisualState:
	var active: bool = false
	var intensity: float = 0.0
	var fade_timer: float = 0.0
	var waveform_phase: float = 0.0
	var particles: Array[Node2D] = []
	var color: Color
	var position: Vector2
	var glow_alpha: float = 0.0

var lane_states: Array[LaneVisualState] = []
var lane_sound_system: LaneSoundSystem = null
var lane_audio_controller: LaneAudioController = null
var beat_manager: Node = null

# Waveform data
var waveform_points: Array[float] = []
var waveform_update_timer: float = 0.0
var waveform_update_rate: float = 0.016  # 60 FPS

# Debug
var _debug_logging: bool = false


func _ready():
	_log("=== LaneSoundVisualizer Initialization ===")
	
	# Initialize lane states
	_initialize_lanes()
	
	# Get references
	_find_audio_systems()
	
	# Initialize waveform data
	waveform_points.resize(waveform_resolution)
	for i in waveform_resolution:
		waveform_points[i] = 0.0
	
	# Create particle pools
	if particle_enabled:
		_create_particle_pools()
	
	_log("LaneSoundVisualizer ready with %d lanes" % lane_count)
	_log("==========================================")


func _log(message: String) -> void:
	if _debug_logging:
		var timestamp = Time.get_time_string_from_system()
		print("[%s] LaneSoundVisualizer: %s" % [timestamp, message])


func _initialize_lanes():
	"""Initialize visual state for each lane"""
	lane_states.clear()
	
	var colors = [left_lane_color, center_lane_color, right_lane_color]
	
	for i in lane_count:
		var state = LaneVisualState.new()
		state.color = colors[i % colors.size()]
		
		# Calculate lane position
		var lane_offset = (i - lane_count / 2.0 + 0.5) * lane_spacing
		state.position = center_lane_offset + Vector2(lane_offset, 0)
		
		lane_states.append(state)


func _find_audio_systems():
	"""Find audio system references in the scene"""
	# Look for LaneSoundSystem
	var systems = get_tree().get_nodes_in_group("lane_sound_system")
	if systems.size() > 0:
		lane_sound_system = systems[0]
		_connect_sound_system()
	
	# Look for LaneAudioController
	var controllers = get_tree().get_nodes_in_group("lane_audio_controller")
	if controllers.size() > 0:
		lane_audio_controller = controllers[0]
		_connect_audio_controller()
	
	# Get BeatManager
	beat_manager = get_node("/root/BeatManager") if has_node("/root/BeatManager") else null


func _connect_sound_system():
	"""Connect to lane sound system signals"""
	if lane_sound_system:
		# Listen for lane activation
		if lane_sound_system.has_signal("lane_started"):
			lane_sound_system.lane_started.connect(_on_lane_sound_started)
		if lane_sound_system.has_signal("lane_stopped"):
			lane_sound_system.lane_stopped.connect(_on_lane_sound_stopped)
		
		_log("Connected to LaneSoundSystem")


func _connect_audio_controller():
	"""Connect to lane audio controller signals"""
	if lane_audio_controller:
		# Listen for volume changes
		if lane_audio_controller.has_signal("lane_volume_changed"):
			lane_audio_controller.lane_volume_changed.connect(_on_lane_volume_changed)
		
		_log("Connected to LaneAudioController")


func _create_particle_pools():
	"""Create particle pools for each lane"""
	for lane_state in lane_states:
		for i in particles_per_lane:
			var particle = _create_particle()
			particle.visible = false
			add_child(particle)
			lane_state.particles.append(particle)


func _create_particle() -> Node2D:
	"""Create a single particle node"""
	var particle = Node2D.new()
	return particle


func activate_lane(lane: int, intensity: float = 1.0):
	"""Activate visual effects for a lane"""
	if lane < 0 or lane >= lane_states.size():
		return
	
	var state = lane_states[lane]
	state.active = true
	state.intensity = clamp(intensity, 0.0, 1.0)
	state.fade_timer = 0.0
	
	if pulse_on_activation:
		_trigger_lane_pulse(lane)
	
	emit_signal("lane_activated", lane, intensity)
	_log("Lane %d activated with intensity %.2f" % [lane, intensity])


func deactivate_lane(lane: int):
	"""Deactivate visual effects for a lane"""
	if lane < 0 or lane >= lane_states.size():
		return
	
	var state = lane_states[lane]
	state.active = false
	
	emit_signal("lane_deactivated", lane)
	_log("Lane %d deactivated" % lane)


func _on_lane_sound_started(lane: int):
	"""Handle lane sound start"""
	activate_lane(lane)


func _on_lane_sound_stopped(lane: int):
	"""Handle lane sound stop"""
	deactivate_lane(lane)


func _on_lane_volume_changed(lane: int, volume: float):
	"""Handle lane volume change"""
	if reactive_to_volume and lane >= 0 and lane < lane_states.size():
		lane_states[lane].intensity = volume


func _trigger_lane_pulse(lane: int):
	"""Trigger a pulse effect for a lane"""
	# Could emit particles or create a pulse animation
	if particle_enabled and lane < lane_states.size():
		_emit_lane_particles(lane)


func _emit_lane_particles(lane: int):
	"""Emit particles for a lane"""
	var state = lane_states[lane]
	var available_particles = []
	
	# Find available particles
	for particle in state.particles:
		if not particle.visible:
			available_particles.append(particle)
	
	# Emit particles
	var emit_count = min(10, available_particles.size())
	for i in emit_count:
		var particle = available_particles[i]
		_launch_particle(particle, state)


func _launch_particle(particle: Node2D, state: LaneVisualState):
	"""Launch a single particle"""
	particle.visible = true
	particle.global_position = global_position + state.position
	particle.modulate = state.color
	
	# Random direction (mostly upward)
	var angle = randf_range(-PI/4, PI/4) - PI/2
	var velocity = Vector2.from_angle(angle) * particle_speed
	
	# Animate particle
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(particle, "position", particle.position + velocity * particle_lifetime, particle_lifetime)
	tween.tween_property(particle, "modulate:a", 0.0, particle_lifetime)
	tween.chain().tween_callback(_hide_particle.bind(particle))


func _hide_particle(particle: Node2D):
	"""Hide particle after animation"""
	particle.visible = false
	particle.modulate.a = 1.0


func _process(delta: float):
	"""Update visual effects"""
	# Update lane states
	for i in lane_states.size():
		_update_lane_state(i, delta)
	
	# Update waveform
	if waveform_enabled:
		_update_waveform(delta)
	
	# Request redraw
	queue_redraw()


func _update_lane_state(lane: int, delta: float):
	"""Update individual lane state"""
	var state = lane_states[lane]
	
	if state.active:
		# Fade in
		state.fade_timer = min(state.fade_timer + delta, fade_in_time)
		state.glow_alpha = state.fade_timer / fade_in_time * state.intensity
		
		# Update waveform phase
		state.waveform_phase += delta * 10.0 * state.intensity
	else:
		# Fade out
		state.fade_timer = max(state.fade_timer - delta, 0.0)
		state.glow_alpha = state.fade_timer / fade_in_time * state.intensity


func _update_waveform(delta: float):
	"""Update waveform visualization data"""
	waveform_update_timer += delta
	
	if waveform_update_timer >= waveform_update_rate:
		waveform_update_timer = 0.0
		
		# Generate waveform data based on active lanes
		for i in waveform_resolution:
			var value = 0.0
			
			# Add contribution from each active lane
			for lane_idx in lane_states.size():
				var state = lane_states[lane_idx]
				if state.active:
					# Create different waveforms for each lane
					var phase = state.waveform_phase + (float(i) / float(waveform_resolution)) * TAU
					
					match lane_idx:
						0:  # Left lane - sine wave
							value += sin(phase) * state.intensity
						1:  # Center lane - square wave
							value += sign(sin(phase * 2)) * state.intensity * 0.8
						2:  # Right lane - triangle wave
							value += (2.0 / PI) * asin(sin(phase * 3)) * state.intensity * 0.6
			
			waveform_points[i] = value


func _draw():
	"""Draw visual effects"""
	for i in lane_states.size():
		_draw_lane_effects(i)


func _draw_lane_effects(lane: int):
	"""Draw effects for a single lane"""
	var state = lane_states[lane]
	
	if state.glow_alpha <= 0:
		return
	
	var base_pos = state.position
	
	# Draw glow
	if glow_enabled:
		var glow_color = state.color
		glow_color.a = state.glow_alpha * 0.3
		
		for i in range(3):
			var radius = glow_radius * (i + 1) / 3.0 * state.intensity
			glow_color.a *= 0.5
			draw_circle(base_pos, radius, glow_color)
	
	# Draw waveform
	if waveform_enabled and state.active:
		_draw_lane_waveform(lane, base_pos)


func _draw_lane_waveform(lane: int, base_pos: Vector2):
	"""Draw waveform for a lane"""
	var state = lane_states[lane]
	var points = PackedVector2Array()
	
	var width = lane_width
	var step = width / float(waveform_resolution - 1)
	
	# Create waveform points
	for i in waveform_resolution:
		var x = base_pos.x - width/2 + i * step
		var y = base_pos.y + waveform_points[i] * waveform_height * state.glow_alpha
		points.append(Vector2(x, y))
	
	# Draw waveform line
	if points.size() > 1:
		var color = state.color
		color.a = state.glow_alpha
		draw_polyline(points, color, 2.0, true)


# Configuration methods
func set_lane_count(count: int):
	"""Set number of lanes"""
	lane_count = max(1, count)
	_initialize_lanes()
	if particle_enabled:
		_create_particle_pools()


func set_lane_color(lane: int, color: Color):
	"""Set color for a specific lane"""
	if lane >= 0 and lane < lane_states.size():
		lane_states[lane].color = color


func set_debug_logging(enabled: bool):
	"""Enable/disable debug logging"""
	_debug_logging = enabled


func get_lane_intensity(lane: int) -> float:
	"""Get current intensity of a lane"""
	if lane >= 0 and lane < lane_states.size():
		return lane_states[lane].intensity
	return 0.0


func reset():
	"""Reset all visual effects"""
	for state in lane_states:
		state.active = false
		state.intensity = 0.0
		state.fade_timer = 0.0
		state.waveform_phase = 0.0
		state.glow_alpha = 0.0
		
		# Hide all particles
		for particle in state.particles:
			particle.visible = false
	
	# Reset waveform
	for i in waveform_resolution:
		waveform_points[i] = 0.0
	
	queue_redraw()