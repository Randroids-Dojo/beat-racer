extends PanelContainer
class_name BPMControl

# BPM Control
# Display and control for beats per minute

signal bpm_changed(new_bpm: float)
signal tap_tempo_detected(bpm: float)

# BPM settings
@export var min_bpm: float = 60.0
@export var max_bpm: float = 240.0
@export var bpm_step: float = 5.0
@export var default_bpm: float = 120.0

# Visual settings
@export var control_size: Vector2 = Vector2(200, 100)
@export var enable_tap_tempo: bool = true
@export var tap_timeout: float = 2.0  # Reset taps after this time

# UI References
var bpm_label: Label
var bpm_value_label: Label
var bpm_slider: HSlider
var decrease_button: Button
var increase_button: Button
var tap_button: Button
var preset_container: HBoxContainer

# Tap tempo tracking
var tap_times: Array[float] = []
var last_tap_time: float = 0.0

# State
var current_bpm: float = 120.0
var beat_manager: Node


func _ready():
	custom_minimum_size = control_size
	
	# Get beat manager
	beat_manager = get_node("/root/BeatManager") if has_node("/root/BeatManager") else null
	if beat_manager:
		current_bpm = beat_manager.bpm
	else:
		current_bpm = default_bpm
	
	# Create UI structure
	var vbox = VBoxContainer.new()
	add_child(vbox)
	
	# BPM display
	var display_container = HBoxContainer.new()
	display_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(display_container)
	
	bpm_label = Label.new()
	bpm_label.text = "BPM: "
	bpm_label.add_theme_font_size_override("font_size", 16)
	display_container.add_child(bpm_label)
	
	bpm_value_label = Label.new()
	bpm_value_label.text = str(int(current_bpm))
	bpm_value_label.add_theme_font_size_override("font_size", 24)
	bpm_value_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	display_container.add_child(bpm_value_label)
	
	# Slider control
	var slider_container = HBoxContainer.new()
	vbox.add_child(slider_container)
	
	decrease_button = Button.new()
	decrease_button.text = "-"
	decrease_button.custom_minimum_size = Vector2(30, 30)
	decrease_button.pressed.connect(_on_decrease_pressed)
	slider_container.add_child(decrease_button)
	
	bpm_slider = HSlider.new()
	bpm_slider.min_value = min_bpm
	bpm_slider.max_value = max_bpm
	bpm_slider.step = 0.01  # Smooth control as per guidelines
	bpm_slider.value = current_bpm
	bpm_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bpm_slider.value_changed.connect(_on_bpm_slider_changed)
	slider_container.add_child(bpm_slider)
	
	increase_button = Button.new()
	increase_button.text = "+"
	increase_button.custom_minimum_size = Vector2(30, 30)
	increase_button.pressed.connect(_on_increase_pressed)
	slider_container.add_child(increase_button)
	
	# Preset buttons
	var preset_label = Label.new()
	preset_label.text = "Presets:"
	preset_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(preset_label)
	
	preset_container = HBoxContainer.new()
	preset_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(preset_container)
	
	_create_preset_buttons()
	
	# Tap tempo button
	if enable_tap_tempo:
		tap_button = Button.new()
		tap_button.text = "Tap Tempo"
		tap_button.pressed.connect(_on_tap_tempo)
		vbox.add_child(tap_button)
	
	# Set initial theme
	_update_theme()
	
	# Update display
	_update_display()


func _create_preset_buttons():
	"""Create preset BPM buttons"""
	var presets = [80, 100, 120, 140, 160]
	
	for preset in presets:
		var button = Button.new()
		button.text = str(preset)
		button.custom_minimum_size = Vector2(35, 25)
		button.pressed.connect(_on_preset_pressed.bind(preset))
		preset_container.add_child(button)


func _on_preset_pressed(preset_bpm: int):
	"""Handle preset button press"""
	set_bpm(float(preset_bpm))


func _on_decrease_pressed():
	"""Decrease BPM by step amount"""
	set_bpm(current_bpm - bpm_step)


func _on_increase_pressed():
	"""Increase BPM by step amount"""
	set_bpm(current_bpm + bpm_step)


func _on_bpm_slider_changed(value: float):
	"""Handle slider value change"""
	# Round to nearest step
	var rounded_bpm = round(value / bpm_step) * bpm_step
	set_bpm(rounded_bpm, false)  # Don't update slider since it's the source


func _on_tap_tempo():
	"""Handle tap tempo button press"""
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Reset if too much time has passed
	if current_time - last_tap_time > tap_timeout:
		tap_times.clear()
	
	last_tap_time = current_time
	tap_times.append(current_time)
	
	# Need at least 2 taps to calculate BPM
	if tap_times.size() >= 2:
		var intervals: Array[float] = []
		
		# Calculate intervals between taps
		for i in range(1, tap_times.size()):
			intervals.append(tap_times[i] - tap_times[i - 1])
		
		# Calculate average interval
		var avg_interval = 0.0
		for interval in intervals:
			avg_interval += interval
		avg_interval /= intervals.size()
		
		# Convert to BPM
		var detected_bpm = 60.0 / avg_interval
		detected_bpm = clamp(detected_bpm, min_bpm, max_bpm)
		
		# Round to nearest step
		detected_bpm = round(detected_bpm / bpm_step) * bpm_step
		
		set_bpm(detected_bpm)
		emit_signal("tap_tempo_detected", detected_bpm)
		
		# Limit tap history
		if tap_times.size() > 8:
			tap_times.pop_front()
	
	# Visual feedback
	if tap_button:
		tap_button.modulate = Color(1.2, 1.2, 1.2)
		var tween = create_tween()
		tween.tween_property(tap_button, "modulate", Color.WHITE, 0.1)


func set_bpm(bpm: float, update_slider: bool = true):
	"""Set the BPM value"""
	current_bpm = clamp(bpm, min_bpm, max_bpm)
	
	# Update beat manager
	if beat_manager:
		beat_manager.bpm = current_bpm
	
	# Update slider
	if update_slider and bpm_slider:
		bpm_slider.set_value_no_signal(current_bpm)
	
	# Update display
	_update_display()
	
	# Emit signal
	emit_signal("bpm_changed", current_bpm)


func get_bpm() -> float:
	"""Get current BPM value"""
	return current_bpm


func _update_display():
	"""Update the BPM display"""
	bpm_value_label.text = str(int(current_bpm))
	
	# Update button states
	decrease_button.disabled = current_bpm <= min_bpm
	increase_button.disabled = current_bpm >= max_bpm
	
	# Highlight active preset
	var preset_values = [80, 100, 120, 140, 160]
	for i in range(preset_container.get_child_count()):
		var button = preset_container.get_child(i) as Button
		if i < preset_values.size() and preset_values[i] == int(current_bpm):
			button.modulate = Color(1.0, 0.8, 0.0)
		else:
			button.modulate = Color.WHITE


func _update_theme():
	"""Update panel theme"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.3, 0.3, 0.3)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	add_theme_stylebox_override("panel", style)


func enable_controls(enabled: bool):
	"""Enable or disable BPM controls"""
	bpm_slider.editable = enabled
	decrease_button.disabled = not enabled
	increase_button.disabled = not enabled
	
	for child in preset_container.get_children():
		if child is Button:
			child.disabled = not enabled
	
	if tap_button:
		tap_button.disabled = not enabled