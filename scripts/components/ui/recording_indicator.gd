extends Control
class_name RecordingIndicator

# Recording Indicator UI
# Shows recording status and progress

signal recording_toggled(is_recording: bool)

# Visual settings
@export var recording_color: Color = Color(1.0, 0.2, 0.2)
@export var idle_color: Color = Color(0.5, 0.5, 0.5)
@export var pulse_speed: float = 2.0
@export var show_sample_count: bool = true
@export var show_duration: bool = true
@export var show_progress_bar: bool = true

# Components
@onready var status_label: Label = $StatusLabel
@onready var info_label: Label = $InfoLabel
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var record_button: Button = $RecordButton
@onready var indicator_light: Panel = $IndicatorLight

# References
var lap_recorder: LapRecorder

# State
var is_recording: bool = false
var pulse_timer: float = 0.0


func _ready():
	# Create UI if not in scene
	if not status_label:
		_create_ui()
	
	# Connect button
	if record_button:
		record_button.pressed.connect(_on_record_button_pressed)
	
	# Initial state
	_update_display()


func _create_ui():
	"""Create UI elements programmatically"""
	# Status label
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "IDLE"
	status_label.add_theme_font_size_override("font_size", 24)
	status_label.position = Vector2(10, 10)
	add_child(status_label)
	
	# Info label
	info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.text = "Ready to record"
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.position = Vector2(10, 40)
	add_child(info_label)
	
	# Progress bar
	if show_progress_bar:
		progress_bar = ProgressBar.new()
		progress_bar.name = "ProgressBar"
		progress_bar.position = Vector2(10, 70)
		progress_bar.size = Vector2(200, 20)
		progress_bar.value = 0
		add_child(progress_bar)
	
	# Record button
	record_button = Button.new()
	record_button.name = "RecordButton"
	record_button.text = "Start Recording"
	record_button.position = Vector2(10, 100)
	record_button.size = Vector2(120, 30)
	add_child(record_button)
	
	# Indicator light
	indicator_light = Panel.new()
	indicator_light.name = "IndicatorLight"
	indicator_light.position = Vector2(220, 10)
	indicator_light.size = Vector2(30, 30)
	indicator_light.modulate = idle_color
	add_child(indicator_light)


func setup(recorder: LapRecorder):
	"""Connect to lap recorder"""
	lap_recorder = recorder
	
	if not lap_recorder:
		push_error("RecordingIndicator requires a LapRecorder reference")
		return
	
	# Connect signals
	lap_recorder.recording_started.connect(_on_recording_started)
	lap_recorder.recording_stopped.connect(_on_recording_stopped)
	lap_recorder.lap_completed.connect(_on_lap_completed)
	lap_recorder.recording_state_changed.connect(_on_recording_state_changed)


func _process(delta: float):
	if not lap_recorder:
		return
	
	# Update recording display
	if is_recording:
		_update_recording_info()
		
		# Pulse effect
		pulse_timer += delta * pulse_speed
		var pulse = (sin(pulse_timer) + 1.0) * 0.5
		indicator_light.modulate = recording_color * (0.5 + pulse * 0.5)
	
	# Update progress bar
	if progress_bar and is_recording:
		progress_bar.value = lap_recorder.get_recording_progress() * 100.0


func _update_display():
	"""Update all display elements"""
	if is_recording:
		status_label.text = "RECORDING"
		status_label.modulate = recording_color
		record_button.text = "Stop Recording"
		
		if not lap_recorder:
			info_label.text = "Recording..."
	else:
		status_label.text = "IDLE"
		status_label.modulate = Color.WHITE
		record_button.text = "Start Recording"
		info_label.text = "Ready to record"
		indicator_light.modulate = idle_color
		
		if progress_bar:
			progress_bar.value = 0


func _update_recording_info():
	"""Update recording information display"""
	if not lap_recorder:
		return
	
	var info_text = ""
	
	# Duration
	if show_duration:
		var duration = lap_recorder.get_recording_duration()
		info_text += "Time: %.1fs" % duration
	
	# Sample count
	if show_sample_count:
		var samples = lap_recorder.get_sample_count()
		if info_text != "":
			info_text += " | "
		info_text += "Samples: %d" % samples
	
	info_label.text = info_text


func _on_record_button_pressed():
	"""Handle record button press"""
	if not lap_recorder:
		push_error("No LapRecorder connected")
		return
	
	if is_recording:
		lap_recorder.stop_recording()
	else:
		lap_recorder.start_recording()
	
	emit_signal("recording_toggled", not is_recording)


func _on_recording_started():
	"""Handle recording started"""
	is_recording = true
	pulse_timer = 0.0
	_update_display()


func _on_recording_stopped():
	"""Handle recording stopped"""
	is_recording = false
	_update_display()


func _on_lap_completed(lap_data):
	"""Handle lap completion"""
	info_label.text = "Lap completed! Duration: %.1fs" % lap_data.duration
	info_label.modulate = Color(0.2, 1.0, 0.2)
	
	# Reset color after delay
	await get_tree().create_timer(2.0).timeout
	info_label.modulate = Color.WHITE


func _on_recording_state_changed(recording: bool):
	"""Handle recording state change"""
	is_recording = recording
	_update_display()


# Manual control methods
func start_recording():
	"""Manually start recording"""
	if lap_recorder and not is_recording:
		lap_recorder.start_recording()


func stop_recording():
	"""Manually stop recording"""
	if lap_recorder and is_recording:
		lap_recorder.stop_recording()


func set_custom_info(text: String):
	"""Set custom info text"""
	info_label.text = text