extends Node
class_name PathPlayer

# Path Player System
# Plays back recorded lap data by interpolating position samples
# Supports looping and playback control

signal playback_started()
signal playback_stopped()
signal playback_paused()
signal playback_resumed()
signal playback_completed()
signal loop_completed(loop_count: int)
signal position_updated(position: Vector2, rotation: float, lane: int)
signal beat_synchronized(beat_number: int)

# Playback settings
@export var playback_speed: float = 1.0  # Playback speed multiplier
@export var loop_enabled: bool = true  # Enable automatic looping
@export var max_loops: int = 0  # 0 = infinite loops
@export var interpolation_mode: InterpolationMode = InterpolationMode.LINEAR
@export var sync_to_beat: bool = true  # Sync playback start to beat

# Debug settings
@export var debug_logging: bool = false
@export var show_path_preview: bool = false

# Playback state
enum PlaybackState { STOPPED, PLAYING, PAUSED, WAITING_FOR_BEAT }
var current_state: PlaybackState = PlaybackState.STOPPED
var current_recording: LapRecorder.LapRecording
var playback_time: float = 0.0
var loop_count: int = 0
var current_sample_index: int = 0

# References
var beat_manager: Node

# Interpolation modes
enum InterpolationMode { LINEAR, CUBIC, NEAREST }


func _ready():
	_log("=== PathPlayer Initialization ===")
	
	# Get beat manager reference
	beat_manager = get_node("/root/BeatManager") if has_node("/root/BeatManager") else null
	if not beat_manager:
		push_warning("BeatManager not found. Beat synchronization disabled.")
		sync_to_beat = false
	
	set_process(false)  # Only process when playing
	_log("PathPlayer ready")
	_log("==============================")


func _log(message: String) -> void:
	if debug_logging:
		var timestamp = Time.get_time_string_from_system()
		print("[%s] PathPlayer: %s" % [timestamp, message])


func load_recording(recording: LapRecorder.LapRecording) -> bool:
	"""Load a lap recording for playback"""
	if not recording or recording.position_samples.is_empty():
		push_error("Invalid or empty recording")
		return false
	
	if not recording.is_valid:
		push_warning("Recording marked as invalid")
	
	current_recording = recording
	_reset_playback()
	
	_log("Loaded recording: Duration=%.1fs, Samples=%d, BPM=%.0f" % [
		recording.duration,
		recording.total_samples,
		recording.bpm
	])
	
	if show_path_preview:
		_draw_path_preview()
	
	return true


func start_playback():
	"""Start or resume playback"""
	if not current_recording:
		push_error("No recording loaded")
		return
	
	match current_state:
		PlaybackState.STOPPED:
			if sync_to_beat and beat_manager:
				_wait_for_next_beat()
			else:
				_start_playback_immediate()
		
		PlaybackState.PAUSED:
			_resume_playback()
		
		PlaybackState.PLAYING:
			push_warning("Playback already in progress")
		
		PlaybackState.WAITING_FOR_BEAT:
			push_warning("Already waiting for beat sync")


func stop_playback():
	"""Stop playback and reset"""
	if current_state == PlaybackState.STOPPED:
		return
	
	current_state = PlaybackState.STOPPED
	set_process(false)
	_reset_playback()
	
	emit_signal("playback_stopped")
	_log("Playback stopped")


func pause_playback():
	"""Pause playback at current position"""
	if current_state != PlaybackState.PLAYING:
		push_warning("Cannot pause - not playing")
		return
	
	current_state = PlaybackState.PAUSED
	set_process(false)
	
	emit_signal("playback_paused")
	_log("Playback paused at %.1fs" % playback_time)


func _resume_playback():
	"""Resume from paused state"""
	current_state = PlaybackState.PLAYING
	set_process(true)
	
	emit_signal("playback_resumed")
	_log("Playback resumed")


func _wait_for_next_beat():
	"""Wait for next beat before starting playback"""
	current_state = PlaybackState.WAITING_FOR_BEAT
	
	if beat_manager and not beat_manager.beat_occurred.is_connected(_on_beat_sync):
		beat_manager.beat_occurred.connect(_on_beat_sync, CONNECT_ONE_SHOT)
	
	_log("Waiting for beat sync...")


func _on_beat_sync(_beat_count: int, _beat_time: float):
	"""Start playback on beat"""
	if current_state == PlaybackState.WAITING_FOR_BEAT:
		_start_playback_immediate()


func _start_playback_immediate():
	"""Start playback immediately"""
	current_state = PlaybackState.PLAYING
	set_process(true)
	
	emit_signal("playback_started")
	_log("Playback started")


func _reset_playback():
	"""Reset playback state"""
	playback_time = 0.0
	loop_count = 0
	current_sample_index = 0


func _process(delta: float):
	if current_state != PlaybackState.PLAYING or not current_recording:
		return
	
	# Update playback time
	playback_time += delta * playback_speed
	
	# Check for loop or completion
	if playback_time >= current_recording.duration:
		if loop_enabled and (max_loops == 0 or loop_count < max_loops - 1):
			_handle_loop()
		else:
			_handle_completion()
		return
	
	# Get interpolated position
	var sample = _get_interpolated_sample(playback_time)
	if sample:
		emit_signal("position_updated", sample.position, sample.rotation, sample.lane)
		
		# Check for beat synchronization
		if sync_to_beat and beat_manager:
			var current_beat = beat_manager.total_beats
			var last_sample_beat = _get_sample_at_index(max(0, current_sample_index - 1)).beat_number
			if current_beat > last_sample_beat:
				emit_signal("beat_synchronized", current_beat)


