extends Node2D

# Simple Sound Playback Test
# Story 004: Create a standalone test for playing sounds through the audio systems
# Combines lane sounds, beat synchronization, and visual feedback

const BeatIndicator = preload("res://scripts/components/visual/beat_indicator.gd")
const BeatVisualizationPanel = preload("res://scripts/components/visual/beat_visualization_panel.gd")

# UI References
var _ui_panel: Panel
var _play_button: Button
var _bpm_slider: HSlider
var _bpm_label: Label
var _metronome_check: CheckBox
var _volume_slider: HSlider
var _volume_label: Label
var _octave_spin: SpinBox
var _waveform_option: OptionButton
var _scale_option: OptionButton

# Visual feedback components
var _lane_indicators: Dictionary = {}
var _beat_visualization: BeatVisualizationPanel
var _status_label: Label

# Lane sound system
var _lane_sound_system: Node
var _playback_sync: Node

# Current state
var _current_lane: int = -1
var _is_playing: bool = false
var _lane_keys: Dictionary = {
	KEY_Q: 0,  # Left lane
	KEY_W: 1,  # Center lane  
	KEY_E: 2   # Right lane
}

func _ready() -> void:
	_setup_ui()
	_setup_lane_sound_system()
	_setup_playback_sync()
	_setup_visual_indicators()
	_connect_signals()
	
	# Set initial values
	BeatManager.bpm = 120
	_update_bpm_label(120)

func _setup_ui() -> void:
	# Main panel
	_ui_panel = Panel.new()
	_ui_panel.size = Vector2(800, 600)
	_ui_panel.position = Vector2(20, 20)
	add_child(_ui_panel)
	
	# Title
	var title = Label.new()
	title.text = "Simple Sound Playback Test - Story 004"
	title.add_theme_font_size_override("font_size", 24)
	title.position = Vector2(20, 20)
	_ui_panel.add_child(title)
	
	# Instructions
	var instructions = RichTextLabel.new()
	instructions.bbcode_enabled = true
	instructions.text = "[b]Keyboard Controls:[/b]\n" + \
		"[color=cyan]Q[/color] - Play Left Lane\n" + \
		"[color=cyan]W[/color] - Play Center Lane\n" + \
		"[color=cyan]E[/color] - Play Right Lane\n" + \
		"[color=cyan]SPACE[/color] - Start/Stop Playback\n" + \
		"[color=cyan]ESC[/color] - Clear Current Lane"
	instructions.size = Vector2(300, 150)
	instructions.position = Vector2(20, 60)
	_ui_panel.add_child(instructions)
	
	# Play/Stop button
	_play_button = Button.new()
	_play_button.text = "Start Playback"
	_play_button.size = Vector2(150, 40)
	_play_button.position = Vector2(20, 220)
	_ui_panel.add_child(_play_button)
	
	# BPM Slider
	var bpm_container = VBoxContainer.new()
	bpm_container.position = Vector2(20, 280)
	_ui_panel.add_child(bpm_container)
	
	_bpm_label = Label.new()
	_bpm_label.text = "BPM: 120"
	bpm_container.add_child(_bpm_label)
	
	_bpm_slider = HSlider.new()
	_bpm_slider.min_value = 60
	_bpm_slider.max_value = 240
	_bpm_slider.value = 120
	_bpm_slider.size = Vector2(200, 20)
	_bpm_slider.step = 1.0
	bpm_container.add_child(_bpm_slider)
	
	# Metronome toggle
	_metronome_check = CheckBox.new()
	_metronome_check.text = "Enable Metronome"
	_metronome_check.position = Vector2(20, 340)
	_ui_panel.add_child(_metronome_check)
	
	# Sound Parameters Section
	var params_label = Label.new()
	params_label.text = "Sound Parameters"
	params_label.add_theme_font_size_override("font_size", 18)
	params_label.position = Vector2(350, 60)
	_ui_panel.add_child(params_label)
	
	# Waveform selection
	var waveform_label = Label.new()
	waveform_label.text = "Waveform:"
	waveform_label.position = Vector2(350, 100)
	_ui_panel.add_child(waveform_label)
	
	_waveform_option = OptionButton.new()
	_waveform_option.add_item("Sine")
	_waveform_option.add_item("Square")
	_waveform_option.add_item("Triangle")
	_waveform_option.add_item("Saw")
	_waveform_option.position = Vector2(450, 95)
	_waveform_option.size = Vector2(120, 30)
	_ui_panel.add_child(_waveform_option)
	
	# Volume control
	var volume_container = VBoxContainer.new()
	volume_container.position = Vector2(350, 140)
	_ui_panel.add_child(volume_container)
	
	_volume_label = Label.new()
	_volume_label.text = "Volume: 50%"
	volume_container.add_child(_volume_label)
	
	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 1.0
	_volume_slider.value = 0.5
	_volume_slider.step = 0.01
	_volume_slider.size = Vector2(200, 20)
	volume_container.add_child(_volume_slider)
	
	# Octave control
	var octave_label = Label.new()
	octave_label.text = "Octave:"
	octave_label.position = Vector2(350, 200)
	_ui_panel.add_child(octave_label)
	
	_octave_spin = SpinBox.new()
	_octave_spin.min_value = -4
	_octave_spin.max_value = 4
	_octave_spin.value = 0
	_octave_spin.position = Vector2(450, 195)
	_octave_spin.size = Vector2(100, 30)
	_ui_panel.add_child(_octave_spin)
	
	# Scale selection
	var scale_label = Label.new()
	scale_label.text = "Scale:"
	scale_label.position = Vector2(350, 240)
	_ui_panel.add_child(scale_label)
	
	_scale_option = OptionButton.new()
	_scale_option.add_item("Major")
	_scale_option.add_item("Minor")
	_scale_option.add_item("Pentatonic")
	_scale_option.add_item("Blues")
	_scale_option.add_item("Chromatic")
	_scale_option.position = Vector2(450, 235)
	_scale_option.size = Vector2(120, 30)
	_ui_panel.add_child(_scale_option)
	
	# Status label
	_status_label = Label.new()
	_status_label.text = "Status: Ready"
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.position = Vector2(20, 400)
	_ui_panel.add_child(_status_label)

