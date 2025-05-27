extends Node2D

# Lap Recording Demo
# Tests the lap recording system with vehicle tracking

@onready var track_system: Node2D = $TrackSystem
@onready var vehicle: Node2D = $RhythmVehicleWithLanes
@onready var lane_detection: LaneDetectionSystem = $LaneDetectionSystem
@onready var lap_recorder: LapRecorder = $LapRecorder
@onready var recording_indicator: RecordingIndicator = $UI/RecordingIndicator
@onready var camera: Camera2D = $Camera2D

# UI elements
@onready var info_panel: Panel = $UI/InfoPanel
@onready var info_label: Label = $UI/InfoPanel/InfoLabel
@onready var recordings_list: ItemList = $UI/RecordingsPanel/RecordingsList
@onready var playback_button: Button = $UI/RecordingsPanel/PlaybackButton
@onready var clear_button: Button = $UI/RecordingsPanel/ClearButton

# Settings
@onready var sample_rate_slider: HSlider = $UI/SettingsPanel/SampleRateSlider
@onready var sample_rate_label: Label = $UI/SettingsPanel/SampleRateLabel
@onready var show_samples_check: CheckBox = $UI/SettingsPanel/ShowSamplesCheck

# Data
var recordings: Array[LapRecorder.LapRecording] = []
var selected_recording_index: int = -1


func _ready():
	print("\n=== Lap Recording Demo ===")
	print("Testing lap recording system")
	print("Controls:")
	print("- Arrow Keys or WASD: Drive vehicle")
	print("- SPACE: Start/Stop recording")
	print("- R: Reset vehicle position")
	print("- ESC: Exit demo")
	print("===========================\n")
	
	_setup_scene()
	_setup_ui()
	_connect_signals()
	
	# Start beat manager
	if BeatManager:
		BeatManager.set_bpm(120)
		BeatManager.start_beat()


func _setup_scene():
	"""Configure scene components"""
	# Camera setup
	camera.position = Vector2(640, 360)
	camera.zoom = Vector2(0.8, 0.8)
	
	# Track setup
	track_system.track_color = Color(0.3, 0.3, 0.3)
	track_system.show_beat_markers = true
	
	# Vehicle setup
	vehicle.position = track_system.get_start_position()
	vehicle.rotation = 0
	
	# Lane detection setup
	lane_detection.track_reference = track_system
	lane_detection.vehicle_reference = vehicle
	lane_detection.debug_draw = true
	
	# Lap recorder setup
	lap_recorder.setup(vehicle, lane_detection, track_system)
	lap_recorder.debug_logging = true
	
	# Recording indicator setup
	recording_indicator.setup(lap_recorder)


func _setup_ui():
	"""Initialize UI elements"""
	# Sample rate control
	sample_rate_slider.value = lap_recorder.sample_rate
	_update_sample_rate_label()
	
	# Show samples control
	show_samples_check.button_pressed = lap_recorder.show_sample_points
	
	# Clear recordings list
	recordings_list.clear()
	playback_button.disabled = true


func _connect_signals():
	"""Connect all signals"""
	# Lap recorder signals
	lap_recorder.lap_completed.connect(_on_lap_completed)
	lap_recorder.position_sampled.connect(_on_position_sampled)
	
	# UI signals
	sample_rate_slider.value_changed.connect(_on_sample_rate_changed)
	show_samples_check.toggled.connect(_on_show_samples_toggled)
	recordings_list.item_selected.connect(_on_recording_selected)
	playback_button.pressed.connect(_on_playback_pressed)
	clear_button.pressed.connect(_on_clear_pressed)


func _input(event: InputEvent):
	# Start/stop recording
	if event.is_action_pressed("ui_select"):  # SPACE
		if lap_recorder.is_recording_active():
			lap_recorder.stop_recording()
		else:
			lap_recorder.start_recording()
	
	# Reset vehicle
	if event.is_action_pressed("reset"):  # R key
		vehicle.position = track_system.get_start_position()
		vehicle.rotation = 0
		vehicle.linear_velocity = Vector2.ZERO
		vehicle.angular_velocity = 0
	
	# Exit
	if event.is_action_pressed("ui_cancel"):
		_exit_demo()


