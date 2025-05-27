extends Node

# Mock LaneSoundSystem for testing

var lanes_played = []
var all_stopped = false
var current_volume = 1.0

func play_lane(lane: int):
	lanes_played.append(lane)

func play_lane_with_volume(lane: int, volume: float):
	lanes_played.append({"lane": lane, "volume": volume})

func stop_all_lanes():
	all_stopped = true
	lanes_played.clear()

func set_volume(volume: float):
	current_volume = volume

func get_volume() -> float:
	return current_volume