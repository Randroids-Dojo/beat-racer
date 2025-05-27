extends Node2D

# Lane Sound Mapping Demo
# Tests the integration of lane detection with sound generation
# Shows how vehicle lane position controls audio output

@onready var track_system: TrackSystem = $TrackSystem
@onready var vehicle: RhythmVehicleWithLanes = $RhythmVehicleWithLanes
@onready var lane_detection: LaneDetectionSystem = $LaneDetectionSystem
@onready var lane_sound_system: LaneSoundSystem = $LaneSoundSystem
@onready var lane_audio_controller: LaneAudioController = $LaneAudioController
@onready var ui_container: Control = $UIContainer
@onready var info_label: Label = $UIContainer/InfoPanel/InfoLabel
@onready var camera: Camera2D = $Camera2D

# UI Controls
@onready var center_silent_check: CheckBox = $UIContainer/ControlPanel/CenterSilentCheck
@onready var transitions_check: CheckBox = $UIContainer/ControlPanel/TransitionsCheck
@onready var transition_time_slider: HSlider = $UIContainer/ControlPanel/TransitionTimeSlider
@onready var transition_time_label: Label = $UIContainer/ControlPanel/TransitionTimeLabel
@onready var volume_slider: HSlider = $UIContainer/ControlPanel/VolumeSlider
@onready var volume_label: Label = $UIContainer/ControlPanel/VolumeLabel

# Lane indicators
@onready var lane_indicators: Control = $UIContainer/LaneIndicators
var lane_panels: Array[Panel] = []

# Debug info
var info_update_timer: float = 0.0
var info_update_interval: float = 0.05


func _ready():
	print("\n=== Lane Sound Mapping Demo ===")
	print("Testing lane position to sound generation mapping")
	print("Controls:")
	print("- Arrow Keys or WASD: Drive vehicle")
	print("- ESC: Exit demo")
	print("- Center lane can be configured as silent")
	print("===============================\n")
	
	_setup_scene()
	_setup_ui()
	_setup_audio()
	_connect_signals()
	
	# Start beat manager
	if BeatManager:
		BeatManager.start_beat()
	
	# Start audio
	lane_audio_controller.start_audio()


func _setup_scene():
	"""Configure the scene components"""
	# Set camera to follow vehicle
	camera.position = Vector2(640, 360)
	camera.zoom = Vector2(0.8, 0.8)
	
	# Configure track
	track_system.track_color = Color(0.3, 0.3, 0.3)
	track_system.lane_divider_color = Color.WHITE
	track_system.show_center_line = true
	
	# Configure vehicle
	vehicle.position = track_system.get_start_position()
	vehicle.rotation = 0
	vehicle.show_debug_visuals = true
	
	# Configure lane detection
	lane_detection.track_reference = track_system
	lane_detection.vehicle_reference = vehicle
	lane_detection.debug_draw = true


func _setup_ui():
	"""Initialize UI elements"""
	# Create lane indicator panels
	for i in range(3):
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(200, 60)
		panel.modulate = Color.WHITE
		
		var label = Label.new()
		label.text = ["Left Lane", "Center Lane", "Right Lane"][i]
		label.add_theme_font_size_override("font_size", 16)
		label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		
		panel.add_child(label)
		lane_indicators.add_child(panel)
		lane_panels.append(panel)
	
	# Configure controls
	center_silent_check.button_pressed = lane_audio_controller.center_lane_silent
	transitions_check.button_pressed = lane_audio_controller.enable_transitions
	transition_time_slider.value = lane_audio_controller.transition_time
	volume_slider.value = lane_audio_controller.active_lane_volume
	
	_update_ui_labels()


func _setup_audio():
	"""Configure audio components"""
	# Configure lane sounds with distinct characteristics
	var configs = [
		_create_lane_config("Sine", 0, 1, Color.CYAN),      # Left - Low sine
		_create_lane_config("Square", 1, 5, Color.YELLOW),  # Center - Mid square
		_create_lane_config("Triangle", 2, 3, Color.MAGENTA) # Right - High triangle
	]
	
	for i in range(3):
		lane_sound_system.load_lane_configuration(configs[i], i)
	
	# Setup controller
	lane_audio_controller.setup(lane_detection, lane_sound_system)


func _create_lane_config(waveform: String, octave: int, scale_degree: int, color: Color) -> LaneSoundConfig:
	"""Helper to create lane sound configurations"""
	var config = LaneSoundConfig.new()
	config.config_name = "%s Lane" % waveform
	config.waveform = waveform
	config.octave = octave
	config.scale_degree = scale_degree
	config.volume = 0.7
	config.audio_bus = "Melody"
	return config