func _get_interpolated_sample(time: float) -> LapRecorder.PositionSample:
	"""Get interpolated sample at current time"""
	if not current_recording or current_recording.position_samples.is_empty():
		return null
	
	# Find surrounding samples
	var samples = current_recording.position_samples
	var prev_index = -1
	var next_index = -1
	
	# Start search from current index for efficiency
	for i in range(current_sample_index, samples.size()):
		if samples[i].timestamp <= time:
			prev_index = i
			current_sample_index = i
		else:
			next_index = i
			break
	
	# Handle edge cases
	if prev_index == -1:
		return samples[0]
	if next_index == -1:
		return samples[prev_index]
	
	# Interpolate based on mode
	var prev_sample = samples[prev_index]
	var next_sample = samples[next_index]
	var t = (time - prev_sample.timestamp) / (next_sample.timestamp - prev_sample.timestamp)
	
	match interpolation_mode:
		InterpolationMode.LINEAR:
			return LapRecorder.PositionSample.interpolate(prev_sample, next_sample, t)
		InterpolationMode.CUBIC:
			return _cubic_interpolate_samples(prev_index, next_index, t)
		InterpolationMode.NEAREST:
			return next_sample if t > 0.5 else prev_sample
	
	return prev_sample


func _cubic_interpolate_samples(prev_idx: int, next_idx: int, t: float) -> LapRecorder.PositionSample:
	"""Perform cubic interpolation between samples"""
	var samples = current_recording.position_samples
	var p1 = samples[prev_idx]
	var p2 = samples[next_idx]
	
	# Get additional points for cubic interpolation
	var p0 = samples[max(0, prev_idx - 1)]
	var p3 = samples[min(samples.size() - 1, next_idx + 1)]
	
	# Cubic interpolation
	var result = LapRecorder.PositionSample.new()
	result.timestamp = lerp(p1.timestamp, p2.timestamp, t)
	result.position = _cubic_interpolate_vector2(p0.position, p1.position, p2.position, p3.position, t)
	result.velocity = _cubic_interpolate_vector2(p0.velocity, p1.velocity, p2.velocity, p3.velocity, t)
	result.rotation = _cubic_interpolate_angle(p0.rotation, p1.rotation, p2.rotation, p3.rotation, t)
	result.lane_offset = _cubic_interpolate_float(p0.lane_offset, p1.lane_offset, p2.lane_offset, p3.lane_offset, t)
	
	# Use linear for other properties
	result.beat_progress = lerp(p1.beat_progress, p2.beat_progress, t)
	result.track_progress = lerp(p1.track_progress, p2.track_progress, t)
	result.lane = p2.lane if t > 0.5 else p1.lane
	result.beat_number = p2.beat_number if t > 0.5 else p1.beat_number
	
	return result


func _cubic_interpolate_vector2(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	"""Catmull-Rom cubic interpolation for Vector2"""
	var t2 = t * t
	var t3 = t2 * t
	
	return 0.5 * (
		2.0 * p1 +
		(-p0 + p2) * t +
		(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
		(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)


func _cubic_interpolate_float(p0: float, p1: float, p2: float, p3: float, t: float) -> float:
	"""Catmull-Rom cubic interpolation for float"""
	var t2 = t * t
	var t3 = t2 * t
	
	return 0.5 * (
		2.0 * p1 +
		(-p0 + p2) * t +
		(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
		(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)


func _cubic_interpolate_angle(a0: float, a1: float, a2: float, a3: float, t: float) -> float:
	"""Cubic interpolation for angles with wrapping"""
	# Convert to vectors to handle angle wrapping
	var v0 = Vector2.from_angle(a0)
	var v1 = Vector2.from_angle(a1)
	var v2 = Vector2.from_angle(a2)
	var v3 = Vector2.from_angle(a3)
	
	var result = _cubic_interpolate_vector2(v0, v1, v2, v3, t)
	return result.angle()


func _handle_loop():
	"""Handle loop completion"""
	loop_count += 1
	playback_time = 0.0
	current_sample_index = 0
	
	emit_signal("loop_completed", loop_count)
	_log("Loop %d completed" % loop_count)


func _handle_completion():
	"""Handle playback completion"""
	current_state = PlaybackState.STOPPED
	set_process(false)
	
	emit_signal("playback_completed")
	_log("Playback completed after %d loops" % (loop_count + 1))


func _get_sample_at_index(index: int) -> LapRecorder.PositionSample:
	"""Get sample at specific index with bounds checking"""
	if not current_recording or current_recording.position_samples.is_empty():
		return null
	
	index = clamp(index, 0, current_recording.position_samples.size() - 1)
	return current_recording.position_samples[index]


func _draw_path_preview():
	"""Draw preview of recorded path (debug)"""
	# This would create line renderers or other visual elements
	# Implementation depends on specific visual requirements
	pass


# Utility methods
func get_playback_progress() -> float:
	"""Get current playback progress (0.0 to 1.0)"""
	if not current_recording:
		return 0.0
	
	return playback_time / current_recording.duration


func get_current_position() -> Vector2:
	"""Get current interpolated position"""
	var sample = _get_interpolated_sample(playback_time)
	return sample.position if sample else Vector2.ZERO


func get_current_lane() -> int:
	"""Get current lane"""
	var sample = _get_interpolated_sample(playback_time)
	return sample.lane if sample else -1


func is_playing() -> bool:
	"""Check if currently playing"""
	return current_state == PlaybackState.PLAYING


func is_paused() -> bool:
	"""Check if paused"""
	return current_state == PlaybackState.PAUSED


func set_playback_time(time: float):
	"""Seek to specific time"""
	if not current_recording:
		return
	
	playback_time = clamp(time, 0.0, current_recording.duration)
	current_sample_index = 0  # Reset to search from beginning
	_log("Seeked to %.1fs" % playback_time)