func _setup_lane_sound_system() -> void:
	_lane_sound_system = preload("res://scripts/components/sound/lane_sound_system.gd").new()
	add_child(_lane_sound_system)

func _setup_playback_sync() -> void:
	# Create PlaybackSync for metronome functionality
	var PlaybackSyncClass = preload("res://scripts/components/sound/playback_sync.gd")
	_playback_sync = PlaybackSyncClass.new()
	add_child(_playback_sync)

func _setup_visual_indicators() -> void:
	# Create beat visualization panel
	_beat_visualization = BeatVisualizationPanel.new()
	_beat_visualization.position = Vector2(50, 480)
	add_child(_beat_visualization)
	
	# Create lane indicators (visual feedback for each lane)
	var colors = [Color.RED, Color.GREEN, Color.BLUE]
	var names = ["Left (Q)", "Center (W)", "Right (E)"]
	var shapes = ["Circle", "Square", "Diamond"]
	
	for i in range(3):
		var indicator_container = VBoxContainer.new()
		indicator_container.position = Vector2(350 + i * 150, 350)
		_ui_panel.add_child(indicator_container)
		
		var label = Label.new()
		label.text = names[i]
		label.add_theme_font_size_override("font_size", 14)
		indicator_container.add_child(label)
		
		var indicator = BeatIndicator.new()
		indicator.pulse_color = colors[i]
		indicator.pulse_duration = 0.3
		indicator.indicator_shape = shapes[i]
		indicator.size = Vector2(80, 80)
		indicator_container.add_child(indicator)
		
		_lane_indicators[i] = indicator