func _connect_signals():
	"""Connect UI and system signals"""
	# UI signals
	center_silent_check.toggled.connect(_on_center_silent_toggled)
	transitions_check.toggled.connect(_on_transitions_toggled)
	transition_time_slider.value_changed.connect(_on_transition_time_changed)
	volume_slider.value_changed.connect(_on_volume_changed)
	
	# Audio controller signals
	lane_audio_controller.lane_sound_started.connect(_on_lane_sound_started)
	lane_audio_controller.lane_sound_stopped.connect(_on_lane_sound_stopped)
	lane_audio_controller.sound_transition_started.connect(_on_sound_transition_started)
	
	# Lane detection signals (for visual feedback)
	lane_detection.lane_changed.connect(_on_lane_changed_visual)


func _process(delta: float):
	# Update camera to follow vehicle
	camera.position = camera.position.lerp(vehicle.position, delta * 5.0)
	
	# Update info display
	info_update_timer += delta
	if info_update_timer >= info_update_interval:
		info_update_timer = 0.0
		_update_info_display()
	
	# Update lane panel highlights
	_update_lane_panels()
	
	# Handle exit
	if Input.is_action_just_pressed("ui_cancel"):
		_exit_demo()


func _update_info_display():
	"""Update the information display"""
	var lane_info = lane_detection.get_lane_info() if lane_detection else {}
	var current_lane = lane_info.get("current_lane", -1)
	var lane_name = ["Left", "Center", "Right"][current_lane] if current_lane >= 0 else "None"
	var offset = lane_info.get("offset_from_center", 0.0)
	
	var active_sound_lane = lane_audio_controller.get_active_lane()
	var sound_lane_name = ["Left", "Center", "Right"][active_sound_lane] if active_sound_lane >= 0 else "None"
	
	var info_text = "Vehicle Lane: %s (offset: %.2f)\n" % [lane_name, offset]
	info_text += "Active Sound: %s Lane\n" % sound_lane_name
	info_text += "Center Silent: %s\n" % ("Yes" if lane_audio_controller.center_lane_silent else "No")
	info_text += "Transitions: %s\n" % ("Enabled" if lane_audio_controller.enable_transitions else "Disabled")
	
	if lane_audio_controller.is_transitioning:
		info_text += "Status: Transitioning..."
	else:
		info_text += "Status: Stable"
	
	info_label.text = info_text


func _update_lane_panels():
	"""Update visual feedback for active lanes"""
	var active_lane = lane_audio_controller.get_active_lane()
	
	for i in range(lane_panels.size()):
		var panel = lane_panels[i]
		var is_active = (i == active_lane)
		var volume = lane_audio_controller.get_lane_volume(i)
		
		# Update color based on activity
		if is_active and volume > 0.01:
			panel.modulate = Color(0.5, 1.0, 0.5) * (0.5 + volume * 0.5)
		elif i == 1 and lane_audio_controller.center_lane_silent:
			panel.modulate = Color(0.5, 0.5, 0.5)  # Gray for silent center
		else:
			panel.modulate = Color.WHITE * 0.7


func _update_ui_labels():
	"""Update UI label displays"""
	transition_time_label.text = "Transition Time: %.2fs" % transition_time_slider.value
	volume_label.text = "Volume: %.0f%%" % (volume_slider.value * 100)


# Signal handlers
func _on_center_silent_toggled(pressed: bool):
	lane_audio_controller.set_center_lane_silent(pressed)


func _on_transitions_toggled(pressed: bool):
	lane_audio_controller.set_transition_enabled(pressed)


func _on_transition_time_changed(value: float):
	lane_audio_controller.set_transition_time(value)
	_update_ui_labels()


func _on_volume_changed(value: float):
	lane_audio_controller.set_active_lane_volume(value)
	_update_ui_labels()


func _on_lane_sound_started(lane: int):
	print("Sound started for lane %d" % lane)


func _on_lane_sound_stopped(lane: int):
	print("Sound stopped for lane %d" % lane)


func _on_sound_transition_started(from_lane: int, to_lane: int):
	print("Transitioning sound from lane %d to %d" % [from_lane, to_lane])


func _on_lane_changed_visual(from_lane: int, to_lane: int):
	# Additional visual feedback could go here
	pass


func _exit_demo():
	"""Clean up and exit the demo"""
	print("\nExiting Lane Sound Mapping Demo...")
	
	# Stop audio
	lane_audio_controller.stop_audio()
	
	# Stop beat manager
	if BeatManager:
		BeatManager.stop_beat()
	
	# Return to main scene or quit
	get_tree().quit()