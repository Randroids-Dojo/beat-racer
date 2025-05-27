extends PanelContainer
class_name GameStatusIndicator

# Game Status Indicator
# Unified UI component showing recording/playback status
# Combines functionality for both recording and playback modes

signal mode_changed(new_mode: Mode)

# Visual settings
@export var indicator_size: Vector2 = Vector2(250, 80)
@export var idle_color: Color = Color(0.7, 0.7, 0.7)
@export var recording_color: Color = Color(1.0, 0.3, 0.3)
@export var playback_color: Color = Color(0.3, 0.8, 1.0)
@export var paused_color: Color = Color(1.0, 1.0, 0.3)

# Mode management
enum Mode { IDLE, RECORDING, PLAYING, PAUSED }
var current_mode: Mode = Mode.IDLE

# UI References
var mode_icon: TextureRect
var mode_label: Label
var time_label: Label
var info_label: Label

# State tracking
var mode_start_time: float = 0.0
var is_looping: bool = false
var loop_count: int = 0


func _ready():
	custom_minimum_size = indicator_size
	
	# Create UI structure
	var vbox = VBoxContainer.new()
	add_child(vbox)
	
	# Top row with icon and mode
	var top_row = HBoxContainer.new()
	vbox.add_child(top_row)
	
	# Mode icon (using simple shapes for now)
	mode_icon = TextureRect.new()
	mode_icon.custom_minimum_size = Vector2(24, 24)
	mode_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top_row.add_child(mode_icon)
	
	# Mode label
	mode_label = Label.new()
	mode_label.add_theme_font_size_override("font_size", 16)
	mode_label.text = "IDLE"
	top_row.add_child(mode_label)
	
	# Add spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)
	
	# Time label
	time_label = Label.new()
	time_label.text = "0:00"
	top_row.add_child(time_label)
	
	# Info label
	info_label = Label.new()
	info_label.text = "Ready to record"
	info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(info_label)
	
	# Set initial theme
	_update_theme()
	
	# Start process for time updates
	set_process(true)


func set_mode(mode: Mode):
	"""Change the current mode"""
	if current_mode == mode:
		return
	
	current_mode = mode
	mode_start_time = Time.get_ticks_msec() / 1000.0
	
	# Reset loop count when changing modes
	if mode != Mode.PLAYING:
		loop_count = 0
	
	_update_display()
	_update_theme()
	emit_signal("mode_changed", mode)


func set_recording():
	"""Switch to recording mode"""
	set_mode(Mode.RECORDING)
	info_label.text = "Recording lap..."


func set_playback():
	"""Switch to playback mode"""
	set_mode(Mode.PLAYING)
	info_label.text = "Playing recording"


func set_paused():
	"""Switch to paused mode"""
	set_mode(Mode.PAUSED)
	info_label.text = "Playback paused"


func set_idle():
	"""Switch to idle mode"""
	set_mode(Mode.IDLE)
	info_label.text = "Ready to record"


func update_info(text: String):
	"""Update the info label text"""
	info_label.text = text


func set_loop_info(enabled: bool, count: int = 0):
	"""Update loop information"""
	is_looping = enabled
	loop_count = count
	
	if is_looping and current_mode == Mode.PLAYING:
		if loop_count > 0:
			info_label.text = "Loop %d" % loop_count
		else:
			info_label.text = "Looping enabled"


func _process(_delta: float):
	# Update time display based on mode
	if current_mode in [Mode.RECORDING, Mode.PLAYING]:
		var elapsed = Time.get_ticks_msec() / 1000.0 - mode_start_time
		time_label.text = _format_time(elapsed)


func _format_time(seconds: float) -> String:
	"""Format time as M:SS"""
	var minutes = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%d:%02d" % [minutes, secs]


func _update_display():
	"""Update display elements based on mode"""
	match current_mode:
		Mode.IDLE:
			mode_label.text = "IDLE"
			_set_icon_idle()
		Mode.RECORDING:
			mode_label.text = "REC"
			_set_icon_recording()
		Mode.PLAYING:
			mode_label.text = "PLAY"
			_set_icon_playing()
		Mode.PAUSED:
			mode_label.text = "PAUSE"
			_set_icon_paused()


func _update_theme():
	"""Update colors based on mode"""
	var color = idle_color
	
	match current_mode:
		Mode.RECORDING:
			color = recording_color
		Mode.PLAYING:
			color = playback_color
		Mode.PAUSED:
			color = paused_color
	
	mode_label.modulate = color
	
	# Update panel style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	add_theme_stylebox_override("panel", style)


func _set_icon_idle():
	"""Set idle icon (circle)"""
	_create_icon_texture(Color.WHITE, "circle")


func _set_icon_recording():
	"""Set recording icon (filled circle)"""
	_create_icon_texture(recording_color, "filled_circle")


func _set_icon_playing():
	"""Set playing icon (triangle)"""
	_create_icon_texture(playback_color, "triangle")


func _set_icon_paused():
	"""Set paused icon (two bars)"""
	_create_icon_texture(paused_color, "pause")


func _create_icon_texture(color: Color, shape: String):
	"""Create simple icon textures"""
	var image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	
	# Simple drawing based on shape
	match shape:
		"circle":
			# Draw circle outline
			for y in range(24):
				for x in range(24):
					var dist = Vector2(x - 12, y - 12).length()
					if dist >= 8 and dist <= 10:
						image.set_pixel(x, y, color)
		
		"filled_circle":
			# Draw filled circle
			for y in range(24):
				for x in range(24):
					var dist = Vector2(x - 12, y - 12).length()
					if dist <= 10:
						image.set_pixel(x, y, color)
		
		"triangle":
			# Draw play triangle
			for y in range(6, 18):
				var width = (y - 6) / 2
				for x in range(8, 8 + width):
					image.set_pixel(x, y, color)
		
		"pause":
			# Draw pause bars
			for y in range(6, 18):
				for x in range(8, 11):
					image.set_pixel(x, y, color)
				for x in range(13, 16):
					image.set_pixel(x, y, color)
	
	var texture = ImageTexture.create_from_image(image)
	mode_icon.texture = texture