func _connect_signals() -> void:
	_play_button.pressed.connect(_on_play_button_pressed)
	_bpm_slider.value_changed.connect(_on_bpm_changed)
	_metronome_check.toggled.connect(_on_metronome_toggled)
	_volume_slider.value_changed.connect(_on_volume_changed)
	_octave_spin.value_changed.connect(_on_octave_changed)
	_waveform_option.item_selected.connect(_on_waveform_selected)
	_scale_option.item_selected.connect(_on_scale_selected)
	
	# Connect to beat manager for visual sync
	BeatManager.beat_occurred.connect(_on_beat_occurred)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_Q:
				_trigger_lane(0)
			KEY_W:
				_trigger_lane(1)
			KEY_E:
				_trigger_lane(2)
			KEY_SPACE:
				_on_play_button_pressed()
			KEY_ESCAPE:
				_clear_current_lane()

func _trigger_lane(lane: int) -> void:
	if _current_lane != lane:
		# Stop previous lane if any
		if _current_lane >= 0 and _lane_sound_system.is_playing():
			_lane_sound_system.stop_playback()
			_lane_indicators[_current_lane].modulate = Color.WHITE
		
		# Play new lane
		_current_lane = lane
		_lane_sound_system.set_current_lane(lane)
		_lane_sound_system.start_playback()
		_lane_indicators[lane].trigger_pulse()
		_lane_indicators[lane].modulate = Color(1.5, 1.5, 1.5)  # Brighten active lane
		_status_label.text = "Playing Lane %d" % lane
	else:
		# Toggle off if same lane
		_clear_current_lane()

func _clear_current_lane() -> void:
	if _current_lane >= 0:
		_lane_sound_system.stop_playback()
		_lane_indicators[_current_lane].modulate = Color.WHITE
		_current_lane = -1
		_status_label.text = "Status: Ready"

func _on_play_button_pressed() -> void:
	_is_playing = !_is_playing
	if _is_playing:
		BeatManager.start()
		_play_button.text = "Stop Playback"
		_status_label.text = "Status: Playing"
	else:
		BeatManager.stop()
		_play_button.text = "Start Playback"
		_status_label.text = "Status: Stopped"
		_clear_current_lane()

func _on_bpm_changed(value: float) -> void:
	BeatManager.bpm = int(value)
	_update_bpm_label(int(value))

func _update_bpm_label(bpm: int) -> void:
	_bpm_label.text = "BPM: %d" % bpm

func _on_metronome_toggled(enabled: bool) -> void:
	if BeatManager.has_method("enable_metronome"):
		if enabled:
			BeatManager.enable_metronome()
		else:
			BeatManager.disable_metronome()

func _on_volume_changed(value: float) -> void:
	_volume_label.text = "Volume: %d%%" % int(value * 100)
	if _current_lane >= 0:
		_lane_sound_system.set_lane_volume(_current_lane, value)

func _on_octave_changed(value: float) -> void:
	if _current_lane >= 0:
		_lane_sound_system.set_lane_octave(_current_lane, int(value))

func _on_waveform_selected(index: int) -> void:
	if _current_lane >= 0:
		_lane_sound_system.set_lane_waveform(_current_lane, index)

func _on_scale_selected(index: int) -> void:
	var scale_enums = [
		preload("res://scripts/components/sound/sound_generator.gd").Scale.MAJOR,
		preload("res://scripts/components/sound/sound_generator.gd").Scale.MINOR,
		preload("res://scripts/components/sound/sound_generator.gd").Scale.PENTATONIC_MAJOR,
		preload("res://scripts/components/sound/sound_generator.gd").Scale.BLUES,
		preload("res://scripts/components/sound/sound_generator.gd").Scale.CHROMATIC
	]
	_lane_sound_system.set_global_scale(scale_enums[index])

func _on_beat_occurred(beat_number: int, beat_time: float) -> void:
	# Visual pulse on beat
	var beat_in_measure = beat_number % BeatManager.beats_per_measure
	if beat_in_measure == 0:
		# Stronger pulse on downbeat
		for indicator in _lane_indicators.values():
			if indicator.modulate.r > 1.0:  # Only pulse active lanes
				indicator.trigger_pulse()