func _process(delta: float):
	# Update camera to follow vehicle
	camera.position = camera.position.lerp(vehicle.position, delta * 5.0)
	
	# Update info display
	_update_info_display()


func _update_info_display():
	"""Update information panel"""
	var text = "Vehicle Position: %s\n" % vehicle.position
	
	# Lane info
	var lane_info = lane_detection.get_lane_info()
	var lane = lane_info.get("current_lane", -1)
	text += "Current Lane: %d\n" % lane
	
	# Track progress
	if track_system.has_method("get_track_progress_at_position"):
		var progress = track_system.get_track_progress_at_position(vehicle.position)
		text += "Track Progress: %.1f%%\n" % (progress * 100)
	
	# Recording info
	if lap_recorder.is_recording_active():
		text += "\nRECORDING\n"
		text += "Duration: %.1fs\n" % lap_recorder.get_recording_duration()
		text += "Samples: %d\n" % lap_recorder.get_sample_count()
	else:
		text += "\nTotal Recordings: %d\n" % recordings.size()
	
	info_label.text = text


func _update_sample_rate_label():
	"""Update sample rate label"""
	sample_rate_label.text = "Sample Rate: %.0f Hz" % sample_rate_slider.value


# Signal handlers
func _on_lap_completed(lap_data: LapRecorder.LapRecording):
	"""Handle lap completion"""
	print("Lap completed! Duration: %.1fs, Samples: %d" % [lap_data.duration, lap_data.total_samples])
	
	# Store recording
	recordings.append(lap_data)
	
	# Update UI
	var item_text = "Lap %d (%.1fs, %d samples)" % [recordings.size(), lap_data.duration, lap_data.total_samples]
	recordings_list.add_item(item_text)
	
	# Show completion message
	recording_indicator.set_custom_info("Lap completed! Starting new recording...")
	
	# Auto-start new recording
	await get_tree().create_timer(1.0).timeout
	lap_recorder.start_recording()


func _on_position_sampled(sample: LapRecorder.PositionSample):
	"""Handle position sample (for debugging)"""
	# Could add visual feedback here
	pass


func _on_sample_rate_changed(value: float):
	"""Handle sample rate change"""
	lap_recorder.sample_rate = value
	_update_sample_rate_label()


func _on_show_samples_toggled(pressed: bool):
	"""Handle show samples toggle"""
	lap_recorder.show_sample_points = pressed


func _on_recording_selected(index: int):
	"""Handle recording selection"""
	selected_recording_index = index
	playback_button.disabled = false
	
	# Show recording info
	var recording = recordings[index]
	print("Selected recording %d: %.1fs, %d samples" % [index + 1, recording.duration, recording.total_samples])


func _on_playback_pressed():
	"""Handle playback button (placeholder for Story 011)"""
	if selected_recording_index < 0:
		return
	
	var recording = recordings[selected_recording_index]
	print("Playback not yet implemented (Story 011)")
	print("Would play recording with %d samples over %.1fs" % [recording.total_samples, recording.duration])


func _on_clear_pressed():
	"""Clear all recordings"""
	recordings.clear()
	recordings_list.clear()
	selected_recording_index = -1
	playback_button.disabled = true
	print("All recordings cleared")


func _exit_demo():
	"""Exit the demo"""
	print("\nExiting Lap Recording Demo...")
	
	# Stop recording if active
	if lap_recorder.is_recording_active():
		lap_recorder.stop_recording()
	
	# Stop beat manager
	if BeatManager:
		BeatManager.stop_beat()
	
	# Print summary
	print("Total recordings: %d" % recordings.size())
	for i in range(recordings.size()):
		var rec = recordings[i]
		print("  Lap %d: %.1fs, %d samples" % [i + 1, rec.duration, rec.total_samples])
	
	get_tree().quit()