extends Node2D

# Path Playback Demo
# Demonstrates recording vehicle paths and playing them back
# Combines recording from Story 010 with playback from Story 011

# Nodes
var track_system: TrackSystem
var rhythm_vehicle: RhythmVehicleWithLanes
var lap_recorder: LapRecorder
var recording_indicator: RecordingIndicator
var playback_vehicle: PlaybackVehicle
var playback_indicator: PlaybackModeIndicator
var lane_sound_system: LaneSoundSystem
var beat_visualization: BeatVisualizationPanel
var info_label: Label

# State
var current_recording: LapRecorder.LapRecording = null
var is_recording: bool = false
var is_playing: bool = false


func _ready():
	print("=== Path Playback Demo ===")
	print("Record a lap, then watch it play back automatically!")
	print("")
	print("Controls:")
	print("  Arrow Keys: Drive vehicle")
	print("  SPACE: Start/Stop recording")
	print("  P: Play/Pause playback")
	print("  S: Stop playback")
	print("  L: Toggle loop mode")
	print("  1-3: Adjust playback speed")
	print("=======================")
	
	_setup_scene()


func _setup_scene():
	# Create track system
	track_system = TrackSystem.new()
	track_system.track_radius = 300
	track_system.track_width = 120
	track_system.lane_count = 3
	track_system.beat_markers_per_lap = 16
	track_system.debug_drawing = true
	add_child(track_system)
	
	# Create lane sound system
	lane_sound_system = LaneSoundSystem.new()
	lane_sound_system.debug_logging = true
	add_child(lane_sound_system)
	
	# Configure sounds for each lane
	var lane_config = LaneSoundConfig.new()
	
	# Left lane - Low frequency
	var left_mapping = LaneMappingResource.new()
	left_mapping.waveform = LaneMappingResource.Waveform.SINE
	left_mapping.octave = 2
	left_mapping.scale_degree = 0
	lane_config.lane_mappings[0] = left_mapping
	
	# Center lane - Silent
	var center_mapping = LaneMappingResource.new()
	center_mapping.waveform = LaneMappingResource.Waveform.SINE
	center_mapping.octave = 3
	center_mapping.scale_degree = 2
	lane_config.lane_mappings[1] = center_mapping
	
	# Right lane - High frequency
	var right_mapping = LaneMappingResource.new()
	right_mapping.waveform = LaneMappingResource.Waveform.SQUARE
	right_mapping.octave = 4
	right_mapping.scale_degree = 4
	lane_config.lane_mappings[2] = right_mapping
	
	lane_sound_system.load_configuration(lane_config)
	
	# Create player vehicle
	rhythm_vehicle = RhythmVehicleWithLanes.new()
	rhythm_vehicle.position = Vector2(0, -300)
	rhythm_vehicle.debug_draw = true
	add_child(rhythm_vehicle)
	
	# Setup lane detection manually
	var lane_detection = LaneDetectionSystem.new()
	lane_detection.track_geometry = track_system.track_geometry
	rhythm_vehicle.add_child(lane_detection)
	rhythm_vehicle.lane_detection_system = lane_detection
	
	# Create lap recorder
	lap_recorder = LapRecorder.new()
	lap_recorder.debug_logging = true
	lap_recorder.sample_rate = 30.0
	add_child(lap_recorder)
	lap_recorder.setup(rhythm_vehicle, rhythm_vehicle.lane_detection_system, track_system)
	
	# Connect recorder signals
	lap_recorder.recording_started.connect(_on_recording_started)
	lap_recorder.recording_stopped.connect(_on_recording_stopped)
	lap_recorder.lap_completed.connect(_on_lap_completed)
	
	# Create playback vehicle
	playback_vehicle = PlaybackVehicle.new()
	playback_vehicle.debug_logging = true
	playback_vehicle.ghost_color = Color(0.3, 0.8, 1.0, 0.5)
	playback_vehicle.trail_enabled = true
	playback_vehicle.visible = false
	add_child(playback_vehicle)
	playback_vehicle.setup(lane_sound_system)
	
	# Create UI
	_create_ui()
	
	# Create camera
	var camera = Camera2D.new()
	camera.zoom = Vector2(0.8, 0.8)
	camera.position_smoothing_enabled = true
	add_child(camera)
	
	# Start beat visualization
	if beat_visualization:
		beat_visualization.start_visualization()
	
	# Start sounds
	lane_sound_system.start_playback()


