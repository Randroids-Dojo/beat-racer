extends Node

# Beat Manager - Core beat detection and synchronization system
# Provides accurate beat tracking and synchronization for the game
# Emits signals for beat events that other systems can respond to

signal beat_occurred(beat_number: int, beat_time: float)
signal measure_completed(measure_number: int, measure_time: float)
signal half_beat_occurred(half_beat_number: int, beat_time: float)
signal beat_intensity_changed(intensity: float)
signal bpm_changed(old_bpm: float, new_bpm: float)
signal time_signature_changed(beats_per_measure: int)

# Constants
const MIN_BPM: float = 60.0
const MAX_BPM: float = 240.0
const DEFAULT_BPM: float = 120.0
const DEFAULT_BEATS_PER_MEASURE: int = 4

# Timing properties
var bpm: float = DEFAULT_BPM:
	set(value):
		var old_bpm = bpm
		bpm = clamp(value, MIN_BPM, MAX_BPM)
		_recalculate_timing()
		emit_signal("bpm_changed", old_bpm, bpm)

var beats_per_measure: int = DEFAULT_BEATS_PER_MEASURE:
	set(value):
		beats_per_measure = max(1, value)
		emit_signal("time_signature_changed", beats_per_measure)

# Beat tracking
var current_beat: int = 0
var current_measure: int = 0
var current_half_beat: int = 0
var time_since_last_beat: float = 0.0
var time_since_last_half_beat: float = 0.0
var beat_duration: float = 0.5  # Duration of one beat in seconds
var half_beat_duration: float = 0.25  # Duration of half beat in seconds

# Synchronization properties
var audio_offset: float = 0.0  # Offset to compensate for audio latency
var is_playing: bool = false
var start_time: float = 0.0
var total_beats: int = 0
var beat_intensity: float = 1.0  # 0.0 to 1.0, affects visual feedback

# Debug/monitoring
var _debug_logging: bool = true
var _beat_timer: Timer
var _missed_beats: int = 0

func _ready():
	_log("=== BeatManager Initialization ===")
	_log("Default BPM: %f" % DEFAULT_BPM)
	_log("Beats per measure: %d" % DEFAULT_BEATS_PER_MEASURE)
	
	_setup_timer()
	_recalculate_timing()
	
	_log("Beat Manager ready")
	_log("===============================")

func _log(message: String) -> void:
	if _debug_logging:
		var timestamp = Time.get_time_string_from_system()
		print("[%s] BeatManager: %s" % [timestamp, message])

func _setup_timer():
	_beat_timer = Timer.new()
	_beat_timer.one_shot = false
	_beat_timer.timeout.connect(_on_timer_beat)
	add_child(_beat_timer)

func _recalculate_timing():
	beat_duration = 60.0 / bpm
	half_beat_duration = beat_duration / 2.0
	
	if _beat_timer:
		_beat_timer.wait_time = beat_duration
		if is_playing:
			_beat_timer.start()
	
	_log("Timing recalculated - Beat duration: %fs, Half-beat: %fs" % [beat_duration, half_beat_duration])

func start():
	if not is_playing:
		is_playing = true
		start_time = Time.get_ticks_msec() / 1000.0
		current_beat = 0
		current_measure = 0
		current_half_beat = 0
		total_beats = 0
		time_since_last_beat = 0.0
		time_since_last_half_beat = 0.0
		
		_beat_timer.wait_time = beat_duration
		_beat_timer.start()
		
		_log("Started beat tracking at BPM: %f" % bpm)

func stop():
	if is_playing:
		is_playing = false
		_beat_timer.stop()
		_log("Stopped beat tracking")

func reset():
	stop()
	current_beat = 0
	current_measure = 0
	current_half_beat = 0
	total_beats = 0
	time_since_last_beat = 0.0
	time_since_last_half_beat = 0.0
	_log("Beat tracking reset")

func _process(delta: float):
	if not is_playing:
		return
	
	time_since_last_beat += delta
	time_since_last_half_beat += delta
	
	# Check for half beats
	if time_since_last_half_beat >= half_beat_duration:
		_process_half_beat()

func _on_timer_beat():
	if not is_playing:
		return
		
	_process_beat()

func _process_beat():
	var current_time = Time.get_ticks_msec() / 1000.0 - start_time
	
	current_beat = (current_beat + 1) % beats_per_measure
	if current_beat == 0:
		current_measure += 1
		emit_signal("measure_completed", current_measure, current_time)
		_log("Measure %d completed" % current_measure)
	
	total_beats += 1
	time_since_last_beat = 0.0
	
	emit_signal("beat_occurred", total_beats, current_time)
	
	if _debug_logging and total_beats % beats_per_measure == 0:
		_log("Beat %d (Measure %d, Beat %d)" % [total_beats, current_measure, current_beat])

func _process_half_beat():
	var current_time = Time.get_ticks_msec() / 1000.0 - start_time
	
	current_half_beat += 1
	time_since_last_half_beat = 0.0
	
	emit_signal("half_beat_occurred", current_half_beat, current_time)

# Synchronization methods
func get_beat_progress() -> float:
	# Returns 0.0 to 1.0 representing progress through current beat
	if not is_playing or beat_duration <= 0:
		return 0.0
	return clamp(time_since_last_beat / beat_duration, 0.0, 1.0)

func get_time_to_next_beat() -> float:
	if not is_playing:
		return 0.0
	return beat_duration - time_since_last_beat

func get_time_since_last_beat() -> float:
	return time_since_last_beat

func is_on_beat(tolerance: float = 0.1) -> bool:
	# Check if we're within tolerance of a beat
	var progress = get_beat_progress()
	return progress <= tolerance or progress >= (1.0 - tolerance)

func is_on_half_beat(tolerance: float = 0.1) -> bool:
	# Check if we're within tolerance of a half beat
	var half_progress = fmod(time_since_last_half_beat, half_beat_duration) / half_beat_duration
	return half_progress <= tolerance or half_progress >= (1.0 - tolerance)

# Audio offset compensation
func set_audio_offset(offset_ms: float):
	audio_offset = offset_ms / 1000.0
	_log("Audio offset set to: %fms" % offset_ms)

func get_audio_offset() -> float:
	return audio_offset * 1000.0

# Intensity control for visual feedback
func set_beat_intensity(intensity: float):
	beat_intensity = clamp(intensity, 0.0, 1.0)
	emit_signal("beat_intensity_changed", beat_intensity)

func get_beat_intensity() -> float:
	return beat_intensity

# Utility methods
func beats_to_seconds(beats: float) -> float:
	return beats * beat_duration

func seconds_to_beats(seconds: float) -> float:
	if beat_duration <= 0:
		return 0.0
	return seconds / beat_duration

func get_current_beat_in_measure() -> int:
	return current_beat

func get_current_measure() -> int:
	return current_measure

func get_total_beats() -> int:
	return total_beats

# Debug methods
func get_beat_accuracy() -> float:
	# Returns accuracy percentage based on timer precision
	if total_beats <= 0:
		return 100.0
	return (1.0 - float(_missed_beats) / float(total_beats)) * 100.0

func print_debug_info():
	print("=== Beat Manager Debug Info ===")
	print("BPM: %f" % bpm)
	print("Beat Duration: %fs" % beat_duration)
	print("Current Beat: %d" % current_beat)
	print("Current Measure: %d" % current_measure)
	print("Total Beats: %d" % total_beats)
	print("Is Playing: %s" % str(is_playing))
	print("Beat Progress: %.2f%%" % (get_beat_progress() * 100))
	print("Accuracy: %.2f%%" % get_beat_accuracy())
	print("===============================")