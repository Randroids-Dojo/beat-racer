extends PanelContainer
class_name BeatVisualizationPanel

# Beat Visualization Panel
# Comprehensive visual feedback for beat synchronization
# Shows beat count, BPM, and multiple visual indicators

signal visualization_ready()

# UI Components
var _bpm_label: Label
var _beat_count_label: Label
var _measure_label: Label
var _sync_status_label: Label
var _main_indicator: BeatIndicator
var _sub_indicators: Array[BeatIndicator] = []

# Layout
@export var show_bpm: bool = true
@export var show_beat_count: bool = true
@export var show_measure: bool = true
@export var show_sync_status: bool = true
@export var show_sub_indicators: bool = true
@export var sub_indicator_count: int = 4

# Visual properties
@export var panel_color: Color = Color(0.1, 0.1, 0.1, 0.9)
@export var text_color: Color = Color.WHITE
@export var accent_color: Color = Color.CYAN

# References
var _beat_manager: Node = null
var _playback_sync: PlaybackSync = null

# State
var _is_initialized: bool = false

func _ready():
	_setup_ui()
	_connect_references()
	_apply_theme()
	
	_is_initialized = true
	emit_signal("visualization_ready")

func _setup_ui():
	# Create main container
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)
	
	# Header with title
	var header = Label.new()
	header.text = "Beat Sync"
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", accent_color)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)
	
	# Info panel
	var info_panel = PanelContainer.new()
	var info_grid = GridContainer.new()
	info_grid.columns = 2
	info_grid.add_theme_constant_override("h_separation", 20)
	info_grid.add_theme_constant_override("v_separation", 5)
	info_panel.add_child(info_grid)
	vbox.add_child(info_panel)
	
	# BPM display
	if show_bpm:
		var bpm_title = Label.new()
		bpm_title.text = "BPM:"
		info_grid.add_child(bpm_title)
		
		_bpm_label = Label.new()
		_bpm_label.text = "120"
		_bpm_label.add_theme_font_size_override("font_size", 20)
		info_grid.add_child(_bpm_label)
	
	# Beat count display
	if show_beat_count:
		var beat_title = Label.new()
		beat_title.text = "Beat:"
		info_grid.add_child(beat_title)
		
		_beat_count_label = Label.new()
		_beat_count_label.text = "0"
		_beat_count_label.add_theme_font_size_override("font_size", 20)
		info_grid.add_child(_beat_count_label)
	
	# Measure display
	if show_measure:
		var measure_title = Label.new()
		measure_title.text = "Measure:"
		info_grid.add_child(measure_title)
		
		_measure_label = Label.new()
		_measure_label.text = "0"
		_measure_label.add_theme_font_size_override("font_size", 20)
		info_grid.add_child(_measure_label)
	
	# Sync status
	if show_sync_status:
		var sync_title = Label.new()
		sync_title.text = "Sync:"
		info_grid.add_child(sync_title)
		
		_sync_status_label = Label.new()
		_sync_status_label.text = "OFF"
		_sync_status_label.add_theme_font_size_override("font_size", 20)
		info_grid.add_child(_sync_status_label)
	
	# Main beat indicator
	var indicator_container = CenterContainer.new()
	indicator_container.custom_minimum_size = Vector2(150, 150)
	vbox.add_child(indicator_container)
	
	_main_indicator = BeatIndicator.new()
	_main_indicator.indicator_size = 100.0
	_main_indicator.pulse_color = accent_color
	indicator_container.add_child(_main_indicator)
	
	# Sub indicators for individual beats in measure
	if show_sub_indicators:
		var sub_container = HBoxContainer.new()
		sub_container.alignment = BoxContainer.ALIGNMENT_CENTER
		sub_container.add_theme_constant_override("separation", 20)
		vbox.add_child(sub_container)
		
		for i in range(sub_indicator_count):
			var sub_indicator = BeatIndicator.new()
			sub_indicator.indicator_size = 40.0
			sub_indicator.indicator_shape = "Square"
			sub_indicator.pulse_color = accent_color if i == 0 else text_color
			sub_indicator.base_color = Color(0.3, 0.3, 0.3)
			sub_indicator.enable_glow = false
			sub_container.add_child(sub_indicator)
			_sub_indicators.append(sub_indicator)

