extends Node2D

# Metronome Test Scene
# Tests if the metronome actually produces audible sounds

var _status_label: Label
var _tick_button: Button
var _tock_button: Button
var _enable_button: Button
var _bpm_slider: HSlider
var _bpm_label: Label
var _volume_slider: HSlider
var _volume_label: Label

var _is_metronome_enabled: bool = false

func _ready():
	_setup_ui()
	_connect_signals()

func _setup_ui():
	# Status label
	_status_label = Label.new()
	_status_label.text = "Metronome Test - Press buttons to test sounds"
	_status_label.position = Vector2(300, 50)
	add_child(_status_label)
	
	# Tick button
	_tick_button = Button.new()
	_tick_button.text = "Play Tick"
	_tick_button.position = Vector2(300, 100)
	_tick_button.size = Vector2(100, 40)
	add_child(_tick_button)
	
	# Tock button
	_tock_button = Button.new()
	_tock_button.text = "Play Tock"
	_tock_button.position = Vector2(420, 100)
	_tock_button.size = Vector2(100, 40)
	add_child(_tock_button)
	
	# Enable metronome button
	_enable_button = Button.new()
	_enable_button.text = "Enable Metronome"
	_enable_button.position = Vector2(300, 150)
	_enable_button.size = Vector2(220, 40)
	add_child(_enable_button)
	
	# BPM slider
	var bpm_container = VBoxContainer.new()
	bpm_container.position = Vector2(300, 200)
	add_child(bpm_container)
	
	_bpm_label = Label.new()
	_bpm_label.text = "BPM: 120"
	bpm_container.add_child(_bpm_label)
	
	_bpm_slider = HSlider.new()
	_bpm_slider.min_value = 60
	_bpm_slider.max_value = 240
	_bpm_slider.value = 120
	_bpm_slider.step = 1
	_bpm_slider.size = Vector2(200, 20)
	bpm_container.add_child(_bpm_slider)
	
	# Volume slider
	var volume_container = VBoxContainer.new()
	volume_container.position = Vector2(300, 260)
	add_child(volume_container)
	
	_volume_label = Label.new()
	_volume_label.text = "Volume: -6 dB"
	volume_container.add_child(_volume_label)
	
	_volume_slider = HSlider.new()
	_volume_slider.min_value = -20
	_volume_slider.max_value = 0
	_volume_slider.value = -6
	_volume_slider.step = 1
	_volume_slider.size = Vector2(200, 20)
	volume_container.add_child(_volume_slider)

func _connect_signals():
	_tick_button.pressed.connect(_on_tick_pressed)
	_tock_button.pressed.connect(_on_tock_pressed)
	_enable_button.pressed.connect(_on_enable_pressed)
	_bpm_slider.value_changed.connect(_on_bpm_changed)
	_volume_slider.value_changed.connect(_on_volume_changed)

func _on_tick_pressed():
	# Create a metronome generator directly
	var metronome = preload("res://scripts/components/sound/metronome_generator.gd").new()
	add_child(metronome)
	metronome.play_tick(_volume_slider.value)
	
	# Clean up after sound plays
	await get_tree().create_timer(0.5).timeout
	metronome.queue_free()
	
	_status_label.text = "Played tick sound"

func _on_tock_pressed():
	# Create a metronome generator directly
	var metronome = preload("res://scripts/components/sound/metronome_generator.gd").new()
	add_child(metronome)
	metronome.play_tock(_volume_slider.value)
	
	# Clean up after sound plays
	await get_tree().create_timer(0.5).timeout
	metronome.queue_free()
	
	_status_label.text = "Played tock sound"

func _on_enable_pressed():
	_is_metronome_enabled = !_is_metronome_enabled
	
	if _is_metronome_enabled:
		BeatManager.bpm = _bpm_slider.value
		BeatManager.set_metronome_volume(_volume_slider.value)
		BeatManager.enable_metronome()
		BeatManager.start()
		_enable_button.text = "Disable Metronome"
		_status_label.text = "Metronome enabled - BPM: %d" % int(_bpm_slider.value)
	else:
		BeatManager.stop()
		BeatManager.disable_metronome()
		_enable_button.text = "Enable Metronome"
		_status_label.text = "Metronome disabled"

func _on_bpm_changed(value: float):
	_bpm_label.text = "BPM: %d" % int(value)
	if _is_metronome_enabled:
		BeatManager.bpm = value

func _on_volume_changed(value: float):
	_volume_label.text = "Volume: %d dB" % int(value)
	BeatManager.set_metronome_volume(value)

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		if _is_metronome_enabled:
			_on_enable_pressed()  # Disable metronome