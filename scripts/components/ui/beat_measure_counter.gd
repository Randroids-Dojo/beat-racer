extends PanelContainer
class_name BeatMeasureCounter

# Beat Measure Counter
# Displays current beat and measure count with visual feedback

signal measure_changed(measure: int)
signal beat_changed(beat: int, beat_in_measure: int)

# Visual settings
@export var counter_size: Vector2 = Vector2(200, 60)
@export var beat_flash_duration: float = 0.1
@export var downbeat_color: Color = Color(1.0, 0.8, 0.0)
@export var beat_color: Color = Color(0.8, 0.8, 0.8)
@export var inactive_color: Color = Color(0.4, 0.4, 0.4)

# Display settings
@export var show_beat_dots: bool = true
@export var max_beat_dots: int = 4

# UI References
var measure_label: Label
var beat_label: Label
var beat_dots_container: HBoxContainer
var beat_dots: Array[Panel] = []

# State
var current_measure: int = 0
var current_beat: int = 0
var beat_in_measure: int = 0
var beats_per_measure: int = 4
var is_flashing: bool = false
var flash_timer: float = 0.0

# Beat manager reference
var beat_manager: Node


func _ready():
	custom_minimum_size = counter_size
	
	# Get beat manager
	beat_manager = get_node("/root/BeatManager") if has_node("/root/BeatManager") else null
	if beat_manager:
		beat_manager.beat_occurred.connect(_on_beat_occurred)
		beats_per_measure = beat_manager.beats_per_measure
	
	# Create UI structure
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)
	
	# Top row with measure and beat
	var top_row = HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(top_row)
	
	# Measure label
	var measure_container = VBoxContainer.new()
	measure_container.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_child(measure_container)
	
	var measure_title = Label.new()
	measure_title.text = "Measure"
	measure_title.add_theme_font_size_override("font_size", 10)
	measure_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	measure_container.add_child(measure_title)
	
	measure_label = Label.new()
	measure_label.text = "1"
	measure_label.add_theme_font_size_override("font_size", 20)
	measure_container.add_child(measure_label)
	
	# Separator
	var separator = Label.new()
	separator.text = " : "
	separator.add_theme_font_size_override("font_size", 20)
	top_row.add_child(separator)
	
	# Beat label
	var beat_container = VBoxContainer.new()
	beat_container.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_child(beat_container)
	
	var beat_title = Label.new()
	beat_title.text = "Beat"
	beat_title.add_theme_font_size_override("font_size", 10)
	beat_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	beat_container.add_child(beat_title)
	
	beat_label = Label.new()
	beat_label.text = "1"
	beat_label.add_theme_font_size_override("font_size", 20)
	beat_container.add_child(beat_label)
	
	# Beat dots visualization
	if show_beat_dots:
		beat_dots_container = HBoxContainer.new()
		beat_dots_container.alignment = BoxContainer.ALIGNMENT_CENTER
		beat_dots_container.add_theme_constant_override("separation", 8)
		vbox.add_child(beat_dots_container)
		
		_create_beat_dots()
	
	# Set initial theme
	_update_theme()
	
	set_process(true)


func _create_beat_dots():
	"""Create beat dot indicators"""
	var dots_to_create = min(beats_per_measure, max_beat_dots)
	
	for i in range(dots_to_create):
		var dot = Panel.new()
		dot.custom_minimum_size = Vector2(8, 8)
		
		var style = StyleBoxFlat.new()
		style.bg_color = inactive_color
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		dot.add_theme_stylebox_override("panel", style)
		
		beat_dots_container.add_child(dot)
		beat_dots.append(dot)


func _on_beat_occurred(beat_count: int, _beat_time: float):
	"""Handle beat signal from BeatManager"""
	current_beat = beat_count
	
	# Calculate measure and beat in measure
	if beat_manager:
		current_measure = beat_manager.current_measure
		beat_in_measure = beat_manager.current_beat_in_measure
	else:
		current_measure = (beat_count / beats_per_measure) + 1
		beat_in_measure = (beat_count % beats_per_measure) + 1
	
	# Update display
	_update_display()
	
	# Trigger flash
	_start_flash(beat_in_measure == 1)
	
	# Emit signals
	emit_signal("beat_changed", current_beat, beat_in_measure)
	if beat_in_measure == 1:
		emit_signal("measure_changed", current_measure)


func _update_display():
	"""Update the counter display"""
	measure_label.text = str(current_measure)
	beat_label.text = str(beat_in_measure)
	
	# Update beat dots
	if show_beat_dots:
		for i in range(beat_dots.size()):
			var dot = beat_dots[i]
			var style = dot.get_theme_stylebox("panel") as StyleBoxFlat
			
			if i < beat_in_measure:
				# Active beat
				if i == 0:
					style.bg_color = downbeat_color
				else:
					style.bg_color = beat_color
			else:
				# Inactive beat
				style.bg_color = inactive_color


func _start_flash(is_downbeat: bool):
	"""Start beat flash animation"""
	is_flashing = true
	flash_timer = beat_flash_duration
	
	# Set flash color
	var flash_color = downbeat_color if is_downbeat else beat_color
	measure_label.modulate = flash_color if is_downbeat else Color.WHITE
	beat_label.modulate = flash_color


func _process(delta: float):
	# Handle flash animation
	if is_flashing:
		flash_timer -= delta
		
		if flash_timer <= 0:
			is_flashing = false
			measure_label.modulate = Color.WHITE
			beat_label.modulate = Color.WHITE
		else:
			# Fade out the flash
			var t = flash_timer / beat_flash_duration
			var alpha = t
			measure_label.modulate.a = 1.0 + alpha * 0.5
			beat_label.modulate.a = 1.0 + alpha * 0.5


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


func reset():
	"""Reset the counter"""
	current_measure = 0
	current_beat = 0
	beat_in_measure = 0
	_update_display()


func set_beats_per_measure(beats: int):
	"""Update beats per measure and recreate dots if needed"""
	if beats == beats_per_measure:
		return
	
	beats_per_measure = beats
	
	# Recreate beat dots
	if show_beat_dots and beat_dots_container:
		# Clear existing dots
		for dot in beat_dots:
			dot.queue_free()
		beat_dots.clear()
		
		# Create new dots
		_create_beat_dots()


func set_show_beat_dots(show: bool):
	"""Toggle beat dots visibility"""
	show_beat_dots = show
	if beat_dots_container:
		beat_dots_container.visible = show