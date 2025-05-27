extends Control
class_name GameUIPanel

# Game UI Panel
# Main UI container that organizes all game UI elements

signal vehicle_changed(type: VehicleSelector.VehicleType, color: Color)
signal bpm_changed(bpm: float)
signal recording_started()
signal recording_stopped()
signal playback_started()
signal playback_stopped()

# Layout settings
@export var panel_margin: int = 20
@export var element_spacing: int = 10
@export var auto_hide_delay: float = 5.0
@export var enable_auto_hide: bool = false

# UI Components
var status_indicator: GameStatusIndicator
var beat_counter: BeatMeasureCounter
var bpm_control: BPMControl
var vehicle_selector: VehicleSelector

# Layout containers
var top_panel: HBoxContainer
var bottom_panel: HBoxContainer
var left_panel: VBoxContainer
var right_panel: VBoxContainer

# State
var is_visible: bool = true
var auto_hide_timer: float = 0.0


func _ready():
	# Set to fill screen
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Create main panels
	_create_panels()
	
	# Create UI components
	_create_ui_components()
	
	# Arrange components
	_arrange_ui()
	
	# Connect signals
	_connect_signals()


func _create_panels():
	"""Create the main layout panels"""
	# Top panel
	top_panel = HBoxContainer.new()
	top_panel.anchor_right = 1.0
	top_panel.position = Vector2(panel_margin, panel_margin)
	top_panel.size.x = get_viewport().size.x - (panel_margin * 2)
	top_panel.add_theme_constant_override("separation", element_spacing)
	add_child(top_panel)
	
	# Bottom panel
	bottom_panel = HBoxContainer.new()
	bottom_panel.anchor_top = 1.0
	bottom_panel.anchor_bottom = 1.0
	bottom_panel.anchor_right = 1.0
	bottom_panel.position = Vector2(panel_margin, -panel_margin)
	bottom_panel.size.x = get_viewport().size.x - (panel_margin * 2)
	bottom_panel.add_theme_constant_override("separation", element_spacing)
	add_child(bottom_panel)
	
	# Left panel
	left_panel = VBoxContainer.new()
	left_panel.anchor_bottom = 1.0
	left_panel.position = Vector2(panel_margin, panel_margin)
	left_panel.size.y = get_viewport().size.y - (panel_margin * 2)
	left_panel.add_theme_constant_override("separation", element_spacing)
	left_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(left_panel)
	
	# Right panel
	right_panel = VBoxContainer.new()
	right_panel.anchor_left = 1.0
	right_panel.anchor_right = 1.0
	right_panel.anchor_bottom = 1.0
	right_panel.position = Vector2(-panel_margin, panel_margin)
	right_panel.size.y = get_viewport().size.y - (panel_margin * 2)
	right_panel.add_theme_constant_override("separation", element_spacing)
	right_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(right_panel)


func _create_ui_components():
	"""Create all UI components"""
	# Status indicator
	status_indicator = GameStatusIndicator.new()
	status_indicator.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Beat counter
	beat_counter = BeatMeasureCounter.new()
	beat_counter.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# BPM control
	bpm_control = BPMControl.new()
	bpm_control.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Vehicle selector
	vehicle_selector = VehicleSelector.new()
	vehicle_selector.mouse_filter = Control.MOUSE_FILTER_PASS


func _arrange_ui():
	"""Arrange UI components in panels"""
	# Top left: Status and beat counter
	top_panel.add_child(status_indicator)
	top_panel.add_child(beat_counter)
	
	# Add spacer to push BPM to the right
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_panel.add_child(spacer)
	
	# Top right: BPM control
	top_panel.add_child(bpm_control)
	
	# Bottom left: Vehicle selector
	bottom_panel.add_child(vehicle_selector)
	
	# Adjust bottom panel position
	var vehicle_height = vehicle_selector.get_combined_minimum_size().y
	bottom_panel.position.y = -vehicle_height - panel_margin


func _connect_signals():
	"""Connect component signals"""
	# Vehicle selector
	vehicle_selector.vehicle_selected.connect(_on_vehicle_selected)
	vehicle_selector.color_changed.connect(_on_vehicle_color_changed)
	
	# BPM control
	bpm_control.bpm_changed.connect(_on_bpm_changed)
	
	# Status indicator
	status_indicator.mode_changed.connect(_on_mode_changed)


func _on_vehicle_selected(type: VehicleSelector.VehicleType):
	"""Handle vehicle selection"""
	var color = vehicle_selector.get_selected_color()
	emit_signal("vehicle_changed", type, color)


func _on_vehicle_color_changed(color: Color):
	"""Handle vehicle color change"""
	var type = vehicle_selector.get_selected_vehicle()
	emit_signal("vehicle_changed", type, color)


func _on_bpm_changed(bpm: float):
	"""Handle BPM change"""
	emit_signal("bpm_changed", bpm)


func _on_mode_changed(mode: GameStatusIndicator.Mode):
	"""Handle mode change from status indicator"""
	match mode:
		GameStatusIndicator.Mode.RECORDING:
			emit_signal("recording_started")
		GameStatusIndicator.Mode.PLAYING:
			emit_signal("playback_started")
		GameStatusIndicator.Mode.IDLE:
			# Could be from either recording or playback
			pass


func _process(delta: float):
	# Handle auto-hide
	if enable_auto_hide and is_visible:
		auto_hide_timer += delta
		if auto_hide_timer >= auto_hide_delay:
			hide_ui()


func _input(event: InputEvent):
	# Show UI on any input
	if enable_auto_hide and not is_visible:
		if event is InputEventKey or event is InputEventMouseButton:
			show_ui()


# Public methods
func set_recording_mode(active: bool):
	"""Set recording mode in status indicator"""
	if active:
		status_indicator.set_recording()
		bpm_control.enable_controls(false)
		vehicle_selector.visible = false
	else:
		status_indicator.set_idle()
		bpm_control.enable_controls(true)
		vehicle_selector.visible = true


func set_playback_mode(active: bool, paused: bool = false):
	"""Set playback mode in status indicator"""
	if active:
		if paused:
			status_indicator.set_paused()
		else:
			status_indicator.set_playback()
		bpm_control.enable_controls(false)
		vehicle_selector.visible = false
	else:
		status_indicator.set_idle()
		bpm_control.enable_controls(true)
		vehicle_selector.visible = true


func update_status_info(text: String):
	"""Update status indicator info text"""
	status_indicator.update_info(text)


func update_loop_info(enabled: bool, count: int = 0):
	"""Update loop information in status"""
	status_indicator.set_loop_info(enabled, count)


func show_ui():
	"""Show all UI elements"""
	is_visible = true
	visible = true
	auto_hide_timer = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)


func hide_ui():
	"""Hide all UI elements"""
	is_visible = false
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): visible = false).set_delay(0.3)


func toggle_ui():
	"""Toggle UI visibility"""
	if is_visible:
		hide_ui()
	else:
		show_ui()


func get_selected_vehicle() -> VehicleSelector.VehicleType:
	"""Get currently selected vehicle"""
	return vehicle_selector.get_selected_vehicle()


func get_selected_vehicle_color() -> Color:
	"""Get selected vehicle color"""
	return vehicle_selector.get_selected_color()


func get_current_bpm() -> float:
	"""Get current BPM setting"""
	return bpm_control.get_bpm()


func reset_beat_counter():
	"""Reset the beat/measure counter"""
	beat_counter.reset()