func _connect_references():
	# Get singleton references
	_beat_manager = get_node("/root/BeatManager") if has_node("/root/BeatManager") else null
	
	if _beat_manager:
		_beat_manager.connect("beat_occurred", _on_beat_occurred)
		_beat_manager.connect("measure_completed", _on_measure_completed)
		_beat_manager.connect("bpm_changed", _on_bpm_changed)
	
	# Try to find PlaybackSync in the scene
	var nodes = get_tree().get_nodes_in_group("playback_sync")
	if nodes.size() > 0:
		_playback_sync = nodes[0]
		_playback_sync.connect("sync_started", _on_sync_started)
		_playback_sync.connect("sync_stopped", _on_sync_stopped)

func _apply_theme():
	# Panel styling
	add_theme_stylebox_override("panel", _create_panel_style())
	
	# Apply text color to all labels
	for child in get_children():
		_apply_text_color_recursive(child)

func _create_panel_style() -> StyleBox:
	var style = StyleBoxFlat.new()
	style.bg_color = panel_color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	return style

func _apply_text_color_recursive(node: Node):
	if node is Label:
		if not node.has_theme_color_override("font_color"):
			node.add_theme_color_override("font_color", text_color)
	
	for child in node.get_children():
		_apply_text_color_recursive(child)

func _on_beat_occurred(beat_number: int, beat_time: float):
	if _beat_count_label:
		_beat_count_label.text = str(beat_number)
	
	# Update sub indicators
	if _beat_manager and _sub_indicators.size() > 0:
		var beat_in_measure = _beat_manager.get_current_beat_in_measure()
		
		for i in range(_sub_indicators.size()):
			if i == beat_in_measure:
				_sub_indicators[i].trigger_pulse()

func _on_measure_completed(measure_number: int, _measure_time: float):
	if _measure_label:
		_measure_label.text = str(measure_number)

func _on_bpm_changed(_old_bpm: float, new_bpm: float):
	if _bpm_label:
		_bpm_label.text = str(int(new_bpm))

func _on_sync_started():
	if _sync_status_label:
		_sync_status_label.text = "ON"
		_sync_status_label.add_theme_color_override("font_color", Color.GREEN)

func _on_sync_stopped():
	if _sync_status_label:
		_sync_status_label.text = "OFF"
		_sync_status_label.add_theme_color_override("font_color", Color.RED)

# Public methods
func set_accent_color(color: Color):
	accent_color = color
	if _main_indicator:
		_main_indicator.pulse_color = color
	if _sub_indicators.size() > 0:
		_sub_indicators[0].pulse_color = color

func reset_counters():
	if _beat_count_label:
		_beat_count_label.text = "0"
	if _measure_label:
		_measure_label.text = "0"
	
	if _main_indicator:
		_main_indicator.reset()
	
	for indicator in _sub_indicators:
		indicator.reset()

func set_visibility_options(bpm: bool, beat: bool, measure: bool, sync: bool, sub: bool):
	show_bpm = bpm
	show_beat_count = beat
	show_measure = measure
	show_sync_status = sync
	show_sub_indicators = sub
	
	# Rebuild UI with new options
	for child in get_children():
		child.queue_free()
	
	_setup_ui()
	_connect_references()
	_apply_theme()

# Debug methods
func print_debug_info():
	print("=== BeatVisualizationPanel Debug Info ===")
	print("Initialized: %s" % str(_is_initialized))
	print("BeatManager Connected: %s" % str(_beat_manager != null))
	print("PlaybackSync Connected: %s" % str(_playback_sync != null))
	print("Sub Indicators: %d" % _sub_indicators.size())
	print("========================================")
