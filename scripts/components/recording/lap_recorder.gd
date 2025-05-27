extends Node
class_name LapRecorder

# Lap Recording System
# Records vehicle position and lane data during a lap
# Stores the data for later playback

signal recording_started()
signal recording_stopped()
signal lap_completed(lap_data: LapRecording)
signal position_sampled(sample: PositionSample)
signal recording_state_changed(is_recording: bool)

# Recording settings
@export var sample_rate: float = 30.0  # Samples per second
@export var min_lap_time: float = 5.0  # Minimum time for valid lap
@export var max_recording_time: float = 300.0  # Maximum recording time (5 minutes)
@export var store_velocity: bool = true  # Store velocity data
@export var store_rotation: bool = true  # Store rotation data

# Debug settings
@export var debug_logging: bool = false
@export var show_sample_points: bool = false

# References
var vehicle_reference: Node2D
var lane_detection_system: LaneDetectionSystem
var track_system: Node2D
var beat_manager: Node

# Recording state
var is_recording: bool = false
var current_recording: LapRecording
var sample_timer: float = 0.0
var recording_start_time: float = 0.0
var lap_start_position: Vector2
var has_crossed_start_line: bool = false

# Lap detection
var start_line_crossed_count: int = 0
var last_track_progress: float = 0.0

# Sample visualization (debug)
var sample_markers: Array[Node2D] = []


func _ready():
	_log("=== LapRecorder Initialization ===")
	
	# Get beat manager reference
	beat_manager = get_node("/root/BeatManager") if has_node("/root/BeatManager") else null
	if not beat_manager:
		push_warning("BeatManager not found. Lap recordings won't be beat-aligned.")
	
	# Calculate sample interval
	var sample_interval = 1.0 / sample_rate
	_log("Sample rate: %.1f Hz (interval: %.3f sec)" % [sample_rate, sample_interval])
	
	_log("LapRecorder ready")
	_log("===============================")


func _log(message: String) -> void:
	if debug_logging:
		var timestamp = Time.get_time_string_from_system()
		print("[%s] LapRecorder: %s" % [timestamp, message])


func setup(vehicle: Node2D, lane_detection: LaneDetectionSystem, track: Node2D):
	"""Initialize the recorder with required references"""
	vehicle_reference = vehicle
	lane_detection_system = lane_detection
	track_system = track
	
	if not vehicle_reference:
		push_error("LapRecorder requires a vehicle reference")
		return
	
	if not track_system:
		push_error("LapRecorder requires a track system reference")
		return
	
	# Connect to track signals if available
	if track_system.has_signal("lap_completed"):
		track_system.lap_completed.connect(_on_lap_completed)
		_log("Connected to track lap detection")
	
	# Connect to vehicle signals if rhythm vehicle
	if vehicle_reference.has_signal("crossed_start_line"):
		vehicle_reference.crossed_start_line.connect(_on_crossed_start_line)
		_log("Connected to vehicle start line detection")
	
	_log("Setup complete with vehicle and track references")


func start_recording():
	"""Start recording vehicle position data"""
	if is_recording:
		push_warning("Recording already in progress")
		return
	
	if not vehicle_reference:
		push_error("Cannot start recording without vehicle reference")
		return
	
	# Create new recording
	current_recording = LapRecording.new()
	current_recording.start_time = Time.get_ticks_msec() / 1000.0
	
	# Store metadata
	if beat_manager:
		current_recording.bpm = beat_manager.bpm
		current_recording.beats_per_measure = beat_manager.beats_per_measure
		current_recording.start_beat = beat_manager.total_beats
	
	# Initialize recording state
	is_recording = true
	sample_timer = 0.0
	recording_start_time = Time.get_ticks_msec() / 1000.0
	lap_start_position = vehicle_reference.global_position
	has_crossed_start_line = false
	start_line_crossed_count = 0
	last_track_progress = 0.0
	
	# Clear debug markers
	_clear_sample_markers()
	
	# Take first sample immediately
	_sample_position()
	
	emit_signal("recording_started")
	emit_signal("recording_state_changed", true)
	_log("Recording started at position: %s" % lap_start_position)


