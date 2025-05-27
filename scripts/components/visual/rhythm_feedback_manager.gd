class_name RhythmFeedbackManager
extends Node

signal perfect_hit_detected(accuracy: float, lane: int)
signal miss_detected(accuracy: float, lane: int)
signal combo_updated(count: int)
signal streak_broken()

@export_group("Timing Windows")
@export var perfect_window: float = 0.05  # Within 50ms
@export var good_window: float = 0.15     # Within 150ms
@export var ok_window: float = 0.25       # Within 250ms

@export_group("Visual Effects")
@export var enable_screen_effects: bool = true
@export var enable_particle_effects: bool = true
@export var enable_ui_animations: bool = true

var _beat_manager: Node = null
var _current_combo: int = 0
var _best_combo: int = 0
var _last_beat_time: float = 0.0
var _last_accuracy: float = 0.0
var _perfect_streak: int = 0
var _total_beats: int = 0
var _perfect_beats: int = 0
var _good_beats: int = 0
var _missed_beats: int = 0

# Timing tracking
var _last_input_time: float = 0.0
var _expected_beat_time: float = 0.0

# Color themes
const PERFECT_COLOR = Color(0.0, 1.0, 0.5, 1.0)  # Bright green
const GOOD_COLOR = Color(1.0, 1.0, 0.0, 1.0)     # Yellow
const OK_COLOR = Color(1.0, 0.5, 0.0, 1.0)       # Orange
const MISS_COLOR = Color(1.0, 0.0, 0.0, 1.0)     # Red

enum HitQuality {
	PERFECT,
	GOOD,
	OK,
	MISS
}

func _ready():
	_beat_manager = get_node("/root/BeatManager") if has_node("/root/BeatManager") else null
	
	if _beat_manager:
		_beat_manager.beat_occurred.connect(_on_beat_occurred)
		_beat_manager.measure_completed.connect(_on_measure_completed)
	else:
		push_warning("RhythmFeedbackManager: BeatManager not found")

func _on_beat_occurred(beat_number: int, beat_time: float):
	_expected_beat_time = beat_time
	_total_beats += 1
	
	# Check if we have an input registered near this beat
	var time_diff = abs(beat_time - _last_input_time)
	
	# Determine hit quality based on timing
	var hit_quality = _evaluate_timing(time_diff)
	
	# Update statistics
	match hit_quality:
		HitQuality.PERFECT:
			_perfect_beats += 1
			_perfect_streak += 1
			_current_combo += 1
			emit_signal("perfect_hit_detected", time_diff, 0)
		HitQuality.GOOD:
			_good_beats += 1
			_perfect_streak = 0
			_current_combo += 1
		HitQuality.OK:
			_perfect_streak = 0
			_current_combo = 0
		HitQuality.MISS:
			_missed_beats += 1
			_perfect_streak = 0
			_current_combo = 0
			emit_signal("miss_detected", time_diff, 0)
			emit_signal("streak_broken")
	
	# Update best combo
	if _current_combo > _best_combo:
		_best_combo = _current_combo
	
	# Emit combo update
	emit_signal("combo_updated", _current_combo)

func _on_measure_completed(measure_number: int, measure_time: float):
	# Could add measure-based effects or scoring here
	pass

func _evaluate_timing(time_difference: float) -> HitQuality:
	if time_difference <= perfect_window:
		return HitQuality.PERFECT
	elif time_difference <= good_window:
		return HitQuality.GOOD
	elif time_difference <= ok_window:
		return HitQuality.OK
	else:
		return HitQuality.MISS

func register_player_input(lane: int = 0):
	"""Called when player makes an input (accelerate on beat)"""
	_last_input_time = Time.get_ticks_msec() / 1000.0
	var time_to_beat = abs(_expected_beat_time - _last_input_time)
	var hit_quality = _evaluate_timing(time_to_beat)
	
	# Return the quality for immediate feedback
	return hit_quality

func get_timing_color(quality: HitQuality) -> Color:
	match quality:
		HitQuality.PERFECT:
			return PERFECT_COLOR
		HitQuality.GOOD:
			return GOOD_COLOR
		HitQuality.OK:
			return OK_COLOR
		HitQuality.MISS:
			return MISS_COLOR
		_:
			return Color.WHITE

func get_performance_stats() -> Dictionary:
	var accuracy = 0.0
	if _total_beats > 0:
		accuracy = float(_perfect_beats + _good_beats) / float(_total_beats)
	
	return {
		"total_beats": _total_beats,
		"perfect_beats": _perfect_beats,
		"good_beats": _good_beats,
		"missed_beats": _missed_beats,
		"accuracy": accuracy,
		"current_combo": _current_combo,
		"best_combo": _best_combo,
		"perfect_streak": _perfect_streak
	}

func reset_stats():
	_current_combo = 0
	_best_combo = 0
	_perfect_streak = 0
	_total_beats = 0
	_perfect_beats = 0
	_good_beats = 0
	_missed_beats = 0

func get_current_combo() -> int:
	return _current_combo

func get_best_combo() -> int:
	return _best_combo

func is_perfect_streak() -> bool:
	return _perfect_streak > 0

func get_multiplier() -> float:
	# Simple multiplier based on combo
	if _current_combo >= 50:
		return 4.0
	elif _current_combo >= 25:
		return 3.0
	elif _current_combo >= 10:
		return 2.0
	elif _current_combo >= 5:
		return 1.5
	else:
		return 1.0