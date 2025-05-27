extends Node
class_name LaneAudioController

# Lane Audio Controller
# Connects lane detection to sound generation
# Manages smooth transitions between lane sounds

signal lane_sound_started(lane: int)
signal lane_sound_stopped(lane: int)
signal sound_transition_started(from_lane: int, to_lane: int)
signal sound_transition_completed(from_lane: int, to_lane: int)

# Lane configuration
@export var center_lane_silent: bool = true
@export var enable_transitions: bool = true
@export var transition_time: float = 0.2
@export var fade_curve: Curve

# Volume settings
@export var active_lane_volume: float = 1.0
@export var transition_volume_multiplier: float = 0.7

# Debug settings
@export var debug_logging: bool = false

# References
var lane_detection_system: LaneDetectionSystem
var lane_sound_system: LaneSoundSystem
var beat_manager: Node

# State tracking
var current_lane: int = -1
var previous_lane: int = -1
var is_transitioning: bool = false
var transition_timer: float = 0.0
var active_sounds: Dictionary = {}  # lane -> bool

# Volume management
var lane_volumes: Dictionary = {}  # lane -> current_volume
var target_volumes: Dictionary = {}  # lane -> target_volume


func _ready():
	_log("=== LaneAudioController Initialization ===")
	
	# Get beat manager reference
	beat_manager = get_node("/root/BeatManager") if has_node("/root/BeatManager") else null
	if not beat_manager:
		push_warning("BeatManager not found. Lane audio synchronization may not work properly.")
	
	# Initialize volume tracking
	for lane in range(3):
		lane_volumes[lane] = 0.0
		target_volumes[lane] = 0.0
		active_sounds[lane] = false
	
	# Create default fade curve if not set
	if not fade_curve:
		fade_curve = Curve.new()
		fade_curve.add_point(Vector2(0, 0))
		fade_curve.add_point(Vector2(0.2, 0.8))
		fade_curve.add_point(Vector2(0.8, 1.0))
		fade_curve.add_point(Vector2(1, 1))
	
	_log("LaneAudioController ready")
	_log("==============================")


func _log(message: String) -> void:
	if debug_logging:
		var timestamp = Time.get_time_string_from_system()
		print("[%s] LaneAudioController: %s" % [timestamp, message])


func setup(detection_system: LaneDetectionSystem, sound_system: LaneSoundSystem):
	"""Initialize the controller with required systems"""
	lane_detection_system = detection_system
	lane_sound_system = sound_system
	
	if not lane_detection_system or not lane_sound_system:
		push_error("LaneAudioController requires both LaneDetectionSystem and LaneSoundSystem")
		return
	
	# Connect to lane detection signals
	lane_detection_system.lane_changed.connect(_on_lane_changed)
	lane_detection_system.lane_position_updated.connect(_on_lane_position_updated)
	
	# Configure sound system
	lane_sound_system.stop_playback()
	lane_sound_system.set_volume(0.0)
	
	_log("Connected to LaneDetectionSystem and LaneSoundSystem")


func start_audio():
	"""Start the audio system"""
	if not lane_sound_system:
		push_error("Cannot start audio: LaneSoundSystem not connected")
		return
	
	lane_sound_system.start_playback()
	_log("Audio playback started")


func stop_audio():
	"""Stop all audio playback"""
	if not lane_sound_system:
		return
	
	lane_sound_system.stop_playback()
	
	# Reset all volumes
	for lane in lane_volumes:
		lane_volumes[lane] = 0.0
		target_volumes[lane] = 0.0
		active_sounds[lane] = false
	
	_log("Audio playback stopped")


func _on_lane_changed(from_lane: int, to_lane: int):
	"""Handle lane change events"""
	_log("Lane changed from %d to %d" % [from_lane, to_lane])
	
	previous_lane = from_lane
	current_lane = to_lane
	
	# Update target volumes
	_update_target_volumes()
	
	# Handle transitions
	if enable_transitions:
		_start_transition(from_lane, to_lane)
	else:
		_instant_lane_switch(to_lane)


