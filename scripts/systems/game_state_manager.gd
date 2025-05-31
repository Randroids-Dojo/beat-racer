extends Node
## Manages the overall game state and mode transitions for Beat Racer
##
## This class handles the different game modes (Live, Recording, Playback, Layering)
## and coordinates transitions between them. It manages the high-level game flow
## and ensures all systems are properly configured for each mode.

signal mode_changed(old_mode: GameMode, new_mode: GameMode)
signal recording_started()
signal recording_stopped()
signal playback_started()
signal playback_stopped()
signal layer_added(layer_index: int)
signal layer_removed(layer_index: int)

enum GameMode {
	LIVE,       ## Real-time playing with immediate sound generation
	RECORDING,  ## Recording player's path for later playback
	PLAYBACK,   ## Playing back recorded paths
	LAYERING    ## Recording additional layers over existing recordings
}

@export var default_mode: GameMode = GameMode.LIVE

var current_mode: GameMode = GameMode.LIVE
var is_transitioning: bool = false
var recorded_layers: Array[Resource] = []
var active_layer_index: int = -1
var max_layers: int = 8

@onready var beat_manager: Node = get_node("/root/BeatManager")
@onready var audio_manager: Node = get_node("/root/AudioManager")


func _ready() -> void:
	current_mode = default_mode
	_configure_mode(current_mode)


## Changes the game mode with proper transitions
func change_mode(new_mode: GameMode) -> void:
	if is_transitioning or new_mode == current_mode:
		return
	
	is_transitioning = true
	var old_mode = current_mode
	
	# Exit current mode
	_exit_mode(current_mode)
	
	# Enter new mode
	current_mode = new_mode
	_enter_mode(new_mode)
	
	# Configure systems for new mode
	_configure_mode(new_mode)
	
	is_transitioning = false
	mode_changed.emit(old_mode, new_mode)


## Starts recording in either RECORDING or LAYERING mode
func start_recording() -> void:
	match current_mode:
		GameMode.LIVE:
			change_mode(GameMode.RECORDING)
		GameMode.PLAYBACK:
			if recorded_layers.size() > 0:
				change_mode(GameMode.LAYERING)
		_:
			return
	
	recording_started.emit()


## Stops recording and returns to appropriate mode
func stop_recording() -> Resource:
	if current_mode not in [GameMode.RECORDING, GameMode.LAYERING]:
		return null
	
	# Get the recorded data (this would come from lap recorder)
	var recorded_data: Resource = _get_current_recording()
	
	if recorded_data:
		recorded_layers.append(recorded_data)
		active_layer_index = recorded_layers.size() - 1
		layer_added.emit(active_layer_index)
	
	recording_stopped.emit()
	
	# Transition to playback mode
	change_mode(GameMode.PLAYBACK)
	
	return recorded_data


## Starts playback of recorded layers
func start_playback() -> void:
	if recorded_layers.is_empty():
		return
	
	if current_mode != GameMode.PLAYBACK:
		change_mode(GameMode.PLAYBACK)
	
	playback_started.emit()


## Stops playback
func stop_playback() -> void:
	if current_mode == GameMode.PLAYBACK:
		playback_stopped.emit()
		change_mode(GameMode.LIVE)


## Toggles between play and pause in current mode
func toggle_play_pause() -> void:
	match current_mode:
		GameMode.LIVE:
			# In live mode, we could pause/resume the beat
			if beat_manager.is_playing:
				beat_manager.stop()
			else:
				beat_manager.start()
		GameMode.RECORDING, GameMode.LAYERING:
			# These modes are always active when entered
			pass
		GameMode.PLAYBACK:
			# Toggle playback pause
			if is_playing():
				pause_playback()
			else:
				resume_playback()