func stop_recording() -> LapRecording:
	"""Stop recording and return the recorded data"""
	if not is_recording:
		push_warning("No recording in progress")
		return null
	
	is_recording = false
	
	# Finalize recording
	current_recording.end_time = Time.get_ticks_msec() / 1000.0
	current_recording.duration = current_recording.end_time - current_recording.start_time
	current_recording.total_samples = current_recording.position_samples.size()
	
	# Validate recording
	if current_recording.duration < min_lap_time:
		push_warning("Recording too short (%.1fs < %.1fs minimum)" % [current_recording.duration, min_lap_time])
		current_recording.is_valid = false
	
	var result = current_recording
	current_recording = null
	
	emit_signal("recording_stopped")
	emit_signal("recording_state_changed", false)
	_log("Recording stopped. Duration: %.1fs, Samples: %d" % [result.duration, result.total_samples])
	
	return result


func pause_recording():
	"""Temporarily pause recording"""
	if is_recording and current_recording:
		is_recording = false
		_log("Recording paused")


func resume_recording():
	"""Resume a paused recording"""
	if not is_recording and current_recording:
		is_recording = true
		_log("Recording resumed")


func cancel_recording():
	"""Cancel current recording without saving"""
	if is_recording or current_recording:
		is_recording = false
		current_recording = null
		_clear_sample_markers()
		
		emit_signal("recording_stopped")
		emit_signal("recording_state_changed", false)
		_log("Recording cancelled")


func _process(delta: float):
	if not is_recording or not current_recording:
		return
	
	# Check maximum recording time
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - recording_start_time > max_recording_time:
		_log("Maximum recording time reached")
		stop_recording()
		return
	
	# Sample at specified rate
	sample_timer += delta
	var sample_interval = 1.0 / sample_rate
	
	while sample_timer >= sample_interval:
		sample_timer -= sample_interval
		_sample_position()
	
	# Check for lap completion (if no external detection)
	if track_system and track_system.has_method("get_track_progress_at_position"):
		_check_lap_completion()


func _sample_position():
	"""Take a position sample"""
	if not vehicle_reference:
		return
	
	var sample = PositionSample.new()
	
	# Basic position data
	sample.timestamp = Time.get_ticks_msec() / 1000.0 - current_recording.start_time
	sample.position = vehicle_reference.global_position
	
	# Velocity data
	if store_velocity and vehicle_reference.has_method("get_linear_velocity"):
		sample.velocity = vehicle_reference.get_linear_velocity()
	elif store_velocity and vehicle_reference.has_method("get_velocity"):
		sample.velocity = vehicle_reference.get_velocity()
	
	# Rotation data
	if store_rotation:
		sample.rotation = vehicle_reference.rotation
	
	# Lane data
	if lane_detection_system:
		var lane_info = lane_detection_system.get_lane_info()
		sample.lane = lane_info.get("current_lane", -1)
		sample.lane_offset = lane_info.get("offset_from_center", 0.0)
	
	# Beat alignment data
	if beat_manager:
		sample.beat_number = beat_manager.total_beats
		sample.beat_progress = beat_manager.get_beat_progress()
	
	# Track progress
	if track_system and track_system.has_method("get_track_progress_at_position"):
		sample.track_progress = track_system.get_track_progress_at_position(sample.position)
	
	# Add sample to recording
	current_recording.position_samples.append(sample)
	
	# Debug visualization
	if show_sample_points:
		_create_sample_marker(sample.position)
	
	emit_signal("position_sampled", sample)


func _check_lap_completion():
	"""Check if vehicle has completed a lap"""
	if not track_system or not track_system.has_method("get_track_progress_at_position"):
		return
	
	var current_progress = track_system.get_track_progress_at_position(vehicle_reference.global_position)
	
	# Detect crossing start/finish line (progress wraps from ~1.0 to ~0.0)
	if last_track_progress > 0.9 and current_progress < 0.1:
		start_line_crossed_count += 1
		_log("Crossed start/finish line (count: %d)" % start_line_crossed_count)
		
		# Complete lap on second crossing (first crossing starts the lap)
		if start_line_crossed_count > 1:
			_complete_lap()
	
	last_track_progress = current_progress


func _on_lap_completed():
	"""Handle external lap completion signal"""
	if is_recording:
		_complete_lap()


