extends Node2D

# UI Demo
# Demonstrates all UI elements from Story 012

# Components
var game_ui: GameUIPanel
var track_system: TrackSystem
var rhythm_vehicle: RhythmVehicleWithLanes
var lap_recorder: LapRecorder
var playback_vehicle: PlaybackVehicle
var lane_sound_system: LaneSoundSystem

# State
var current_recording: LapRecorder.LapRecording
var is_recording: bool = false
var is_playing: bool = false
var selected_vehicle_type: VehicleSelector.VehicleType = VehicleSelector.VehicleType.STANDARD
var selected_vehicle_color: Color = Color(0.7, 0.7, 0.7)


func _ready():
	print("=== UI Elements Demo ===")
	print("This demo showcases all UI elements from Story 012")
	print("")
	print("Features:")
	print("  - Recording/playback status indicator")
	print("  - Beat and measure counter")
	print("  - BPM control with tap tempo")
	print("  - Vehicle selection with preview")
	print("")
	print("Controls:")
	print("  Arrow Keys: Drive vehicle")
	print("  SPACE: Start/Stop recording")
	print("  P: Play/Pause playback")
	print("  TAB: Toggle UI visibility")
	print("  ESC: Stop all")
	print("========================")
	
	_setup_scene()


func _setup_scene():
	# Create track
	track_system = TrackSystem.new()
	track_system.beats_per_lap = 16
	add_child(track_system)
	
	# Wait for track to initialize then configure
	await get_tree().process_frame
	if track_system.track_geometry:
		track_system.track_geometry.track_width = 180
		track_system.track_geometry.lane_count = 3
		track_system.track_geometry.curve_radius = 300
	
	# Create lane sound system
	lane_sound_system = LaneSoundSystem.new()
	add_child(lane_sound_system)
	_configure_lane_sounds()
	
	# Create UI
	game_ui = GameUIPanel.new()
	add_child(game_ui)
	
	# Connect UI signals
	game_ui.vehicle_changed.connect(_on_vehicle_changed)
	game_ui.bpm_changed.connect(_on_bpm_changed)
	game_ui.recording_started.connect(_on_recording_started_ui)
	game_ui.recording_stopped.connect(_on_recording_stopped_ui)
	game_ui.playback_started.connect(_on_playback_started_ui)
	game_ui.playback_stopped.connect(_on_playback_stopped_ui)
	
	# Create player vehicle
	_create_player_vehicle()
	
	# Create lap recorder
	lap_recorder = LapRecorder.new()
	add_child(lap_recorder)
	lap_recorder.setup(rhythm_vehicle, rhythm_vehicle.lane_detection_system, track_system)
	
	# Connect recorder signals
	lap_recorder.recording_started.connect(_on_recording_started)
	lap_recorder.recording_stopped.connect(_on_recording_stopped)
	lap_recorder.lap_completed.connect(_on_lap_completed)
	lap_recorder.position_sampled.connect(_on_position_sampled)
	
	# Create playback vehicle
	playback_vehicle = PlaybackVehicle.new()
	playback_vehicle.visible = false
	add_child(playback_vehicle)
	playback_vehicle.setup(lane_sound_system)
	
	# Connect playback signals
	playback_vehicle.playback_started.connect(_on_playback_started)
	playback_vehicle.playback_stopped.connect(_on_playback_stopped)
	playback_vehicle.path_player.loop_completed.connect(_on_loop_completed)
	
	# Create camera
	var camera = Camera2D.new()
	camera.zoom = Vector2(0.7, 0.7)
	add_child(camera)
	
	# Start audio
	lane_sound_system.start_playback()
	
	# Create info label
	var info = Label.new()
	info.text = "Arrow Keys: Drive | SPACE: Record | P: Play | TAB: Toggle UI"
	info.position = Vector2(20, 540)
	info.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	add_child(info)


func _configure_lane_sounds():
	"""Configure lane sound mappings"""
	# Create lane mapping resource with default configs
	var mapping = LaneMappingResource.new()
	
	# Left lane - melody
	mapping.left_lane_config.waveform = SoundGenerator.WaveType.SINE
	mapping.left_lane_config.audio_bus = "Melody"
	mapping.left_lane_config.octave = 0
	mapping.left_lane_config.scale_degree = 1
	
	# Center lane - bass
	mapping.center_lane_config.waveform = SoundGenerator.WaveType.SQUARE
	mapping.center_lane_config.audio_bus = "Bass"
	mapping.center_lane_config.octave = -1
	mapping.center_lane_config.scale_degree = 3
	
	# Right lane - higher melody
	mapping.right_lane_config.waveform = SoundGenerator.WaveType.TRIANGLE
	mapping.right_lane_config.audio_bus = "Melody"
	mapping.right_lane_config.octave = 1
	mapping.right_lane_config.scale_degree = 5
	
	# Apply configuration to lane sound system
	# Use the default setup since the system doesn't have load_configuration