## Removes a recorded layer
func remove_layer(layer_index: int) -> void:
	if layer_index < 0 or layer_index >= recorded_layers.size():
		return
	
	recorded_layers.remove_at(layer_index)
	layer_removed.emit(layer_index)
	
	# Adjust active layer if needed
	if active_layer_index >= recorded_layers.size():
		active_layer_index = recorded_layers.size() - 1
	
	# If no layers left, return to live mode
	if recorded_layers.is_empty():
		change_mode(GameMode.LIVE)


## Clears all recorded layers
func clear_all_layers() -> void:
	recorded_layers.clear()
	active_layer_index = -1
	change_mode(GameMode.LIVE)


## Gets the current recording (placeholder - would integrate with lap recorder)
func _get_current_recording() -> Resource:
	# This would integrate with the lap recording system
	# For now, create a dummy LapRecording to test the system
	var dummy_recording = LapRecorder.LapRecording.new()
	dummy_recording.start_time = 0.0
	dummy_recording.end_time = 10.0
	dummy_recording.duration = 10.0
	dummy_recording.total_samples = 100
	dummy_recording.is_complete_lap = true
	dummy_recording.is_valid = true
	# Add some dummy position samples
	for i in range(10):
		var sample = LapRecorder.PositionSample.new()
		sample.timestamp = i
		sample.position = Vector2(i * 10, 0)
		sample.rotation = 0.0
		dummy_recording.position_samples.append(sample)
	return dummy_recording


## Handles mode exit logic
func _exit_mode(mode: GameMode) -> void:
	match mode:
		GameMode.RECORDING, GameMode.LAYERING:
			# Ensure recording is stopped
			pass
		GameMode.PLAYBACK:
			# Stop all playback vehicles
			pass


## Handles mode entry logic  
func _enter_mode(mode: GameMode) -> void:
	match mode:
		GameMode.RECORDING:
			# Prepare for new recording
			pass
		GameMode.LAYERING:
			# Prepare for layered recording
			pass
		GameMode.PLAYBACK:
			# Start playback of all layers
			pass


## Configures all systems for the current mode
func _configure_mode(mode: GameMode) -> void:
	match mode:
		GameMode.LIVE:
			# Enable live sound generation
			# Disable recording indicators
			# Hide playback controls
			pass
		GameMode.RECORDING:
			# Enable recording systems
			# Show recording UI
			# Keep live sound generation active
			pass
		GameMode.PLAYBACK:
			# Disable live sound generation for player
			# Enable playback vehicles
			# Show playback controls
			pass
		GameMode.LAYERING:
			# Enable recording over existing playback
			# Show both recording and playback UI
			# Mix live and playback sounds
			pass


## Returns true if currently playing (context-dependent)
func is_playing() -> bool:
	match current_mode:
		GameMode.LIVE:
			return beat_manager.is_playing if beat_manager else false
		GameMode.RECORDING, GameMode.LAYERING:
			return true  # Always playing when recording
		GameMode.PLAYBACK:
			# Check if playback vehicles are running
			return true  # Placeholder
		_:
			return false


## Pauses playback (only valid in PLAYBACK mode)
func pause_playback() -> void:
	if current_mode != GameMode.PLAYBACK:
		return
	# Pause playback vehicles


## Resumes playback (only valid in PLAYBACK mode)  
func resume_playback() -> void:
	if current_mode != GameMode.PLAYBACK:
		return
	# Resume playback vehicles


## Gets readable name for current mode
func get_mode_name() -> String:
	match current_mode:
		GameMode.LIVE:
			return "Live"
		GameMode.RECORDING:
			return "Recording"
		GameMode.PLAYBACK:
			return "Playback"
		GameMode.LAYERING:
			return "Layering"
		_:
			return "Unknown"


## Gets the number of recorded layers
func get_layer_count() -> int:
	return recorded_layers.size()


## Checks if recording is possible in current state
func can_record() -> bool:
	return current_mode in [GameMode.LIVE, GameMode.PLAYBACK] and recorded_layers.size() < max_layers


## Checks if playback is possible
func can_playback() -> bool:
	return not recorded_layers.is_empty()