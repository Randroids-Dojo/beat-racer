extends PanelContainer
class_name PlaybackModeIndicator

# Playback Mode Indicator
# UI component showing current playback state and controls

signal play_pressed()
signal pause_pressed()
signal stop_pressed()
signal loop_toggled(enabled: bool)
signal speed_changed(speed: float)

# UI References
var mode_label: Label
var status_label: Label
var progress_bar: ProgressBar
var play_pause_button: Button
var stop_button: Button
var loop_button: CheckButton
var speed_slider: HSlider
var speed_label: Label
var loop_count_label: Label

# Visual settings
@export var indicator_size: Vector2 = Vector2(300, 150)
@export var recording_color: Color = Color(1.0, 0.3, 0.3)  # Red
@export var playback_color: Color = Color(0.3, 0.8, 1.0)  # Blue
@export var paused_color: Color = Color(1.0, 1.0, 0.3)  # Yellow

# State
enum Mode { IDLE, RECORDING, PLAYING, PAUSED }
var current_mode: Mode = Mode.IDLE
var playback_progress: float = 0.0
var loop_count: int = 0
var is_looping: bool = true
var playback_speed: float = 1.0


func _ready():
	custom_minimum_size = indicator_size
	
	# Create UI structure
	var vbox = VBoxContainer.new()
	add_child(vbox)
	
	# Mode label
	mode_label = Label.new()
	mode_label.add_theme_font_size_override("font_size", 18)
	mode_label.text = "IDLE"
	vbox.add_child(mode_label)
	
	# Status label
	status_label = Label.new()
	status_label.text = "No recording loaded"
	vbox.add_child(status_label)
	
	# Progress bar
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.y = 20
	progress_bar.value = 0
	vbox.add_child(progress_bar)
	
	# Control buttons
	var button_container = HBoxContainer.new()
	vbox.add_child(button_container)
	
	play_pause_button = Button.new()
	play_pause_button.text = "Play"
	play_pause_button.pressed.connect(_on_play_pause_pressed)
	button_container.add_child(play_pause_button)
	
	stop_button = Button.new()
	stop_button.text = "Stop"
	stop_button.pressed.connect(_on_stop_pressed)
	stop_button.disabled = true
	button_container.add_child(stop_button)
	
	# Loop control
	var loop_container = HBoxContainer.new()
	vbox.add_child(loop_container)
	
	loop_button = CheckButton.new()
	loop_button.text = "Loop"
	loop_button.button_pressed = is_looping
	loop_button.toggled.connect(_on_loop_toggled)
	loop_container.add_child(loop_button)
	
	loop_count_label = Label.new()
	loop_count_label.text = "Loops: 0"
	loop_container.add_child(loop_count_label)
	
	# Speed control
	var speed_container = HBoxContainer.new()
	vbox.add_child(speed_container)
	
	var speed_title = Label.new()
	speed_title.text = "Speed: "
	speed_container.add_child(speed_title)
	
	speed_slider = HSlider.new()
	speed_slider.min_value = 0.25
	speed_slider.max_value = 2.0
	speed_slider.value = 1.0
	speed_slider.step = 0.25
	speed_slider.custom_minimum_size.x = 100
	speed_slider.value_changed.connect(_on_speed_changed)
	speed_container.add_child(speed_slider)
	
	speed_label = Label.new()
	speed_label.text = "1.0x"
	speed_container.add_child(speed_label)
	
	# Set initial theme
	_update_theme()


func set_mode(mode: Mode):
	"""Update current mode and UI"""
	current_mode = mode
	_update_mode_display()
	_update_theme()


func set_recording_active(active: bool):
	"""Update UI for recording state"""
	if active:
		set_mode(Mode.RECORDING)
		play_pause_button.disabled = true
		stop_button.disabled = true
		loop_button.disabled = true
		speed_slider.editable = false
	else:
		set_mode(Mode.IDLE)
		play_pause_button.disabled = false
		stop_button.disabled = true
		loop_button.disabled = false
		speed_slider.editable = true


func set_playback_active(active: bool):
	"""Update UI for playback state"""
	if active:
		set_mode(Mode.PLAYING)
		play_pause_button.text = "Pause"
		stop_button.disabled = false
	else:
		set_mode(Mode.IDLE)
		play_pause_button.text = "Play"
		stop_button.disabled = true
		progress_bar.value = 0
		loop_count = 0
		_update_loop_display()


func set_playback_paused(paused: bool):
	"""Update UI for paused state"""
	if paused:
		set_mode(Mode.PAUSED)
		play_pause_button.text = "Resume"
	else:
		set_mode(Mode.PLAYING)
		play_pause_button.text = "Pause"


func update_playback_progress(progress: float):
	"""Update progress bar (0.0 to 1.0)"""
	playback_progress = progress
	progress_bar.value = progress * 100.0


func update_loop_count(count: int):
	"""Update loop counter"""
	loop_count = count
	_update_loop_display()


func set_recording_loaded(loaded: bool):
	"""Update UI when recording is loaded/unloaded"""
	if loaded:
		status_label.text = "Recording loaded"
		play_pause_button.disabled = false
	else:
		status_label.text = "No recording loaded"
		play_pause_button.disabled = true
		progress_bar.value = 0


func _update_mode_display():
	"""Update mode label text"""
	match current_mode:
		Mode.IDLE:
			mode_label.text = "IDLE"
		Mode.RECORDING:
			mode_label.text = "RECORDING"
		Mode.PLAYING:
			mode_label.text = "PLAYING"
		Mode.PAUSED:
			mode_label.text = "PAUSED"


func _update_theme():
	"""Update colors based on mode"""
	var color = Color.WHITE
	
	match current_mode:
		Mode.RECORDING:
			color = recording_color
		Mode.PLAYING:
			color = playback_color
		Mode.PAUSED:
			color = paused_color
		_:
			color = Color.WHITE
	
	mode_label.modulate = color
	
	# Update panel style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = color
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	add_theme_stylebox_override("panel", style)


func _update_loop_display():
	"""Update loop count display"""
	loop_count_label.text = "Loops: %d" % loop_count


func _on_play_pause_pressed():
	"""Handle play/pause button"""
	match current_mode:
		Mode.IDLE:
			emit_signal("play_pressed")
		Mode.PLAYING:
			emit_signal("pause_pressed")
		Mode.PAUSED:
			emit_signal("play_pressed")


func _on_stop_pressed():
	"""Handle stop button"""
	emit_signal("stop_pressed")


func _on_loop_toggled(pressed: bool):
	"""Handle loop toggle"""
	is_looping = pressed
	emit_signal("loop_toggled", pressed)


func _on_speed_changed(value: float):
	"""Handle speed slider change"""
	playback_speed = value
	speed_label.text = "%.2fx" % value
	emit_signal("speed_changed", value)