func _create_ui():
	# Recording indicator
	recording_indicator = RecordingIndicator.new()
	recording_indicator.position = Vector2(20, 20)
	add_child(recording_indicator)
	
	# Playback indicator
	playback_indicator = PlaybackModeIndicator.new()
	playback_indicator.position = Vector2(20, 200)
	add_child(playback_indicator)
	
	# Connect playback controls
	playback_indicator.play_pressed.connect(_on_play_pressed)
	playback_indicator.pause_pressed.connect(_on_pause_pressed)
	playback_indicator.stop_pressed.connect(_on_stop_pressed)
	playback_indicator.loop_toggled.connect(_on_loop_toggled)
	playback_indicator.speed_changed.connect(_on_speed_changed)
	
	# Beat visualization
	beat_visualization = BeatVisualizationPanel.new()
	beat_visualization.panel_size = Vector2(300, 60)
	beat_visualization.position = Vector2(20, 380)
	add_child(beat_visualization)
	
	# Info label
	info_label = Label.new()
	info_label.position = Vector2(20, 460)
	info_label.add_theme_font_size_override("font_size", 14)
	add_child(info_label)
	
	# Instructions
	var instructions = Label.new()
	instructions.text = "SPACE: Record | P: Play/Pause | S: Stop | L: Loop | 1-3: Speed"
	instructions.position = Vector2(20, 500)
	add_child(instructions)


func _input(event: InputEvent):
	# Recording control
	if event.is_action_pressed("ui_select"):  # SPACE
		if is_recording:
			_stop_recording()
		else:
			_start_recording()
	
	# Playback controls
	if event.is_action_pressed("ui_cancel"):  # ESC
		_stop_recording()
		_stop_playback()
	
	# P - Play/Pause
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		_toggle_playback()
	
	# S - Stop
	if event is InputEventKey and event.pressed and event.keycode == KEY_S:
		_stop_playback()
	
	# L - Loop toggle
	if event is InputEventKey and event.pressed and event.keycode == KEY_L:
		var current_loop = playback_vehicle.path_player.loop_enabled
		_on_loop_toggled(not current_loop)
	
	# Speed controls
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_on_speed_changed(0.5)
			KEY_2:
				_on_speed_changed(1.0)
			KEY_3:
				_on_speed_changed(2.0)


func _start_recording():
	if is_recording or is_playing:
		return
	
	print("Starting recording...")
	lap_recorder.start_recording()
	is_recording = true


func _stop_recording():
	if not is_recording:
		return
	
	print("Stopping recording...")
	current_recording = lap_recorder.stop_recording()
	is_recording = false
	
	if current_recording and current_recording.is_valid:
		playback_indicator.set_recording_loaded(true)
		info_label.text = "Recording saved: %.1fs, %d samples" % [
			current_recording.duration,
			current_recording.total_samples
		]


func _on_recording_started():
	recording_indicator.set_recording_state(true)
	playback_indicator.set_recording_active(true)


func _on_recording_stopped():
	recording_indicator.set_recording_state(false)
	playback_indicator.set_recording_active(false)


func _on_lap_completed(lap_data: LapRecorder.LapRecording):
	print("Lap completed!")
	current_recording = lap_data
	playback_indicator.set_recording_loaded(true)
	info_label.text = "Lap recorded: %.1fs, Complete: %s" % [
		lap_data.duration,
		"Yes" if lap_data.is_complete_lap else "No"
	]
	
	# Auto-start playback
	await get_tree().create_timer(1.0).timeout
	if current_recording and not is_playing:
		_start_playback()


func _toggle_playback():
	if is_playing:
		if playback_vehicle.is_playing() and not playback_vehicle.path_player.is_paused():
			_pause_playback()
		else:
			_resume_playback()
	else:
		_start_playback()


func _start_playback():
	if not current_recording or is_recording:
		print("No recording to play")
		return
	
	print("Starting playback...")
	playback_vehicle.load_recording(current_recording)
	playback_vehicle.start_playback()
	is_playing = true
	playback_indicator.set_playback_active(true)


func _pause_playback():
	if not is_playing:
		return
	
	print("Pausing playback...")
	playback_vehicle.pause_playback()
	playback_indicator.set_playback_paused(true)


func _resume_playback():
	if not is_playing:
		_start_playback()
		return
	
	print("Resuming playback...")
	playback_vehicle.start_playback()  # PathPlayer handles resume
	playback_indicator.set_playback_paused(false)


func _stop_playback():
	if not is_playing:
		return
	
	print("Stopping playback...")
	playback_vehicle.stop_playback()
	is_playing = false
	playback_indicator.set_playback_active(false)


func _on_play_pressed():
	_toggle_playback()


func _on_pause_pressed():
	_pause_playback()


func _on_stop_pressed():
	_stop_playback()


func _on_loop_toggled(enabled: bool):
	playback_vehicle.set_loop_enabled(enabled)
	print("Loop mode: %s" % ("Enabled" if enabled else "Disabled"))


func _on_speed_changed(speed: float):
	playback_vehicle.set_playback_speed(speed)
	print("Playback speed: %.1fx" % speed)


func _process(_delta: float):
	# Update recording indicator
	if is_recording and lap_recorder:
		recording_indicator.update_duration(lap_recorder.get_recording_duration())
		recording_indicator.update_sample_count(lap_recorder.get_sample_count())
		recording_indicator.update_progress(lap_recorder.get_recording_progress())
	
	# Update playback progress
	if is_playing and playback_vehicle:
		var progress = playback_vehicle.get_playback_progress()
		playback_indicator.update_playback_progress(progress)
		
		# Update loop count
		if playback_vehicle.path_player:
			playback_indicator.update_loop_count(playback_vehicle.path_player.loop_count)