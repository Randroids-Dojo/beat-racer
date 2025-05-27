extends Node

# Mock BeatManager for testing

signal beat_occurred(beat_count: int, beat_time: float)

var bpm: float = 120.0
var beats_per_measure: int = 4
var current_measure: int = 1
var current_beat_in_measure: int = 1
var total_beats: int = 0

func set_bpm(new_bpm: float):
	bpm = new_bpm

func get_beat_progress() -> float:
	return 0.5  # Mock progress