func _on_lane_position_updated(lane: int, offset_from_center: float):
	"""Handle continuous lane position updates"""
	# Could be used for volume modulation based on lane position
	# For now, we'll keep it simple
	pass


func _update_target_volumes():
	"""Update target volumes based on current lane"""
	for lane in range(3):
		if lane == current_lane:
			# Check if center lane should be silent
			if lane == 1 and center_lane_silent:
				target_volumes[lane] = 0.0
			else:
				target_volumes[lane] = active_lane_volume
		else:
			target_volumes[lane] = 0.0


func _start_transition(from_lane: int, to_lane: int):
	"""Start a smooth transition between lanes"""
	is_transitioning = true
	transition_timer = 0.0
	
	emit_signal("sound_transition_started", from_lane, to_lane)
	_log("Starting transition from lane %d to %d" % [from_lane, to_lane])


func _instant_lane_switch(to_lane: int):
	"""Instantly switch to a new lane sound"""
	# Update volumes immediately
	for lane in lane_volumes:
		lane_volumes[lane] = target_volumes[lane]
	
	# Update sound system
	_apply_lane_volumes()
	
	# Switch active lane
	if to_lane >= 0 and to_lane < 3:
		if not (to_lane == 1 and center_lane_silent):
			lane_sound_system.set_current_lane(to_lane)
			emit_signal("lane_sound_started", to_lane)
		else:
			# Center lane is silent
			lane_sound_system.set_volume(0.0)
	
	if previous_lane >= 0 and previous_lane < 3:
		emit_signal("lane_sound_stopped", previous_lane)


func _process(delta: float):
	if not is_transitioning:
		return
	
	# Update transition
	transition_timer += delta
	var progress = min(transition_timer / transition_time, 1.0)
	
	# Apply fade curve
	var curved_progress = fade_curve.sample(progress) if fade_curve else progress
	
	# Interpolate volumes
	for lane in lane_volumes:
		var current = lane_volumes[lane]
		var target = target_volumes[lane]
		
		# During transition, apply multiplier
		if target > 0 and progress < 1.0:
			target *= transition_volume_multiplier
		
		lane_volumes[lane] = lerp(current, target, curved_progress)
	
	# Apply volumes
	_apply_lane_volumes()
	
	# Check if transition is complete
	if progress >= 1.0:
		_complete_transition()


func _apply_lane_volumes():
	"""Apply current volumes to the sound system"""
	if not lane_sound_system:
		return
	
	# For now, we control the overall volume based on active lane
	# In a more complex system, we might mix multiple lanes
	if current_lane >= 0 and current_lane < 3:
		var volume = lane_volumes[current_lane]
		lane_sound_system.set_volume(volume)
		
		# Update active sounds tracking
		for lane in active_sounds:
			active_sounds[lane] = lane_volumes[lane] > 0.01


func _complete_transition():
	"""Complete the current transition"""
	is_transitioning = false
	transition_timer = 0.0
	
	# Ensure we're on the correct lane
	if current_lane >= 0 and current_lane < 3:
		if not (current_lane == 1 and center_lane_silent):
			lane_sound_system.set_current_lane(current_lane)
	
	emit_signal("sound_transition_completed", previous_lane, current_lane)
	_log("Transition completed")


# Configuration methods
func set_center_lane_silent(silent: bool):
	center_lane_silent = silent
	_update_target_volumes()


func set_transition_enabled(enabled: bool):
	enable_transitions = enabled


func set_transition_time(time: float):
	transition_time = max(0.01, time)


func set_active_lane_volume(volume: float):
	active_lane_volume = clamp(volume, 0.0, 1.0)
	_update_target_volumes()


# Utility methods
func get_active_lane() -> int:
	return current_lane


func is_lane_active(lane: int) -> bool:
	return active_sounds.get(lane, false)


func get_lane_volume(lane: int) -> float:
	return lane_volumes.get(lane, 0.0)


func force_lane(lane: int):
	"""Force immediate switch to a specific lane (for testing)"""
	_on_lane_changed(current_lane, lane)