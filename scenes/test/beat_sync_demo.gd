extends Node2D

# Beat Sync Demo Scene
# Demonstrates the complete beat synchronization system

var PlaybackSync = preload("res://scripts/components/sound/playback_sync.gd")
var BeatEventSystem = preload("res://scripts/components/sound/beat_event_system.gd")
var BeatIndicator = preload("res://scripts/components/visual/beat_indicator.gd")
var BeatVisualizationPanel = preload("res://scripts/components/visual/beat_visualization_panel.gd")
var LaneSoundSystem = preload("res://scripts/components/sound/lane_sound_system.gd")

# Components
var playback_sync: PlaybackSync
var beat_event_system: BeatEventSystem
var visualization_panel: BeatVisualizationPanel
var lane_sound_system: LaneSoundSystem

# UI Elements
var start_button: Button
var stop_button: Button
var bpm_slider: HSlider
var bpm_label: Label
var metronome_checkbox: CheckBox
var lane_selector: OptionButton

func _ready():
	# Add to playback_sync group for visualization panel
	add_to_group("playback_sync")
	
	# Create components
	_create_components()
	_create_ui()
	_setup_demo_events()
	
	print("Beat Sync Demo ready!")
	print("Press Start to begin beat synchronization")

func _create_components():
	# Create playback sync
	playback_sync = PlaybackSync.new()
	playback_sync.name = "PlaybackSync"
	add_child(playback_sync)
	
	# Create beat event system
	beat_event_system = BeatEventSystem.new()
	beat_event_system.name = "BeatEventSystem"
	add_child(beat_event_system)
	
	# Create lane sound system
	lane_sound_system = LaneSoundSystem.new()
	lane_sound_system.name = "LaneSoundSystem"
	add_child(lane_sound_system)
	
	# Create visualization panel
	visualization_panel = BeatVisualizationPanel.new()
	visualization_panel.position = Vector2(50, 50)
	visualization_panel.size = Vector2(300, 400)
	add_child(visualization_panel)

func _create_ui():
	# Control panel
	var control_panel = PanelContainer.new()
	control_panel.position = Vector2(400, 50)
	control_panel.size = Vector2(300, 400)
	add_child(control_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	control_panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Beat Sync Controls"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	# Start/Stop buttons
	var button_container = HBoxContainer.new()
	vbox.add_child(button_container)
	
	start_button = Button.new()
	start_button.text = "Start"
	start_button.pressed.connect(_on_start_pressed)
	button_container.add_child(start_button)
	
	stop_button = Button.new()
	stop_button.text = "Stop"
	stop_button.pressed.connect(_on_stop_pressed)
	stop_button.disabled = true
	button_container.add_child(stop_button)
	
	# BPM control
	var bpm_container = VBoxContainer.new()
	vbox.add_child(bpm_container)
	
	bpm_label = Label.new()
	bpm_label.text = "BPM: 120"
	bpm_container.add_child(bpm_label)
	
	bpm_slider = HSlider.new()
	bpm_slider.min_value = 60.0
	bpm_slider.max_value = 240.0
	bpm_slider.value = 120.0
	bpm_slider.step = 1.0
	bpm_slider.value_changed.connect(_on_bpm_changed)
	bpm_container.add_child(bpm_slider)
	
	# Metronome toggle
	metronome_checkbox = CheckBox.new()
	metronome_checkbox.text = "Enable Metronome"
	metronome_checkbox.toggled.connect(_on_metronome_toggled)
	vbox.add_child(metronome_checkbox)
	
	# Lane selector
	var lane_container = VBoxContainer.new()
	vbox.add_child(lane_container)
	
	var lane_label = Label.new()
	lane_label.text = "Current Lane:"
	lane_container.add_child(lane_label)
	
	lane_selector = OptionButton.new()
	lane_selector.add_item("Left")
	lane_selector.add_item("Center")
	lane_selector.add_item("Right")
	lane_selector.selected = 1  # Center by default
	lane_selector.item_selected.connect(_on_lane_selected)
	lane_container.add_child(lane_selector)
	
	# Info text
	var info = RichTextLabel.new()
	info.text = "[b]Instructions:[/b]\n"
	info.text += "• Use Start/Stop to control playback\n"
	info.text += "• Adjust BPM with the slider\n"
	info.text += "• Toggle metronome for audio feedback\n"
	info.text += "• Switch lanes to hear different sounds\n"
	info.text += "• Watch the visual indicators sync to the beat!"
	info.bbcode_enabled = true
	info.fit_content = true
	vbox.add_child(info)

func _setup_demo_events():
	# Register some demo events
	beat_event_system.register_event(
		"demo_beat_flash",
		Callable(self, "_on_demo_beat"),
		BeatEventSystem.Quantization.BEAT
	)
	
	beat_event_system.register_event(
		"demo_measure_change",
		Callable(self, "_on_demo_measure"),
		BeatEventSystem.Quantization.MEASURE
	)
	
	# Create additional visual indicators
	var positions = [
		Vector2(100, 500),
		Vector2(200, 500),
		Vector2(300, 500),
		Vector2(400, 500)
	]
	
	for i in range(4):
		var indicator = BeatIndicator.new()
		indicator.position = positions[i]
		indicator.indicator_size = 50.0
		indicator.indicator_shape = ["Circle", "Square", "Diamond", "Circle"][i]
		indicator.pulse_color = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW][i]
		add_child(indicator)

func _on_start_pressed():
	# Start all systems
	BeatManager.start()
	playback_sync.start_sync()
	lane_sound_system.start_playback()
	
	# Update UI
	start_button.disabled = true
	stop_button.disabled = false
	
	print("Beat synchronization started!")

func _on_stop_pressed():
	# Stop all systems
	BeatManager.stop()
	playback_sync.stop_sync()
	lane_sound_system.stop_playback()
	
	# Update UI
	start_button.disabled = false
	stop_button.disabled = true
	
	print("Beat synchronization stopped!")

func _on_bpm_changed(value: float):
	BeatManager.bpm = value
	lane_sound_system.set_bpm(value)
	bpm_label.text = "BPM: %d" % int(value)

func _on_metronome_toggled(pressed: bool):
	playback_sync.set_metronome_enabled(pressed)

func _on_lane_selected(index: int):
	lane_sound_system.set_current_lane(index)

func _on_demo_beat(data: Dictionary):
	# Could add additional visual effects here
	pass

func _on_demo_measure(data: Dictionary):
	# Could trigger lane changes or other effects
	pass

func _unhandled_key_input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				if start_button.disabled:
					_on_stop_pressed()
				else:
					_on_start_pressed()
			KEY_LEFT:
				lane_selector.selected = 0
				_on_lane_selected(0)
			KEY_UP:
				lane_selector.selected = 1
				_on_lane_selected(1)
			KEY_RIGHT:
				lane_selector.selected = 2
				_on_lane_selected(2)