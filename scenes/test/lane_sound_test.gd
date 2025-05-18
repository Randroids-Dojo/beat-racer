extends Node

var lane_sound_system: LaneSoundSystem
var current_lane_label: Label
var status_label: Label
var controls_container: VBoxContainer

func _ready():
	_setup_ui()
	_setup_lane_sound_system()
	_create_controls()

func _setup_ui():
	# Create UI elements
	controls_container = VBoxContainer.new()
	controls_container.position = Vector2(20, 20)
	add_child(controls_container)
	
	# Title
	var title = Label.new()
	title.text = "Lane Sound Test"
	title.add_theme_font_size_override("font_size", 24)
	controls_container.add_child(title)
	
	# Status label
	status_label = Label.new()
	status_label.text = "Status: Stopped"
	controls_container.add_child(status_label)
	
	# Current lane label
	current_lane_label = Label.new()
	current_lane_label.text = "Current Lane: Center"
	controls_container.add_child(current_lane_label)
	
	# Add spacing
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	controls_container.add_child(spacer)

func _setup_lane_sound_system():
	lane_sound_system = LaneSoundSystem.new()
	add_child(lane_sound_system)
	
	# Connect signals
	lane_sound_system.lane_changed.connect(_on_lane_changed)
	
	# Configure initial settings
	lane_sound_system.set_global_scale(SoundGenerator.Scale.PENTATONIC_MAJOR)
	lane_sound_system.set_global_root_note(SoundGenerator.Note.C)
	
	# Configure lanes with different sounds
	lane_sound_system.set_lane_waveform(LaneSoundSystem.LaneType.LEFT, SoundGenerator.WaveType.SINE)
	lane_sound_system.set_lane_waveform(LaneSoundSystem.LaneType.CENTER, SoundGenerator.WaveType.SQUARE)
	lane_sound_system.set_lane_waveform(LaneSoundSystem.LaneType.RIGHT, SoundGenerator.WaveType.TRIANGLE)
	
	# Set different octaves
	lane_sound_system.set_lane_octave(LaneSoundSystem.LaneType.LEFT, 0)
	lane_sound_system.set_lane_octave(LaneSoundSystem.LaneType.CENTER, -1)
	lane_sound_system.set_lane_octave(LaneSoundSystem.LaneType.RIGHT, 1)
	
	# Set scale degrees
	lane_sound_system.set_lane_scale_degree(LaneSoundSystem.LaneType.LEFT, 1)
	lane_sound_system.set_lane_scale_degree(LaneSoundSystem.LaneType.CENTER, 1)
	lane_sound_system.set_lane_scale_degree(LaneSoundSystem.LaneType.RIGHT, 5)

func _create_controls():
	# Play/Stop toggle
	var play_button = Button.new()
	play_button.text = "Play/Stop"
	play_button.pressed.connect(_toggle_playback)
	controls_container.add_child(play_button)
	
	# Lane selection
	var lane_label = Label.new()
	lane_label.text = "Select Lane:"
	controls_container.add_child(lane_label)
	
	var lane_buttons = HBoxContainer.new()
	controls_container.add_child(lane_buttons)
	
	for i in range(3):
		var lane_button = Button.new()
		lane_button.text = ["Left", "Center", "Right"][i]
		lane_button.pressed.connect(_select_lane.bind(i))
		lane_buttons.add_child(lane_button)
	
	# Waveform selection
	var wave_label = Label.new()
	wave_label.text = "Waveform:"
	controls_container.add_child(wave_label)
	
	var wave_option = OptionButton.new()
	wave_option.add_item("Sine")
	wave_option.add_item("Square")
	wave_option.add_item("Triangle")
	wave_option.add_item("Saw")
	wave_option.selected = 0
	wave_option.item_selected.connect(_on_waveform_changed)
	controls_container.add_child(wave_option)
	
	# Volume control
	var volume_label = Label.new()
	volume_label.text = "Volume:"
	controls_container.add_child(volume_label)
	
	var volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.value = 0.5
	volume_slider.step = 0.01
	volume_slider.value_changed.connect(_on_volume_changed)
	controls_container.add_child(volume_slider)
	
	# Octave control
	var octave_label = Label.new()
	octave_label.text = "Octave:"
	controls_container.add_child(octave_label)
	
	var octave_spin = SpinBox.new()
	octave_spin.min_value = -4
	octave_spin.max_value = 4
	octave_spin.value = 0
	octave_spin.value_changed.connect(_on_octave_changed)
	controls_container.add_child(octave_spin)
	
	# Scale selection
	var scale_label = Label.new()
	scale_label.text = "Scale:"
	controls_container.add_child(scale_label)
	
	var scale_option = OptionButton.new()
	scale_option.add_item("Major")
	scale_option.add_item("Minor")
	scale_option.add_item("Pentatonic Major")
	scale_option.add_item("Pentatonic Minor")
	scale_option.add_item("Blues")
	scale_option.add_item("Chromatic")
	scale_option.selected = 2  # Pentatonic Major
	scale_option.item_selected.connect(_on_scale_changed)
	controls_container.add_child(scale_option)
	
	# Play all lanes button
	var play_all_button = Button.new()
	play_all_button.text = "Play All Lanes"
	play_all_button.pressed.connect(_play_all_lanes)
	controls_container.add_child(play_all_button)
	
	# Stop all lanes button
	var stop_all_button = Button.new()
	stop_all_button.text = "Stop All Lanes"
	stop_all_button.pressed.connect(_stop_all_lanes)
	controls_container.add_child(stop_all_button)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				_select_lane(LaneSoundSystem.LaneType.LEFT)
			KEY_UP:
				_select_lane(LaneSoundSystem.LaneType.CENTER)
			KEY_RIGHT:
				_select_lane(LaneSoundSystem.LaneType.RIGHT)
			KEY_SPACE:
				_toggle_playback()

func _toggle_playback():
	if lane_sound_system.is_playing():
		lane_sound_system.stop_playback()
		status_label.text = "Status: Stopped"
	else:
		lane_sound_system.start_playback()
		status_label.text = "Status: Playing"

func _select_lane(lane: int):
	lane_sound_system.set_current_lane(lane)

func _on_lane_changed(old_lane: int, new_lane: int):
	var lane_names = ["Left", "Center", "Right"]
	current_lane_label.text = "Current Lane: " + lane_names[new_lane]

func _on_waveform_changed(index: int):
	var current_lane = lane_sound_system.get_current_lane()
	lane_sound_system.set_lane_waveform(current_lane, index)

func _on_volume_changed(value: float):
	var current_lane = lane_sound_system.get_current_lane()
	lane_sound_system.set_lane_volume(current_lane, value)

func _on_octave_changed(value: float):
	var current_lane = lane_sound_system.get_current_lane()
	lane_sound_system.set_lane_octave(current_lane, int(value))

func _on_scale_changed(index: int):
	lane_sound_system.set_global_scale(index)

func _play_all_lanes():
	lane_sound_system.start_all_lanes()
	status_label.text = "Status: All Lanes Playing"

func _stop_all_lanes():
	lane_sound_system.stop_all_lanes()
	status_label.text = "Status: All Lanes Stopped"