func _on_crossed_start_line():
	"""Handle vehicle crossing start line"""
	if is_recording:
		has_crossed_start_line = true
		start_line_crossed_count += 1
		
		if start_line_crossed_count > 1:
			_complete_lap()


func _complete_lap():
	"""Complete the current lap recording"""
	if not is_recording or not current_recording:
		return
	
	# Mark as complete lap
	current_recording.is_complete_lap = true
	
	# Stop and emit
	var completed_recording = stop_recording()
	emit_signal("lap_completed", completed_recording)
	
	_log("Lap completed! Duration: %.1fs" % completed_recording.duration)


func _create_sample_marker(position: Vector2):
	"""Create visual marker for sample point (debug)"""
	var marker = Node2D.new()
	marker.position = position
	marker.z_index = 100
	
	# Custom draw
	marker.set_script(preload("res://scripts/components/recording/sample_marker.gd"))
	
	get_tree().current_scene.add_child(marker)
	sample_markers.append(marker)


func _clear_sample_markers():
	"""Remove all sample markers"""
	for marker in sample_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	sample_markers.clear()


# Utility methods
func get_recording_duration() -> float:
	"""Get current recording duration"""
	if not is_recording or not current_recording:
		return 0.0
	
	return Time.get_ticks_msec() / 1000.0 - current_recording.start_time


func get_sample_count() -> int:
	"""Get number of samples in current recording"""
	if not current_recording:
		return 0
	
	return current_recording.position_samples.size()


func get_recording_progress() -> float:
	"""Get recording progress (0.0 to 1.0)"""
	if not is_recording or not current_recording:
		return 0.0
	
	var duration = get_recording_duration()
	return min(duration / max_recording_time, 1.0)


func is_recording_active() -> bool:
	"""Check if currently recording"""
	return is_recording


# Inner classes
class LapRecording extends Resource:
	"""Contains all data for a recorded lap"""
	@export var position_samples: Array[PositionSample] = []
	@export var start_time: float = 0.0
	@export var end_time: float = 0.0
	@export var duration: float = 0.0
	@export var total_samples: int = 0
	@export var is_complete_lap: bool = false
	@export var is_valid: bool = true
	
	# Metadata
	@export var bpm: float = 120.0
	@export var beats_per_measure: int = 4
	@export var start_beat: int = 0
	
	func get_sample_at_time(time: float) -> PositionSample:
		"""Get interpolated sample at specific time"""
		if position_samples.is_empty():
			return null
		
		# Find surrounding samples
		var prev_sample: PositionSample = null
		var next_sample: PositionSample = null
		
		for sample in position_samples:
			if sample.timestamp <= time:
				prev_sample = sample
			else:
				next_sample = sample
				break
		
		# Return exact or interpolated sample
		if not next_sample:
			return prev_sample
		if not prev_sample:
			return next_sample
		
		# Interpolate between samples
		var t = (time - prev_sample.timestamp) / (next_sample.timestamp - prev_sample.timestamp)
		return PositionSample.interpolate(prev_sample, next_sample, t)


class PositionSample extends Resource:
	"""Single position sample in a recording"""
	@export var timestamp: float = 0.0
	@export var position: Vector2 = Vector2.ZERO
	@export var velocity: Vector2 = Vector2.ZERO
	@export var rotation: float = 0.0
	@export var lane: int = -1
	@export var lane_offset: float = 0.0
	@export var beat_number: int = 0
	@export var beat_progress: float = 0.0
	@export var track_progress: float = 0.0
	
	static func interpolate(a: PositionSample, b: PositionSample, t: float) -> PositionSample:
		"""Interpolate between two samples"""
		var result = PositionSample.new()
		result.timestamp = lerp(a.timestamp, b.timestamp, t)
		result.position = a.position.lerp(b.position, t)
		result.velocity = a.velocity.lerp(b.velocity, t)
		result.rotation = lerp_angle(a.rotation, b.rotation, t)
		result.lane_offset = lerp(a.lane_offset, b.lane_offset, t)
		result.beat_progress = lerp(a.beat_progress, b.beat_progress, t)
		result.track_progress = lerp(a.track_progress, b.track_progress, t)
		
		# Use nearest for discrete values
		result.lane = b.lane if t > 0.5 else a.lane
		result.beat_number = b.beat_number if t > 0.5 else a.beat_number
		
		return result