func _create_player_vehicle():
	"""Create player vehicle with selected type"""
	if rhythm_vehicle:
		rhythm_vehicle.queue_free()
	
	rhythm_vehicle = RhythmVehicleWithLanes.new()
	rhythm_vehicle.position = Vector2(0, -300)  # Start above track center
	
	# Apply vehicle properties based on selection
	var vehicle_data = game_ui.vehicle_selector.get_vehicle_data(selected_vehicle_type)
	if vehicle_data:
		rhythm_vehicle.max_speed *= vehicle_data.speed_modifier
		rhythm_vehicle.turn_speed *= vehicle_data.handling_modifier
	
	# Apply color (would need visual component in real implementation)
	rhythm_vehicle.modulate = selected_vehicle_color
	
	add_child(rhythm_vehicle)
	
	# Setup lane detection manually
	var lane_detection = LaneDetectionSystem.new()
	lane_detection.track_geometry = track_system.track_geometry
	rhythm_vehicle.add_child(lane_detection)
	rhythm_vehicle.lane_detection_system = lane_detection
	
	# Update recorder reference
	if lap_recorder:
		lap_recorder.setup(rhythm_vehicle, rhythm_vehicle.lane_detection_system, track_system)


func _input(event: InputEvent):
	# Recording control
	if event.is_action_pressed("ui_select"):  # SPACE
		if is_recording:
			_stop_recording()
		else:
			_start_recording()
	
	# Playback control
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		if is_playing:
			if playback_vehicle.path_player.is_paused():
				_resume_playback()
			else:
				_pause_playback()
		else:
			_start_playback()
	
	# UI toggle
	if event.is_action_pressed("ui_focus_next"):  # TAB
		game_ui.toggle_ui()
	
	# Stop all
	if event.is_action_pressed("ui_cancel"):  # ESC
		_stop_all()


func _start_recording():
	if is_recording or is_playing:
		return
	
	lap_recorder.start_recording()
	is_recording = true
	game_ui.set_recording_mode(true)


func _stop_recording():
	if not is_recording:
		return
	
	current_recording = lap_recorder.stop_recording()
	is_recording = false
	game_ui.set_recording_mode(false)
	
	if current_recording and current_recording.is_valid:
		game_ui.update_status_info("Recording saved - Press P to play")


func _start_playback():
	if not current_recording or is_recording:
		return
	
	playback_vehicle.load_recording(current_recording)
	playback_vehicle.path_player.sync_to_beat = false
	playback_vehicle.start_playback()
	is_playing = true
	game_ui.set_playback_mode(true)


func _pause_playback():
	if not is_playing:
		return
	
	playback_vehicle.pause_playback()
	game_ui.set_playback_mode(true, true)


func _resume_playback():
	if not is_playing:
		return
	
	playback_vehicle.start_playback()  # Resume
	game_ui.set_playback_mode(true, false)


func _stop_playback():
	if not is_playing:
		return
	
	playback_vehicle.stop_playback()
	is_playing = false
	game_ui.set_playback_mode(false)


func _stop_all():
	_stop_recording()
	_stop_playback()


# Signal handlers
func _on_vehicle_changed(type: VehicleSelector.VehicleType, color: Color):
	selected_vehicle_type = type
	selected_vehicle_color = color
	
	# Recreate vehicle with new properties
	if not is_recording and not is_playing:
		_create_player_vehicle()
		print("Vehicle changed to: %s" % VehicleSelector.VehicleType.keys()[type])


func _on_bpm_changed(bpm: float):
	print("BPM changed to: %.0f" % bpm)


func _on_recording_started():
	game_ui.update_status_info("Recording...")


func _on_recording_stopped():
	if current_recording:
		game_ui.update_status_info("Recording complete")


func _on_lap_completed(lap_data: LapRecorder.LapRecording):
	current_recording = lap_data
	game_ui.update_status_info("Lap recorded! Press P to play")
	
	# Auto-stop recording
	is_recording = false
	game_ui.set_recording_mode(false)


func _on_position_sampled(_sample):
	# Update recording info
	if is_recording and lap_recorder:
		var duration = lap_recorder.get_recording_duration()
		var samples = lap_recorder.get_sample_count()
		game_ui.update_status_info("Recording: %.1fs, %d samples" % [duration, samples])


func _on_playback_started():
	game_ui.update_status_info("Playing recording")


func _on_playback_stopped():
	game_ui.update_status_info("Playback stopped")
	game_ui.set_playback_mode(false)


func _on_loop_completed(loop_count: int):
	game_ui.update_loop_info(true, loop_count)


# UI signal handlers (placeholder)
func _on_recording_started_ui():
	print("UI: Recording started")


func _on_recording_stopped_ui():
	print("UI: Recording stopped")


func _on_playback_started_ui():
	print("UI: Playback started")


func _on_playback_stopped_ui():
	print("UI: Playback stopped")


func _process(_delta: float):
	# Update playback progress
	if is_playing and playback_vehicle:
		var _progress = playback_vehicle.get_playback_progress()
		# Could update a progress bar here
